#import "PLVFlutterDownloadMonitor.h"

#import "PLVFlutterEventEmitter.h"

#import <PolyvMediaPlayerSDK/PolyvMediaPlayerSDK.h>

@interface PLVFlutterDownloadMonitor ()

@property (nonatomic, strong) PLVFlutterEventEmitter *eventEmitter;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadPreviousStates;
@property (nonatomic, strong) NSTimer *downloadStatusCheckTimer;

@end

@implementation PLVFlutterDownloadMonitor

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter {
    self = [super init];
    if (self) {
        _eventEmitter = eventEmitter;
    }
    return self;
}

- (void)startMonitoring {
    self.downloadPreviousStates = [NSMutableDictionary dictionary];

    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];
    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    for (PLVDownloadInfo *info in allDownloads) {
        NSString *vid = info.vid ?: @"";
        self.downloadPreviousStates[vid] = @(info.state);
    }

    self.downloadStatusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                     target:self
                                                                   selector:@selector(checkDownloadStatusChanges)
                                                                   userInfo:nil
                                                                    repeats:YES];

    NSLog(@"[PolyvPlugin] Download status monitoring started with %lu tasks", (unsigned long)allDownloads.count);
}

- (void)stopMonitoring {
    if (self.downloadStatusCheckTimer) {
        [self.downloadStatusCheckTimer invalidate];
        self.downloadStatusCheckTimer = nil;
        NSLog(@"[PolyvPlugin] Download status monitoring stopped");
    }
}

- (NSArray<NSDictionary *> *)fetchDownloadTaskList {
    NSMutableArray<NSDictionary *> *taskList = [NSMutableArray array];

    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];

    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    NSLog(@"[PolyvPlugin] Total tasks from SDK: %lu (unfinished: %lu, finished: %lu)",
          (unsigned long)allDownloads.count, (unsigned long)unfinishedDownloads.count, (unsigned long)finishedDownloads.count);

    NSMutableSet<NSString *> *seenVids = [NSMutableSet set];

    for (PLVDownloadInfo *info in allDownloads) {
        NSDictionary *taskDict = [self convertDownloadInfoToDict:info];
        if (taskDict) {
            NSString *vid = taskDict[@"vid"];

            if ([seenVids containsObject:vid]) {
                NSLog(@"[PolyvPlugin] WARNING: Duplicate vid found in download list: vid=%@", vid);
            } else {
                [seenVids addObject:vid];
            }

            if (vid.length > 0) {
                [taskList addObject:taskDict];
                NSLog(@"[PolyvPlugin] Adding task to list: vid=%@, status=%@, downloadedBytes=%lld",
                      vid, taskDict[@"status"], [taskDict[@"downloadedBytes"] longLongValue]);
            } else {
                NSLog(@"[PolyvPlugin] Filtering out task without vid");
            }
        }
    }

    NSLog(@"[PolyvPlugin] Returning %lu tasks (filtered from %lu total)", (unsigned long)taskList.count, (unsigned long)allDownloads.count);
    return taskList;
}

- (void)checkDownloadStatusChanges {
    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];
    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    for (PLVDownloadInfo *info in allDownloads) {
        NSString *vid = info.vid ?: @"";
        if (vid.length == 0) continue;

        PLVVodDownloadState currentState = info.state;
        NSNumber *previousStateNumber = self.downloadPreviousStates[vid];
        PLVVodDownloadState previousState = previousStateNumber ? (PLVVodDownloadState)[previousStateNumber integerValue] : PLVVodDownloadStatePreparing;

        if (currentState != previousState) {
            NSLog(@"[PolyvPlugin] Download state changed for vid=%@: %ld -> %ld",
                  vid, (long)previousState, (long)currentState);

            [self handleDownloadStateChanged:info fromState:previousState toState:currentState];

            self.downloadPreviousStates[vid] = @(currentState);
        }

        if (currentState == PLVVodDownloadStateRunning ||
            currentState == PLVVodDownloadStatePreparing ||
            currentState == PLVVodDownloadStatePreparingTask ||
            currentState == PLVVodDownloadStateReady) {
            [self sendDownloadProgressEvent:info];
        }
    }
}

- (void)handleDownloadStateChanged:(PLVDownloadInfo *)info
                         fromState:(PLVVodDownloadState)fromState
                           toState:(PLVVodDownloadState)toState {
    switch (toState) {
        case PLVVodDownloadStateSuccess:
            [self sendDownloadCompletedEvent:info];
            break;

        case PLVVodDownloadStateFailed:
            [self sendDownloadFailedEvent:info];
            break;

        case PLVVodDownloadStateStopping:
        case PLVVodDownloadStateStopped:
            [self sendDownloadPausedEvent:info];
            break;

        case PLVVodDownloadStateRunning:
            if (fromState == PLVVodDownloadStateStopped || fromState == PLVVodDownloadStateStopping) {
                [self sendDownloadResumedEvent:info];
            }
            break;

        default:
            break;
    }
}

- (void)sendDownloadProgressEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    long long downloadedBytes = (long long)(info.progress * info.filesize);

    [self.eventEmitter sendDownloadEvent:@{
        @"type": @"taskProgress",
        @"data": @{
            @"id": vid,
            @"downloadedBytes": @(downloadedBytes),
            @"totalBytes": @(info.filesize),
            @"bytesPerSecond": @(0),
            @"status": [self convertDownloadStateToString:info.state]
        }
    }];
}

- (void)sendDownloadCompletedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    NSString *completedAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];

    [self.eventEmitter sendDownloadEvent:@{
        @"type": @"taskCompleted",
        @"data": @{
            @"id": vid,
            @"completedAt": completedAt
        }
    }];
}

- (void)sendDownloadFailedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    [self.eventEmitter sendDownloadEvent:@{
        @"type": @"taskFailed",
        @"data": @{
            @"id": vid,
            @"errorMessage": @"下载失败"
        }
    }];
}

- (void)sendDownloadPausedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    [self.eventEmitter sendDownloadEvent:@{
        @"type": @"taskPaused",
        @"data": @{
            @"id": vid
        }
    }];
}

- (void)sendDownloadResumedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    long long downloadedBytes = (long long)(info.progress * info.filesize);

    [self.eventEmitter sendDownloadEvent:@{
        @"type": @"taskProgress",
        @"data": @{
            @"id": vid,
            @"downloadedBytes": @(downloadedBytes),
            @"totalBytes": @(info.filesize),
            @"bytesPerSecond": @(0),
            @"status": @"downloading"
        }
    }];

    NSLog(@"[PolyvPlugin] Send resumed event for vid=%@ with downloadedBytes=%lld", vid, downloadedBytes);
}

- (NSDictionary *)convertDownloadInfoToDict:(PLVDownloadInfo *)info {
    if (!info) return nil;

    NSString *vid = info.vid ?: @"";
    NSString *taskId = vid;
    NSString *title = info.title ?: @"未知视频";
    NSString *thumbnail = info.snapshot ?: @"";

    long long totalBytes = info.filesize;
    long long downloadedBytes = (long long)(info.progress * info.filesize);

    int bytesPerSecond = 0;

    NSString *status = [self convertDownloadStateToString:info.state];

    NSString *errorMessage = nil;
    if (info.state == PLVVodDownloadStateFailed) {
        errorMessage = @"下载失败";
    }

    NSString *createdAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];
    NSString *completedAt = nil;
    if (info.state == PLVVodDownloadStateSuccess) {
        completedAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];
    }

    NSMutableDictionary *dict = [@{
        @"id": taskId,
        @"vid": vid,
        @"title": title,
        @"totalBytes": @(totalBytes),
        @"downloadedBytes": @(downloadedBytes),
        @"bytesPerSecond": @(bytesPerSecond),
        @"status": status,
        @"createdAt": createdAt,
    } mutableCopy];

    if (thumbnail.length > 0) {
        dict[@"thumbnail"] = thumbnail;
    }
    if (errorMessage) {
        dict[@"errorMessage"] = errorMessage;
    }
    if (completedAt) {
        dict[@"completedAt"] = completedAt;
    }

    return dict;
}

- (NSString *)convertDownloadStateToString:(PLVVodDownloadState)state {
    switch (state) {
        case PLVVodDownloadStatePreparing:
        case PLVVodDownloadStatePreparingTask:
            return @"preparing";

        case PLVVodDownloadStateReady:
            return @"waiting";

        case PLVVodDownloadStateRunning:
            return @"downloading";

        case PLVVodDownloadStateStopping:
        case PLVVodDownloadStateStopped:
            return @"paused";

        case PLVVodDownloadStateSuccess:
            return @"completed";

        case PLVVodDownloadStateFailed:
            return @"error";

        default:
            return @"waiting";
    }
}

- (NSDateFormatter *)iso8601Formatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    });
    return formatter;
}

@end
