//
//  MapTabViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-10-11.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "BookmarksViewController.h"
#import "NavigationSearchBar.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "NSData+NSValue.h"
#import "NSValue+MKCoordinateRegion.h"
#import "UIView+Keyboard.h"
#import "MapPostsTableViewController.h"

@interface MapTabViewController : UIViewController<CLLocationManagerDelegate,UISearchDisplayDelegate,UISearchBarDelegate,BookmarksViewControllerDelegate,UITableViewDelegate,UITableViewDataSource,MapPostsTableViewControllerDelegate>
{
    UIBarButtonItem *zoneIn;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

-(void)zoneInClicked;
- (IBAction)findMe:(id)sender;
- (IBAction)addBookmark:(id)sender;

@end
