//
//  PortfolioViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-28.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "MapViewController.h"
#import "CreateReplyViewController.h"
#import "NavigationSearchBar.h"
#import "singletonData.h"
#import "CustomIOS7AlertView.h"
#import "BLPost.h"
#import "GTMNSString+HTML.h"
#import "UIImageView+AFNetworking.h"

@interface PortfolioViewController : UITableViewController<MapViewControllerDelegate, UISearchBarDelegate,BellohDelegate,UITextViewDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate, CreateReplyViewControllerDelegate, UIAlertViewDelegate, CustomIOS7AlertViewDelegate>

@property (nonatomic) IBOutlet UIBarButtonItem *starsBarButton;
@property (nonatomic) IBOutlet UIBarButtonItem *postsBarButton;
-(IBAction)starsButtonClick:(UIBarButtonItem*)sender;
-(IBAction)postsButtonClick:(UIBarButtonItem*)sender;

-(void)setStats;
-(void)loadUserPosts;
-(BLPost*)getContextPost:(NSString*)identifier;
@end