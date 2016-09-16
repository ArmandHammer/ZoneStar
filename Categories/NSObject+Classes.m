//
//  NSObject+Classes.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "NSObject+Classes.h"

@implementation NSObject (Classes)

+ (instancetype)sanitize:(id)object withDefault:(id)aDefault
{
    if (object == nil) {
        return aDefault;
    }
    else if ([object isKindOfClass:self]) {
        return object;
    }
    else if (self == [NSString class]) {
        return [object description];
    }
    else if (self == [NSNumber class]) {
        if ([object isKindOfClass:[NSString class]]) {
            // If it is an NSString, attempt to convert it to an NSNumber.
            static dispatch_once_t onceToken;
            static NSNumberFormatter *f;
            dispatch_once(&onceToken, ^{
                f = [[NSNumberFormatter alloc] init];
                [f setNumberStyle:NSNumberFormatterDecimalStyle];
            });
            return [f numberFromString:object];
        }
    }
    return aDefault;
}

+ (instancetype)sanitize:(id)object
{
    return [self sanitize:object withDefault:nil];
}

- (BOOL)isKindOfSomeClass:(Class)aClass, ...
{
    va_list ap;
    va_start(ap, aClass);
    
    Class class = aClass;
    
    do {
        if ([self isKindOfClass:class]) {
            return YES;
        }
        
        class = va_arg(ap, Class);
        
    } while (class != nil);
    
    va_end(ap);
    return NO;
}

@end
