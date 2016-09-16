//
//  PlaceholderTextView.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "PlaceholderTextView.h"

@interface PlaceholderTextView ()

@property (nonatomic) UILabel *placeholderLabel;

@end

@implementation PlaceholderTextView

@synthesize placeholderColor = _placeholderColor;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textChanged:(NSNotification *)notification
{
    [UIView animateWithDuration:0.1 animations:^{
        if([self.text length] == 0) {
            self.placeholderLabel.alpha = 1;
        }
        else {
            self.placeholderLabel.alpha = 0;
        }
    }];
}

- (UIColor *)placeholderColor
{
    if (_placeholderColor == nil) {
        _placeholderColor = [UIColor lightGrayColor];
    }
    return _placeholderColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    self.placeholderLabel.textColor = placeholderColor;
    _placeholderColor = placeholderColor;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    
    if([self.placeholder length] > 0 && !self.placeholderLabel) {
        self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,9,0,0)];
        self.placeholderLabel.alpha = [self.text length] == 0 ? 1 : 0;
        self.placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.placeholderLabel.numberOfLines = 0;
        self.placeholderLabel.font = self.font;
        self.placeholderLabel.backgroundColor = [UIColor clearColor];
        self.placeholderLabel.textColor = self.placeholderColor;
        [self addSubview:self.placeholderLabel];
        [self sendSubviewToBack:self.placeholderLabel];
    }
    
    self.placeholderLabel.text = self.placeholder;
    
    CGRect frame = self.placeholderLabel.frame;
    frame.size.width = self.bounds.size.width;
    self.placeholderLabel.frame = frame;
    [self.placeholderLabel sizeToFit];
}

@end

