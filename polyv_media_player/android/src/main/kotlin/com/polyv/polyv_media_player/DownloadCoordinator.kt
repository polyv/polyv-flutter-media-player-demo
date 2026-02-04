package com.polyv.polyv_media_player

import android.content.Context
import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaBitRate
import net.polyv.android.player.business.scene.common.model.vo.PLVMediaResource
import net.polyv.android.player.business.scene.common.model.vo.PLVViewerParam
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMainAccountAuthentication
import net.polyv.android.player.business.scene.common.model.vo.PLVVodMediaResource
import net.polyv.android.player.sdk.addon.download.PLVMediaDownloaderManager
import net.polyv.android.player.sdk.addon.download.common.PLVMediaDownloader
import net.polyv.android.player.sdk.addon.download.common.model.vo.PLVMediaDownloadStatus
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.Timer
import java.util.TimerTask

internal class DownloadCoordinator(
    private val mainHandler: Handler,
    private val downloadEventEmitter: DownloadEventEmitter,
    private val getApplicationContext: () -> Context?,
    private val getAuthConfigOrThrow: () -> Pair<String, String>,
    private val getReadToken: () -> String?,
    private val getWriteToken: () -> String?,
    private val errorCodeNotInitialized: String
) {

    private val downloadEventTaskProgress = "taskProgress"
    private val downloadEventTaskCompleted = "taskCompleted"
    private val downloadEventTaskFailed = "taskFailed"
    private val downloadEventTaskRemoved = "taskRemoved"
    private val downloadEventTaskPaused = "taskPaused"

    private val downloadPreviousStates = mutableMapOf<String, PLVMediaDownloadStatus?>()
    private var downloadStatusCheckTimer: Timer? = null
    private val deletedDownloadVids = mutableSetOf<String>()

    fun startDownloadStatusMonitoring() {
        downloadPreviousStates.clear()

        val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: emptyList()
        for (downloader in downloaderList) {
            val mediaResource = downloader.mediaResource
            if (mediaResource is PLVVodMediaResource) {
                val vid = mediaResource.videoId ?: continue
                downloadPreviousStates[vid] = downloader.listenerRegistry.status.value
            }
        }

        downloadStatusCheckTimer = Timer()
        downloadStatusCheckTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                mainHandler.post {
                    checkDownloadStatusChanges()
                }
            }
        }, 0, 500)

        android.util.Log.d(
            "PolyvMediaPlayerPlugin",
            "Download status monitoring started with ${downloaderList.size} tasks"
        )
    }

    fun stopDownloadStatusMonitoring() {
        downloadStatusCheckTimer?.cancel()
        downloadStatusCheckTimer = null
        android.util.Log.d("PolyvMediaPlayerPlugin", "Download status monitoring stopped")
    }

    fun handlePauseDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handlePauseDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            PLVMediaDownloaderManager.pauseDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download paused for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to pause download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to pause download", null)
        }
    }

    fun handleResumeDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleResumeDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            PLVMediaDownloaderManager.startDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download resumed for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to resume download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to resume download", null)
        }
    }

    fun handleRetryDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleRetryDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            PLVMediaDownloaderManager.startDownloader(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download retry started for vid: $vid")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to retry download: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to retry download", null)
        }
    }

    fun handleDeleteDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleDeleteDownload called")
        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        val downloader = findDownloaderByVid(vid)
        if (downloader == null) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download task not found for vid: $vid")
            result.error("NOT_FOUND", "Download task not found", null)
            return
        }

        try {
            PLVMediaDownloaderManager.deleteDownloadContent(downloader)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Download deleted for vid: $vid")

            deletedDownloadVids.add(vid)
            downloadPreviousStates.remove(vid)

            sendDownloadEventReliably(
                mapOf(
                    "type" to downloadEventTaskRemoved,
                    "data" to mapOf("id" to vid)
                )
            )

            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to delete download: ${e.message}")
            result.error("DELETE_FAILED", e.message ?: "Failed to delete download", null)
        }
    }

    fun handleGetDownloadList(result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleGetDownloadList called")

        try {
            val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: emptyList()
            android.util.Log.d("PolyvMediaPlayerPlugin", "Total tasks from SDK: ${downloaderList.size}")

            val taskList = mutableListOf<Map<String, Any?>>()
            val seenVids = mutableSetOf<String>()

            for (downloader in downloaderList) {
                val taskDict = convertDownloaderToDict(downloader)
                if (taskDict != null) {
                    val vid = taskDict["vid"] as? String

                    if (vid != null && vid in seenVids) {
                        android.util.Log.d(
                            "PolyvMediaPlayerPlugin",
                            "WARNING: Skipping duplicate vid in download list: vid=$vid"
                        )
                        continue
                    }
                    if (vid != null) {
                        seenVids.add(vid)
                    }

                    if (vid != null && deletedDownloadVids.contains(vid)) {
                        android.util.Log.d(
                            "PolyvMediaPlayerPlugin",
                            "Filtering out deleted task: vid=$vid"
                        )
                        downloadPreviousStates.remove(vid)
                        continue
                    }

                    if (!vid.isNullOrEmpty()) {
                        taskList.add(taskDict)
                        android.util.Log.d(
                            "PolyvMediaPlayerPlugin",
                            "Adding task to list: vid=$vid, status=${taskDict["status"]}, downloadedBytes=${taskDict["downloadedBytes"]}"
                        )
                    } else {
                        android.util.Log.d("PolyvMediaPlayerPlugin", "Filtering out task without vid")
                    }
                }
            }

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "Returning ${taskList.size} tasks (filtered from ${downloaderList.size} total)"
            )
            result.success(taskList)
        } catch (e: Exception) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Failed to get download list: ${e.message}")
            result.error("SDK_ERROR", e.message ?: "Failed to get download list", null)
        }
    }

    fun handleStartDownload(call: MethodCall, result: Result) {
        android.util.Log.d("PolyvMediaPlayerPlugin", "handleStartDownload called")

        val args = call.arguments as? Map<*, *>
        val vid = args?.get("vid")?.toString()?.trim()
        val quality = args?.get("quality")?.toString()?.trim()

        android.util.Log.d("PolyvMediaPlayerPlugin", "VID: $vid, Quality: $quality")

        if (vid.isNullOrBlank()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "VID is empty")
            result.error("INVALID_ARGUMENT", "VID is required", null)
            return
        }

        deletedDownloadVids.remove(vid)

        val appCtx = getApplicationContext()
        if (appCtx == null) {
            result.error(errorCodeNotInitialized, "Context not initialized", null)
            return
        }

        val config = try {
            getAuthConfigOrThrow()
        } catch (e: IllegalStateException) {
            result.error(errorCodeNotInitialized, e.message, null)
            return
        }

        val userId = config.first
        val secretKey = config.second
        val readToken = getReadToken()
        val writeToken = getWriteToken()

        android.util.Log.d(
            "PolyvMediaPlayerPlugin",
            "Download config - userId: $userId, hasReadToken: ${readToken != null}, hasWriteToken: ${writeToken != null}"
        )

        val authentication = PLVVodMainAccountAuthentication(userId, secretKey, readToken, writeToken)
        val viewerParam = PLVViewerParam(
            "viewer",
            "viewer",
            null, null, null, null,
            null
        )

        val downloadRoots = listOfNotNull(appCtx.getExternalFilesDir(null)?.absolutePath)
        android.util.Log.d("PolyvMediaPlayerPlugin", "Download roots: $downloadRoots")

        if (downloadRoots.isEmpty()) {
            android.util.Log.e("PolyvMediaPlayerPlugin", "Download root directory is null")
            result.error("SDK_ERROR", "Download directory not available", null)
            return
        }

        android.util.Log.d("PolyvMediaPlayerPlugin", "Creating download resource for vid: $vid")

        try {
            val mediaResource = PLVMediaResource.vod(vid, authentication, viewerParam, downloadRoots)
            android.util.Log.d("PolyvMediaPlayerPlugin", "Media resource created for vid: $vid")

            val targetBitRate = PLVMediaBitRate.BITRATE_AUTO
            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "Using BITRATE_AUTO, quality parameter: $quality (ignored)"
            )

            val downloader = runCatching {
                PLVMediaDownloaderManager.getDownloader(mediaResource, targetBitRate)
            }.getOrElse { e ->
                android.util.Log.e(
                    "PolyvMediaPlayerPlugin",
                    "Failed to get downloader: ${e.message}, stack: ${e.stackTraceToString()}"
                )
                result.error("SDK_ERROR", "Failed to create downloader: ${e.message}", null)
                return
            }

            if (downloader == null) {
                android.util.Log.e("PolyvMediaPlayerPlugin", "Downloader is null")
                result.error("SDK_ERROR", "Failed to create downloader: returned null", null)
                return
            }

            val initialStatus = downloader.listenerRegistry.status.value
            android.util.Log.d("PolyvMediaPlayerPlugin", "Downloader retrieved, initial status: $initialStatus")

            downloadPreviousStates[vid] = initialStatus

            when (initialStatus) {
                PLVMediaDownloadStatus.NOT_STARTED,
                PLVMediaDownloadStatus.PAUSED,
                PLVMediaDownloadStatus.WAITING -> {
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Starting downloader from status: $initialStatus"
                    )
                    PLVMediaDownloaderManager.startDownloader(downloader)
                }

                PLVMediaDownloadStatus.DOWNLOADING -> {
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Downloader already in DOWNLOADING status"
                    )
                }

                PLVMediaDownloadStatus.COMPLETED -> {
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Downloader already COMPLETED"
                    )
                }

                is PLVMediaDownloadStatus.ERROR -> {
                    android.util.Log.d(
                        "PolyvMediaPlayerPlugin",
                        "Downloader in ERROR status, retrying"
                    )
                    PLVMediaDownloaderManager.startDownloader(downloader)
                }

                null -> {
                    android.util.Log.d("PolyvMediaPlayerPlugin", "Status is null, trying to start")
                    PLVMediaDownloaderManager.startDownloader(downloader)
                }
            }

            android.util.Log.d(
                "PolyvMediaPlayerPlugin",
                "Download task created successfully for vid: $vid"
            )

            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e(
                "PolyvMediaPlayerPlugin",
                "Failed to create download task: ${e.message}, stack: ${e.stackTraceToString()}"
            )
            result.error("SDK_ERROR", e.message ?: "Failed to create download task", null)
            return
        }
    }

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

            if (currentState != previousState) {
                android.util.Log.d(
                    "PolyvMediaPlayerPlugin",
                    "Download state changed for vid=$vid: $previousState -> $currentState"
                )

                handleDownloadStateChanged(downloader, previousState, currentState)
                downloadPreviousStates[vid] = currentState
            }

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

    private fun handleDownloadStateChanged(
        downloader: PLVMediaDownloader,
        fromState: PLVMediaDownloadStatus?,
        toState: PLVMediaDownloadStatus?
    ) {
        when (toState) {
            PLVMediaDownloadStatus.COMPLETED -> sendDownloadCompletedEvent(downloader)
            is PLVMediaDownloadStatus.ERROR -> sendDownloadFailedEvent(downloader)
            PLVMediaDownloadStatus.PAUSED -> sendDownloadPausedEvent(downloader)
            PLVMediaDownloadStatus.DOWNLOADING -> {
                if (fromState == PLVMediaDownloadStatus.PAUSED) {
                    sendDownloadResumedEvent(downloader)
                }
                sendDownloadProgressEvent(downloader)
            }

            else -> {}
        }
    }

    private fun sendDownloadProgressEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val size: Long = totalBytesVal ?: 0L
        val prog: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (size.toDouble() * prog).toLong()

        sendDownloadEvent(
            mapOf(
                "type" to downloadEventTaskProgress,
                "data" to mapOf(
                    "id" to vid,
                    "downloadedBytes" to downloadedBytes,
                    "totalBytes" to (totalBytesVal ?: 0L),
                    "bytesPerSecond" to (downloader.listenerRegistry.downloadBytesPerSecond.value ?: 0L),
                    "status" to convertDownloadStatusToString(downloader.listenerRegistry.status.value)
                )
            )
        )
    }

    private fun sendDownloadCompletedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val completedAt = SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            Locale.US
        ).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date())

        sendDownloadEvent(
            mapOf(
                "type" to downloadEventTaskCompleted,
                "data" to mapOf(
                    "id" to vid,
                    "completedAt" to completedAt
                )
            )
        )
    }

    private fun sendDownloadFailedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val errorMessage = "下载失败"
        android.util.Log.e("PolyvMediaPlayerPlugin", "Download failed for vid: $vid")

        sendDownloadEvent(
            mapOf(
                "type" to downloadEventTaskFailed,
                "data" to mapOf(
                    "id" to vid,
                    "errorMessage" to errorMessage
                )
            )
        )
    }

    private fun sendDownloadPausedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        sendDownloadEvent(
            mapOf(
                "type" to downloadEventTaskPaused,
                "data" to mapOf(
                    "id" to vid
                )
            )
        )
    }

    private fun sendDownloadResumedEvent(downloader: PLVMediaDownloader) {
        val mediaResource = downloader.mediaResource as? PLVVodMediaResource
        val vid = mediaResource?.videoId ?: return

        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val size: Long = totalBytesVal ?: 0L
        val prog: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (size.toDouble() * prog).toLong()

        sendDownloadEvent(
            mapOf(
                "type" to downloadEventTaskProgress,
                "data" to mapOf(
                    "id" to vid,
                    "downloadedBytes" to downloadedBytes,
                    "totalBytes" to size,
                    "bytesPerSecond" to 0,
                    "status" to "downloading"
                )
            )
        )
        android.util.Log.d(
            "PolyvMediaPlayerPlugin",
            "Send resumed event for vid=$vid with downloadedBytes=$downloadedBytes"
        )
    }

    private fun sendDownloadEvent(event: Map<String, Any>) {
        downloadEventEmitter.send(event)
    }

    private fun sendDownloadEventReliably(event: Map<String, Any>) {
        downloadEventEmitter.sendReliably(event)
    }

    private fun findDownloaderByVid(vid: String): PLVMediaDownloader? {
        val downloaderList = PLVMediaDownloaderManager.downloaderList.value ?: return null

        return downloaderList.find { downloader ->
            val mediaResource = downloader.mediaResource
            if (mediaResource is PLVVodMediaResource) {
                mediaResource.videoId == vid
            } else {
                false
            }
        }
    }

    private fun convertDownloaderToDict(downloader: PLVMediaDownloader): Map<String, Any?>? {
        val mediaResource = downloader.mediaResource
        if (mediaResource !is PLVVodMediaResource) {
            return null
        }

        val vid = mediaResource.videoId ?: return null
        val taskId = vid
        val title = "Video_$vid"
        val thumbnail = downloader.listenerRegistry.coverImage.value

        val totalBytesVal = downloader.listenerRegistry.fileSize.value
        val progressVal = downloader.listenerRegistry.progress.value
        val totalBytes: Long = totalBytesVal ?: 0L
        val prog: Float = progressVal ?: 0.0f
        val downloadedBytes: Long = (totalBytes.toDouble() * prog).toLong()

        val bytesPerSecond = downloader.listenerRegistry.downloadBytesPerSecond.value ?: 0L

        val status = convertDownloadStatusToString(downloader.listenerRegistry.status.value)

        val errorMessage: String? = if (downloader.listenerRegistry.status.value is PLVMediaDownloadStatus.ERROR) {
            "下载失败"
        } else {
            null
        }

        val createdAt = SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            Locale.US
        ).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date())

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
}
