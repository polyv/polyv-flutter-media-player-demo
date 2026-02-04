package com.polyv.polyv_media_player

import android.os.Handler
import io.flutter.plugin.common.EventChannel

internal class PlaybackEventEmitter(
    private val mainHandler: Handler
) {
    private var eventSink: EventChannel.EventSink? = null

    val hasListener: Boolean
        get() = eventSink != null

    fun onListen(events: EventChannel.EventSink?) {
        eventSink = events
    }

    fun onCancel() {
        eventSink = null
    }

    fun send(event: Map<String, Any>) {
        val sink = eventSink
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

    fun sendReliably(event: Map<String, Any>) {
        val sink = eventSink
        if (sink == null) {
            android.util.Log.w("PolyvMediaPlayerPlugin", "eventSink is null, queuing event: $event")
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

    fun sendStateChange(state: String) {
        send(
            mapOf(
                "type" to "stateChanged",
                "data" to mapOf("state" to state)
            )
        )
    }

    fun sendProgress(positionMs: Long, durationMs: Long, bufferedMs: Long) {
        send(
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

    fun sendError(code: String, message: String) {
        send(
            mapOf(
                "type" to "error",
                "data" to mapOf(
                    "code" to code,
                    "message" to message
                )
            )
        )
    }

    fun sendCompleted() {
        send(
            mapOf(
                "type" to "completed",
                "data" to emptyMap<String, Any>()
            )
        )
    }
}
