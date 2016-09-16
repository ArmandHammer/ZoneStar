//
//  CreateViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.

#import "CreateViewController.h"
#import "UIColor+App.h"
#import "UIView+Keyboard.h"
#include <stdlib.h>

@interface CreateViewController ()
{
    NSArray *funnyErrors;
    NSString *currentAreaName;
    UIImage *cameraPhoto;
}
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) NSTimer *timer;

@end

@implementation CreateViewController

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.geocoder = [[CLGeocoder alloc] init];
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(hideKeyboard:)];
    recog.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:recog];
    [self.messageView setReturnKeyType:UIReturnKeyDone];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.signatureField.text = [defaults objectForKey:@"signature"];
    
    self.messageView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.3].CGColor;
    self.messageView.layer.borderWidth = 1.0;
    self.signatureField.superview.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.3].CGColor;
    self.signatureField.superview.layer.borderWidth = 1.0;
    self.messageView.layer.cornerRadius = 5.f;
    self.signatureField.superview.layer.cornerRadius = 5.f;
    self.messageView.clipsToBounds = YES;
    self.postButton.layer.cornerRadius = 5;
    
    //delegates
    self.messageView.delegate = self;
    self.signatureField.delegate = self;
    
    //funny errors
    funnyErrors = [[NSArray alloc] initWithObjects:@"No.", @"GTFO", @"Just Stop", @"Are You Always This Quiet", @"Try Again", @"Error, Yo!", @"Put More Effort In", @"Nothing To Say?", @"Write Something", @"Artard", @"This Isn't Difficult", nil];
    
    if ([self.delegate respondsToSelector:@selector(createViewControllerDidLoad:)]) {
        [self.delegate createViewControllerDidLoad:self];
    }
    
    //set map on new post view
    self.miniMap.zoomEnabled = YES;
    self.miniMap.scrollEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setCurrentAreaName];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)post:(id)sender
{
    NSString *msg = self.messageView.text;
    
    if ([msg length] == 0)
    {
        //random number generator for funny error responses
        NSUInteger r = arc4random() % [funnyErrors count];
        NSString *title = [funnyErrors objectAtIndex:r];
        NSString *errorString = [NSString stringWithFormat:@"You didn't say anything."];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:errorString delegate:nil cancelButtonTitle:@"I'll Try Harder" otherButtonTitles:nil];
        [alert show];
    }
    else if ([self.delegate respondsToSelector:@selector(createViewControllerDidPost:withImageData:)]) {
        BLPost *post = [[BLPost alloc] init];
        post.message = msg;
        post.latitude = self.myLocation.latitude;
        post.longitude = self.myLocation.longitude;
        
        //create and store signature
        NSString *sig = self.signatureField.text;
        post.signature = sig;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:sig forKey:@"signature"];
        [defaults synchronize];
        
        //if a photo was taken, compress and upload it to server
        NSData *data;
        if (cameraPhoto){
            data = [self compress:cameraPhoto];
        }
        
        [self.delegate createViewControllerDidPost:post withImageData:data];
    }
}

//limit characters in text view
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    if ([text isEqualToString:@"\n"])
    {
        [self.messageView resignFirstResponder];
        return NO;
    }
    
    //check length of post
    if(newLength <= 320)
    {
        return YES;
    }
    else
    {
        NSUInteger emptySpace = 320 - (textView.text.length - range.length);
        textView.text = [[[textView.text substringToIndex:range.location]
                          stringByAppendingString:[text substringToIndex:emptySpace]]
                         stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
        return NO;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    
    if(newLength <= 24)
    {
        return YES;
    } else {
        NSUInteger emptySpace = 24 - (textField.text.length - range.length);
        textField.text = [[[textField.text substringToIndex:range.location]
                          stringByAppendingString:[string substringToIndex:emptySpace]]
                         stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
        return NO;
    }
}

- (IBAction)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(createViewControllerDidCancel)]) {
        [self.delegate createViewControllerDidCancel];
    }
}

# pragma geolocation

- (void)setCurrentAreaName
{
    CLLocationCoordinate2D center = self.myLocation;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];

    currentAreaName = nil;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateEllipsis:) userInfo:nil repeats:YES];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        [self.timer invalidate];
        
        if (error) {
            self.messageView.placeholder = @"Can't Detect Your Location";
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
        
        if (cameraPhoto){
            self.messageView.placeholder = [NSString stringWithFormat:@"Say something about your photo at %@", locationName];
        }
        else{
            self.messageView.placeholder = [NSString stringWithFormat:@"Say something at %@", locationName];
        }
    }];
}

- (void)updateEllipsis:(NSTimer *)timer
{
    if ([currentAreaName length] >= 5) {
        self.messageView.placeholder = nil;
    }
    else if ([currentAreaName length] == 0) {
        currentAreaName = @".";
        self.messageView.placeholder = [NSString stringWithFormat:@"Say something at %@", currentAreaName];
    }
    else {
        currentAreaName = [currentAreaName stringByAppendingString:@" ."];
        self.messageView.placeholder = [NSString stringWithFormat:@"Say something at %@", currentAreaName];
    }
}

# pragma camera functions

- (IBAction)takePhoto:(UIBarButtonItem*)sender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera or camera is disabled."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
    }
    else{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    cameraPhoto = [info objectForKey:UIImagePickerControllerEditedImage];
    
    self.cameraImage.image = cameraPhoto;
    [self.miniMap setHidden:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSData *)compress:(UIImage *)image
{
    int maxFileSize = 600000; // 600kb
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    
    if ([imageData length] <= maxFileSize){
        return imageData;
    }
    
    // Too big
    return nil;
}

@end
