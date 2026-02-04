package com.polyv.polyv_media_player

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

internal class MethodRouter(
    private val plugin: PolyvMediaPlayerPlugin
) {
    fun handle(call: MethodCall, result: Result) {
        when (call.method) {
            "getConfig" -> plugin.handleGetConfig(result)
            "initialize" -> plugin.handleInitialize(call, result)
            "loadVideo" -> plugin.handleLoadVideo(call, result)
            "play" -> plugin.handlePlay(result)
            "pause" -> plugin.handlePause(result)
            "stop" -> plugin.handleStop(result)
            "disposePlayer" -> plugin.handleDisposePlayer(result)
            "seekTo" -> plugin.handleSeekTo(call, result)
            "setPlaybackSpeed" -> plugin.handleSetPlaybackSpeed(call, result)
            "setQuality" -> plugin.handleSetQuality(call, result)
            "setSubtitle" -> plugin.handleSetSubtitle(call, result)
            "getQualities" -> result.success(emptyList<Any>())
            "getSubtitles" -> result.success(emptyList<Any>())
            "pauseDownload" -> plugin.handlePauseDownload(call, result)
            "resumeDownload" -> plugin.handleResumeDownload(call, result)
            "retryDownload" -> plugin.handleRetryDownload(call, result)
            "deleteDownload" -> plugin.handleDeleteDownload(call, result)
            "getDownloadList" -> plugin.handleGetDownloadList(result)
            "startDownload" -> plugin.handleStartDownload(call, result)
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }
}
