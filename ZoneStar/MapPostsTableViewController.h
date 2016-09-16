//
//  MapPostsTableViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-10-11.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.

@class BLPost;
@class MapTabViewController;
#import <UIKit/UIKit.h>
#import "MapViewController.h"
#import "CreateReplyViewController.h"
#import "NavigationSearchBar.h"
#import "singletonData.h"
#import "GTMNSString+HTML.h"
#import "NewsTableViewCell.h"
#import "NavigationSearchBar.h"
#import "BottomTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "NSValue+MKCoordinateRegion.h"
#import "NSData+NSValue.h"
#import "UIColor+App.h"

@class MapPostsTableViewController;

@protocol MapPostsTableViewControllerDelegate <NSObject>

@optional
- (void)mapPostsTableViewControllerDidLoad:(MapPostsTableViewController *)controller;
@end

@interface MapPostsTableViewController : UITableViewController<MapViewControllerDelegate, UISearchBarDelegate,BellohDelegate,UITextViewDelegate, UIGestureRecognizerDelegate, CreateReplyViewControllerDelegate, MKMapViewDelegate, UIAlertViewDelegate, UISearchDisplayDelegate>
{
    UIBarButtonItem *backToMap;
}
@property (weak, nonatomic) id<MapPostsTableViewControllerDelegate> delegate;
@property (nonatomic) MKCoordinateRegion region;
- (IBAction)upstarButtonClicked:(UIButton *)sender;
//-(void)backToMapClicked;
@end
