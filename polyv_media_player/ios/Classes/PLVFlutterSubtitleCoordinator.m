#import "PLVFlutterSubtitleCoordinator.h"

#import "PLVMediaPlayerSubtitleModule.h"
#import "PLVFlutterEventEmitter.h"

#import <PolyvMediaPlayerSDK/PLVVodMediaVideo.h>

@interface PLVFlutterSubtitleCoordinator ()

@property (nonatomic, strong) PLVFlutterEventEmitter *eventEmitter;
@property (nonatomic, weak) UIView *containerView;

@property (nonatomic, strong) PLVMediaPlayerSubtitleModule *subtitleModule;

@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *subtitleTopLabel;
@property (nonatomic, strong) UILabel *subtitleLabel2;
@property (nonatomic, strong) UILabel *subtitleTopLabel2;

@property (nonatomic, copy) NSString *currentSubtitleTrackKey;
@property (nonatomic, assign) BOOL currentSubtitleEnabled;
@property (nonatomic, assign) BOOL subtitleStateInitialized;

@end

@implementation PLVFlutterSubtitleCoordinator

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter {
    self = [super init];
    if (self) {
        _eventEmitter = eventEmitter;
    }
    return self;
}

- (void)updateContainerView:(UIView *)containerView {
    if (self.containerView == containerView) {
        return;
    }

    self.containerView = containerView;

    // container 变化时，旧 label 已经挂在旧 container 上，需要清理并重新创建
    [self resetLabelsAndModule];
}

- (void)resetLabelsAndModule {
    [self.subtitleLabel removeFromSuperview];
    [self.subtitleTopLabel removeFromSuperview];
    [self.subtitleLabel2 removeFromSuperview];
    [self.subtitleTopLabel2 removeFromSuperview];

    self.subtitleLabel = nil;
    self.subtitleTopLabel = nil;
    self.subtitleLabel2 = nil;
    self.subtitleTopLabel2 = nil;

    self.subtitleModule = nil;
}

- (void)resetAll {
    [self resetLabelsAndModule];

    self.currentSubtitleTrackKey = nil;
    self.currentSubtitleEnabled = NO;
    self.subtitleStateInitialized = NO;
}

- (void)setupIfNeededForVideo:(PLVVodMediaVideo *)video {
    if (!self.containerView) {
        return;
    }

    UIView *container = self.containerView;
    NSLog(@"[PolyvPlugin] ========== setupSubtitleModuleIfNeededForVideo called ==========");
    NSLog(@"[PolyvPlugin] container.bounds: %@", NSStringFromCGRect(container.bounds));
    NSLog(@"[PolyvPlugin] subtitleLabel exists: %@", self.subtitleLabel ? @"YES" : @"NO");

    if (!self.subtitleLabel) {
        CGRect bounds = container.bounds;
        CGFloat width = bounds.size.width > 0 ? bounds.size.width : [UIScreen mainScreen].bounds.size.width;
        CGFloat height = bounds.size.height > 0 ? bounds.size.height : [UIScreen mainScreen].bounds.size.height;

        UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 80.0, width - 32.0, 40.0)];
        bottomLabel.textColor = [UIColor whiteColor];
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        bottomLabel.numberOfLines = 0;
        bottomLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        bottomLabel.shadowOffset = CGSizeMake(0, 1);
        bottomLabel.backgroundColor = [UIColor clearColor];
        bottomLabel.adjustsFontSizeToFitWidth = YES;
        bottomLabel.minimumScaleFactor = 0.5;

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 120.0, width - 32.0, 40.0)];
        topLabel.textColor = [UIColor whiteColor];
        topLabel.textAlignment = NSTextAlignmentCenter;
        topLabel.numberOfLines = 0;
        topLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        topLabel.shadowOffset = CGSizeMake(0, 1);
        topLabel.backgroundColor = [UIColor clearColor];
        topLabel.adjustsFontSizeToFitWidth = YES;
        topLabel.minimumScaleFactor = 0.5;

        UILabel *bottomLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 40.0, width - 32.0, 30.0)];
        bottomLabel2.textColor = [UIColor whiteColor];
        bottomLabel2.textAlignment = NSTextAlignmentCenter;
        bottomLabel2.numberOfLines = 0;
        bottomLabel2.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        bottomLabel2.shadowOffset = CGSizeMake(0, 1);
        bottomLabel2.backgroundColor = [UIColor clearColor];
        bottomLabel2.adjustsFontSizeToFitWidth = YES;
        bottomLabel2.minimumScaleFactor = 0.5;

        UILabel *topLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 160.0, width - 32.0, 30.0)];
        topLabel2.textColor = [UIColor whiteColor];
        topLabel2.textAlignment = NSTextAlignmentCenter;
        topLabel2.numberOfLines = 0;
        topLabel2.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        topLabel2.shadowOffset = CGSizeMake(0, 1);
        topLabel2.backgroundColor = [UIColor clearColor];
        topLabel2.adjustsFontSizeToFitWidth = YES;
        topLabel2.minimumScaleFactor = 0.5;

        bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        topLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        bottomLabel2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        topLabel2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        [container addSubview:topLabel2];
        [container addSubview:bottomLabel2];
        [container addSubview:topLabel];
        [container addSubview:bottomLabel];

        self.subtitleLabel = bottomLabel;
        self.subtitleTopLabel = topLabel;
        self.subtitleLabel2 = bottomLabel2;
        self.subtitleTopLabel2 = topLabel2;

        NSLog(@"[PolyvPlugin] Subtitle labels created and added to container");
        NSLog(@"[PolyvPlugin] bottomLabel frame: %@", NSStringFromCGRect(bottomLabel.frame));
    } else {
        NSLog(@"[PolyvPlugin] Subtitle labels already exist, bringing to front");
        [container bringSubviewToFront:self.subtitleTopLabel2];
        [container bringSubviewToFront:self.subtitleLabel2];
        [container bringSubviewToFront:self.subtitleTopLabel];
        [container bringSubviewToFront:self.subtitleLabel];
    }

    if (!self.subtitleModule) {
        self.subtitleModule = [[PLVMediaPlayerSubtitleModule alloc] init];
        NSLog(@"[PolyvPlugin] SubtitleModule created");
    }

    NSLog(@"[PolyvPlugin] Loading subtitle module with video...");
    [self.subtitleModule loadSubtitlsWithVideoModel:video
                                             label:self.subtitleLabel
                                          topLabel:self.subtitleTopLabel
                                            label2:self.subtitleLabel2
                                         topLabel2:self.subtitleTopLabel2];
    NSLog(@"[PolyvPlugin] Subtitle module loaded");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[PolyvPlugin] Delayed bringSubtitleLabelsToFront called");
        [self bringSubtitleLabelsToFront];
    });

    if (self.subtitleStateInitialized && self.currentSubtitleEnabled) {
        NSString *subtitleName = self.currentSubtitleTrackKey;
        if (subtitleName.length == 0 && video) {
            @try {
                NSArray *srts = [video valueForKey:@"srts"];
                if ([srts isKindOfClass:[NSArray class]] && srts.count > 0) {
                    id firstSrt = srts.firstObject;
                    if ([firstSrt respondsToSelector:@selector(title)]) {
                        subtitleName = [firstSrt valueForKey:@"title"];
                    }
                }
            } @catch (__unused NSException *exception) {
            }
        }

        if (subtitleName.length > 0) {
            NSLog(@"[PolyvPlugin] 恢复字幕选择: %@", subtitleName);
            [self.subtitleModule updateSubtitleWithName:subtitleName show:YES];
        }
    }
}

- (void)bringSubtitleLabelsToFront {
    if (!self.containerView) {
        return;
    }

    UIView *container = self.containerView;

    NSLog(@"[PolyvPlugin] ========== bringSubtitleLabelsToFront ==========");
    NSLog(@"[PolyvPlugin] container.bounds: %@, container.frame: %@", NSStringFromCGRect(container.bounds), NSStringFromCGRect(container.frame));
    NSLog(@"[PolyvPlugin] containerView subviews count: %lu", (unsigned long)container.subviews.count);

    [self updateSubtitleLabelFrames];

    NSLog(@"[PolyvPlugin] subtitleLabel.frame: %@", NSStringFromCGRect(self.subtitleLabel.frame));
    NSLog(@"[PolyvPlugin] subtitleTopLabel.frame: %@", NSStringFromCGRect(self.subtitleTopLabel.frame));
    NSLog(@"[PolyvPlugin] subtitleLabel.text: '%@'", self.subtitleLabel.text);

    for (int i = 0; i < container.subviews.count; i++) {
        UIView *subview = container.subviews[i];
        NSLog(@"[PolyvPlugin]   [%d] %@ (frame=%@, hidden=%d)", i,
              NSStringFromClass(subview.class),
              NSStringFromCGRect(subview.frame),
              subview.isHidden);
    }

    if (self.subtitleTopLabel2 && self.subtitleTopLabel2.superview == container) {
        [container bringSubviewToFront:self.subtitleTopLabel2];
        NSLog(@"[PolyvPlugin] Brought subtitleTopLabel2 to front");
    }
    if (self.subtitleLabel2 && self.subtitleLabel2.superview == container) {
        [container bringSubviewToFront:self.subtitleLabel2];
        NSLog(@"[PolyvPlugin] Brought subtitleLabel2 to front");
    }
    if (self.subtitleTopLabel && self.subtitleTopLabel.superview == container) {
        [container bringSubviewToFront:self.subtitleTopLabel];
        NSLog(@"[PolyvPlugin] Brought subtitleTopLabel to front");
    }
    if (self.subtitleLabel && self.subtitleLabel.superview == container) {
        [container bringSubviewToFront:self.subtitleLabel];
        NSLog(@"[PolyvPlugin] Brought subtitleLabel to front");
    }
}

- (void)updateSubtitleLabelFrames {
    if (!self.containerView) {
        return;
    }

    UIView *container = self.containerView;
    CGRect bounds = container.bounds;

    if (bounds.size.width <= 0 || bounds.size.height <= 0) {
        bounds = [UIScreen mainScreen].bounds;
    }

    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;

    if (self.subtitleLabel) {
        self.subtitleLabel.frame = CGRectMake(16, height - 80.0, width - 32.0, 40.0);
    }
    if (self.subtitleTopLabel) {
        self.subtitleTopLabel.frame = CGRectMake(16, height - 120.0, width - 32.0, 40.0);
    }
    if (self.subtitleLabel2) {
        self.subtitleLabel2.frame = CGRectMake(16, height - 40.0, width - 32.0, 30.0);
    }
    if (self.subtitleTopLabel2) {
        self.subtitleTopLabel2.frame = CGRectMake(16, height - 160.0, width - 32.0, 30.0);
    }
}

- (void)showSubtitlesWithPlaytime:(NSTimeInterval)playtime {
    if (self.subtitleModule) {
        [self.subtitleModule showSubtilesWithPlaytime:playtime];
    }
}

- (void)sendSubtitleChangedEventWithVideo:(PLVVodMediaVideo *)video enabled:(BOOL)enabled trackKey:(NSString *)trackKey {
    NSMutableArray *subtitlesArray = [NSMutableArray array];
    NSInteger currentIndex = -1;

    if (video) {
        @try {
            NSArray *srts = [video valueForKey:@"srts"];
            if ([srts isKindOfClass:[NSArray class]]) {
                for (id item in srts) {
                    NSString *title = nil;
                    NSString *url = nil;
                    @try {
                        if ([item respondsToSelector:@selector(title)]) {
                            title = [item valueForKey:@"title"];
                        }
                        if ([item respondsToSelector:@selector(url)]) {
                            url = [item valueForKey:@"url"];
                        }
                    } @catch (__unused NSException *inner) {
                        title = nil;
                        url = nil;
                    }

                    if (title.length == 0) {
                        title = @"";
                    }

                    NSMutableDictionary *subtitleDict = [@{
                        @"trackKey": title,
                        @"language": title,
                        @"label": title,
                        @"isBilingual": @NO,
                        @"isDefault": @NO
                    } mutableCopy];
                    if (url.length > 0) {
                        subtitleDict[@"url"] = url;
                    }

                    if (trackKey && [trackKey isEqualToString:title] && currentIndex == -1) {
                        currentIndex = subtitlesArray.count;
                    }

                    [subtitlesArray addObject:subtitleDict];
                }
            }
        } @catch (__unused NSException *exception) {
        }
    }

    if (!enabled) {
        currentIndex = -1;
        trackKey = nil;
    } else if (currentIndex < 0 && subtitlesArray.count > 0) {
        currentIndex = 0;
        NSDictionary *first = subtitlesArray.firstObject;
        trackKey = [first[@"language"] isKindOfClass:[NSString class]] ? first[@"language"] : nil;
    }

    if (self.subtitleModule) {
        NSString *subtitleName = trackKey;
        if (!enabled || subtitleName.length == 0) {
            subtitleName = @"";
        }
        [self.subtitleModule updateSubtitleWithName:subtitleName show:(enabled && subtitleName.length > 0)];
    }

    self.currentSubtitleEnabled = enabled;
    self.currentSubtitleTrackKey = trackKey;
    self.subtitleStateInitialized = YES;

    NSMutableDictionary *data = [@{
        @"subtitles": subtitlesArray,
        @"currentIndex": @(currentIndex),
        @"enabled": @(enabled)
    } mutableCopy];
    if (trackKey) {
        data[@"trackKey"] = trackKey;
    }

    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"subtitleChanged",
        @"data": data
    }];
}

@end
