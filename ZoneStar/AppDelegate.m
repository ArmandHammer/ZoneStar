//
//  AppDelegate.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "AppDelegate.h"
#import "NewsViewController.h"
#import "GSKeyChain.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window.tintColor = [UIColor colorWithRed:229.0/255.0 green:162.0/255.0 blue:38.0/255.0 alpha:1.0];

    NSDictionary *settings = @{NSFontAttributeName: [UIFont fontWithName:@"Thonburi" size:14.0]};
    
    //[[UINavigationBar appearance] setTitleTextAttributes:settings];
    [[UIBarButtonItem appearance] setTitleTextAttributes:settings forState:UIControlStateNormal];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor whiteColor], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"Thonburi" size:14.0], NSFontAttributeName, nil]];
    //store singleton data value for zone radius
    singletonData *sData = [singletonData sharedID];
    sData.zoneRange = 100;
    sData.sliderValue = 1.0;
    
    //get unique ID and store in keychain
    NSString *secret = [[GSKeychain systemKeychain] secretForKey:@"userUniqueID"];
    if (!secret){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        //create and save objects
        [[GSKeychain systemKeychain] setSecret:uuid forKey:@"userUniqueID"];
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        NSMutableArray *upvotedPosts = [[NSMutableArray alloc] init];
        NSMutableArray *flaggedPosts = [[NSMutableArray alloc] init];
        //NSMutableArray *replyPosts = [[NSMutableArray alloc] init];

        //save the different types of posts in user defaults
        [defaults setObject:upvotedPosts forKey:@"upvotedPosts"];
        [defaults setObject:flaggedPosts forKey:@"flaggedPosts"];
        [defaults setObject:posts forKey:@"posts"];
        //[defaults setObject:replyPosts forKey:@"replies"];
        [defaults synchronize];
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
