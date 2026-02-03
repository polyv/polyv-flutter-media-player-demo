#import <Foundation/Foundation.h>

@class PLVFlutterEventStreamHandler;

@interface PLVFlutterEventEmitter : NSObject

- (instancetype)initWithPlayerStreamHandler:(PLVFlutterEventStreamHandler *)playerStreamHandler
                        downloadStreamHandler:(PLVFlutterEventStreamHandler *)downloadStreamHandler;

- (void)sendPlayerEvent:(NSDictionary<NSString *, id> *)event;
- (void)sendDownloadEvent:(NSDictionary<NSString *, id> *)event;

@end
