//
//  CreateReplyViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "PlaceholderTextView.h"
#import "singletonData.h"
#import "BottomTableViewCell.h"
#import "MapViewController.h"
#import "ReplyHeaderImageView.h"
#import "GTMNSString+HTML.h"

@class BLPost, CreateReplyViewController;

@protocol CreateReplyViewControllerDelegate <NSObject>

@optional
- (void)createReplyViewControllerDidCancel;
- (void)createReplyViewControllerDidPost:(BLPost *)post withImageData:(NSData *)imageData;
- (void)createReplyViewControllerDidLoad:(CreateReplyViewController *)controller;

@end

@interface CreateReplyViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate, MKMapViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate, BellohDelegate, CLLocationManagerDelegate,MapViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) BLPost *post;

@property (nonatomic, weak) id<CreateReplyViewControllerDelegate> delegate;
- (IBAction)cancel:(id)sender;

@property CLLocationCoordinate2D myLocation;
@property (nonatomic, weak) IBOutlet ReplyHeaderImageView *replyHeaderImageView;
@property (nonatomic, weak) IBOutlet UIView *frameView;
@property (nonatomic, weak) IBOutlet UIImageView *cameraImage;
- (IBAction)takePhoto:(UIBarButtonItem*)sender;

//header - reply functions
@property (nonatomic, weak) IBOutlet PlaceholderTextView *replyTextView;
@property (nonatomic, weak) IBOutlet UIButton *postButton;
@property (nonatomic, weak) IBOutlet UITextField *signatureField;
- (IBAction)post:(id)sender;
-(void)setHeaderFrame;

//tableview functions
- (IBAction)upstarButtonClicked:(UIButton*)sender;

@end
