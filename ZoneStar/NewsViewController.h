//
//  NewsViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "MapViewController.h"
#import "CreateViewController.h"
#import "CreateReplyViewController.h"
#import "NavigationSearchBar.h"
#import "singletonData.h"
#import "CustomIOS7AlertView.h"
#import "GTMNSString+HTML.h"
#import "NewsTableViewCell.h"
#import "NavigationSearchBar.h"
#import "BottomTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "NSValue+MKCoordinateRegion.h"
#import "NSData+NSValue.h"
#import "UIColor+App.h"

@interface NewsViewController : UITableViewController<CreateViewControllerDelegate,MapViewControllerDelegate,UISearchBarDelegate,BellohDelegate,UITextViewDelegate,CLLocationManagerDelegate, CustomIOS7AlertViewDelegate, UIGestureRecognizerDelegate, CreateReplyViewControllerDelegate, MKMapViewDelegate, UIAlertViewDelegate>
{
    UIBarButtonItem *zone;
    UIBarButtonItem *compose;
}
-(void)zoneButton;
- (IBAction)upstarButtonClicked:(UIButton *)sender;

@end