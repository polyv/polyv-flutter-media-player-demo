package com.polyv.polyv_media_player

import android.os.Handler
import io.flutter.plugin.common.EventChannel

internal class DownloadEventEmitter(
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

    fun sendReliably(event: Map<String, Any>) {
        val sink = eventSink
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
}
