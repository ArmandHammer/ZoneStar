//
//  NSObject+Classes.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Classes)

+ (instancetype)sanitize:(id)object withDefault:(id)aDefault;
+ (instancetype)sanitize:(id)object;

- (BOOL)isKindOfSomeClass:(Class)aClass, ... NS_REQUIRES_NIL_TERMINATION;

@end
