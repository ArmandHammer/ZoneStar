//
//  CreateViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "PlaceholderTextView.h"
#import <QuartzCore/QuartzCore.h>

@class BLPost, CreateViewController;

@protocol CreateViewControllerDelegate <NSObject>

@optional
- (void)createViewControllerDidCancel;
- (void)createViewControllerDidPost:(BLPost *)post withImageData:(NSData *)imageData;
- (void)createViewControllerDidLoad:(CreateViewController *)controller;

@end

@interface CreateViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<CreateViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet PlaceholderTextView *messageView;
@property (nonatomic, weak) IBOutlet UIButton *postButton;
@property (nonatomic, weak) IBOutlet MKMapView *miniMap;
@property (nonatomic, weak) IBOutlet UIImageView *cameraImage;
@property (nonatomic, weak) IBOutlet UITextField *signatureField;
@property (nonatomic) MKCoordinateRegion newPostRegion;
@property (nonatomic) CLLocationCoordinate2D myLocation;

- (IBAction)post:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)takePhoto:(UIBarButtonItem*)sender;
@end
