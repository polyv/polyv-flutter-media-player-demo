//
//  PLVVodMediaCommonUtil.m
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/8/27.
//

#import "PLVVodMediaCommonUtil.h"

@implementation PLVVodMediaCommonUtil

/// 判断是否为空字符串
+ (BOOL)isNilString:(NSString *)origStr{
    if (!origStr || [origStr isKindOfClass:[NSNull class]] || !origStr.length){
        return YES;
    }
    
    return NO;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    return [self colorFromHexString:hexString alpha:1.0];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString alpha:(float)alpha {
    if (!hexString || hexString.length < 6) {
        return [UIColor whiteColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1]; // bypass '#' character
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

+ (NSString *)formatFilesize:(NSInteger)filesize {
    return [NSByteCountFormatter stringFromByteCount:filesize countStyle:NSByteCountFormatterCountStyleBinary];
}

+ (NSString *)timeFormatStringWithTime:(NSTimeInterval )time{
    
    NSInteger hour = time/60/60;
    NSInteger minite = (time - hour*60*60)/60;
    NSInteger second = (time - hour*60*60 - minite*60);
    
    NSString *timeStr =[NSString stringWithFormat:@"%02d:%02d:%02d", (int)hour, (int)minite,(int)second];
    
    return timeStr;
}


@end
