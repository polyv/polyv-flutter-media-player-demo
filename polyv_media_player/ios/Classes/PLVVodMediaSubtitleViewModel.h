//
//  PLVVodMediaSubtitleViewModel.h
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/12/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLVVodMediaSubtitleItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVVodMediaSubtitleItemStyle : NSObject

@property (nonatomic, strong) UIColor *textColor; // 字体颜色
@property (nonatomic, assign) BOOL bold; // 字体是否加粗
@property (nonatomic, assign) BOOL italic; // 字体是否
@property (nonatomic, strong) UIColor *backgroundColor; // 背景颜色

+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor;

@end

@interface PLVVodMediaSubtitleViewModel : NSObject

@property (nonatomic, strong) PLVVodMediaSubtitleItem *subtitleItem;
@property (nonatomic, strong) PLVVodMediaSubtitleItem *subtitleAtTopItem;
@property (nonatomic, strong) PLVVodMediaSubtitleItem *subtitleItem2;
@property (nonatomic, strong) PLVVodMediaSubtitleItem *subtitleAtTopItem2;

@property (nonatomic, weak)  UILabel *subtitleLabel;    // 底部字幕 下
@property (nonatomic, weak)  UILabel *subtitleTopLabel;
@property (nonatomic, weak)  UILabel *subtitleLabel2;   // 底部字幕 上
@property (nonatomic, weak)  UILabel *subtitleTopLabel2;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, strong) PLVVodMediaSubtitleItemStyle *subtitleItemStyle;
@property (nonatomic, strong) PLVVodMediaSubtitleItemStyle *subtitleAtTopItemStyle;
@property (nonatomic, strong) PLVVodMediaSubtitleItemStyle *subtitleItemStyle2;
@property (nonatomic, strong) PLVVodMediaSubtitleItemStyle *subtitleAtTopItemStyle2;

- (void)setSubtitleLabel:(UILabel *)subtitleLabel style:(PLVVodMediaSubtitleItemStyle *)style;
- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVVodMediaSubtitleItemStyle *)style;
- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 style:(PLVVodMediaSubtitleItemStyle *)style;
- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 style:(PLVVodMediaSubtitleItemStyle *)style;

@end

NS_ASSUME_NONNULL_END
