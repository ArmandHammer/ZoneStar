//
//  NSData+NSValue.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "NSData+NSValue.h"

@implementation NSData (NSValue)

+ (instancetype)dataWithValue:(NSValue *)value
{
    NSUInteger size;
    const char *encoding = [value objCType];
    NSGetSizeAndAlignment(encoding, &size, NULL);
    
    void *ptr = malloc(size);
    [value getValue:ptr];
    id data = [self dataWithBytes:ptr length:size];
    free(ptr);
    
    return data;
}

- (NSValue *)valueWithObjCType:(const char *)type
{
    NSUInteger size;
    NSGetSizeAndAlignment(type, &size, NULL);
    
    void *ptr = malloc(size);
    [self getBytes:ptr length:size];
    NSValue *value = [NSValue valueWithBytes:ptr objCType:type];
    free(ptr);
    
    return value;
}

@end
