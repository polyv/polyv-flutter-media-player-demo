#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频视图工厂
@interface PLVVideoViewFactory : NSObject <FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

/// 视频视图控制器
@interface PLVVideoViewController : NSObject <FlutterPlatformView>

@property (nonatomic, strong) UIView *containerView;

- (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
