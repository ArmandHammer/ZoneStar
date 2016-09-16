//
//  NSValue+MKCoordinateRegion.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "NSValue+MKCoordinateRegion.h"

@implementation NSValue (MKCoordinateRegion)

+ (instancetype)valueWithMKCoordinateRegion:(MKCoordinateRegion)region
{
    return [self valueWithBytes:&region objCType:@encode(MKCoordinateRegion)];
}

- (MKCoordinateRegion)MKCoordinateRegionValue
{
    MKCoordinateRegion region;
    [self getValue:&region];
    return region;
}

@end
