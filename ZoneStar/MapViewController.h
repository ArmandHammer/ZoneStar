//
//  FlipsideViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

@class MapViewController;

@protocol MapViewControllerDelegate <NSObject>

@optional
- (void)mapViewControllerDidLoad:(MapViewController *)controller;
- (void)mapViewControllerDidFinish:(MapViewController *)controller;

@end

@interface MapViewController : UIViewController<CLLocationManagerDelegate>

@property (weak, nonatomic) id<MapViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) MKUserLocation *currentLocation;
@property (nonatomic) MKCoordinateRegion mapRegion;

-(IBAction)done:(id)sender;

@end
