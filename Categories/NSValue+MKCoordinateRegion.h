//
//  NSValue+MKCoordinateRegion.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValue (MKCoordinateRegion)

+ (instancetype)valueWithMKCoordinateRegion:(MKCoordinateRegion)region;
- (MKCoordinateRegion)MKCoordinateRegionValue;

@end
