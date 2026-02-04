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
    private var targetBitRateName: String? = null
    private var lastKnownDurationMs: Long = 0L

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
        targetBitRateName = null
        pendingSeekPositionAfterQualityChange = null
        pendingAutoPlayAfterQualityChange = false
        lastKnownDurationMs = 0L
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
            val isPlaying =
                plvPlayer.getStateListenerRegistry().playingState.value == PLVMediaPlayerPlayingState.PLAYING

            if (isPlaying) {
                plvPlayer.pause()
            }

            val currentPosition = plvPlayer.getStateListenerRegistry().progressState.value ?: 0L

            val targetBitRate = bitRates[index]
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "setQuality: index=$index, targetBitRate=${targetBitRate.name}, currentPosition=$currentPosition, isPlaying=$isPlaying"
            )

            pendingSeekPositionAfterQualityChange = currentPosition
            pendingAutoPlayAfterQualityChange = isPlaying
            isChangingBitRate = true
            targetBitRateName = targetBitRate.name

            plvPlayer.changeBitRate(targetBitRate)

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

    private fun observePlayer(plvPlayer: PLVMediaPlayer) {
        observers.clear()

        plvPlayer.getEventListenerRegistry().onPrepared.observe {
            playbackEventEmitter.sendStateChange(statePrepared)
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
            when (playingState) {
                PLVMediaPlayerPlayingState.PLAYING -> playbackEventEmitter.sendStateChange(statePlaying)
                else -> playbackEventEmitter.sendStateChange(statePaused)
            }
        }.addTo(observers)

        plvPlayer.getStateListenerRegistry().progressState.observe { progress ->
            val positionToReport = if (isChangingBitRate && pendingSeekPositionAfterQualityChange != null) {
                pendingSeekPositionAfterQualityChange!!
            } else {
                progress
            }

            val rawDuration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
            if (rawDuration > 0L) {
                lastKnownDurationMs = rawDuration
            }

            val durationToReport = if (isChangingBitRate && lastKnownDurationMs > 0L) {
                lastKnownDurationMs
            } else {
                rawDuration
            }

            playbackEventEmitter.sendProgress(positionToReport, durationToReport, 0L)
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

            if (isChangingBitRate && pendingSeekPositionAfterQualityChange != null && bitRate != null) {
                if (bitRate.name == targetBitRateName) {
                    val pendingSeek = pendingSeekPositionAfterQualityChange!!
                    val duration = plvPlayer.getStateListenerRegistry().durationState.value ?: 0L
                    val clampedPosition = pendingSeek.coerceIn(0L, duration)

                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Target quality matched: ${bitRate.name}, restoring position: $clampedPosition, autoPlay=$pendingAutoPlayAfterQualityChange"
                    )

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
                            isChangingBitRate = false
                            targetBitRateName = null
                            pendingSeekPositionAfterQualityChange = null
                            pendingAutoPlayAfterQualityChange = false
                        }
                    }, 300)
                }
            }
        }.addTo(observers)
    }
}
