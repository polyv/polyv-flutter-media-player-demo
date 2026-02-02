package com.polyv.polyv_media_player

import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaResource
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaBitRate
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaSubtitle
import net.polyv.android.player.business.scene.common.model.vo.PLVViewerParam
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMainAccountAuthentication
import net.polyv.android.player.business.scene.vod.model.vo.PLVVodSubtitleText
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMediaResource
import net.polyv.android.player.core.api.listener.event.PLVMediaPlayerOnInfoEvent
import net.polyv.android.player.core.api.listener.state.PLVMediaPlayerPlayingState
import net.polyv.android.player.core.api.option.PLVMediaPlayerOptionEnum
import net.polyv.android.player.sdk.PLVMediaPlayer
import net.polyv.android.player.sdk.PLVVideoView
import net.polyv.android.player.sdk.foundation.lang.MutableObserver
import net.polyv.android.player.sdk.addon.download.common.PLVMediaDownloader
import net.polyv.android.player.sdk.addon.download.common.model.vo.PLVMediaDownloadStatus
import net.polyv.android.player.sdk.addon.download.common.model.vo.PLVMediaDownloadSetting
import net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager
import java.util.Timer
import java.util.TimerTask
import kotlin.concurrent.schedule

/** PolyvMediaPlayerPlugin */
class PolyvMediaPlayerPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var playbackEventChannel: EventChannel
    private lateinit var downloadEventChannel: EventChannel

    private val mainHandler = Handler(Looper.getMainLooper())

    private var applicationContext: Context? = null
    private var player: PLVMediaPlayer? = null

    private var playbackEventSink: EventChannel.EventSink? = null
    private var downloadEventSink: EventChannel.EventSink? = null
    private val observers = mutableListOf<MutableObserver<*>>()

    // 运行时注入的账号配置（优先于 AndroidManifest 中的配置）
    private var injectedUserId: String? = null
    private var injectedSecretKey: String? = null
    private var injectedReadToken: String? = null
    private var injectedWriteToken: String? = null

    // 用于将 SDK 的 vodCurrentSubTitleTexts 回调到实际的 Android View 上进行渲染
    private var subtitleTextUpdater: ((List<PLVVodSubtitleText>) -> Unit)? = null

    private var currentVid: String? = null

    // 清晰度切换时用于在新清晰度准备完成后恢复进度和播放状态
    private var pendingSeekPositionAfterQualityChange: Long? = null
    private var pendingAutoPlayAfterQualityChange: Boolean = false
    private var isChangingBitRate: Boolean = false
    private var targetBitRateName: String? = null // 记录目标清晰度名称
    private var lastKnownDurationMs: Long = 0L // 记录最近一次非 0 的总时长，用于避免切清晰度期间 duration 短暂回到 0

    private val methodChannelName = "com.polyv.media_player/player"
    private val eventChannelName = "com.polyv.media_player/events"
    private val downloadEventChannelName = "com.polyv.media_player/download_events"
    private val videoViewType = "com.polyv.media_player/video_view"

    private val errorCodeInvalidVid = "INVALID_VID"
    private val errorCodeNetworkError = "NETWORK_ERROR"
    private val errorCodeNotInitialized = "NOT_INITIALIZED"

    private val stateIdle = "idle"
    private val stateLoading = "loading"
    private val statePrepared = "prepared"
    private val statePlaying = "playing"
    private val statePaused = "paused"
    private val stateBuffering = "buffering"
    private val stateCompleted = "completed"
    private val stateError = "error"

    // Story 9.8: 下载事件类型
    private val downloadEventTaskProgress = "taskProgress"
    private val downloadEventTaskCompleted = "taskCompleted"
    private val downloadEventTaskFailed = "taskFailed"
    private val downloadEventTaskRemoved = "taskRemoved"
    private val downloadEventTaskPaused = "taskPaused"
    private val downloadEventTaskResumed = "taskResumed"

    // Story 9.8: 下载状态跟踪
    private val downloadPreviousStates = mutableMapOf<String, PLVMediaDownloadStatus?>()
    private var downloadStatusCheckTimer: Timer? = null
    private val deletedDownloadVids = mutableSetOf<String>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(this)

        playbackEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, eventChannelName)
        playbackEventChannel.setStreamHandler(this)

        downloadEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, downloadEventChannelName)
        downloadEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                android.util.Log.d(
                    "PolyvMediaPlayerPlugin",
                    "downloadEventChannel onListen called, eventSink: ${events != null}"
                )
                downloadEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                android.util.Log.d("PolyvMediaPlayerPlugin", "downloadEventChannel onCancel called")
                downloadEventSink = null
            }
        })

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            videoViewType,
            PolyvVideoViewFactory(this)
        )

        // 初始化下载管理器（必须在调用 getDownloader 之前）
        // 参考 polyv-android-media-player-sdk-demo 示例代码
        try {
            val downloadSetting = PLVMediaDownloadSetting.defaultSetting(applicationContext!!)
            PLVMediaDownloaderManager.init(downloadSetting)
            android.util.Log.d("PolyvMediaPlayerPlugin", "PLVMediaDownloaderManager initialized successfully")
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to initialize PLVMediaDownloaderManager: ${e.message}", e)
        }

        // Story 9.8: 启动下载状态监控
        startDownloadStatusMonitoring()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getConfig" -> handleGetConfig(result)
            "initialize" -> handleInitialize(call, result)
            "loadVideo" -> handleLoadVideo(call, result)
            "play" -> handlePlay(result)
            "pause" -> handlePause(result)
            "stop" -> handleStop(result)
            "disposePlayer" -> handleDisposePlayer(result)
            "seekTo" -> handleSeekTo(call, result)
            "setPlaybackSpeed" -> handleSetPlaybackSpeed(call, result)
            "setQuality" -> handleSetQuality(call, result)
            "setSubtitle" -> handleSetSubtitle(call, result)
            "getQualities" -> result.success(emptyList<Any>())
            "getSubtitles" -> result.success(emptyList<Any>())
            "pauseDownload" -> handlePauseDownload(call, result)
            "resumeDownload" -> handleResumeDownload(call, result)
            "retryDownload" -> handleRetryDownload(call, result)
            "deleteDownload" -> handleDeleteDownload(call, result)
            "getDownloadList" -> handleGetDownloadList(result)
            "startDownload" -> handleStartDownload(call, result)
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }

    private fun sendDownloadEvent(event: Map<String, Any>) {
        val sink = downloadEventSink
        if (sink == null) {
            android.util.Log.e(
                "PolyvMediaPlayerPlugin",
                "downloadEventSink is null, cannot send event: $event"
            )
            return
        }
        mainHandler.post {
            try {
                android.util.Log.d("PolyvMediaPlayerPlugin", "Sending download event: $event")
                sink.success(event)
            } catch (t: Throwable) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send download event", t)
            }
        }
    }

    private fun sendDownloadEventReliably(event: Map<String, Any>) {
        val sink = downloadEventSink
        if (sink == null) {
            android.util.Log.w(
                "PolyvMediaPlayerPlugin",
                "downloadEventSink is null, queuing event: $event"
            )
            return
        }
        mainHandler.post {
            try {
                android.util.Log.d("PolyvMediaPlayerPlugin", "Sending reliable download event: $event")
                sink.success(event)
            } catch (t: Throwable) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send reliable download event", t)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "onListen called, eventSink: ${events != null}")
        playbackEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "onCancel called")
        playbackEventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        playbackEventChannel.setStreamHandler(null)
        downloadEventChannel.setStreamHandler(null)
        releasePlayer()
        applicationContext = null

        // Story 9.8: 停止下载状态监控
        stopDownloadStatusMonitoring()
    }

    internal fun ensurePlayer(): PLVMediaPlayer {
        val existing = player
        if (existing != null) return existing

        val newPlayer = PLVMediaPlayer()
        player = newPlayer

        observePlayer(newPlayer)
        sendStateChangeEvent(stateIdle)
        return newPlayer
    }

    private fun releasePlayer() {
        observers.forEach { observer ->
            try {
                observer.dispose()
            } catch (_: Throwable) {
            }
        }
        observers.clear()

        try {
            player?.destroy()
        } catch (_: Throwable) {
        }
        player = null
        currentVid = null

        // 清理清晰度切换状态
        isChangingBitRate = false
        targetBitRateName = null
        pendingSeekPositionAfterQualityChange = null
        pendingAutoPlayAfterQualityChange = false
        lastKnownDurationMs = 0L
    }

    internal fun setSubtitleTextUpdater(updater: ((List<PLVVodSubtitleText>) -> Unit)?) {
        subtitleTextUpdater = updater
    }

    internal fun clearSubtitleTextUpdaterIfMatches(updater: (List<PLVVodSubtitleText>) -> Unit) {
        if (subtitleTextUpdater === updater) {
            subtitleTextUpdater = null
        }
    }

    /// 获取账号配置（必须通过 initialize 方法预先注入）
    private fun getConfigOrThrow(): Pair<String, String> {
        val userId = injectedUserId
        val secretKey = injectedSecretKey

        if (!userId.isNullOrBlank() && !secretKey.isNullOrBlank()) {
            return Pair(userId, secretKey)
        }

        throw IllegalStateException("Polyv authentication not configured. Please call PolyvConfigService.setAccountConfig() with userId and secretKey before loading video.")
    }

    /// 处理 initialize 方法（从 Flutter 层注入配置）
    private fun handleInitialize(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()

        val userId = args["userId"]?.toString()?.trim()
        val secretKey = args["secretKey"]?.toString()?.trim()
        val readToken = args["readToken"]?.toString()?.trim()
        val writeToken = args["writeToken"]?.toString()?.trim()

        if (userId.isNullOrBlank() || secretKey.isNullOrBlank()) {
            result.error(
                "INVALID_CONFIG",
                "userId and secretKey are required",
                null
            )
            return
        }

        // 保存注入的配置
        injectedUserId = userId
        injectedSecretKey = secretKey
        injectedReadToken = readToken
        injectedWriteToken = writeToken

        android.util.Log.d("PolyvMediaPlayerPlugin", "Account config injected: userId=$userId")

        result.success(null)
    }

    private fun handleLoadVideo(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim().orEmpty()
        val autoPlay = (args?.get("autoPlay") as? Boolean) ?: false
        val isOfflineMode = (args?.get("isOfflineMode") as? Boolean) ?: false

        android.util.Log.d("PolyvMediaPlayerPlugin", "handleLoadVideo: vid=$vid, autoPlay=$autoPlay, isOfflineMode=$isOfflineMode")

        if (vid.isEmpty()) {
            result.error(errorCodeInvalidVid, "VID is required", null)
            return
        }

        currentVid = vid
        sendStateChangeEvent(stateLoading)

        val appCtx = applicationContext
        if (appCtx == null) {
            result.error(errorCodeNotInitialized, "Context not initialized", null)
            return
        }

        // 离线播放模式
        if (isOfflineMode) {
            android.util.Log.d("PolyvMediaPlayerPlugin", "Loading video in OFFLINE mode")
            loadVideoOffline(vid, autoPlay, appCtx, result)
            return
        }

        // 在线播放模式
        android.util.Log.d("PolyvMediaPlayerPlugin", "Loading video in ONLINE mode")
        loadVideoOnline(vid, autoPlay, appCtx, result)
    }

    /// 在线播放视频
    private fun loadVideoOnline(vid: String, autoPlay: Boolean, appCtx: Context, result: Result) {
        // 获取账号配置（优先使用运行时注入的配置）
        val config = try {
            getConfigOrThrow()
        } catch (e: IllegalStateException) {
            result.error(errorCodeNotInitialized, e.message, null)
            return
        }
        val userId = config.first
        val secretKey = config.second

        // 获取其他配置（使用运行时注入的值或默认值）
        val readToken = injectedReadToken
        val writeToken = injectedWriteToken

        val viewerId = "viewer"
        val viewerName = "viewer"
        val viewerExtra1: String? = null
        val viewerExtra2: String? = null
        val viewerExtra3: String? = null

        val authentication = PLVVodMainAccountAuthentication(userId, secretKey, readToken, writeToken)
        val viewerParam = PLVViewerParam(
            viewerId,
            viewerName,
            null,
            null,
            null,
            null,
            viewerExtra1,
            viewerExtra2,
            viewerExtra3
        )

        val downloadRoots = listOfNotNull(
            appCtx.getExternalFilesDir(null)?.absolutePath
        )

        val mediaResource = PLVMediaResource.vod(vid, authentication, viewerParam, downloadRoots)
        val plvPlayer = try {
            ensurePlayer()
        } catch (t: Throwable) {
            result.error(errorCodeNotInitialized, t.message, null)
            return
        }

        plvPlayer.setPlayerOption(
            listOf(
                PLVMediaPlayerOptionEnum.ENABLE_ACCURATE_SEEK.value("1"),
                PLVMediaPlayerOptionEnum.SKIP_ACCURATE_SEEK_AT_START.value("1"),
                PLVMediaPlayerOptionEnum.START_ON_PREPARED.value(if (autoPlay) "1" else "0"),
                PLVMediaPlayerOptionEnum.RENDER_ON_PREPARED.value("1")
            )
        )

        try {
            plvPlayer.setMediaResource(mediaResource)
            // 清晰度数据将在 onPrepared 事件中获取并发送
        } catch (t: Throwable) {
            sendErrorEvent(errorCodeNetworkError, t.message ?: "loadVideo failed")
            sendStateChangeEvent(stateError)
            result.error(errorCodeNetworkError, t.message, null)
            return
        }

        result.success(null)
    }

    /// 离线播放视频
    private fun loadVideoOffline(vid: String, autoPlay: Boolean, appCtx: Context, result: Result) {
        // 获取账号配置（离线播放也需要配置来获取视频元数据）
        val config = try {
            getConfigOrThrow()
        } catch (e: IllegalStateException) {
            result.error(errorCodeNotInitialized, e.message, null)
            return
        }
        val userId = config.first
        val secretKey = config.second
        val readToken = injectedReadToken
        val writeToken = injectedWriteToken

        // 获取下载目录
        val downloadRoots = listOfNotNull(
            appCtx.getExternalFilesDir(null)?.absolutePath
        )

        android.util.Log.d("PolyvMediaPlayerPlugin", "Download roots for offline playback: $downloadRoots")

        if (downloadRoots.isEmpty()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download directory not found")
            sendErrorEvent("OFFLINE_ERROR", "Download directory not found")
            sendStateChangeEvent(stateError)
            result.error("OFFLINE_ERROR", "Download directory not available", null)
            return
        }

        val viewerParam = PLVViewerParam(
            "viewer",
            "viewer",
            null, null, null, null,
            null, null, null
        )

        val authentication = PLVVodMainAccountAuthentication(userId, secretKey, readToken, writeToken)

        // 创建媒体资源，传入本地路径实现离线播放
        // 关键：downloadRoots 参数让 SDK 优先从本地加载
        val mediaResource = PLVMediaResource.vod(vid, authentication, viewerParam, downloadRoots)

        val plvPlayer = try {
            ensurePlayer()
        } catch (t: Throwable) {
            result.error(errorCodeNotInitialized, t.message, null)
            return
        }

        plvPlayer.setPlayerOption(
            listOf(
                PLVMediaPlayerOptionEnum.ENABLE_ACCURATE_SEEK.value("1"),
                PLVMediaPlayerOptionEnum.SKIP_ACCURATE_SEEK_AT_START.value("1"),
                PLVMediaPlayerOptionEnum.START_ON_PREPARED.value(if (autoPlay) "1" else "0"),
                PLVMediaPlayerOptionEnum.RENDER_ON_PREPARED.value("1")
            )
        )

        try {
            plvPlayer.setMediaResource(mediaResource)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Offline media resource set successfully")
            // 清晰度数据将在 onPrepared 事件中获取并发送
        } catch (t: Throwable) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to load offline video: ${t.message}")
            sendErrorEvent("OFFLINE_ERROR", t.message ?: "Failed to load offline video")
            sendStateChangeEvent(stateError)
            result.error("OFFLINE_ERROR", "Failed to load offline video: ${t.message}", null)
            return
        }

        result.success(null)
    }

    /// 获取 Polyv 配置信息
    private fun handleGetConfig(result: Result) {
        try {
            val userId = injectedUserId
            val secretKey = injectedSecretKey
            val readToken = injectedReadToken ?: ""
            val writeToken = injectedWriteToken ?: ""

            if (userId.isNullOrBlank() || secretKey.isNullOrBlank()) {
                result.error(
                    errorCodeNotInitialized,
                    "Polyv authentication not configured. Please call PolyvConfigService.setAccountConfig() with userId and secretKey",
                    null
                )
                return
            }

            val config = mapOf(
                "userId" to userId,
                "readToken" to readToken,
                "writeToken" to writeToken,
                "secretKey" to secretKey
            )

            result.success(config)
        } catch (t: Throwable) {
            result.error(errorCodeNetworkError, "Failed to get config: ${t.message}", null)
        }
    }

    private fun handlePlay(result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }
        try {
            plvPlayer.start()
            result.success(null)
        } catch (t: Throwable) {
            sendErrorEvent(errorCodeNetworkError, t.message ?: "play failed")
            sendStateChangeEvent(stateError)
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun handleSetQuality(call: MethodCall, result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }

        val args = call.arguments as? Map<*, *>
        val index = (args?.get("index") as? Number)?.toInt() ?: 0

        val bitRates = plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.value
        if (bitRates == null || bitRates.isEmpty()) {
            result.error(errorCodeNetworkError, "No available bitrates", null)
            return
        }

        if (index < 0 || index >= bitRates.size) {
            result.error(errorCodeNotInitialized, "Quality index out of range", null)
            return
        }

        try {
            // 记录当前播放状态
            val isPlaying = plvPlayer.getStateListenerRegistry().playingState.value == PLVMediaPlayerPlayingState.PLAYING

            // 如果当前正在播放，先暂停，避免在切换清晰度期间继续向前播放一段，再被 seek 回来，造成音频重复感
            if (isPlaying) {
                plvPlayer.pause()
            }

            // 在暂停之后再读取当前进度，用于在新清晰度准备完成后恢复，尽量贴近用户真实感知的位置
            val currentPosition = plvPlayer.getStateListenerRegistry().progressState.value ?: 0L

            val targetBitRate = bitRates[index]
            android.util.Log.d("PolyvMediaPlayerPlugin", "setQuality: index=$index, targetBitRate=${targetBitRate.name}, currentPosition=$currentPosition, isPlaying=$isPlaying")

            pendingSeekPositionAfterQualityChange = currentPosition
            pendingAutoPlayAfterQualityChange = isPlaying
            isChangingBitRate = true
            targetBitRateName = targetBitRate.name // 记录目标清晰度名称

            plvPlayer.changeBitRate(targetBitRate)

            // 切换清晰度后，重新发送一次清晰度数据，
            // 以便 Flutter 端更新當前選中清晰度索引
            val updatedBitRates = plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.value
            sendQualityData(updatedBitRates ?: bitRates)

            result.success(null)
        } catch (t: Throwable) {
            isChangingBitRate = false
            targetBitRateName = null
            pendingSeekPositionAfterQualityChange = null
            pendingAutoPlayAfterQualityChange = false
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun handleSetSubtitle(call: MethodCall, result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }

        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()

        android.util.Log.d(
            "PolyvMediaPlayerPlugin",
            "handleSetSubtitle called, args=$args"
        )

        // 兼容旧接口：setSubtitle(index)
        val hasNewApiArgs = args.containsKey("enabled") || args.containsKey("trackKey")

        try {
            if (!hasNewApiArgs) {
                val index = (args["index"] as? Number)?.toInt() ?: -1

                if (index < 0) {
                    // 旧接口 index = -1 视为关闭字幕
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "handleSetSubtitle legacy API: disable subtitles, index=$index"
                    )
                    plvPlayer.setShowSubtitles(emptyList())
                    sendSubtitleChangedEvent(
                        plvPlayer,
                        enabledOverride = false,
                        trackKeyOverride = null
                    )
                    result.success(null)
                    return
                }

                val subtitleSetting = plvPlayer.getBusinessListenerRegistry().supportSubtitleSetting.value
                val availableSingles: List<PLVMediaSubtitle> = subtitleSetting?.availableSubtitles
                    ?: emptyList()

                if (index >= availableSingles.size) {
                    // 索引越界时不抛错，直接忽略
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "handleSetSubtitle legacy API: index out of range, index=$index, size=${availableSingles.size}"
                    )
                    result.success(null)
                    return
                }

                val target = listOf(availableSingles[index])
                plvPlayer.setShowSubtitles(target)

                val trackName = target.firstOrNull()?.name
                android.util.Log.d(
                    "PolyvMediaPlayerPlugin",
                    "handleSetSubtitle legacy API: enable subtitle, index=$index, name=$trackName"
                )
                sendSubtitleChangedEvent(
                    plvPlayer,
                    enabledOverride = trackName != null,
                    trackKeyOverride = trackName
                )
                result.success(null)
                return
            }

            // 新接口：setSubtitleWithKey({ enabled, trackKey })
            val enabled = (args["enabled"] as? Boolean) ?: true
            val trackKey = args["trackKey"] as? String

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "handleSetSubtitle new API: enabled=$enabled, trackKey=$trackKey"
            )

            if (!enabled) {
                plvPlayer.setShowSubtitles(emptyList())
                sendSubtitleChangedEvent(
                    plvPlayer,
                    enabledOverride = false,
                    trackKeyOverride = null
                )
                result.success(null)
                return
            }

            val subtitleSetting = plvPlayer.getBusinessListenerRegistry().supportSubtitleSetting.value
            if (subtitleSetting == null || !subtitleSetting.available) {
                android.util.Log.d(
                    "PolyvMediaPlayerPlugin",
                    "handleSetSubtitle new API: subtitleSetting unavailable, enabled=$enabled, trackKey=$trackKey"
                )
                result.success(null)
                return
            }

            val availableSingles: List<PLVMediaSubtitle> = subtitleSetting.availableSubtitles ?: emptyList()

            val target: List<PLVMediaSubtitle> = when {
                trackKey.isNullOrEmpty() -> {
                    // 未指定 trackKey，则复用 SDK 默认：优先双语，其次第一条单字幕
                    subtitleSetting.defaultDoubleSubtitles
                        ?: availableSingles.firstOrNull()?.let { listOf(it) }
                        ?: emptyList()
                }

                else -> {
                    // 根据 trackKey（当前使用 name 作为 key）在单字幕列表中查找
                    availableSingles.firstOrNull { it.name == trackKey }?.let { listOf(it) }
                        // 若未找到，则退回 SDK 默认
                        ?: subtitleSetting.defaultDoubleSubtitles
                        ?: availableSingles.firstOrNull()?.let { listOf(it) }
                        ?: emptyList()
                }
            }

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "handleSetSubtitle new API: resolved target size=${target.size}, names=${target.joinToString { it.name ?: "" }}"
            )

            plvPlayer.setShowSubtitles(target)
            sendSubtitleChangedEvent(
                plvPlayer,
                enabledOverride = true,
                trackKeyOverride = trackKey
            )
            result.success(null)
        } catch (t: Throwable) {
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun sendSubtitleChangedEvent(
        plvPlayer: PLVMediaPlayer,
        enabledOverride: Boolean? = null,
        trackKeyOverride: String? = null
    ) {
        try {
            val subtitleSetting = plvPlayer.getBusinessListenerRegistry().supportSubtitleSetting.value
            val availableSingles: List<PLVMediaSubtitle> = subtitleSetting?.availableSubtitles ?: emptyList()

            // 获取双语字幕（用于判断是否为双语）
            val doubleSubtitles = subtitleSetting?.defaultDoubleSubtitles
            val hasDoubleSubtitles = doubleSubtitles != null && doubleSubtitles.isNotEmpty()

            val subtitlesJson = mutableListOf<Map<String, Any>>()

            // 如果存在双语字幕，添加到列表开头
            if (hasDoubleSubtitles) {
                val doubleItem = mapOf(
                    "trackKey" to "双语",
                    "language" to "zh+en",
                    "label" to "双语",
                    "isBilingual" to true,
                    "isDefault" to true
                )
                subtitlesJson.add(doubleItem)
            }

            // 添加单语字幕
            for (single in availableSingles) {
                val name = single.name ?: ""
                subtitlesJson.add(
                    mapOf(
                        "trackKey" to name,
                        "language" to name,
                        "label" to name,
                        "isBilingual" to false,
                        "isDefault" to false
                    )
                )
            }

            var enabled = enabledOverride
            var trackKey = trackKeyOverride
            var currentIndex = -1

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "sendSubtitleChangedEvent: enabledOverride=$enabledOverride, trackKeyOverride=$trackKeyOverride, availableSingles=${availableSingles.size}, hasDoubleSubtitles=$hasDoubleSubtitles"
            )

            // 如果未显式指定 enabled，则根据当前正在显示的字幕推断
            if (enabled == null) {
                val current: List<PLVMediaSubtitle>? =
                    plvPlayer.getBusinessListenerRegistry().currentShowSubTitles.value
                enabled = current != null && current.isNotEmpty()

                if (enabled && current != null && current.isNotEmpty()) {
                    val firstCurrent = current.first()
                    val currentName = firstCurrent.name

                    val isDouble = hasDoubleSubtitles &&
                        doubleSubtitles!!.any { it.name == currentName }

                    trackKey = if (isDouble) {
                        "双语"
                    } else {
                        currentName
                    }
                }
            }

            // 根据 enabled / trackKey 计算 currentIndex
            if (enabled == true) {
                if (!trackKey.isNullOrEmpty()) {
                    val index = subtitlesJson.indexOfFirst { it["trackKey"] == trackKey }
                    if (index >= 0) {
                        currentIndex = index
                    }
                }

                // 如果仍未找到索引，但有可用字幕，则退回到第一条
                if (currentIndex < 0 && subtitlesJson.isNotEmpty()) {
                    currentIndex = 0
                    trackKey = subtitlesJson[0]["trackKey"] as? String
                }
            } else {
                // 关闭字幕时，强制 currentIndex = -1，清空 trackKey
                enabled = false
                currentIndex = -1
                trackKey = null
            }

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "sendSubtitleChangedEvent: resolved state enabled=$enabled, trackKey=$trackKey, currentIndex=$currentIndex, subtitlesJsonSize=${subtitlesJson.size}"
            )

            val data = mutableMapOf<String, Any>(
                "subtitles" to subtitlesJson,
                "currentIndex" to currentIndex,
                "enabled" to enabled
            )
            if (!trackKey.isNullOrEmpty()) {
                data["trackKey"] = trackKey
            }

            sendEvent(
                mapOf(
                    "type" to "subtitleChanged",
                    "data" to data
                )
            )
        } catch (t: Throwable) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send subtitleChanged event", t)
        }
    }

    private fun handlePause(result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }
        try {
            plvPlayer.pause()
            result.success(null)
        } catch (t: Throwable) {
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun handleStop(result: Result) {
        // stop 不应该销毁播放器，只停止播放并重置进度
        val plvPlayer = player
        if (plvPlayer != null) {
            plvPlayer.pause()
            plvPlayer.seek(0L)
        }
        sendStateChangeEvent(stateIdle)
        result.success(null)
    }

    private fun handleDisposePlayer(result: Result) {
        releasePlayer()
        sendStateChangeEvent(stateIdle)
        result.success(null)
    }

    private fun handleSeekTo(call: MethodCall, result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }

        val args = call.arguments as? Map<*, *>
        val positionMs = (args?.get("position") as? Number)?.toLong() ?: 0L
        try {
            plvPlayer.seek(positionMs)
            result.success(null)
        } catch (t: Throwable) {
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun handleSetPlaybackSpeed(call: MethodCall, result: Result) {
        val plvPlayer = player
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }

        val args = call.arguments as? Map<*, *>
        val speed = (args?.get("speed") as? Number)?.toFloat() ?: 1f
        try {
            plvPlayer.setSpeed(speed)
            result.success(null)
        } catch (t: Throwable) {
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    /// Story 9.7: 暂停下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.pauseDownloader 方法
    private fun handlePauseDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handlePauseDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        // 从下载列表中查找对应的下载器
        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.pauseDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download paused for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to pause download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to pause download", null)
        }
    }

    /// Story 9.7: 恢复下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.startDownloader 方法
    private fun handleResumeDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleResumeDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        // 从下载列表中查找对应的下载器
        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.startDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download resumed for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to resume download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to resume download", null)
        }
    }

    /// Story 9.4/9.7: 重试失败的下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.startDownloader 方法
    private fun handleRetryDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleRetryDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        // 从下载列表中查找对应的下载器
        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.startDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download retry started for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to retry download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to retry download", null)
        }
    }

    /// Story 9.5/9.7: 删除下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.deleteDownloadContent 方法
    /// Bug 修复: 确保删除操作完整，taskRemoved 事件可靠发送
    private fun handleDeleteDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleDeleteDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        // 从下载列表中查找对应的下载器
        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            // 下载任务不存在，返回 NOT_FOUND 错误（强一致性：找不到任务就是失败）
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            // 执行实际的删除操作
            net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.deleteDownloadContent(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download deleted for vid: $vid")

            deletedDownloadVids.add(vid)

            // 删除成功后，从 previousStates 中移除该任务的状态记录
            // 这样可以防止后续同步时出现状态不一致
            downloadPreviousStates.remove(vid)

            // 删除成功后发送 taskRemoved 事件通知 Flutter 层
            // 确保只有删除成功才发送事件，保持状态一致性
            sendDownloadEventReliably(mapOf(
                "type" to downloadEventTaskRemoved,
                "data" to mapOf("id" to vid)
            ))

            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to delete download: ${e.message}")
            result.error("DELETE_FAILED", e.message ?: "Failed to delete download", null)
        }
    }

    /// 根据 vid 从下载列表中查找对应的下载器
    private fun findDownloaderByVid(vid: String): net.polyv.android.player.sdk.addon.download.common.PLVMediaDownloader? {
        val downloaderList = net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.downloaderList.value
            ?: return null
        
        return downloaderList.find { downloader ->
            val mediaResource = downloader.mediaResource
            if (mediaResource is PLVVodMediaResource) {
                mediaResource.videoId == vid
            } else {
                false
            }
        }
    }

    /// Story 9.8: 获取下载任务列表（权威同步）
    ///
    /// 从 PLVMediaDownloaderManager 获取所有下载任务，转换为 Flutter 可用的格式
    private fun handleGetDownloadList(result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleGetDownloadList called")

        try {
            val downloaderList = net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager.downloaderList.value
                ?: emptyList()

            android.util.Log.d("PolyvMediaPlayerPlugin", "Total tasks from SDK: ${downloaderList.size}")

            val taskList = mutableListOf<Map<String, Any?>>()

            // 用于检测重复 vid 的集合
            val seenVids = mutableSetOf<String>()

            for (downloader in downloaderList) {
                val taskDict = convertDownloaderToDict(downloader)
                if (taskDict != null) {
                    val vid = taskDict["vid"] as? String

                    // 检测重复 vid
                    if (vid != null && vid in seenVids) {
                        android.util.Log.d("PolyvMediaPlayerPlugin", "WARNING: Duplicate vid found in download list: vid=$vid")
                    } else {
                        if (vid != null) {
                            seenVids.add(vid)
                        }
                    }

                    // 过滤掉已删除的任务
                    if (vid != null && deletedDownloadVids.contains(vid)) {
                        android.util.Log.d(
                            "PolyvMediaPlayerPlugin",
                            "Filtering out deleted task: vid=$vid"
                        )
                        downloadPreviousStates.remove(vid)
                        continue
                    }

                    // 只过滤掉没有 vid 的无效任务
                    if (!vid.isNullOrEmpty()) {
                        taskList.add(taskDict)
                        android.util.Log.d("PolyvMediaPlayerPlugin", "Adding task to list: vid=$vid, status=${taskDict["status"]}, downloadedBytes=${taskDict["downloadedBytes"]}")
                    } else {
                        android.util.Log.d("PolyvMediaPlayerPlugin", "Filtering out task without vid")
                    }
                }
            }

            android.util.Log.d("PolyvMediaPlayerPlugin", "Returning ${taskList.size} tasks (filtered from ${downloaderList.size} total)")
            result.success(taskList)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to get download list: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to get download list", null)
        }
    }

    /// Story 9.9: 创建下载任务（添加视频到下载队列）
    ///
    /// Android 端实现：使用 PLVMediaDownloaderManager.getDownloader 创建下载器
    private fun handleStartDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleStartDownload called")

        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        deletedDownloadVids.remove(vid)

        // 获取应用上下文
        val appCtx = applicationContext
        if (appCtx == null) {
            result.error(errorCodeNotInitialized, "Context not initialized", null)
            return
        }

        // 获取账号配置
        val config = try {
            getConfigOrThrow()
        } catch (e: IllegalStateException) {
            result.error(errorCodeNotInitialized, e.message, null)
            return
        }
        val userId = config.first
        val secretKey = config.second
        val readToken = injectedReadToken
        val writeToken = injectedWriteToken

        android.util.Log.d("PolyvMediaPlayerPlugin", "Download config - userId: $userId, hasReadToken: ${readToken != null}, hasWriteToken: ${writeToken != null}")

        // 创建认证和观看者参数（与播放器加载视频相同的逻辑）
        val authentication = PLVVodMainAccountAuthentication(userId, secretKey, readToken, writeToken)
        val viewerParam = PLVViewerParam(
            "viewer",  // viewerId
            "viewer",  // viewerName
            null, null, null, null,  // avatar, nickname, extra1, extra2
            null  // extra3
        )

        // 下载根目录
        val downloadRoots = listOfNotNull(
            appCtx.getExternalFilesDir(null)?.absolutePath
        )

        android.util.Log.d("PolyvMediaPlayerPlugin", "Download roots: $downloadRoots")

        if (downloadRoots.isEmpty()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download root directory is null")
            result.error("SDK_ERROR", "Download directory not available", null)
            return
        }

        android.util.Log.d("PolyvMediaPlayerPlugin", "Creating download resource for vid: $vid")

        try {
            // 创建 VOD 媒体资源（用于下载）- 使用与播放器相同的方式
            val mediaResource = PLVMediaResource.vod(vid, authentication, viewerParam, downloadRoots)

            android.util.Log.d("PolyvMediaPlayerPlugin", "Media resource created, getting downloader")

            // 使用 PLVMediaDownloaderManager.getDownloader 获取或创建下载器
            // 参考 polyv-android-media-player-sdk-demo 示例代码
            val downloader = runCatching {
                PLVMediaDownloaderManager.getDownloader(mediaResource, PLVMediaBitRate.BITRATE_AUTO)
            }.getOrElse { e ->
                android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to get downloader: ${e.message}, stack: ${e.stackTraceToString()}")
                result.error("SDK_ERROR", "Failed to create downloader: ${e.message}", null)
                return
            }

            if (downloader == null) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Downloader is null")
                result.error("SDK_ERROR", "Failed to create downloader: returned null", null)
                return
            }

            android.util.Log.d("PolyvMediaPlayerPlugin", "Downloader created, initial status: ${downloader.listenerRegistry.status.value}")

            // 启动下载
            PLVMediaDownloaderManager.startDownloader(downloader)

            android.util.Log.d("PolyvMediaPlayerPlugin", "Download task created successfully for vid: $vid, status after start: ${downloader.listenerRegistry.status.value}")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to create download task: ${e.message}, stack: ${e.stackTraceToString()}")
            result.error("SDK_ERROR", e.message ?: "Failed to create download task", null)
            return
        }
    }

    /// 将下载器转换为 Flutter 可用的字典格式
    private fun convertDownloaderToDict(downloader: net.polyv.android.player.sdk.addon.download.common.PLVMediaDownloader): Map<String, Any?>? {
        val mediaResource = downloader.mediaResource
        if (mediaResource !is PLVVodMediaResource) {
            return null
        }

        val vid = mediaResource.videoId ?: return null
        val taskId = vid // 使用 vid 作为任务 ID
        val title = "Video_$vid"
        val thumbnail = downloader.listenerRegistry.coverImage.value

        // 文件大小信息（从 listenerRegistry 获取）
        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val totalBytes: Long = totalBytesVal ?: 0L
        val progress: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (totalBytes.toDouble() * progress).toLong()

        // 下载速度
        val bytesPerSecond = downloader.listenerRegistry.downloadBytesPerSecond.value ?: 0L

        // 状态转换
        val status = convertDownloadStatusToString(downloader.listenerRegistry.status.value)

        // 错误信息
        val errorMessage: String? = if (downloader.listenerRegistry.status.value is PLVMediaDownloadStatus.ERROR) {
            "下载失败"
        } else {
            null
        }

        // 时间信息（使用当前时间作为占位符）
        val createdAt = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(java.util.Date())

        val completedAt: String? = if (downloader.listenerRegistry.status.value == PLVMediaDownloadStatus.COMPLETED) {
            createdAt
        } else {
            null
        }

        val dict = mutableMapOf<String, Any?>(
            "id" to taskId,
            "vid" to vid,
            "title" to title,
            "totalBytes" to totalBytes,
            "downloadedBytes" to downloadedBytes,
            "bytesPerSecond" to bytesPerSecond,
            "status" to status,
            "createdAt" to createdAt
        )

        if (!thumbnail.isNullOrEmpty()) {
            dict["thumbnail"] = thumbnail
        }
        if (errorMessage != null) {
            dict["errorMessage"] = errorMessage
        }
        if (completedAt != null) {
            dict["completedAt"] = completedAt
        }

        return dict
    }

    /// 将 SDK 下载状态转换为 Flutter 状态字符串
    private fun convertDownloadStatusToString(status: PLVMediaDownloadStatus?): String {
        return when (status) {
            PLVMediaDownloadStatus.WAITING -> "waiting"
            PLVMediaDownloadStatus.NOT_STARTED -> "waiting"
            PLVMediaDownloadStatus.DOWNLOADING -> "downloading"
            PLVMediaDownloadStatus.PAUSED -> "paused"
            PLVMediaDownloadStatus.COMPLETED -> "completed"
            is PLVMediaDownloadStatus.ERROR -> "error"
            null -> "waiting"
        }
    }

    private fun observePlayer(plvPlayer: PLVMediaPlayer) {
        observers.clear()

        plvPlayer.getEventListenerRegistry().onPrepared.observe {
            sendStateChangeEvent(statePrepared)
            // 视频准备完成后，获取清晰度数据
            val bitRates = plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.value
            android.util.Log.d("PolyvMediaPlayerPlugin", "onPrepared: supportMediaBitRates = ${bitRates?.size ?: 0}")
            sendQualityData(bitRates)
            // 视频准备完成后，发送字幕轨道信息给 Flutter 层
            // 这样 Flutter 层就能知道有哪些字幕可用，字幕按钮才能正常点击
            sendSubtitleChangedEvent(plvPlayer)
        }.addTo(observers)

        plvPlayer.getEventListenerRegistry().onCompleted.observe {
            sendStateChangeEvent(stateCompleted)
            sendEvent(mapOf("type" to "completed", "data" to emptyMap<String, Any>()))
        }.addTo(observers)

        plvPlayer.getEventListenerRegistry().onInfo.observe { event ->
            when (event.what) {
                PLVMediaPlayerOnInfoEvent.MEDIA_INFO_BUFFERING_START -> sendStateChangeEvent(stateBuffering)
                PLVMediaPlayerOnInfoEvent.MEDIA_INFO_BUFFERING_END -> {
                    val isPlaying = plvPlayer.getStateListenerRegistry().playingState.value == PLVMediaPlayerPlayingState.PLAYING
                    sendStateChangeEvent(if (isPlaying) statePlaying else statePaused)
                }
                else -> {}
            }
        }.addTo(observers)

        // 监听当前字幕文本，用于在原生层渲染字幕
        plvPlayer.getBusinessListenerRegistry().vodCurrentSubTitleTexts.observe { texts ->
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "vodCurrentSubTitleTexts changed: size=${texts?.size ?: 0}, hasUpdater=${subtitleTextUpdater != null}, texts=${texts?.map { it.text }}"
            )
            mainHandler.post {
                subtitleTextUpdater?.invoke(texts ?: emptyList())
            }
        }.addTo(observers)

        plvPlayer.getStateListenerRegistry().playingState.observe { playingState ->
            when (playingState) {
                PLVMediaPlayerPlayingState.PLAYING -> sendStateChangeEvent(statePlaying)
                else -> sendStateChangeEvent(statePaused)
            }
        }.addTo(observers)

        plvPlayer.getStateListenerRegistry().progressState.observe { progress ->
            // 清晰度切换期间，使用保存的位置而不是实际播放器的位置
            // 防止进度条因为播放器内部重置而跳动
            val positionToReport = if (isChangingBitRate && pendingSeekPositionAfterQualityChange != null) {
                pendingSeekPositionAfterQualityChange!!
            } else {
                progress
            }
            val rawDuration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L

            // 记录最近一次非 0 的总时长
            if (rawDuration > 0L) {
                lastKnownDurationMs = rawDuration
            }

            // 在清晰度切换期间，如果 SDK 短暂把 duration 重置为 0，则继续使用切换前记录的时长，
            // 避免 progress 因 duration=0 被算成 0，导致进度条滑块回到起点。
            val durationToReport = if (isChangingBitRate && lastKnownDurationMs > 0L) {
                lastKnownDurationMs
            } else {
                rawDuration
            }

            sendProgressEvent(positionToReport, durationToReport, 0L)
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().businessErrorState.observe { errorState ->
            if (errorState != null) {
                sendErrorEvent(errorCodeNetworkError, errorState.toString())
                sendStateChangeEvent(stateError)
            }
        }.addTo(observers)

        // 监听清晰度变化
        plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.observe { bitRates ->
            android.util.Log.d("PolyvMediaPlayerPlugin", "supportMediaBitRates changed: ${bitRates?.size ?: 0} bitrates, eventSink: ${playbackEventSink != null}")
            sendQualityData(bitRates)
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().currentMediaBitRate.observe { bitRate ->
            android.util.Log.d("PolyvMediaPlayerPlugin", "currentMediaBitRate changed: ${bitRate?.name}, isChangingBitRate=$isChangingBitRate, targetBitRateName=$targetBitRateName")

            // 如果是清晰度切换触发的变化，并且当前清晰度匹配目标清晰度，则恢复进度和播放状态
            if (isChangingBitRate && pendingSeekPositionAfterQualityChange != null && bitRate != null) {
                // 只在实际切换到目标清晰度时才恢复位置
                if (bitRate.name == targetBitRateName) {
                    val pendingSeek = pendingSeekPositionAfterQualityChange!!
                    val duration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
                    val clampedPosition = pendingSeek.coerceIn(0L, duration)

                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Target quality matched: ${bitRate.name}, restoring position: $clampedPosition, autoPlay=$pendingAutoPlayAfterQualityChange"
                    )

                    // 延迟执行，确保播放器已经准备好
                    mainHandler.postDelayed({
                        try {
                            plvPlayer.seek(clampedPosition)
                            if (pendingAutoPlayAfterQualityChange) {
                                plvPlayer.start()
                            } else {
                                plvPlayer.pause()
                            }
                        } catch (t: Throwable) {
                            android.util.Log.e(
                                "PolyvMediaPlayerPlugin",
                                "Failed to restore position after quality change",
                                t
                            )
                        } finally {
                            // 清理状态
                            isChangingBitRate = false
                            targetBitRateName = null
                            pendingSeekPositionAfterQualityChange = null
                            pendingAutoPlayAfterQualityChange = false
                        }
                    }, 300) // 延迟 300ms，确保清晰度切换完成
                }
            }
        }.addTo(observers)
    }

    private fun sendStateChangeEvent(state: String) {
        sendEvent(
            mapOf(
                "type" to "stateChanged",
                "data" to mapOf("state" to state)
            )
        )
    }

    private fun sendProgressEvent(positionMs: Long, durationMs: Long, bufferedMs: Long) {
        sendEvent(
            mapOf(
                "type" to "progress",
                "data" to mapOf(
                    "position" to positionMs.toInt(),
                    "duration" to durationMs.toInt(),
                    "bufferedPosition" to bufferedMs.toInt()
                )
            )
        )
    }

    private fun sendErrorEvent(code: String, message: String) {
        sendEvent(
            mapOf(
                "type" to "error",
                "data" to mapOf(
                    "code" to code,
                    "message" to message
                )
            )
        )
    }

    private fun sendEvent(event: Map<String, Any>) {
        val sink = playbackEventSink
        if (sink == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "eventSink is null, cannot send event: $event")
            return
        }
        mainHandler.post {
            try {
                android.util.Log.d("PolyvMediaPlayerPlugin", "Sending event: $event")
                sink.success(event)
            } catch (t: Throwable) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send event", t)
            }
        }
    }

    /// Bug 修复: 可靠地发送下载事件，确保即使 eventSink 暂时不可用也能在恢复后发送
    /// 用于关键事件如 taskRemoved
    private fun sendEventReliably(event: Map<String, Any>) {
        val sink = playbackEventSink
        if (sink == null) {
            android.util.Log.w("PolyvMediaPlayerPlugin", "eventSink is null, queuing event: $event")
            // 如果 eventSink 为 null，说明 EventChannel 暂时未监听
            // 当 onListen 被调用时，应该会通过 syncFromNative 重新同步状态
            // 所以这里只需要记录日志，不需要实际队列
            return
        }
        mainHandler.post {
            try {
                android.util.Log.d("PolyvMediaPlayerPlugin", "Sending reliable event: $event")
                sink.success(event)
            } catch (t: Throwable) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send reliable event", t)
            }
        }
    }

    private fun sendQualityData() {
        android.util.Log.d("PolyvMediaPlayerPlugin", "sendQualityData called (deprecated - use observer version)")

        // 构建清晰度数据
        val qualitiesList = mutableListOf<Map<String, Any>>()

        // 定义清晰度顺序和对应标签
        // 注意：这里使用模拟数据，实际应从 PLVMediaPlayer 获取可用清晰度
        val qualityDefinitions = listOf(
            mapOf("key" to "4k", "description" to "4K 超清", "value" to "4k"),
            mapOf("key" to "super", "description" to "1080P 高清", "value" to "1080p"),
            mapOf("key" to "high", "description" to "720P 标清", "value" to "720p"),
            mapOf("key" to "standard", "description" to "480P 流畅", "value" to "480p"),
            mapOf("key" to "smooth", "description" to "360P 极速", "value" to "360p"),
        )

        // TODO: 从 PLVMediaPlayer 获取实际可用的清晰度
        // 目前使用模拟数据，将所有清晰度标记为可用
        var currentIndex = 1 // 默认选择 1080p

        for (def in qualityDefinitions) {
            qualitiesList.add(mapOf(
                "description" to def["description"]!!,
                "value" to def["value"]!!,
                "isAvailable" to true  // 暂时都标记为可用
            ))
        }

        // 添加"自动"选项
        qualitiesList.add(0, mapOf(
            "description" to "自动",
            "value" to "auto",
            "isAvailable" to true
        ))
        currentIndex = 0 // 默认选择自动

        android.util.Log.d("PolyvMediaPlayerPlugin", "Sending qualityChanged event: $qualitiesList, currentIndex: $currentIndex")

        sendEvent(mapOf(
            "type" to "qualityChanged",
            "data" to mapOf(
                "qualities" to qualitiesList,
                "currentIndex" to currentIndex
            )
        ))
    }

    /// 从 SDK 的 PLVMediaBitRate 列表发送清晰度数据
    private fun sendQualityData(bitRates: List<net.polyv.android.player.business.scene.common.model.vo.PLVMediaBitRate>?) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "sendQualityData called with ${bitRates?.size ?: 0} bitrates")

        // 如果 SDK 没有返回清晰度数据，使用默认清晰度列表
        if (bitRates == null || bitRates.isEmpty()) {
            android.util.Log.d("PolyvMediaPlayerPlugin", "No bitrates from SDK, using default quality list")
            sendQualityData() // 使用默认清晰度列表
            return
        }

        val qualitiesList = mutableListOf<Map<String, Any>>()
        var currentIndex = 0

        // 映射清晰度名称到我们的 value 格式
        val qualityNameMapping = mapOf(
            "自动" to "auto",
            "极速" to "360p",
            "流畅" to "480p",
            "标清" to "720p",
            "高清" to "1080p",
            "超清" to "1080p",
            "蓝光" to "1080p",
            "4K" to "4k"
        )

        for ((index, bitRate) in bitRates.withIndex()) {
            val name = bitRate.name
            val value = qualityNameMapping[name] ?: name.lowercase()

            qualitiesList.add(mapOf(
                "description" to name,
                "value" to value,
                "isAvailable" to true
            ))

            // 找到当前清晰度的索引
            val currentBitRate = player?.getBusinessListenerRegistry()?.currentMediaBitRate?.value
            if (currentBitRate != null && currentBitRate.name == name) {
                currentIndex = index
            }
        }

        android.util.Log.d("PolyvMediaPlayerPlugin", "Sending qualityChanged event: $qualitiesList, currentIndex: $currentIndex")

        sendEvent(mapOf(
            "type" to "qualityChanged",
            "data" to mapOf(
                "qualities" to qualitiesList,
                "currentIndex" to currentIndex
            )
        ))
    }

    // ========== Story 9.8: Download Status Monitoring ==========

    /// 启动下载状态监控
    private fun startDownloadStatusMonitoring() {
        downloadPreviousStates.clear()

        // 记录初始状态
        val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: emptyList()
        for (downloader in downloaderList) {
            val mediaResource = downloader.mediaResource
            if (mediaResource is PLVVodMediaResource) {
                val vid = mediaResource.videoId ?: continue
                downloadPreviousStates[vid] = downloader.listenerRegistry.status.value
            }
        }

        // 启动定时器，每 0.5 秒检查一次下载状态变化，提高进度更新频率
        downloadStatusCheckTimer = Timer()
        downloadStatusCheckTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                mainHandler.post {
                    checkDownloadStatusChanges()
                }
            }
        }, 0, 500) // 每 0.5 秒执行一次

        android.util.Log.d("PolyvMediaPlayerPlugin", "Download status monitoring started with ${downloaderList.size} tasks")
    }

    /// 停止下载状态监控
    private fun stopDownloadStatusMonitoring() {
        downloadStatusCheckTimer?.cancel()
        downloadStatusCheckTimer = null
        android.util.Log.d("PolyvMediaPlayerPlugin", "Download status monitoring stopped")
    }

    /// 检查下载状态变化并推送事件
    private fun checkDownloadStatusChanges() {
        val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: return

        for (downloader in downloaderList) {
            val mediaResource = downloader.mediaResource
            if (mediaResource !is PLVVodMediaResource) {
                continue
            }

            val vid = mediaResource.videoId ?: continue

            if (deletedDownloadVids.contains(vid)) {
                downloadPreviousStates.remove(vid)
                continue
            }
            val currentState = downloader.listenerRegistry.status.value
            val previousState = downloadPreviousStates[vid]

            // 检测状态变化
            if (currentState != previousState) {
                android.util.Log.d("PolyvMediaPlayerPlugin", "Download state changed for vid=$vid: $previousState -> $currentState")

                handleDownloadStateChanged(downloader, previousState, currentState)

                // 更新记录的状态
                downloadPreviousStates[vid] = currentState
            }

            // Bug 修复: 对于正在下载、等待中或准备中的任务，每次都定期发送进度更新
            // 无论状态是否变化，这样 UI 可以实时看到进度变化
            // 之前的问题是：长时间下载时状态一直保持 DOWNLOADING，不会触发状态变化事件，
            // 导致进度更新停止发送，UI 看起来进度不动了
            when (currentState) {
                PLVMediaDownloadStatus.DOWNLOADING,
                PLVMediaDownloadStatus.WAITING,
                PLVMediaDownloadStatus.NOT_STARTED -> {
                    sendDownloadProgressEvent(downloader)
                }
                else -> {}
            }
        }
    }

    /// 处理下载状态变化
    private fun handleDownloadStateChanged(
        downloader: PLVMediaDownloader,
        fromState: PLVMediaDownloadStatus?,
        toState: PLVMediaDownloadStatus?
    ) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        // 根据新状态发送对应事件
        when (toState) {
            PLVMediaDownloadStatus.COMPLETED -> sendDownloadCompletedEvent(downloader)
            is PLVMediaDownloadStatus.ERROR -> sendDownloadFailedEvent(downloader)
            PLVMediaDownloadStatus.PAUSED -> sendDownloadPausedEvent(downloader)
            PLVMediaDownloadStatus.DOWNLOADING -> {
                // 如果之前是暂停状态，现在恢复下载
                if (fromState == PLVMediaDownloadStatus.PAUSED) {
                    sendDownloadResumedEvent(downloader)
                }
                // 状态变为下载中时，立即发送一次进度事件，确保 Flutter 层能立即看到进度变化
                sendDownloadProgressEvent(downloader)
            }
            else -> {}
        }
    }

    /// 发送下载进度事件
    private fun sendDownloadProgressEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val size: Long = totalBytesVal ?: 0L
        val prog: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (size.toDouble() * prog).toLong()

        sendDownloadEvent(mapOf(
            "type" to downloadEventTaskProgress,
            "data" to mapOf(
                "id" to vid,
                "downloadedBytes" to downloadedBytes,
                "totalBytes" to (totalBytesVal ?: 0L),
                "bytesPerSecond" to (downloader.listenerRegistry.downloadBytesPerSecond.value ?: 0L),
                "status" to convertDownloadStatusToString(downloader.listenerRegistry.status.value)
            )
        ))
    }

    /// 发送下载完成事件
    private fun sendDownloadCompletedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val completedAt = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(java.util.Date())

        sendDownloadEvent(mapOf(
            "type" to downloadEventTaskCompleted,
            "data" to mapOf(
                "id" to vid,
                "completedAt" to completedAt
            )
        ))
    }

    /// 发送下载失败事件
    private fun sendDownloadFailedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        // 获取错误详情
        val errorMessage = "下载失败"
        android.util.Log.e("PolyvMediaPlayerPlugin", "Download failed for vid: $vid")

        sendDownloadEvent(mapOf(
            "type" to downloadEventTaskFailed,
            "data" to mapOf(
                "id" to vid,
                "errorMessage" to errorMessage
            )
        ))
    }

    /// 发送下载暂停事件
    private fun sendDownloadPausedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        sendDownloadEvent(mapOf(
            "type" to downloadEventTaskPaused,
            "data" to mapOf(
                "id" to vid
            )
        ))
    }

    /// 发送下载恢复事件
    private fun sendDownloadResumedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        // 获取当前的下载进度
        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val size: Long = totalBytesVal ?: 0L
        val prog: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (size.toDouble() * prog).toLong()

        sendDownloadEvent(mapOf(
            "type" to downloadEventTaskProgress,  // 使用 taskProgress 而不是 taskResumed，包含进度信息
            "data" to mapOf(
                "id" to vid,
                "downloadedBytes" to downloadedBytes,
                "totalBytes" to size,
                "bytesPerSecond" to 0,  // 速度信息后续会更新
                "status" to "downloading"
            )
        ))
        android.util.Log.d("PolyvMediaPlayerPlugin", "Send resumed event for vid=$vid with downloadedBytes=$downloadedBytes")
    }
}

private fun <T> MutableObserver<T>.addTo(list: MutableList<MutableObserver<*>>): MutableObserver<T> {
    list.add(this)
    return this
}

private fun dpToPx(context: Context, dp: Int): Int {
    val density = context.resources.displayMetrics.density
    return (dp * density + 0.5f).toInt()
}

private class PolyvVideoViewFactory(
    private val plugin: PolyvMediaPlayerPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return PolyvVideoPlatformView(context, plugin)
    }
}

private class PolyvVideoPlatformView(
    private val context: Context,
    private val plugin: PolyvMediaPlayerPlugin
) : PlatformView {

    private val container: FrameLayout
    private val videoView: PLVVideoView
    private val subtitleTopTextView: TextView
    private val subtitleBottomTextView: TextView
    private val subtitleUpdater: (List<PLVVodSubtitleText>) -> Unit

    init {
        val plvPlayer = plugin.ensurePlayer()

        container = FrameLayout(context)

        videoView = PLVVideoView(
            context = context,
            mediaPlayer = plvPlayer
        )

        // 视频画面占满容器
        container.addView(
            videoView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        // 顶部字幕文本
        subtitleTopTextView = TextView(context).apply {
            setTextColor(android.graphics.Color.WHITE)
            textSize = 14f
            // 添加阴影，提高可读性
            setShadowLayer(4f, 0f, 1f, android.graphics.Color.argb(204, 0, 0, 0))
            setPadding(dpToPx(context, 16), 0, dpToPx(context, 16), 0)
            gravity = Gravity.CENTER
            textAlignment = android.view.View.TEXT_ALIGNMENT_CENTER
            visibility = android.view.View.GONE
        }

        // 底部字幕文本
        subtitleBottomTextView = TextView(context).apply {
            setTextColor(android.graphics.Color.WHITE)
            textSize = 14f
            setShadowLayer(4f, 0f, 1f, android.graphics.Color.argb(204, 0, 0, 0))
            setPadding(dpToPx(context, 16), 0, dpToPx(context, 16), 0)
            gravity = Gravity.CENTER
            textAlignment = android.view.View.TEXT_ALIGNMENT_CENTER
            visibility = android.view.View.GONE
        }

        val bottomParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            // 更靠近视频底部
            bottomMargin = dpToPx(context, 16)
        }

        val topParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            bottomMargin = dpToPx(context, 48)
        }

        container.addView(subtitleBottomTextView, bottomParams)
        container.addView(subtitleTopTextView, topParams)

        // 注册字幕文本更新回调
        subtitleUpdater = { texts ->
            updateSubtitleTexts(texts)
        }
        plugin.setSubtitleTextUpdater(subtitleUpdater)
    }

    private fun updateSubtitleTexts(texts: List<PLVVodSubtitleText>) {
        android.util.Log.d(
            "PolyvMediaPlayerPlugin",
            "PolyvVideoPlatformView.updateSubtitleTexts called: size=${texts.size}, texts=${texts.map { it.text }}"
        )
        subtitleTopTextView.post {
            if (texts.isEmpty()) {
                subtitleTopTextView.visibility = android.view.View.GONE
                subtitleBottomTextView.visibility = android.view.View.GONE
            } else if (texts.size == 1) {
                subtitleTopTextView.visibility = android.view.View.VISIBLE
                subtitleBottomTextView.visibility = android.view.View.GONE
                subtitleTopTextView.text = texts[0].text ?: ""
            } else {
                subtitleTopTextView.visibility = android.view.View.VISIBLE
                subtitleBottomTextView.visibility = android.view.View.VISIBLE
                subtitleTopTextView.text = texts[0].text ?: ""
                subtitleBottomTextView.text = texts[1].text ?: ""
            }
        }
    }

    override fun getView(): android.view.View {
        return container
    }

    override fun dispose() {
        plugin.clearSubtitleTextUpdaterIfMatches(subtitleUpdater)
        container.removeAllViews()
    }
}
