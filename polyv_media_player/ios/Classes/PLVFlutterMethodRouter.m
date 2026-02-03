#import "PLVFlutterMethodRouter.h"
#import "PolyvMediaPlayerPlugin+MethodHandlers.h"

@interface PLVFlutterMethodRouter ()
@property (nonatomic, weak) PolyvMediaPlayerPlugin *plugin;
@end

@implementation PLVFlutterMethodRouter

- (instancetype)initWithPlugin:(PolyvMediaPlayerPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
    }
    return self;
}

- (BOOL)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;

    if ([call.method isEqualToString:@"initialize"]) {
        [self.plugin handleInitialize:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"loadVideo"]) {
        [self.plugin handleLoadVideo:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"play"]) {
        [self.plugin handlePlay:result];
        return YES;
    } else if ([call.method isEqualToString:@"pause"]) {
        [self.plugin handlePause:result];
        return YES;
    } else if ([call.method isEqualToString:@"stop"]) {
        [self.plugin handleStop:result];
        return YES;
    } else if ([call.method isEqualToString:@"seekTo"]) {
        [self.plugin handleSeekTo:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"setPlaybackSpeed"]) {
        [self.plugin handleSetPlaybackSpeed:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"setQuality"]) {
        [self.plugin handleSetQuality:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"setSubtitle"]) {
        [self.plugin handleSetSubtitle:args result:result];
        return YES;
    } else if ([call.method isEqualToString:@"getQualities"]) {
        [self.plugin handleGetQualities:result];
        return YES;
    } else if ([call.method isEqualToString:@"getSubtitles"]) {
        [self.plugin handleGetSubtitles:result];
        return YES;
    } else if ([call.method isEqualToString:@"disposePlayer"]) {
        [self.plugin clearPlayer];
        result(nil);
        return YES;
    } else if ([call.method isEqualToString:@"pauseDownload"]) {
        [self.plugin handlePauseDownload:call.arguments result:result];
        return YES;
    } else if ([call.method isEqualToString:@"resumeDownload"]) {
        [self.plugin handleResumeDownload:call.arguments result:result];
        return YES;
    } else if ([call.method isEqualToString:@"retryDownload"]) {
        [self.plugin handleRetryDownload:call.arguments result:result];
        return YES;
    } else if ([call.method isEqualToString:@"deleteDownload"]) {
        [self.plugin handleDeleteDownload:call.arguments result:result];
        return YES;
    } else if ([call.method isEqualToString:@"getDownloadList"]) {
        [self.plugin handleGetDownloadList:result];
        return YES;
    } else if ([call.method isEqualToString:@"startDownload"]) {
        [self.plugin handleStartDownload:call.arguments result:result];
        return YES;
    }

    return NO;
}

@end
