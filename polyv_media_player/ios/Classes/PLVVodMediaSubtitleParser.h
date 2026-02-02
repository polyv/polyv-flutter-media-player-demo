//
//  PLVVodMediaSubtitleParser.h
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/12/23.
//

#import <Foundation/Foundation.h>
#import "PLVVodMediaSubtitleItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVVodMediaSubtitleParser : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<PLVVodMediaSubtitleItem *> *subtitleItems;

+ (instancetype)parserWithSubtitle:(NSString *)content error:(NSError **)error;
- (NSDictionary *)subtitleItemAtTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
