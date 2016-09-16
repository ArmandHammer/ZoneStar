//
//  CreateReplyViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-28.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.

#import "CreateReplyViewController.h"
#import "UIColor+App.h"
#import "UIView+Keyboard.h"
#import "NewsTableViewCell.h"
#import "UIKit+AFNetworking.h"
#include <stdlib.h>

@interface CreateReplyViewController ()
{
    NSArray *funnyErr;
    MKCoordinateRegion postRegion;
    CLLocationCoordinate2D postCoordinates;
    NSInteger tapCount, tappedRow;
    NSTimer *tapTimer;
    CGFloat height;
    NSString *currentAreaName;
    UIImage *cameraPhoto;
}
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) Belloh *belloh;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSURL *selectedURL;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation CreateReplyViewController

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
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.geocoder = [[CLGeocoder alloc] init];
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(hideKeyboard:)];
    recog.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:recog];
    [self.replyTextView setReturnKeyType:UIReturnKeyDone];

    self.replyTextView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.3].CGColor;
    self.replyTextView.layer.borderWidth = 1.0;
    self.replyTextView.layer.cornerRadius = 5.f;
    self.replyTextView.clipsToBounds = YES;
    self.postButton.layer.cornerRadius = 5;
    self.signatureField.superview.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.3].CGColor;
    self.signatureField.superview.layer.borderWidth = 1.0;
    self.signatureField.superview.layer.cornerRadius = 5.f;
    
    //delegates
    self.replyTextView.delegate = self;
    self.signatureField.delegate = self;
    
    //funny errors
    funnyErr = [[NSArray alloc] initWithObjects:@"Believe In Yourself", @"You Can Do It", @"Stop Being Shy", @"People Will Care", @"Say Something", @"Indifference Is Dull", @"Try Again", @"Talk", @"Don't Give Up", @"You Matter", @"Don't Worry About Haters", nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if ([self.delegate respondsToSelector:@selector(createReplyViewControllerDidLoad:)]) {
        [self.delegate createReplyViewControllerDidLoad:self];
    }

    [self setCurrentAreaName];
    [self setHeaderFrame];
    }

- (void)setPost:(BLPost *)post
{
    if (self.belloh == nil) {
        self.belloh = [[Belloh alloc] init];
        self.belloh.delegate = self;
    }
    self.belloh.reply_to = post.identifier;
    _post = post;
    [self.belloh loadPosts];
}

-(void)setHeaderFrame
{
    //check if post has already been upvoted by user
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *userUpvotedPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"upvotedPosts"]];
    NSMutableArray *userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];
    
    if ([userUpvotedPosts containsObject:self.post.identifier]) {
        self.replyHeaderImageView.postUpstarButton.enabled = NO;
        self.replyHeaderImageView.postUpstarButton.alpha = 0.5;
    }
    else if ([userPosts containsObject:self.post.identifier]){
        self.replyHeaderImageView.postUpstarButton.enabled = NO;
        self.replyHeaderImageView.postUpstarButton.alpha = 0.5;
    }
    else {
        self.replyHeaderImageView.postUpstarButton.enabled = YES;
        self.replyHeaderImageView.postUpstarButton.alpha = 1;
        // setting the index on upstar's tag
        self.replyHeaderImageView.postUpstarButton.tag = 999;
    }
    
    //check if post is an image
    if (self.post.imageURLString) {
        NSURL *url = [NSURL URLWithString:self.post.imageURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        // TODO: set a placeholder image
        [self.replyHeaderImageView.cameraImage setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            self.replyHeaderImageView.cameraImage.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            // TODO: set a default image
            [self.replyHeaderImageView.cameraImage setImage:nil];
        }];
    }
    
    self.replyHeaderImageView.postUpstarLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.post.totalStars];
    //zone button tag
    self.replyHeaderImageView.postZone.tag = 999;
    //[sectionHeaderView.postZone removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.replyHeaderImageView.postZone addTarget:self action:@selector(zoneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.replyHeaderImageView.messageView.delegate = self;
    [self.replyHeaderImageView setContent:self.post];
    
    //set size of frame dependant on post length
    NSString *text = self.post.message.gtm_stringByUnescapingFromHTML;
    CGFloat width = CGRectGetWidth(self.replyHeaderImageView.bounds) - 52.f;
    
    UIFont *font = [UIFont fontWithName:@"Thonburi" size:14.f];
    CGSize size = (CGSize){width, CGFLOAT_MAX};
    
    size.width -= 2.f;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];
    
    size = [attributedText boundingRectWithSize:size
                                        options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        context:nil].size;
    
    height = 75.f;
    if ([text length]) {
        height += floorf(size.height);
        if (self.post.imageURLString){
            if (height>105.f){
                height-=15;
            }
            height+=self.view.frame.size.width+10;
        }
        else if (height>105.f){
            height-=20;
        }
    }
    
    //set new frame parameters
    CGRect newFrame = CGRectMake(0, 0, self.frameView.frame.size.width, height);
    [self.replyHeaderImageView setFrame:newFrame];
    CGRect newHeaderFrame = CGRectMake(0, 0, self.frameView.frame.size.width, 148 + height);
    [self.frameView setFrame:newHeaderFrame];
    [self.tableView setTableHeaderView:self.frameView];
}

- (void)handleRefresh
{
    [self.belloh loadPosts];
}

- (void)loadingPostsSucceeded
{
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadingPostsFailedWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.belloh postCount] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *NoThumbCellIdentifier = @"ImageCell";
    static NSString *BottomCellIdentifier = @"BottomCell";

    //number of replies cell
    if (indexPath.row >= [self.belloh postCount]) {
        BottomTableViewCell *bottomCell = [tableView dequeueReusableCellWithIdentifier:BottomCellIdentifier forIndexPath:indexPath];
        
        if (self.belloh.isRemainingPosts) {
            [bottomCell.activityIndicator startAnimating];
            bottomCell.postCountLabel.hidden = YES;
            if ([self.belloh lastPost]) {
                [self.belloh loadAndAppendOlderPosts];
            }
        }
        else {
            [bottomCell.activityIndicator stopAnimating];
            bottomCell.postCountLabel.hidden = NO;
            int n = (int)self.belloh.postCount;
            NSString *text;
            if (n == 0) {
                text = @"No Replies";
            }
            else if (n == 1) {
                text = @"1 Reply";
            }
            else {
                text = [NSString stringWithFormat:@"%i Replies", n];
            }
            bottomCell.postCountLabel.text = text;
        }
        return bottomCell;
    }
    
    BLPost *post = [self.belloh postAtIndex:indexPath.row];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoThumbCellIdentifier forIndexPath:indexPath];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    //check if post has already been upvoted by user
    NSMutableArray *userUpvotedPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"upvotedPosts"]];
    NSMutableArray *userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];

    if ([userUpvotedPosts containsObject:post.identifier]) {
        cell.upstar.enabled = NO;
        cell.upstar.alpha = 0.5;
    }
    else if ([userPosts containsObject:post.identifier]){
        cell.upstar.enabled = NO;
        cell.upstar.alpha = 0.5;
    }
    else {
        cell.upstar.enabled = YES;
        cell.upstar.alpha = 1;
        // setting the index on upstar's tag
        cell.upstar.tag = indexPath.row;
    }
    
    //check if post is an image
    if (post.imageURLString) {
        NSURL *url = [NSURL URLWithString:post.imageURLString];
        [cell.image setImageWithURL:url placeholderImage:nil];
    }
    else {
        cell.image.image = nil;
    }
    
    cell.starScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)post.totalStars];
    
    //zone button tag
    cell.zone.tag = indexPath.row;
    [cell.zone addTarget:self action:@selector(zoneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.messageView.delegate = self;
    [cell setContent:post];
    return cell;
}

#pragma mark - double tap methods for flagging posts

- (void)tapTimerFired:(NSTimer *)aTimer
{
    if (tapTimer != nil)
    {
        tapCount = 0;
        tappedRow = -1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // checking for double taps here
    if (indexPath.row >= [self.belloh postCount])
    {
    }
    else if (tapCount == 1 && tapTimer != nil && tappedRow == indexPath.row)
    {
        // double tap - Put your double tap code here
        [tapTimer invalidate];
        tapTimer = nil;
        
        //load post into singleton data
        BLPost *post = [self.belloh postAtIndex:indexPath.row];
        singletonData *sData = [singletonData sharedID];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *userFlaggedPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"flaggedPosts"]];
        
        if ([userFlaggedPosts containsObject:post.identifier])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Reported" message:@"You cannot flag a message twice." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report" message:@"Flag this message for spam or offensive content?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            [alert show];
            sData.postToFlag = post.identifier;
        }
        tapCount = 0;
        tappedRow = -1;
    }
    else if (tapCount == 0)
    {
        // This is the first tap. If there is no tap till tapTimer is fired, it is a single tap
        tapCount = 1;
        tappedRow = indexPath.row;
        tapTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self
                                                  selector:@selector(tapTimerFired:)
                                                  userInfo:nil repeats:NO];
    }
    else if (tappedRow != indexPath.row)
    {
        // tap on new row
        tapCount = 0;
        if (tapTimer != nil)
        {
            [tapTimer invalidate];
            tapTimer = nil;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    singletonData *sData = [singletonData sharedID];
    //OK pressed, flag++ this message
    if (buttonIndex == 1){
        //send URL request to increase flag count on post
        NSString *urlString = [NSString stringWithFormat:@"http://api.zonestarapp.com/post/%@/flag", sData.postToFlag];
        NSURL *webURL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSError *error;
        
        NSURLResponse *response;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (returnData){
            NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            if ([returnString isEqualToString:@"Not found"]){
                UIAlertView *responseError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unknown error occurred flagging this message." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [responseError show];
                sData.postToFlag = nil;
            }
            else{
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSMutableArray *userFlaggedPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"flaggedPosts"]];
                
                //load user upvoted posts and insert new post id
                [userFlaggedPosts addObject:sData.postToFlag];
                [defaults setObject:userFlaggedPosts forKey:@"flaggedPosts"];
                [defaults synchronize];
            }
        }
        else{
            UIAlertView *connectError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error connecting to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [connectError show];
            sData.postToFlag = nil;
        }
    }
    //Cancel pressed, clear post in singleton
    else{
        sData.postToFlag = nil;
    }
}

#pragma mark - handle button clicks

- (IBAction)upstarButtonClicked:(UIButton *)sender
{
    BLPost *senderPost;
    
    if (sender.tag == 999){
        senderPost = self.post;
    }
    else{
        senderPost = [self.belloh postAtIndex:sender.tag];
    }
    
    //send URL request to authenticate login
    NSString *urlString = [NSString stringWithFormat:@"http://api.zonestarapp.com/post/%@/star", senderPost.identifier];
    NSURL *webURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *error;
    
    NSURLResponse *response;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (returnData)
    {
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        if ([returnString isEqualToString:@"Not found"]){
            UIAlertView *responseError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error giving this post a star. Check your internet connection and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [responseError show];
        }
        else{
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *userUpvotedPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"upvotedPosts"]];
            senderPost.totalStars++;
            
            //load user upvoted posts and insert new post id
            [userUpvotedPosts addObject:senderPost.identifier];
            [defaults setObject:userUpvotedPosts forKey:@"upvotedPosts"];
            [defaults synchronize];
            
            if (sender.tag == 999){
                [self.replyHeaderImageView.postUpstarLabel setText:[NSString stringWithFormat:@"%lu", (unsigned long)senderPost.totalStars]];
                 self.replyHeaderImageView.postUpstarButton.enabled = NO;
                 self.replyHeaderImageView.postUpstarButton.alpha = 0.5;
            }
            else{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
                NewsTableViewCell *cell = (NewsTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.starScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)senderPost.totalStars];
                cell.upstar.enabled = NO;
            }
        }
    }
    else{
        UIAlertView *connectError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error connecting to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectError show];
    }
}

-(void)zoneButtonClicked:(UIButton*)sender
{
    BLPost *senderPost;
    
    if (sender.tag == 999){
        senderPost = self.post;
        postCoordinates = CLLocationCoordinate2DMake(senderPost.latitude, senderPost.longitude);
        MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, 250, 250);
        postRegion = MKCoordinateRegionMake(postCoordinates, rgn.span);
        [self performSegueWithIdentifier:@"showPostMap" sender:self];
    }
    else{
        senderPost = [self.belloh postAtIndex:sender.tag];
        postCoordinates = CLLocationCoordinate2DMake(senderPost.latitude, senderPost.longitude);
        MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, 250, 250);
        postRegion = MKCoordinateRegionMake(postCoordinates, rgn.span);
        [self performSegueWithIdentifier:@"showMap" sender:self];
    }
}

- (void)mapViewControllerDidLoad:(MapViewController *)controller
{
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = postRegion.center;
    [controller.mapView addAnnotation:point];
    controller.mapRegion = postRegion;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = [segue identifier];
    id dest = [segue destinationViewController];
    if ([identifier isEqualToString:@"showMap"] || [identifier isEqualToString:@"showPostMap"]) {
        UINavigationController *nav = (UINavigationController *)dest;
        MapViewController *vc = (MapViewController *)[nav.viewControllers firstObject];
        [vc setDelegate:self];
    }
}

#pragma mark - UITableView Delegate

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.belloh postCount]) {
        return 44.f;
    }
    
    BLPost *post = [self.belloh postAtIndex:indexPath.row];
    NSString *text = post.message.gtm_stringByUnescapingFromHTML;
    CGFloat width = CGRectGetWidth(tableView.bounds) - 52.f;
    
    UIFont *font = [UIFont fontWithName:@"Thonburi" size:14.f];
    CGSize size = (CGSize){width, CGFLOAT_MAX};
    
    size.width -= 2.f;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];
    
    size = [attributedText boundingRectWithSize:size
                                        options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        context:nil].size;
    
    height = 65.f;
    if ([text length]) {
        height += floorf(size.height);
        if (post.imageURLString){
            if(height > 85){
                height -= 15;
            }
            height+=self.view.frame.size.width+18;
        }
        else if(height > 85){
            height -= 20;
        }
    }
    
    return height;
}

//limit characters in text view
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    
    if ([text isEqualToString:@"\n"])
    {
        [self.replyTextView resignFirstResponder];
        return NO;
    }
    if(newLength <= 320)
    {
        return YES;
    } else {
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)post:(id)sender
{
    NSString *msg = self.replyTextView.text;
    
    if ([msg length] == 0)
    {
        //random number generator for funny error responses
        NSUInteger r = arc4random() % [funnyErr count];
        NSString *title = [funnyErr objectAtIndex:r];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"You didn't say anything..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        BLPost *post = [[BLPost alloc] init];
        post.message = msg;
        post.signature = [NSString sanitize:self.signatureField.text withDefault:@""];
        post.reply_to_identifier = self.post.identifier;
        post.latitude = self.myLocation.latitude;
        post.longitude = self.myLocation.longitude;
        
        //if a photo was taken, compress and upload it to server
        NSData *data;
        if (cameraPhoto){
            data = [self compress:cameraPhoto];
        }
        
        __weak __typeof(self)weakSelf = self;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self.belloh sendNewPost:post imageData:data completion:^(NSError *error){
            [weakSelf.tableView reloadData];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        self.replyTextView.text = @"";
    }
}

- (IBAction)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(createReplyViewControllerDidCancel)]) {
        [self.delegate createReplyViewControllerDidCancel];
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
            self.replyTextView.placeholder = @"Can't Detect Your Location";
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
        
        if (cameraPhoto){
            self.replyTextView.placeholder = [NSString stringWithFormat:@"Leave a photo reply from %@", locationName];
        }
        else{
            self.replyTextView.placeholder = [NSString stringWithFormat:@"Leave a reply from %@", locationName];
        }
        currentAreaName = locationName;
    }];
}

- (void)updateEllipsis:(NSTimer *)timer
{
    if ([currentAreaName length] >= 5) {
        self.replyTextView.placeholder = nil;
    }
    else if ([currentAreaName length] == 0) {
        currentAreaName = @".";
        self.replyTextView.placeholder = [NSString stringWithFormat:@"Leave a reply from %@", currentAreaName];
    }
    else {
        currentAreaName = [currentAreaName stringByAppendingString:@" ."];
        self.replyTextView.placeholder = [NSString stringWithFormat:@"Leave a reply from %@", currentAreaName];
    }
}

#pragma takePhoto

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
    self.cameraImage.frame = CGRectMake(self.cameraImage.bounds.origin.x-91, self.replyHeaderImageView.frame.size.height+8, 91, 91);
    self.cameraImage.center = self.cameraImage.superview.center;
    self.cameraImage.image = cameraPhoto;
    self.replyTextView.frame = CGRectMake(self.replyTextView.bounds.origin.x, self.replyTextView.bounds.origin.y, self.replyTextView.frame.size.width-91, self.replyTextView.frame.size.height);
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
