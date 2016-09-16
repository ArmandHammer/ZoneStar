//
//  Post.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "BLPost.h"
#import "NSObject+Classes.h"

@interface NSString (Extras)

+ (NSString *)stringWithIntervalInSeconds:(unsigned int)intervalInSeconds;

@end

@implementation NSString (Extras)

+ (NSString *)stringWithIntervalInSeconds:(unsigned int)intervalInSeconds
{
    if (intervalInSeconds >= 60) {
        unsigned int minutes = round(intervalInSeconds/60);
        if (minutes >= 60) {
            unsigned int hours = round(minutes/60);
            if (hours >= 24) {
                unsigned int days = round(hours/24);
                if (days >= 365) {
                    unsigned int years = round(days/365);
                    return [NSString stringWithFormat:@"%dy", years];
                }
                else if (days >= 7) {
                    unsigned int weeks = round(days/7);
                    return [NSString stringWithFormat:@"%dw", weeks];
                }
                return [NSString stringWithFormat:@"%dd", days];
            }
            return [NSString stringWithFormat:@"%dh", hours];
        }
        return [NSString stringWithFormat:@"%dm", minutes];
    }
    return [NSString stringWithFormat:@"%ds", intervalInSeconds];
}

@end

@implementation BLPost

- (id)initWithDictionary:(NSDictionary *)postDictionary
{
    if ((self = [super init])) {
        self.message = [NSString sanitize:postDictionary[BLMessageKeyName]];
        self.latitude = [[NSNumber sanitize:postDictionary[BLLatitudeKeyName]] floatValue];
        self.longitude = [[NSNumber sanitize:postDictionary[BLLongitudeKeyName]] floatValue];
        self.identifier = [NSString sanitize:postDictionary[BLIdentifierKeyName]];
        
        if ([[NSNumber sanitize:postDictionary[@"hasImage"]] boolValue]) {
            self.imageURLString = [NSString stringWithFormat:@"http://s3.amazonaws.com/ZoneStar/images/%@.%@", self.identifier, @"jpg"];
        }
        
        self.signature = [NSString sanitize:postDictionary[BLSignatureKeyName]];
        self.reply_to_identifier = [NSString sanitize:postDictionary[BLReplyToKeyName]];
        self.totalReplies = [[NSNumber sanitize:postDictionary[BLReplies]] unsignedIntegerValue];
        self.totalStars = [[NSNumber sanitize:postDictionary[BLStarsKeyName]] unsignedIntegerValue];
        [self setTimestampWithBSONId:self.identifier];
    }
    return self;
}

- (void)setTimestampWithBSONId:(NSString *)BSONId
{
    NSString *BSONTimestamp = [BSONId substringToIndex:8];
    unsigned int BSONDateInSeconds = 0;
    NSScanner *scanner = [NSScanner scannerWithString:BSONTimestamp];
    
    [scanner scanHexInt:&BSONDateInSeconds];
    
    unsigned int currentDateInSeconds = [[NSDate date] timeIntervalSince1970];
    unsigned int intervalInSeconds = currentDateInSeconds-BSONDateInSeconds;
    self.timestamp = [NSString stringWithIntervalInSeconds:intervalInSeconds];
}

- (BOOL)isReply
{
    return self.reply_to_identifier != nil;
}

@end
