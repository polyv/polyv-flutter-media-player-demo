#import "PLVVideoViewFactory.h"

@implementation PLVVideoViewController

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        _containerView = [[UIView alloc] initWithFrame:frame];
        _containerView.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (UIView *)view {
    return _containerView;
}

@end

#pragma mark - PLVVideoViewFactory

@implementation PLVVideoViewFactory {
    NSObject<FlutterBinaryMessenger> *_messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    PLVVideoViewController *controller = [[PLVVideoViewController alloc] initWithFrame:frame];

    // 发送通知告知视频视图已创建
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PLVVideoViewCreated"
                                                        object:controller
                                                      userInfo:@{@"viewId": @(viewId)}];

    return controller;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

@end
