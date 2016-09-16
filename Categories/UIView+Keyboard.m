//
//  UIView+Keyboard.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "UIView+Keyboard.h"

@implementation UIView (Keyboard)

- (IBAction)hideKeyboard:(id)sender
{
    [self endEditing:YES];
}

@end
