//
//  singletonData.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-29.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "singletonData.h"

@implementation singletonData
static singletonData *sharedID = nil; //static instance variable

+(singletonData *)sharedID
{
    if(sharedID == nil)
    {
        sharedID = [[super allocWithZone:NULL] init];
    }
    return sharedID;
}

+(id)allocWithZone:(NSZone *)zone //ensure singleton status
{
    return [self sharedID];
}

-(id)copyWithZone:(NSZone *)zone //ensure singleton status
{
    return self;
}

@end
