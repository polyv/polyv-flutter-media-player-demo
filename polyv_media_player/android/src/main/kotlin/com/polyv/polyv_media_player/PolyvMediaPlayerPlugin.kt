package com.polyv.polyv_media_player

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaResource
import net.polyv.android.player.business.scene.common.model.vo.PLVViewerParam
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMainAccountAuthentication
import net.polyv.android.player.business.scene.vod.model.vo.PLVVodSubtitleText
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMediaResource
import net.polyv.android.player.core.api.option.PLVMediaPlayerOptionEnum
import net.polyv.android.player.sdk.PLVMediaPlayer
import net.polyv.android.player.sdk.addon.download.common.model.vo.PLVMediaDownloadSetting
import net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager

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

    private val playbackEventEmitter = PlaybackEventEmitter(mainHandler)
    private val downloadEventEmitter = DownloadEventEmitter(mainHandler)
    private val methodRouter = MethodRouter(this)

    // 运行时注入的账号配置（优先于 AndroidManifest 中的配置）
    private var injectedUserId: String? = null
    private var injectedSecretKey: String? = null
    private var injectedReadToken: String? = null
    private var injectedWriteToken: String? = null

    // 用于将 SDK 的 vodCurrentSubTitleTexts 回调到实际的 Android View 上进行渲染
    private var subtitleTextUpdater: ((List<PLVVodSubtitleText>) -> Unit)? = null

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

    private val subtitleCoordinator by lazy {
        SubtitleCoordinator(
            playbackEventEmitter = playbackEventEmitter,
            getPlayer = { player },
            errorCodeNotInitialized = errorCodeNotInitialized,
            errorCodeNetworkError = errorCodeNetworkError
        )
    }

    private val playerCoordinator by lazy {
        PlayerCoordinator(
            mainHandler = mainHandler,
            playbackEventEmitter = playbackEventEmitter,
            getPlayer = { player },
            setPlayer = { player = it },
            getSubtitleTextUpdater = { subtitleTextUpdater },
            sendQualityData = { bitRates -> sendQualityData(bitRates) },
            sendSubtitleChangedEvent = { plvPlayer -> subtitleCoordinator.sendSubtitleChangedEvent(plvPlayer) },
            stateIdle = stateIdle,
            statePrepared = statePrepared,
            statePlaying = statePlaying,
            statePaused = statePaused,
            stateBuffering = stateBuffering,
            stateCompleted = stateCompleted,
            stateError = stateError,
            errorCodeNotInitialized = errorCodeNotInitialized,
            errorCodeNetworkError = errorCodeNetworkError
        )
    }

    private val downloadCoordinator by lazy {
        DownloadCoordinator(
            mainHandler = mainHandler,
            downloadEventEmitter = downloadEventEmitter,
            getApplicationContext = { applicationContext },
            getAuthConfigOrThrow = { getConfigOrThrow() },
            getReadToken = { injectedReadToken },
            getWriteToken = { injectedWriteToken },
            errorCodeNotInitialized = errorCodeNotInitialized
        )
    }

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
                downloadEventEmitter.onListen(events)
            }

            override fun onCancel(arguments: Any?) {
                android.util.Log.d("PolyvMediaPlayerPlugin", "downloadEventChannel onCancel called")
                downloadEventEmitter.onCancel()
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
        downloadCoordinator.startDownloadStatusMonitoring()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        methodRouter.handle(call, result)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "onListen called, eventSink: ${events != null}")
        playbackEventEmitter.onListen(events)
    }

    override fun onCancel(arguments: Any?) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "onCancel called")
        playbackEventEmitter.onCancel()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        playbackEventChannel.setStreamHandler(null)
        downloadEventChannel.setStreamHandler(null)
        releasePlayer()
        applicationContext = null

        // Story 9.8: 停止下载状态监控
        downloadCoordinator.stopDownloadStatusMonitoring()
    }

    internal fun ensurePlayer(): PLVMediaPlayer {
        return playerCoordinator.ensurePlayer()
    }

    private fun releasePlayer() {
        playerCoordinator.releasePlayer()
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
    internal fun handleInitialize(call: MethodCall, result: Result) {
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

    internal fun handleLoadVideo(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim().orEmpty()
        val autoPlay = (args?.get("autoPlay") as? Boolean) ?: false
        val isOfflineMode = (args?.get("isOfflineMode") as? Boolean) ?: false

        android.util.Log.d("PolyvMediaPlayerPlugin", "handleLoadVideo: vid=$vid, autoPlay=$autoPlay, isOfflineMode=$isOfflineMode")

        if (vid.isEmpty()) {
            result.error(errorCodeInvalidVid, "VID is required", null)
            return
        }

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
    ///
    /// 修复：无网络情况下播放已下载视频
    /// 1. 从 PLVMediaDownloaderManager 获取已下载的 downloader
    /// 2. 使用 downloader 的 mediaResource（包含已缓存的元数据）
    /// 3. 避免创建新的 PLVMediaResource.vod() 导致的网络请求
    private fun loadVideoOffline(vid: String, autoPlay: Boolean, appCtx: Context, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "========== loadVideoOffline called ==========")
        android.util.Log.d("PolyvMediaPlayerPlugin", "VID: $vid")

        // Step 1: 尝试从下载管理器获取已下载的 downloader
        // downloader 的 mediaResource 包含下载时获取的视频元数据
        val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: emptyList()
        val downloader = downloaderList.find { dl ->
            val mr = dl.mediaResource
            mr is PLVVodMediaResource && mr.videoId == vid
        }

        val mediaResource = if (downloader != null) {
            android.util.Log.d("PolyvMediaPlayerPlugin", "Found downloader for vid: $vid, using cached mediaResource")
            // 使用下载器的 mediaResource，包含已缓存的元数据
            downloader.mediaResource
        } else {
            android.util.Log.w("PolyvMediaPlayerPlugin", "Downloader not found for vid: $vid, creating new mediaResource")
            // 降级：如果没有找到下载器，创建新的 mediaResource（可能需要网络）
            val downloadRoots = listOfNotNull(appCtx.getExternalFilesDir(null)?.absolutePath)

            if (downloadRoots.isEmpty()) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Download directory not found")
                sendErrorEvent("OFFLINE_ERROR", "Download directory not found")
                sendStateChangeEvent(stateError)
                result.error("OFFLINE_ERROR", "Download directory not available", null)
                return
            }

            val config = try {
                getConfigOrThrow()
            } catch (e: IllegalStateException) {
                result.error(errorCodeNotInitialized, e.message, null)
                return
            }

            val authentication = PLVVodMainAccountAuthentication(
                config.first,
                config.second,
                injectedReadToken,
                injectedWriteToken
            )
            val viewerParam = PLVViewerParam(
                "viewer",
                "viewer",
                null, null, null, null,
                null, null, null
            )

            PLVMediaResource.vod(vid, authentication, viewerParam, downloadRoots)
        }

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
    internal fun handleGetConfig(result: Result) {
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

    internal fun handlePlay(result: Result) {
        playerCoordinator.handlePlay(result)
    }

    internal fun handleSetQuality(call: MethodCall, result: Result) {
        playerCoordinator.handleSetQuality(call, result)
    }

    internal fun handleSetSubtitle(call: MethodCall, result: Result) {
        subtitleCoordinator.handleSetSubtitle(call, result)
    }

    internal fun handlePause(result: Result) {
        playerCoordinator.handlePause(result)
    }

    internal fun handleStop(result: Result) {
        playerCoordinator.handleStop(result)
    }

    internal fun handleDisposePlayer(result: Result) {
        playerCoordinator.handleDisposePlayer(result)
    }

    internal fun handleSeekTo(call: MethodCall, result: Result) {
        playerCoordinator.handleSeekTo(call, result)
    }

    internal fun handleSetPlaybackSpeed(call: MethodCall, result: Result) {
        playerCoordinator.handleSetPlaybackSpeed(call, result)
    }

    /// Story 9.7: 暂停下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.pauseDownloader 方法
    internal fun handlePauseDownload(call: MethodCall, result: Result) {
        downloadCoordinator.handlePauseDownload(call, result)
    }

    /// Story 9.7: 恢复下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.startDownloader 方法
    internal fun handleResumeDownload(call: MethodCall, result: Result) {
        downloadCoordinator.handleResumeDownload(call, result)
    }

    /// Story 9.4/9.7: 重试失败的下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.startDownloader 方法
    internal fun handleRetryDownload(call: MethodCall, result: Result) {
        downloadCoordinator.handleRetryDownload(call, result)
    }

    /// Story 9.5/9.7: 删除下载任务
    ///
    /// 调用 PLVMediaDownloaderManager.deleteDownloadContent 方法
    /// Bug 修复: 确保删除操作完整，taskRemoved 事件可靠发送
    internal fun handleDeleteDownload(call: MethodCall, result: Result) {
        downloadCoordinator.handleDeleteDownload(call, result)
    }

    /// Story 9.8: 获取下载任务列表（权威同步）
    ///
    /// 从 PLVMediaDownloaderManager 获取所有下载任务，转换为 Flutter 可用的格式
    internal fun handleGetDownloadList(result: Result) {
        downloadCoordinator.handleGetDownloadList(result)
    }

    /// Story 9.9: 创建下载任务（添加视频到下载队列）
    ///
    /// Android 端实现：使用 PLVMediaDownloaderManager.getDownloader 创建下载器
    internal fun handleStartDownload(call: MethodCall, result: Result) {
        downloadCoordinator.handleStartDownload(call, result)
    }

    private fun sendStateChangeEvent(state: String) {
        playbackEventEmitter.sendStateChange(state)
    }

    private fun sendProgressEvent(positionMs: Long, durationMs: Long, bufferedMs: Long) {
        playbackEventEmitter.sendProgress(positionMs, durationMs, bufferedMs)
    }

    private fun sendErrorEvent(code: String, message: String) {
        playbackEventEmitter.sendError(code, message)
    }

    private fun sendEvent(event: Map<String, Any>) {
        playbackEventEmitter.send(event)
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
 }
