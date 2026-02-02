//
//  PLVVodMediaUtil.h
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/8/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVVodMediaCommonUtil : NSObject

+ (BOOL)isNilString:(NSString *)origStr;

+ (UIColor *)colorFromHexString:(NSString *)hexString ;

+ (UIColor *)colorFromHexString:(NSString *)hexString alpha:(float)alpha ;

+ (NSString *)formatFilesize:(NSInteger)filesize;

+ (NSString *)timeFormatStringWithTime:(NSTimeInterval )time;

@end

NS_ASSUME_NONNULL_END
