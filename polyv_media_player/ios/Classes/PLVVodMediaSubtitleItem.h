//
//  PLVVodMediaSubtitleItem.h
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/12/23.
//

#import <Foundation/Foundation.h>

typedef struct {
    NSInteger hours;
    NSInteger minutes;
    NSInteger seconds;
    NSInteger milliseconds;
} PLVVodMediaSubtitleTime;

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSMutableAttributedString *HTMLString(NSString *string);
NSTimeInterval PLVVodMediaSubtitleTimeGetSeconds(PLVVodMediaSubtitleTime time);

@interface PLVVodMediaSubtitleItem : NSObject

@property (nonatomic, assign) PLVVodMediaSubtitleTime startTime;
@property (nonatomic, assign) PLVVodMediaSubtitleTime endTime;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSAttributedString *attributedText;

@property (nonatomic, assign) NSString *identifier;

@property (nonatomic, assign) BOOL atTop;

- (instancetype)initWithText:(NSString *)text start:(PLVVodMediaSubtitleTime)startTime end:(PLVVodMediaSubtitleTime)endTime;

@end


NS_ASSUME_NONNULL_END
