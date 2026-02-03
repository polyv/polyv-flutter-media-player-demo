#import "PLVFlutterEventStreamHandler.h"

@implementation PLVFlutterEventStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    NSLog(@"[PolyvPlugin] EventStreamHandler onListen called");
    self.eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"[PolyvPlugin] EventStreamHandler onCancel called");
    self.eventSink = nil;
    return nil;
}

- (void)sendEvent:(NSDictionary<NSString *, id> *)event {
    NSLog(@"[PolyvPlugin] EventStreamHandler sendEvent called, sink=%p, event=%@", self.eventSink, event);
    if (self.eventSink) {
        self.eventSink(event);
        NSLog(@"[PolyvPlugin] Event sent successfully");
    } else {
        NSLog(@"[PolyvPlugin] WARNING: eventSink is nil, event not sent!");
    }
}

@end
