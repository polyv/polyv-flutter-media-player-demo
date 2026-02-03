#import <Flutter/Flutter.h>

@class PolyvMediaPlayerPlugin;

@interface PLVFlutterMethodRouter : NSObject

- (instancetype)initWithPlugin:(PolyvMediaPlayerPlugin *)plugin;
- (BOOL)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;

@end
