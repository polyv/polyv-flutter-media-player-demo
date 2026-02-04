package com.polyv.polyv_media_player

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaSubtitle
import net.polyv.android.player.sdk.PLVMediaPlayer

internal class SubtitleCoordinator(
    private val playbackEventEmitter: PlaybackEventEmitter,
    private val getPlayer: () -> PLVMediaPlayer?,
    private val errorCodeNotInitialized: String,
    private val errorCodeNetworkError: String
) {

    fun handleSetSubtitle(call: MethodCall, result: Result) {
        val plvPlayer = getPlayer()
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

    fun sendSubtitleChangedEvent(
        plvPlayer: PLVMediaPlayer,
        enabledOverride: Boolean? = null,
        trackKeyOverride: String? = null
    ) {
        try {
            val subtitleSetting = plvPlayer.getBusinessListenerRegistry().supportSubtitleSetting.value
            val availableSingles: List<PLVMediaSubtitle> = subtitleSetting?.availableSubtitles ?: emptyList()
            val doubleSubtitles: List<PLVMediaSubtitle>? = subtitleSetting?.defaultDoubleSubtitles
            val hasDoubleSubtitles = doubleSubtitles != null && doubleSubtitles.isNotEmpty()

            val subtitlesJson = mutableListOf<Map<String, Any>>()

            if (hasDoubleSubtitles) {
                subtitlesJson.add(
                    mapOf(
                        "trackKey" to "双语",
                        "language" to "双语",
                        "label" to "双语",
                        "isBilingual" to true,
                        "isDefault" to true
                    )
                )
            }

            for (subtitle in availableSingles) {
                val name = subtitle.name ?: continue
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

            if (enabled == true) {
                if (!trackKey.isNullOrEmpty()) {
                    val index = subtitlesJson.indexOfFirst { it["trackKey"] == trackKey }
                    if (index >= 0) {
                        currentIndex = index
                    }
                }

                if (currentIndex < 0 && subtitlesJson.isNotEmpty()) {
                    currentIndex = 0
                    trackKey = subtitlesJson[0]["trackKey"] as? String
                }
            } else {
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

            playbackEventEmitter.send(
                mapOf(
                    "type" to "subtitleChanged",
                    "data" to data
                )
            )
        } catch (t: Throwable) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to send subtitleChanged event", t)
        }
    }
}
