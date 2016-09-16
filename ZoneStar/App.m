//
//  App.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "App.h"

@implementation App

- (BOOL)openURL:(NSURL *)URL
{
    if ([URL.scheme isEqual:@"http"] || [URL.scheme isEqual:@"https"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openURL" object:nil userInfo:@{@"URL": URL}];
        return NO;
    }
    return YES;
}

@end
