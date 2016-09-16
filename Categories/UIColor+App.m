//
//  UIColor+App.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "UIColor+App.h"

@implementation UIColor (App)

+ (UIColor *)mainColor
{
    static UIColor *color;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithRed:0/255.0 green:35.0/255.0 blue:153.0/255.0 alpha:1.0];
    });
    return color;
}

@end