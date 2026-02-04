package com.polyv.polyv_media_player

import android.content.Context
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMediaResource
import net.polyv.android.player.business.scene.vod.model.vo.PLVVodSubtitleText
import net.polyv.android.player.sdk.PLVVideoView

internal class PolyvVideoViewFactory(
    private val plugin: PolyvMediaPlayerPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return PolyvVideoPlatformView(context, plugin)
    }
}

internal class PolyvVideoPlatformView(
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

        container.addView(
            videoView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        subtitleTopTextView = TextView(context).apply {
            setTextColor(android.graphics.Color.WHITE)
            textSize = 14f
            setShadowLayer(4f, 0f, 1f, android.graphics.Color.argb(204, 0, 0, 0))
            setPadding(dpToPx(context, 16), 0, dpToPx(context, 16), 0)
            gravity = Gravity.CENTER
            textAlignment = android.view.View.TEXT_ALIGNMENT_CENTER
            visibility = android.view.View.GONE
        }

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

private fun dpToPx(context: Context, dp: Int): Int {
    val density = context.resources.displayMetrics.density
    return (dp * density + 0.5f).toInt()
}
