//
//  MapPostsTableViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-10-11.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "MapPostsTableViewController.h"

@interface MapPostsTableViewController ()
{
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
@property (nonatomic) NSTimer *timer;
@end

@implementation MapPostsTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.geocoder = [[CLGeocoder alloc] init];
        self.belloh = [[Belloh alloc] init];
        self.belloh.delegate = self;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *data = [defaults objectForKey:@"region"];
        
        if (data) {
            NSValue *region = [data valueWithObjCType:@encode(MKCoordinateRegion)];
            self.belloh.region = [region MKCoordinateRegionValue];
            [self.belloh loadPosts];
            [self setNavBarTitleToLocationName];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navBar = (NavigationSearchBar *)self.navigationController.navigationBar;
    self.navBar.leftSide = YES;
    self.navBar.searchBar.text = nil;
    self.navBar.searchBar.placeholder = @"Filter posts";
    self.navBar.searchBar.delegate = self;
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    if (!MKCoordinateRegionEqualToRegion(self.region, self.belloh.region)) {
        self.belloh.region = self.region;
        
        // Save the region
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSValue *value = [NSValue valueWithMKCoordinateRegion:self.region];
        NSData *data = [NSData dataWithValue:value];
        [defaults setObject:data forKey:@"region"];
        [defaults synchronize];
        
        [self.belloh removeAllPosts];
        [self.tableView reloadData];
        [self.belloh loadPosts];
        [self setNavBarTitleToLocationName];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navBar hideSearchBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    //delegate
    if ([self.delegate respondsToSelector:@selector(mapPostsTableViewControllerDidLoad:)]) {
        [self.delegate mapPostsTableViewControllerDidLoad:self];
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.refreshControl];
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
    [self.belloh loadPosts];
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

- (void)loadingPostsSucceeded
{
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadingPostsFailedWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];
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
    else if ([identifier isEqualToString:@"showReplies"]) {
        UINavigationController *nav = (UINavigationController *)dest;
        CreateReplyViewController *vc = (CreateReplyViewController *)[nav.viewControllers firstObject];
        UIView *view = (UIView *)sender;
        BLPost *post = [self.belloh postAtIndex:view.tag];
        vc.post = post;
        [vc setDelegate:self];
    }
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
    CLLocationCoordinate2D center = self.belloh.region.center;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    
    self.navigationItem.title = nil;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateEllipsis:) userInfo:nil repeats:YES];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        [self.timer invalidate];
        
        if (error) {
            self.navigationItem.title = @"Cannot Detect Zone Address";
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

//back to map
//-(void)backToMapClicked
//{
//    [self.navigationController popToRootViewControllerAnimated:YES];
//}

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
