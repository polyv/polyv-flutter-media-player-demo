//
//  PLVVodMediaSubtitleViewModel.m
//  PolyvIOSMediaPlayerDemo
//
//  Created by polyv on 2024/12/23.
//

#import "PLVVodMediaSubtitleViewModel.h"

static const double PLVVodMediaSubtitleAnimationDuration = 0.15;

@interface PLVVodMediaSubtitleItemStyle ()

@end

@implementation PLVVodMediaSubtitleItemStyle

+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor {
    PLVVodMediaSubtitleItemStyle *style = [[PLVVodMediaSubtitleItemStyle alloc] init];
    style.textColor = textColor;
    style.bold = bold;
    style.italic = italic;
    style.backgroundColor = backgroundColor;
    return style;
}

@end

@interface PLVVodMediaSubtitleViewModel ()

@end

@implementation PLVVodMediaSubtitleViewModel

#pragma mark - dealloc & init


#pragma mark - property

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    [self performSelectorOnMainThread:@selector(hideSubtitleWithAnimation) withObject:nil waitUntilDone:YES];
}

- (void)setSubtitleItem:(PLVVodMediaSubtitleItem *)subtitleItem {
    BOOL same = subtitleItem == _subtitleItem;
    if (same) {
        return;
    }
    _subtitleItem = subtitleItem;

    [self subtitleItemDidChange:subtitleItem];
}

- (void)setSubtitleAtTopItem:(PLVVodMediaSubtitleItem *)subtitleAtTopItem {
    BOOL same = subtitleAtTopItem == _subtitleAtTopItem;
    if (same) {
        return;
    }
    _subtitleAtTopItem = subtitleAtTopItem;
    
    [self subtitleItemAtTopDidChange:subtitleAtTopItem];
}

- (void)setSubtitleItem2:(PLVVodMediaSubtitleItem *)subtitleItem2 {
    BOOL same = subtitleItem2 == _subtitleItem2;
    if (same) {
        return;
    }
    _subtitleItem2 = subtitleItem2;

    [self subtitleItem2DidChange:subtitleItem2];
}

- (void)setSubtitleAtTopItem2:(PLVVodMediaSubtitleItem *)subtitleAtTopItem2 {
    BOOL same = subtitleAtTopItem2 == _subtitleAtTopItem2;
    if (same) {
        return;
    }
    _subtitleAtTopItem2 = subtitleAtTopItem2;
    
    [self subtitleItem2AtTopDidChange:subtitleAtTopItem2];
}

- (void)setSubtitleLabel:(UILabel *)subtitleLabel {
    [self setSubtitleLabel:subtitleLabel style:nil];
}

- (void)setSubtitleLabel:(UILabel *)subtitleLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    _subtitleLabel = subtitleLabel;
    _subtitleItemStyle = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleLabel:subtitleLabel style:style];
    });
}

- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel {
    [self setSubtitleTopLabel:subtitleTopLabel style:nil];
}

- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    _subtitleTopLabel = subtitleTopLabel;
    _subtitleAtTopItemStyle = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleTopLabel:subtitleTopLabel style:style];
    });
}

- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 {
    [self setSubtitleLabel2:subtitleLabel2 style:nil];
}

- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 style:(PLVVodMediaSubtitleItemStyle *)style {
    _subtitleLabel2 = subtitleLabel2;
    _subtitleItemStyle2 = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleLabel2:subtitleLabel2 style:style];
    });
}

- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 {
    [self setSubtitleTopLabel2:subtitleTopLabel2 style:nil];
}

- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 style:(PLVVodMediaSubtitleItemStyle *)style {
    _subtitleTopLabel2 = subtitleTopLabel2;
    _subtitleAtTopItemStyle2 = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleTopLabel2:subtitleTopLabel2 style:style];
    });
}

#pragma mark - private

- (void)hideSubtitleWithAnimation {
    [UIView animateWithDuration:PLVVodMediaSubtitleAnimationDuration animations:^{
        self.subtitleLabel.alpha = self.enable ? 1.0 : 0;
        self.subtitleTopLabel.alpha = self.enable ? 1.0 : 0;
    }];
}

- (void)setupSubtitleLabel:(UILabel *)subtitleLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    subtitleLabel.text = @"";
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.contentMode = UIViewContentModeBottom;
    subtitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
    subtitleLabel.shadowOffset = CGSizeMake(1, 1);
    // 强制使用透明背景，与 Android 保持一致
    subtitleLabel.backgroundColor = [UIColor clearColor];
}

- (void)setupSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    subtitleTopLabel.text = @"";
    subtitleTopLabel.numberOfLines = 0;
    subtitleTopLabel.contentMode = UIViewContentModeBottom;
    subtitleTopLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleTopLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
    subtitleTopLabel.shadowOffset = CGSizeMake(1, 1);
    // 强制使用透明背景，与 Android 保持一致
    subtitleTopLabel.backgroundColor = [UIColor clearColor];
}

- (void)setupSubtitleLabel2:(UILabel *)subtitleLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    subtitleLabel.text = @"";
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.contentMode = UIViewContentModeBottom;
    subtitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
    subtitleLabel.shadowOffset = CGSizeMake(1, 1);
    // 强制使用透明背景，与 Android 保持一致
    subtitleLabel.backgroundColor = [UIColor clearColor];
}

- (void)setupSubtitleTopLabel2:(UILabel *)subtitleTopLabel style:(PLVVodMediaSubtitleItemStyle *)style {
    subtitleTopLabel.text = @"";
    subtitleTopLabel.numberOfLines = 0;
    subtitleTopLabel.contentMode = UIViewContentModeBottom;
    subtitleTopLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleTopLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
    subtitleTopLabel.shadowOffset = CGSizeMake(1, 1);
    // 强制使用透明背景，与 Android 保持一致
    subtitleTopLabel.backgroundColor = [UIColor clearColor];
}

- (void)subtitleItemDidChange:(PLVVodMediaSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleLabel duration:PLVVodMediaSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleLabel.attributedText = [self subtitleItem:subtitleItem style:self.subtitleItemStyle];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItemAtTopDidChange:(PLVVodMediaSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleTopLabel duration:PLVVodMediaSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleTopLabel.attributedText = [self subtitleItem:subtitleItem style:self.subtitleAtTopItemStyle];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItem2DidChange:(PLVVodMediaSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleLabel2 duration:PLVVodMediaSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleLabel2.attributedText = [self subtitleItem:subtitleItem style:self.subtitleItemStyle2];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItem2AtTopDidChange:(PLVVodMediaSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleTopLabel2 duration:PLVVodMediaSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleTopLabel2.attributedText = [self subtitleItem:subtitleItem style:self.subtitleAtTopItemStyle2];
    } completion:^(BOOL finished) {
        
    }];
}

- (NSAttributedString *)subtitleItem:(PLVVodMediaSubtitleItem *)subtitleItem style:(PLVVodMediaSubtitleItemStyle *)style {
    if (!subtitleItem.attributedText) {
        return nil;
    }
    
    if (!style || ![style isKindOfClass:[PLVVodMediaSubtitleItemStyle class]]) {
        return subtitleItem.attributedText;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:subtitleItem.attributedText];
    
    // 调整颜色
    if (style.textColor) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:style.textColor range:NSMakeRange(0, attributedString.length)];
    }
    
    // 调整字体大小（与 Android 保持一致，使用 14pt）
    CGFloat fontSize = 14.0;
    if (style.bold) {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-SemiBold" size:fontSize] range:NSMakeRange(0, attributedString.length)];
    } else {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Regular" size:fontSize] range:NSMakeRange(0, attributedString.length)];
    }
    
    // 调整字体倾斜
    if (style.italic) {
        [attributedString addAttribute:NSObliquenessAttributeName value:@(15 * M_PI / 180) range:NSMakeRange(0, attributedString.length)];
    }
    
    return [attributedString copy];
}

@end
