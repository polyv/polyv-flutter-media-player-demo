package com.polyv.polyv_media_player

import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import net.polyv.android.player.core.api.listener.event.PLVMediaPlayerOnInfoEvent
import net.polyv.android.player.core.api.listener.state.PLVMediaPlayerPlayingState
import net.polyv.android.player.sdk.PLVMediaPlayer
import net.polyv.android.player.sdk.foundation.lang.MutableObserver

internal class PlayerCoordinator(
    private val mainHandler: Handler,
    private val playbackEventEmitter: PlaybackEventEmitter,
    private val getPlayer: () -> PLVMediaPlayer?,
    private val setPlayer: (PLVMediaPlayer?) -> Unit,
    private val getSubtitleTextUpdater: () -> ((List<net.polyv.android.player.business.scene.vod.model.vo.PLVVodSubtitleText>) -> Unit)?,
    private val sendQualityData: (List<net.polyv.android.player.business.scene.common.model.vo.PLVMediaBitRate>?) -> Unit,
    private val sendSubtitleChangedEvent: (PLVMediaPlayer) -> Unit,
    private val stateIdle: String,
    private val statePrepared: String,
    private val statePlaying: String,
    private val statePaused: String,
    private val stateBuffering: String,
    private val stateCompleted: String,
    private val stateError: String,
    private val errorCodeNotInitialized: String,
    private val errorCodeNetworkError: String
) {

    private val observers = mutableListOf<MutableObserver<*>>()

    private var pendingSeekPositionAfterQualityChange: Long? = null
    private var pendingAutoPlayAfterQualityChange: Boolean = false
    private var isChangingBitRate: Boolean = false
    private var waitingForSeekCompletion: Boolean = false
    private var targetBitRateName: String? = null
    private var lastKnownDurationMs: Long = 0L
    private var qualityChangeGeneration: Int = 0  // 用于使旧的 postDelayed 失效

    fun ensurePlayer(): PLVMediaPlayer {
        val existing = getPlayer()
        if (existing != null) return existing

        val newPlayer = PLVMediaPlayer()
        setPlayer(newPlayer)

        observePlayer(newPlayer)
        playbackEventEmitter.sendStateChange(stateIdle)
        return newPlayer
    }

    fun releasePlayer() {
        observers.forEach { observer ->
            try {
                observer.dispose()
            } catch (_: Throwable) {
            }
        }
        observers.clear()

        try {
            getPlayer()?.destroy()
        } catch (_: Throwable) {
        }

        setPlayer(null)

        isChangingBitRate = false
        waitingForSeekCompletion = false
        targetBitRateName = null
        pendingSeekPositionAfterQualityChange = null
        pendingAutoPlayAfterQualityChange = false
        lastKnownDurationMs = 0L
        qualityChangeGeneration++
    }

    fun handlePlay(result: Result) {
        val plvPlayer = getPlayer()
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }
        try {
            plvPlayer.start()
            result.success(null)
        } catch (t: Throwable) {
            playbackEventEmitter.sendError(errorCodeNetworkError, t.message ?: "play failed")
            playbackEventEmitter.sendStateChange(stateError)
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    fun handlePause(result: Result) {
        val plvPlayer = getPlayer()
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

    fun handleStop(result: Result) {
        val plvPlayer = getPlayer()
        if (plvPlayer != null) {
            plvPlayer.pause()
            plvPlayer.seek(0L)
        }
        playbackEventEmitter.sendStateChange(stateIdle)
        result.success(null)
    }

    fun handleDisposePlayer(result: Result) {
        releasePlayer()
        playbackEventEmitter.sendStateChange(stateIdle)
        result.success(null)
    }

    fun handleSeekTo(call: MethodCall, result: Result) {
        val plvPlayer = getPlayer()
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

    fun handleSetPlaybackSpeed(call: MethodCall, result: Result) {
        val plvPlayer = getPlayer()
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

    fun handleSetQuality(call: MethodCall, result: Result) {
        val plvPlayer = getPlayer()
        if (plvPlayer == null) {
            result.error(errorCodeNotInitialized, "Player not initialized", null)
            return
        }

        val args = call.arguments as? Map<*, *>
        val index = (args?.get("index") as? Number)?.toInt() ?: 0
        // 从 Flutter 层获取播放位置（毫秒），如果未传递则从播放器获取
        val flutterPosition = (args?.get("position") as? Number)?.toLong()

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
            // 如果已经在切换清晰度，保留原始的播放状态（而不是读 SDK 当前状态，
            // 因为上一次 handleSetQuality 已经 pause() 了播放器）
            val wasAlreadyChanging = isChangingBitRate
            val isPlaying = if (wasAlreadyChanging) {
                pendingAutoPlayAfterQualityChange  // 保留之前记录的真实播放意图
            } else {
                plvPlayer.getStateListenerRegistry().playingState.value == PLVMediaPlayerPlayingState.PLAYING
            }

            // 优先使用 Flutter 层传递的位置，这是最准确的
            val currentPosition = if (wasAlreadyChanging && pendingSeekPositionAfterQualityChange != null) {
                pendingSeekPositionAfterQualityChange!!  // 保留原始位置
            } else if (flutterPosition != null && flutterPosition > 0) {
                flutterPosition  // 使用 Flutter 层传递的位置
            } else {
                plvPlayer.getStateListenerRegistry().progressState.value ?: 0L
            }

            val targetBitRate = bitRates[index]

            // 递增 generation，使旧的 postDelayed 回调失效
            qualityChangeGeneration++

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "setQuality: index=$index, targetBitRate=${targetBitRate.name}, flutterPosition=$flutterPosition, currentPosition=$currentPosition, isPlaying=$isPlaying, wasAlreadyChanging=$wasAlreadyChanging, generation=$qualityChangeGeneration"
            )

            // ⚠️ 必须在 pause()/changeBitRate() 之前设置 guard！
            // 否则 pause() 触发的 paused 事件会泄漏到 Flutter
            pendingSeekPositionAfterQualityChange = currentPosition
            pendingAutoPlayAfterQualityChange = isPlaying
            isChangingBitRate = true
            targetBitRateName = targetBitRate.name

            if (!wasAlreadyChanging && isPlaying) {
                plvPlayer.pause()
            }

            plvPlayer.changeBitRate(targetBitRate)

            val updatedBitRates = plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.value
            sendQualityData(updatedBitRates ?: bitRates)

            result.success(null)
        } catch (t: Throwable) {
            isChangingBitRate = false
            waitingForSeekCompletion = false
            targetBitRateName = null
            pendingSeekPositionAfterQualityChange = null
            pendingAutoPlayAfterQualityChange = false
            result.error(errorCodeNetworkError, t.message, null)
        }
    }

    private fun observePlayer(plvPlayer: PLVMediaPlayer) {
        observers.clear()

        plvPlayer.getEventListenerRegistry().onPrepared.observe {
            if (isChangingBitRate) {
                // 清晰度切换期间：onPrepared 表示新流已就绪，此时可以安全 seek
                android.util.Log.d(
                    "PolyvMediaPlayerPlugin",
                    "onPrepared during quality change, performing seek"
                )
                val pendingSeek = pendingSeekPositionAfterQualityChange
                if (pendingSeek != null && pendingSeek > 0) {
                    val duration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
                    val seekPosition = if (duration > 0L) pendingSeek.coerceIn(0L, duration) else pendingSeek

                    // 先 start() 让播放器进入播放状态并开始缓冲
                    // 对于高切低，duration 可能此时还不准确，需要延迟 seek
                    val capturedAutoPlay = pendingAutoPlayAfterQualityChange
                    try {
                        if (capturedAutoPlay) {
                            plvPlayer.start()
                        }
                    } catch (t: Throwable) {
                        android.util.Log.e(
                            "PolyvMediaPlayerPlugin",
                            "Failed to start after quality change in onPrepared",
                            t
                        )
                    }

                    // 延迟 300ms 再 seek，确保 duration 已更新
                    mainHandler.postDelayed({
                        try {
                            val currentDuration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
                            val finalSeekPos = if (currentDuration > 0L) {
                                pendingSeek.coerceIn(0L, currentDuration)
                            } else {
                                seekPosition
                            }
                            android.util.Log.d(
                                "PolyvMediaPlayerPlugin",
                                "Delayed seek after onPrepared: pos=$finalSeekPos, duration=$currentDuration"
                            )
                            plvPlayer.seek(finalSeekPos)
                            if (!capturedAutoPlay) {
                                plvPlayer.pause()
                            }
                        } catch (t: Throwable) {
                            android.util.Log.e(
                                "PolyvMediaPlayerPlugin",
                                "Failed delayed seek after quality change",
                                t
                            )
                        }
                    }, 300)

                    // 设置等待 seek 完成标志
                    waitingForSeekCompletion = true

                    // 5 秒超时兜底
                    val capturedGeneration = qualityChangeGeneration
                    val timeoutAutoPlay = pendingAutoPlayAfterQualityChange  // 先捕获，避免后续被重置后读到 false
                    mainHandler.postDelayed({
                        if (waitingForSeekCompletion && capturedGeneration == qualityChangeGeneration) {
                            android.util.Log.w(
                                "PolyvMediaPlayerPlugin",
                                "Quality change seek timeout, forcing guard release"
                            )
                            waitingForSeekCompletion = false
                            isChangingBitRate = false
                            targetBitRateName = null
                            pendingSeekPositionAfterQualityChange = null
                            pendingAutoPlayAfterQualityChange = false
                            val finalState = if (timeoutAutoPlay) statePlaying else statePaused
                            playbackEventEmitter.sendStateChange(finalState)
                        }
                    }, 5000)
                } else {
                    // 无需 seek，直接释放 guard
                    val autoPlay = pendingAutoPlayAfterQualityChange
                    isChangingBitRate = false
                    targetBitRateName = null
                    pendingSeekPositionAfterQualityChange = null
                    pendingAutoPlayAfterQualityChange = false
                    val finalState = if (autoPlay) statePlaying else statePaused
                    playbackEventEmitter.sendStateChange(finalState)
                }
            } else {
                playbackEventEmitter.sendStateChange(statePrepared)
            }
            val bitRates = plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.value
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "onPrepared: supportMediaBitRates = ${bitRates?.size ?: 0}"
            )
            sendQualityData(bitRates)
            sendSubtitleChangedEvent(plvPlayer)
        }.addTo(observers)

        plvPlayer.getEventListenerRegistry().onCompleted.observe {
            playbackEventEmitter.sendStateChange(stateCompleted)
            playbackEventEmitter.sendCompleted()
        }.addTo(observers)

        plvPlayer.getEventListenerRegistry().onInfo.observe { event ->
            if (isChangingBitRate) return@observe
            when (event.what) {
                PLVMediaPlayerOnInfoEvent.MEDIA_INFO_BUFFERING_START -> playbackEventEmitter.sendStateChange(stateBuffering)

                PLVMediaPlayerOnInfoEvent.MEDIA_INFO_BUFFERING_END -> {
                    val isPlaying =
                        plvPlayer.getStateListenerRegistry().playingState.value == PLVMediaPlayerPlayingState.PLAYING
                    playbackEventEmitter.sendStateChange(if (isPlaying) statePlaying else statePaused)
                }

                else -> {}
            }
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().vodCurrentSubTitleTexts.observe { texts ->
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "vodCurrentSubTitleTexts changed: size=${texts?.size ?: 0}, hasUpdater=${getSubtitleTextUpdater() != null}, texts=${texts?.map { it.text }}"
            )
            mainHandler.post {
                getSubtitleTextUpdater()?.invoke(texts ?: emptyList())
            }
        }.addTo(observers)

        plvPlayer.getStateListenerRegistry().playingState.observe { playingState ->
            // 清晰度切换期间，不发送中间状态事件
            if (isChangingBitRate) return@observe
            when (playingState) {
                PLVMediaPlayerPlayingState.PLAYING -> playbackEventEmitter.sendStateChange(statePlaying)
                else -> playbackEventEmitter.sendStateChange(statePaused)
            }
        }.addTo(observers)

        plvPlayer.getStateListenerRegistry().progressState.observe { progress ->
            val rawDuration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
            if (rawDuration > 0L) {
                lastKnownDurationMs = rawDuration
            }

            // Fallback: 当 durationState 为 0（离线播放常见）时使用上次已知的 duration
            val effectiveDuration = if (rawDuration > 0L) rawDuration else lastKnownDurationMs

            // 检测 seek 是否完成：实际进度接近目标位置（容差 2000ms）
            if (waitingForSeekCompletion && pendingSeekPositionAfterQualityChange != null) {
                val target = pendingSeekPositionAfterQualityChange!!
                if (progress > 0 && Math.abs(progress - target) < 2000) {
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Seek completed after quality change: progress=$progress, target=$target"
                    )
                    waitingForSeekCompletion = false
                    val autoPlay = pendingAutoPlayAfterQualityChange
                    val finalState = if (autoPlay) statePlaying else statePaused
                    playbackEventEmitter.sendStateChange(finalState)

                    // 延迟重置 guard 到下一个主线程循环
                    mainHandler.post {
                        isChangingBitRate = false
                        targetBitRateName = null
                        pendingSeekPositionAfterQualityChange = null
                        pendingAutoPlayAfterQualityChange = false
                        android.util.Log.d("PolyvMediaPlayerPlugin", "Quality change guard released after seek completion")
                    }
                }
            }

            val positionToReport = if (isChangingBitRate && pendingSeekPositionAfterQualityChange != null) {
                pendingSeekPositionAfterQualityChange!!
            } else {
                progress
            }

            val durationToReport = if (isChangingBitRate && lastKnownDurationMs > 0L) {
                lastKnownDurationMs
            } else {
                effectiveDuration
            }

            playbackEventEmitter.sendProgress(positionToReport, durationToReport, 0L)
        }.addTo(observers)

        // 监听 durationState 变化：当 duration 从 0 变为有效值时，立即发送进度更新
        // 这解决离线播放时 duration 延迟更新的问题
        plvPlayer.getStateListenerRegistry().durationState.observe { durationMs ->
            if (durationMs != null && durationMs > 0L && !isChangingBitRate) {
                lastKnownDurationMs = durationMs
                val currentPosition = plvPlayer.getStateListenerRegistry().progressState.value ?: 0L
                playbackEventEmitter.sendProgress(currentPosition, durationMs, 0L)
            }
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().businessErrorState.observe { errorState ->
            if (errorState != null) {
                playbackEventEmitter.sendError(errorCodeNetworkError, errorState.toString())
                playbackEventEmitter.sendStateChange(stateError)
            }
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().supportMediaBitRates.observe { bitRates ->
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "supportMediaBitRates changed: ${bitRates?.size ?: 0} bitrates, eventSink: ${playbackEventEmitter.hasListener}"
            )
            sendQualityData(bitRates)
        }.addTo(observers)

        plvPlayer.getBusinessListenerRegistry().currentMediaBitRate.observe { bitRate ->
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "currentMediaBitRate changed: ${bitRate?.name}, isChangingBitRate=$isChangingBitRate, targetBitRateName=$targetBitRateName"
            )
            // 清晰度切换的 seek 逻辑已移至 onPrepared，确保新流就绪后才 seek
            // 此处仅用于日志记录
        }.addTo(observers)
    }
}
