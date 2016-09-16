//
//  NewsViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "NewsViewController.h"
#import "UIKit+AFNetworking.h"

@interface NewsViewController ()
{
    int zoneExponentialVal;
    UIImageView *earthImage;
    UILabel *zoneLabel;
    UISlider *slider;
    CLLocation *myLocation;
    MKCoordinateRegion postRegion;
    CLLocationCoordinate2D postCoordinates;
    MKMapView *zoneMap;
    NSInteger tapCount, tappedRow;
    NSTimer *tapTimer;
}

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) Belloh *belloh;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSIndexPath *previousVisibleIndexPath;
@property (nonatomic) NavigationSearchBar *navBar;

@end

@implementation NewsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.geocoder = [[CLGeocoder alloc] init];
        self.belloh = [[Belloh alloc] init];
        self.belloh.delegate = self;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        if(IS_OS_8_OR_LATER) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [self.locationManager startUpdatingLocation];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    singletonData *sData = [singletonData sharedID];
    CLLocation *location = [locations lastObject];
    myLocation = location;
    
    sData.myCoordinates = location.coordinate;
    //disable buttons while loading coordinates
    [zone setEnabled:NO];
    [compose setEnabled:NO];
    self.navigationItem.title = @"Locating...";
    
    [NSTimer scheduledTimerWithTimeInterval:3
                                         target:self
                                       selector:@selector(detectingLocation:)
                                       userInfo:nil
                                        repeats:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navBar = (NavigationSearchBar *)self.navigationController.navigationBar;
    self.navBar.leftSide = NO;
    self.navBar.searchBar.text = nil;
    self.navBar.searchBar.placeholder = @"Filter posts";
    self.navBar.searchBar.delegate = self;
    
    //add buttons to nav bar
    self.navigationItem.rightBarButtonItems = @[compose, zone];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.navBar hideSearchBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];

    self.tabBarController.tabBar.translucent=NO;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //create the 3 nav bar buttons
    zone = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"location.png"] style:UIBarButtonItemStylePlain target:self action:@selector(zoneButton)];
    
    compose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButton)];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.refreshControl];
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
}

-(void)composeButton
{
    [self performSegueWithIdentifier:@"newPost" sender:self];
}

-(void)zoneButton
{
    CustomIOS7AlertView *newZoneView = [[CustomIOS7AlertView alloc] init];
    [newZoneView setContainerView:[self createDemoView]];
    [newZoneView setButtonTitles:[NSMutableArray arrayWithObjects:@"Cancel", @"OK", nil]];
    [newZoneView setUseMotionEffects:TRUE];
    [newZoneView setDelegate:self];
    [newZoneView show];
}

- (UIView *)createDemoView
{
    //create Zone Radius view
    UIView *contentSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 370)];
    contentSubView.layer.cornerRadius = 10.0;
    
    //setup slider
    slider = [[UISlider alloc] initWithFrame:CGRectMake(5, 335, 290, 30)];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [slider setBackgroundColor:[UIColor clearColor]];
    slider.minimumValue = 1;
    slider.maximumValue = 112;
    singletonData *sData = [singletonData sharedID];
    slider.value = sData.sliderValue;
    
    //formula for exponential growth zooming
    zoneExponentialVal = 91*(pow(1.1, (int)slider.value));
    
    //setup mapview
    zoneMap = [[MKMapView alloc] initWithFrame:CGRectMake(5, 25, 290, 285)];
    zoneMap.layer.cornerRadius = 2.0;
    zoneMap.scrollEnabled = NO;
    zoneMap.zoomEnabled = NO;
    zoneMap.mapType = MKMapTypeHybrid;
    zoneMap.rotateEnabled = NO;
    
    postCoordinates = CLLocationCoordinate2DMake(sData.myCoordinates.latitude, sData.myCoordinates.longitude);
    MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, zoneExponentialVal*2, zoneExponentialVal*2);
    [zoneMap setRegion:rgn];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = rgn.center;
    [zoneMap addAnnotation:point];
    
    //setup earth image
    earthImage = [[UIImageView alloc] initWithFrame:CGRectMake(5, 25, 290, 285)];
    earthImage.image = [UIImage imageNamed:@"earth.png"];
    
    //setup labels
    zoneLabel = [[UILabel alloc] initWithFrame:CGRectMake(75, 322, 150, 12)];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(115, 2, 90, 20)];
    [labelView setText:@"Zoning In"];
    [labelView setFont:[UIFont fontWithName:@"Thonburi" size:15]];
    [zoneLabel setFont:[UIFont fontWithName:@"Thonburi" size:12]];
    labelView.textColor = [UIColor whiteColor];
    zoneLabel.textColor = [UIColor whiteColor];
    zoneLabel.textAlignment = NSTextAlignmentCenter;
    
    //set meters/km/whole world zone
    if (slider.value == 112){
        [earthImage setHidden:NO];
        [zoneMap setHidden:YES];
        [zoneLabel setText: @"The World"];
    }
    else
    {
        [earthImage setHidden:YES];
        [zoneMap setHidden:NO];
        if (zoneExponentialVal > 1000){
            [zoneLabel setText: [NSString stringWithFormat:@"%ikm", zoneExponentialVal/1000]];
        }
        else{
            [zoneLabel setText: [NSString stringWithFormat:@"%im", zoneExponentialVal]];
        }
    }

    //add subviews to contentSubView
    [contentSubView addSubview:slider];
    [contentSubView addSubview:labelView];
    [contentSubView addSubview:zoneLabel];
    [contentSubView addSubview:zoneMap];
    [contentSubView addSubview:earthImage];
    return contentSubView;
}

-(void)sliderAction:(UISlider*)sender
{
    zoneExponentialVal = 91*(pow(1.1, (int)slider.value));
    
    MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, zoneExponentialVal*2, zoneExponentialVal*2);
    [zoneMap setRegion:rgn];
    
    //set meters/km zone
    if (sender.value == 112){
        slider.value = sender.value;
        [earthImage setHidden:NO];
        [zoneMap setHidden:YES];
        [zoneLabel setText: @"The World"];
    }
    else
    {
        [earthImage setHidden:YES];
        [zoneMap setHidden:NO];
        if (zoneExponentialVal > 1000){
            [zoneLabel setText: [NSString stringWithFormat:@"%ikm", zoneExponentialVal/1000]];
        }
        else{
            [zoneLabel setText: [NSString stringWithFormat:@"%im", zoneExponentialVal]];
        }    }
}

//handle zone button clicks
- (void)customIOS7dialogButtonTouchUpInside: (CustomIOS7AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //cancel
    if (buttonIndex == 0)
    {
        [alertView close];
    }
    //OK, reset zone, refresh posts
    else if(buttonIndex == 1)
    {
        singletonData *sData = [singletonData sharedID];
        if (slider.value == 112){
            sData.sliderValue = 112.0;
            MKCoordinateSpan span = {.latitudeDelta = 180, .longitudeDelta = 360};
            MKCoordinateRegion rgn = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0000f, 0.0000f), span);
            self.belloh.region = MKCoordinateRegionMake(myLocation.coordinate, rgn.span);
        }
        else{
            MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(myLocation.coordinate, zoneExponentialVal*2, zoneExponentialVal*2);
            self.belloh.region = MKCoordinateRegionMake(myLocation.coordinate, rgn.span);
            sData.sliderValue = slider.value;
            sData.zoneRange = zoneExponentialVal;
        }
        [self.belloh loadPosts];
        [alertView close];
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![(NavigationSearchBar *)self.navigationController.navigationBar active];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleRefresh
{
    [self.locationManager startUpdatingLocation];
}

- (void)detectingLocation:(NSTimer *)timer
{
    singletonData *sData = [singletonData sharedID];
    if (sData.sliderValue == 112.0){
        MKCoordinateSpan span = {.latitudeDelta = 180, .longitudeDelta = 360};
        MKCoordinateRegion rgn = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0000f, 0.0000f), span);
        self.belloh.region = MKCoordinateRegionMake(myLocation.coordinate, rgn.span);
    }
    else{
        MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(myLocation.coordinate, sData.zoneRange*2, sData.zoneRange*2);
        self.belloh.region = MKCoordinateRegionMake(myLocation.coordinate, rgn.span);
    }
    [self.locationManager stopUpdatingLocation];
    [self.belloh loadPosts];
    [self setNavBarTitleToLocationName];
    [zone setEnabled:YES];
    [compose setEnabled:YES];
}

- (void)loadingPostsSucceeded
{
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadingPostsFailedWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];
//    if (error) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//    }
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
                text = @"No posts in this zone";
            }
            else if (n == 1) {
                text = @"1 Post";
            }
            else {
                text = [NSString stringWithFormat:@"%i Posts", n];
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
    [cell.reply setTitle:[NSString stringWithFormat:@"Reply(%lu)", (unsigned long)post.totalReplies] forState:UIControlStateNormal];
    
    //zone button tag
    cell.zone.tag = indexPath.row;
    [cell.zone addTarget:self action:@selector(zoneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    //reply button tag
    cell.reply.tag = indexPath.row;
    [cell.reply addTarget:self action:@selector(replyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
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
    //OK pressed, attempt to send flag message to server
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
                
                //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sData.postIndex inSection:0];
                //NewsTableViewCell *cell = (NewsTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
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
    BLPost *post = [self.belloh postAtIndex:sender.tag];

    //send URL request to authenticate login
    NSString *urlString = [NSString stringWithFormat:@"http://api.zonestarapp.com/post/%@/star", post.identifier];
    NSURL *webURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
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
            
            //load user upvoted posts and insert new post id
            [userUpvotedPosts addObject:post.identifier];
            [defaults setObject:userUpvotedPosts forKey:@"upvotedPosts"];
            [defaults synchronize];
            
            post.totalStars++;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
            NewsTableViewCell *cell = (NewsTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.starScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)post.totalStars];
            cell.upstar.enabled = NO;
        }
    }
    else{
        UIAlertView *connectError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error connecting to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectError show];
    }
}

-(void)zoneButtonClicked:(UIButton*)sender
{
    BLPost *post = [self.belloh postAtIndex:sender.tag];
    postCoordinates = CLLocationCoordinate2DMake(post.latitude, post.longitude);
    MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, 250, 250);
    postRegion = MKCoordinateRegionMake(postCoordinates, rgn.span);
    [self performSegueWithIdentifier:@"showMap" sender:self];
}

-(void)replyButtonClicked:(UIButton*)sender
{
    [self performSegueWithIdentifier:@"showReplies" sender:sender];
}

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
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];
    
    size = [attributedText boundingRectWithSize:size
                                        options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        context:nil].size;
    //calculate height
    CGFloat height = 65.f;
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

#pragma mark - Map View Controller Delegate

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
    if ([identifier isEqualToString:@"showMap"]) {
        UINavigationController *nav = (UINavigationController *)dest;
        MapViewController *vc = (MapViewController *)[nav.viewControllers firstObject];
        [vc setDelegate:self];
    }
    else if ([identifier isEqualToString:@"newPost"]) {
        UINavigationController *nav = (UINavigationController *)dest;
        CreateViewController *vc = (CreateViewController *)[nav.viewControllers firstObject];
        [vc setDelegate:self];
    }
    else if ([identifier isEqualToString:@"showReplies"]) {
        UINavigationController *nav = (UINavigationController *)dest;
        CreateReplyViewController *vc = (CreateReplyViewController *)[nav.viewControllers firstObject];
        UIView *view = (UIView *)sender;
        BLPost *post = [self.belloh postAtIndex:view.tag];
        vc.post = post;
        [vc setDelegate:self];
    }
}

#pragma mark - Create View Controller Delegate

- (void)createViewControllerDidLoad:(CreateViewController *)controller
{
    singletonData *sData = [singletonData sharedID];
    postCoordinates = sData.myCoordinates;
    MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, 300, 300);
    [controller.miniMap setRegion:rgn animated:NO];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = rgn.center;
    [controller.miniMap addAnnotation:point];
    controller.myLocation = postCoordinates;
}

- (void)createViewControllerDidPost:(BLPost *)post withImageData:(NSData *)imageData
{
    __weak typeof(self) weakSelf = self;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.belloh sendNewPost:post imageData:imageData completion:^(NSError *error){
        [weakSelf.tableView reloadData];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createViewControllerDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Create Reply View Controller Delegate

- (void)createReplyViewControllerDidLoad:(CreateReplyViewController *)controller
{
    singletonData *sData = [singletonData sharedID];
    controller.myLocation = sData.myCoordinates;
}

- (void)createReplyViewControllerDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Geocoding

- (void)setNavBarTitleToLocationName
{
    singletonData *sData = [singletonData sharedID];
    CLLocationCoordinate2D center = sData.myCoordinates;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        self.navigationItem.title = nil;
        
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

#pragma mark - UISearchBarDelegate methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (self.belloh.filter) {
        self.belloh.filter = nil;
        [self.tableView reloadData];
        NSUInteger rows = [self tableView:self.tableView numberOfRowsInSection:self.previousVisibleIndexPath.section];
        if (self.previousVisibleIndexPath.row < rows) {
            [self.tableView scrollToRowAtIndexPath:self.previousVisibleIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        else {
            [self.tableView setContentOffset:CGPointZero animated:NO];
            self.previousVisibleIndexPath = nil;
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.previousVisibleIndexPath = [[self.tableView indexPathsForVisibleRows] firstObject];
    self.belloh.filter = searchBar.text;
    BLLOG(@"Filter: %@", searchBar.text);
    [searchBar endEditing:YES];
}

@end
