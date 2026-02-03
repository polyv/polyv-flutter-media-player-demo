#import <Foundation/Foundation.h>

@class PLVFlutterEventEmitter;

@interface PLVFlutterDownloadMonitor : NSObject

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter;

- (void)startMonitoring;
- (void)stopMonitoring;

- (NSArray<NSDictionary *> *)fetchDownloadTaskList;

@end
