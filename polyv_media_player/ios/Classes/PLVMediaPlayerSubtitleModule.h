//
//  PLVMediaPlayerSubtitleModule.h
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/8/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PolyvMediaPlayerSDK/PLVVodMediaVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVMediaPlayerSubtitleModule : NSObject

/// 首次初始化字幕
- (void)loadSubtitlsWithVideoModel:(PLVVodMediaVideo *)videoModel
                             label:(UILabel *)label
                          topLabel:(UILabel *)topLabel
                            label2:(UILabel *)label2
                         topLabel2:(UILabel *)topLabel2;

/// 根据字幕选项 - 更新字幕
- (void)updateSubtitleWithName:(NSString *)subtitleName show:(BOOL)show;

/// 字幕显示
- (void)showSubtilesWithPlaytime:(NSTimeInterval )playtime;

@end

NS_ASSUME_NONNULL_END
