#import <Flutter/Flutter.h>

@interface PLVFlutterEventStreamHandler : NSObject <FlutterStreamHandler>

@property (nonatomic, copy) FlutterEventSink eventSink;

- (void)sendEvent:(NSDictionary<NSString *, id> *)event;

@end
