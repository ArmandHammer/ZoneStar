//
//  Post.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

static NSString *const BLMessageKeyName = @"message";
static NSString *const BLLatitudeKeyName = @"lat";
static NSString *const BLLongitudeKeyName = @"lng";
static NSString *const BLIdentifierKeyName = @"_id";
static NSString *const BLThumbnailKeyName = @"thumb";
static NSString *const BLStarsKeyName = @"stars";
static NSString *const BLFlagsKeyName = @"flags";
static NSString *const BLReplyID = @"replyID";
static NSString *const BLReplies = @"replies";
static NSString *const BLReplyToKeyName = @"_reply_to";
static NSString *const BLSignatureKeyName = @"signature";

@interface BLPost : NSObject

@property (nonatomic, copy) NSString *imageURLString;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *signature;
//@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, copy) NSString *timestamp;
@property (nonatomic, assign) float latitude;
@property (nonatomic, assign) float longitude;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NSUInteger totalStars;
@property (nonatomic, assign) NSUInteger totalReplies;
@property (nonatomic, copy) NSString *reply_to_identifier;
- (BOOL)isReply;

- (id)initWithDictionary:(NSDictionary *)postDictionary;
- (void)setTimestampWithBSONId:(NSString *)BSONId;

@end