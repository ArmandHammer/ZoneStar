//
//  singletonData.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-29.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSKeyChain.h"

@interface singletonData : NSObject

@property (nonatomic, assign) float sliderValue;
@property (nonatomic, assign) int zoneRange;
@property CLLocationCoordinate2D myCoordinates;

+(singletonData *)sharedID; //class method returns singleton object
@property (nonatomic, copy) NSString *postToFlag;
@property (nonatomic, assign) int postIndex;
@end