//
//  Belloh.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "Belloh.h"
#import "AFHTTPRequestOperationManager.h"
#import "NSObject+Classes.h"

enum {
    // TODO: possible bug with BLNoPostsRemaining etc.. not loading older posts correctly.
    BLNoPostsRemaining = 1,
    BLNoFilteredResultsRemaining = 2
};

@implementation Belloh {

@private
    NSMutableArray *_posts;
    NSMutableArray *_filteredResults;
    int _remainingPosts;
    NSString *_loadUUID;
}

static NSString *apiBaseURLString = @"http://api.zonestarapp.com";

- (id)init
{
    if (self = [super init]) {
        self->_posts = [NSMutableArray array];
    }
    return self;
}

- (id)initWithRegion:(MKCoordinateRegion)region
{
    if (self = [self init]) {
        self.region = region;
    }
    return self;
}

- (void)setFilter:(NSString *)filter
{
    if ([filter length] && ![self.filter isEqualToString:filter]) {
        self->_filteredResults = [NSMutableArray array];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(message CONTAINS[cd] %@) OR (signature CONTAINS[cd] %@)", filter, filter];
            NSArray *results = [self->_posts filteredArrayUsingPredicate:predicate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                BLLOG(@"results: %@", results);
                if ([results count]) {
                    self->_remainingPosts &= ~BLNoFilteredResultsRemaining;
                    self->_filteredResults = [results mutableCopy];
                    if ([self.delegate respondsToSelector:@selector(loadingPostsSucceeded)]) {
                        [self.delegate loadingPostsSucceeded];
                    }
                }
                else {
                    [self _BL_loadPostsForQuery:nil];
                }
            });
        });
    }
    else if ([filter length] == 0) {
        [self->_filteredResults removeAllObjects];
    }
    self->_filter = filter;
}

#pragma mark - Belloh Posts

- (NSMutableArray *)_BL_posts
{
    return [self.filter length] == 0 ? self->_posts : self->_filteredResults;
}

- (BLPost *)postAtIndex:(NSUInteger)index
{
    return self._BL_posts[index];
}

- (BLPost *)lastPost
{
    return [self._BL_posts lastObject];
}

- (void)_BL_appendPost:(BLPost *)post
{
    [self._BL_posts addObject:post];
}

- (void)_BL_insertPost:(BLPost *)post atIndex:(NSUInteger)index
{
    //save user post
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];
    [userPosts addObject:post.identifier];
    [defaults setObject:userPosts forKey:@"posts"];
    [defaults synchronize];
    [self._BL_posts insertObject:post atIndex:index];
}

- (void)removeAllPosts
{
    [self._BL_posts removeAllObjects];
}

- (NSUInteger)postCount
{
    return [self._BL_posts count];
}

- (void)removePostAtIndex:(NSUInteger)index
{
    [self._BL_posts removeObjectAtIndex:index];
}

- (void)insertPost:(BLPost *)post atIndex:(NSUInteger)index
{
    [self._BL_posts insertObject:post atIndex:index];
}

#pragma mark - Belloh Posts Queries

+ (NSString *)_BL_queryForRegion:(MKCoordinateRegion)region
{
    CGFloat lat = region.center.latitude;
    CGFloat lon = region.center.longitude;
    CGFloat deltaLat = region.span.latitudeDelta/2;
    CGFloat deltaLon = region.span.longitudeDelta/2;
    static NSString *format = @"box%%5B0%%5D%%5B%%5D=%f&box%%5B0%%5D%%5B%%5D=%f&box%%5B1%%5D%%5B%%5D=%f&box%%5B1%%5D%%5B%%5D=%f";
    return [NSString stringWithFormat:format,lat-deltaLat,lon-deltaLon,lat+deltaLat,lon+deltaLon];
}

- (BOOL)isRemainingPosts
{
    BLLOG(@"%i, %i",self->_remainingPosts,self->_remainingPosts&BLNoPostsRemaining);
    
    if (self->_remainingPosts&BLNoPostsRemaining) {
        return NO;
    }
    else if (self.filter && self->_remainingPosts&BLNoFilteredResultsRemaining) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Belloh Posts Loading

- (void)loadAndAppendOlderPosts
{
    if (![self isRemainingPosts]) {
        return;
    }
    
    BLPost *lastPost = [self lastPost];
    if (lastPost == nil) {
        return;
    }
    
    BLLOG(@"loading more posts...");
    NSString *lastPostId = lastPost.identifier;
    NSString *query = [NSString stringWithFormat:@"elder_id=%@", lastPostId];
    [self _BL_loadPostsForQuery:query];
}

- (void)loadPosts
{
    NSString *postFilter = self.filter;
    self.filter = nil;
    // First load posts then load filtered results.
    
    [self _BL_loadPostsForQuery:nil completion:^(NSArray *posts){
        [self->_posts removeAllObjects];
        for (NSDictionary *dict in posts) {
            [self _BL_insertPostWithDictionary:dict atIndex:-1];
        }
        self.filter = postFilter;
    }];
}

- (void)_BL_loadPostsForQuery:(NSString *)query
{
    [self _BL_loadPostsForQuery:query completion:^(NSArray *posts){
        for (NSDictionary *dict in posts) {
            [self _BL_insertPostWithDictionary:dict atIndex:-1];
        }
    }];
}

- (void)_BL_loadPostsForQuery:(NSString *)query completion:(void (^)(NSArray *))completion
{
    // Used to make sure only latest query is used.
    NSString *UUID = [[NSUUID UUID] UUIDString];
    self->_loadUUID = UUID;
    
    if (query == nil) {
        query = @"";
    }
    
    NSString *queryURLString = [@"posts?" stringByAppendingString:query];
    
    if (self.reply_to) {
        queryURLString = [NSString stringWithFormat:@"%@&reply_to=%@", queryURLString, self.reply_to];
    }
    else {
        queryURLString = [NSString stringWithFormat:@"%@&%@", queryURLString, [Belloh _BL_queryForRegion:self.region]];
    }
    
    if (self.filter) {
        queryURLString = [NSString stringWithFormat:@"%@&filter=%@", queryURLString, self.filter];
    }
    
    if (self.customTag) {
        queryURLString = [NSString stringWithFormat:@"%@&tag=%@", queryURLString, self.customTag];
    }
    
    if (self.top) {
        queryURLString = [NSString stringWithFormat:@"%@&top=true", queryURLString];
    }
    
    NSURL *postsURL = [NSURL URLWithString:queryURLString relativeToURL:[NSURL URLWithString:apiBaseURLString]];
    BLLOG(@"%@", postsURL.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postsURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod:@"GET"];
    
    int num = (self.filter == nil ? BLNoPostsRemaining : BLNoFilteredResultsRemaining);
    self->_remainingPosts &= ~num;
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError){
        
        if (![UUID isEqualToString:self->_loadUUID]) {
            return;
        }
        
        if (data == nil) {
            if ([self.delegate respondsToSelector:@selector(loadingPostsFailedWithError:)]) {
                [self.delegate loadingPostsFailedWithError:connectionError];
            }
            return;
        }
        
        NSError *error;
        NSArray *postsArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
//        if (error) {
//            if ([self.delegate respondsToSelector:@selector(loadingPostsFailedWithError:)]) {
//                [self.delegate loadingPostsFailedWithError:error];
//            }
//            return;
//        }
        
        if ([postsArray count] == 0) {
            self->_remainingPosts |= num;
        }
        
        if (completion) {
            completion(postsArray);
        }
        
        if ([self.delegate respondsToSelector:@selector(loadingPostsSucceeded)]) {
            [self.delegate loadingPostsSucceeded];
        }
    }];
}

- (void)_BL_insertPostWithDictionary:(NSDictionary *)postDictionary atIndex:(NSInteger)signedIndex
{
    BLPost *post = [[BLPost alloc] initWithDictionary:postDictionary];
    
    //static NSString *thumbnailURLFormat = @"http://s3.amazonaws.com/belloh/thumbs/%@.jpg";
    //post.thumbnail = [NSString stringWithFormat:thumbnailURLFormat, post.identifier];
    
    if (signedIndex == -1) {
        [self _BL_appendPost:post];
    }
    else if (signedIndex < -1) {
        NSUInteger i = [self postCount] + signedIndex;
        [self _BL_insertPost:post atIndex:i];
    }
    else {
        [self _BL_insertPost:post atIndex:signedIndex];
    }
}

#pragma mark - Belloh New Post

- (void)sendNewPost:(BLPost *)newPost completion:(void (^)(NSError *))completion
{
    NSURL *newPostURL = [NSURL URLWithString:apiBaseURLString];
    NSMutableURLRequest *newPostRequest = [NSMutableURLRequest requestWithURL:newPostURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    newPostRequest.HTTPMethod = @"POST";
    [newPostRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithDictionary:@{BLMessageKeyName: newPost.message, BLSignatureKeyName: newPost.signature, BLLatitudeKeyName: @(newPost.latitude), BLLongitudeKeyName: @(newPost.longitude)}];
    
    if ([newPost isReply]) {
        postDictionary[BLReplyToKeyName] = newPost.reply_to_identifier;
    }
    
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDictionary options:0 error:&error];
    
    if (error && completion) {
        return completion(error);
    }
    
    newPostRequest.HTTPBody = postData;
    [NSURLConnection sendAsynchronousRequest:newPostRequest queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         
         if (connectionError && completion) {
             return completion(connectionError);
         }
         
         NSError *parseError;
         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
         NSString *serverErrors = [dict valueForKey:@"errors"];
         
         if (completion) {
             if (serverErrors) {
                 return completion([NSError errorWithDomain:serverErrors code:0 userInfo:nil]);
             }
             else if (parseError) {
                 return completion(parseError);
             }
         }
         
         [self _BL_insertPostWithDictionary:dict atIndex:0];
         
         if (completion) {
             completion(nil);
         }
     }];
}

- (void)sendNewPost:(BLPost *)newPost imageData:(NSData *)imageData completion:(void (^)(NSError *))completion
{
    if (imageData == nil) {
        return [self sendNewPost:newPost completion:completion];
    }
    
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionaryWithDictionary:@{BLMessageKeyName: newPost.message, BLSignatureKeyName: newPost.signature, BLLatitudeKeyName: @(newPost.latitude), BLLongitudeKeyName: @(newPost.longitude)}];
    
    if ([newPost isReply]) {
        postDictionary[BLReplyToKeyName] = newPost.reply_to_identifier;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //[manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    manager.requestSerializer.timeoutInterval = 20;
    
    [manager POST:apiBaseURLString parameters:postDictionary constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion) {
            completion(nil);
        }
        [self _BL_insertPostWithDictionary:responseObject atIndex:0];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - Get Post

- (void)getPostWithIdentifier:(NSString *)identifier completion:(void (^)(NSError *, BLPost *))completion
{
    NSURL *baseURL = [NSURL URLWithString:apiBaseURLString];
    NSString *postURLString = [NSString stringWithFormat:@"post/%@", identifier];
    NSURL *postURL = [NSURL URLWithString:postURLString relativeToURL:baseURL];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:postURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    postRequest.HTTPMethod = @"GET";
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    [NSURLConnection sendAsynchronousRequest:postRequest queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         
         if (connectionError && completion) {
             return completion(connectionError, nil);
         }
         
         NSError *parseError;
         NSDictionary *postDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
         NSString *serverErrors = [postDictionary valueForKey:@"errors"];
         
         if (completion) {
             if (serverErrors) {
                 return completion([NSError errorWithDomain:serverErrors code:0 userInfo:nil], nil);
             }
             else if (parseError) {
                 return completion(parseError, nil);
             }
             else {
                 BLPost *post = [[BLPost alloc] initWithDictionary:postDictionary];
                 completion(nil, post);
                 if ([self.delegate respondsToSelector:@selector(loadingPostsSucceeded)]) {
                     [self.delegate loadingPostsSucceeded];
                 }
             }
             
         }
     }];
}

@end
