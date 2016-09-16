//
//  FlipsideViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "MapViewController.h"
#import "NavigationSearchBar.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "NSData+NSValue.h"
#import "NSValue+MKCoordinateRegion.h"
#import "UIView+Keyboard.h"

@interface MapViewController ()
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSArray *searchResults;
@property (nonatomic) MKLocalSearch *search;
@property (nonatomic) UITableView *resultsTableView;
@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) NSTimer *timer;

@end

@interface UIViewController ()

- (void)setSearchDisplayController:(UISearchController *)searchDisplayController;

@end

@implementation MapViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.geocoder = [[CLGeocoder alloc] init];
    [self.mapView setRegion:self.mapRegion animated:NO];
    [self setNavBarTitleToLocationName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if ([self.delegate respondsToSelector:@selector(mapViewControllerDidLoad:)]) {
        [self.delegate mapViewControllerDidLoad:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapViewControllerDidEnd
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setNavBarTitleToLocationName
{
    CLLocationCoordinate2D center = self.mapRegion.center;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    
    self.navigationItem.title = nil;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateEllipsis:) userInfo:nil repeats:YES];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        [self.timer invalidate];
        
        if (error) {
            self.navigationItem.title = @"Can't Detect Location";
            return BLLOG(@"geocoding: %@", error);
        }
        
        CLPlacemark *placemark = placemarks[0];
        NSString *locationName;
        
        if (placemark.locality) {
            locationName = [NSString stringWithFormat:@"%@, %@, %@", placemark.name, placemark.locality, placemark.country];
        }
        else if (placemark.country) {
            locationName = [NSString stringWithFormat:@"%@, %@", placemark.name, placemark.country];
        }
        else {
            locationName = [NSString stringWithFormat:@"%@", placemark.name];
        }
        
        self.navigationItem.title = locationName;
    }];
}

- (void)updateEllipsis:(NSTimer *)timer
{
    NSString *title = self.navigationItem.title;
    if ([title length] >= 5) {
        self.navigationItem.title = nil;
    }
    else if ([title length] == 0) {
        self.navigationItem.title = @".";
    }
    else {
        self.navigationItem.title = [title stringByAppendingString:@" ."];
    }
}

#pragma mark - IBActions

- (IBAction)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(mapViewControllerDidFinish:)]) {
        [self.delegate mapViewControllerDidFinish:self];
    }
}

@end
