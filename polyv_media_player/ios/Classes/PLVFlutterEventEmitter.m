#import "PLVFlutterEventEmitter.h"
#import "PLVFlutterEventStreamHandler.h"

@interface PLVFlutterEventEmitter ()
@property (nonatomic, strong) PLVFlutterEventStreamHandler *playerStreamHandler;
@property (nonatomic, strong) PLVFlutterEventStreamHandler *downloadStreamHandler;
@end

@implementation PLVFlutterEventEmitter

- (instancetype)initWithPlayerStreamHandler:(PLVFlutterEventStreamHandler *)playerStreamHandler
                        downloadStreamHandler:(PLVFlutterEventStreamHandler *)downloadStreamHandler {
    self = [super init];
    if (self) {
        _playerStreamHandler = playerStreamHandler;
        _downloadStreamHandler = downloadStreamHandler;
    }
    return self;
}

- (void)sendPlayerEvent:(NSDictionary<NSString *, id> *)event {
    [self.playerStreamHandler sendEvent:event];
}

- (void)sendDownloadEvent:(NSDictionary<NSString *, id> *)event {
    [self.downloadStreamHandler sendEvent:event];
}

@end
