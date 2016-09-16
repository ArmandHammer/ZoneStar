//
//  CustomTableViewCell.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.

#import "NewsTableViewCell.h"

@implementation NewsTableViewCell

- (void)setContent:(BLPost *)content;
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:12.f]};
    NSAttributedString *boldSig = [[NSAttributedString alloc] initWithString:content.signature.gtm_stringByUnescapingFromHTML attributes:attributes];
    NSMutableAttributedString *timestamp = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ago by ", content.timestamp]];
    [timestamp appendAttributedString:boldSig];
    self.timestampLabel.attributedText = timestamp;
    self.messageView.userInteractionEnabled = NO;
    
//
// Hack to get around UITextView's link detection bug.
//

    UITextView *theContent = [[UITextView alloc] init];
    [theContent setFont:self.messageView.font];
    [theContent setTextColor:self.messageView.textColor];
    if ([theContent respondsToSelector:@selector(setTintColor:)]) {
        [theContent setTintColor:self.messageView.tintColor];
    }
    [theContent setDataDetectorTypes:UIDataDetectorTypeLink];
    [theContent setText:content.message.gtm_stringByUnescapingFromHTML];
    
    self.messageView.attributedText = theContent.attributedText;
}

@end
