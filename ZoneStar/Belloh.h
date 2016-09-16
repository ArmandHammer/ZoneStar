//
//  Belloh.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "BLPost.h"
#import <MapKit/MKGeometry.h>

// NSLog extension which prints the name of the calling class and method
#define BLLOG(format,...) NSLog([NSString stringWithFormat:@"%%@->%%@ %@",format],NSStringFromClass([self class]),NSStringFromSelector(_cmd),##__VA_ARGS__)

@protocol BellohDelegate <NSObject>

@optional
- (void)loadingPostsSucceeded;
- (void)loadingPostsFailedWithError:(NSError *)error;

@end

@interface Belloh : NSObject {
    NSMutableArray *userUpvotedPosts;
}

@property (nonatomic, assign) MKCoordinateRegion region;
@property (nonatomic, copy) NSString *filter;
@property (nonatomic, copy) NSString *customTag;
@property (nonatomic, weak) id<BellohDelegate> delegate;
@property (nonatomic, copy) NSString *reply_to;
@property (nonatomic, assign) BOOL top;

- (id)initWithRegion:(MKCoordinateRegion)region;
- (NSUInteger)postCount;
- (void)removePostAtIndex:(NSUInteger)index;
- (void)insertPost:(BLPost *)post atIndex:(NSUInteger)index;
- (BLPost *)postAtIndex:(NSUInteger)index;
- (BLPost *)lastPost;
- (void)loadAndAppendOlderPosts;
- (void)loadPosts;
- (void)sendNewPost:(BLPost *)newPost completion:(void (^)(NSError *))completion;
- (void)sendNewPost:(BLPost *)newPost imageData:(NSData *)imageData completion:(void (^)(NSError *))completion;
- (void)getPostWithIdentifier:(NSString *)identifier completion:(void (^)(NSError *, BLPost *))completion;
- (void)removeAllPosts;
- (BOOL)isRemainingPosts;

@end
