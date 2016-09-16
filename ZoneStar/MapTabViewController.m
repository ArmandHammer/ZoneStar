//
//  MapTabViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-10-11.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "MapTabViewController.h"

@interface MapTabViewController ()

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSArray *searchResults;
@property (nonatomic) MKLocalSearch *search;
@property (nonatomic) UITableView *resultsTableView;
@property (nonatomic) NavigationSearchBar *navBar;

@end

@interface UIViewController()
- (void)setSearchDisplayController:(UISearchController *)searchDisplayController;
@end

@implementation MapTabViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navBar = (NavigationSearchBar *)self.navigationController.navigationBar;
    self.navBar.leftSide = YES;
    self.navBar.searchBar.text = nil;
    self.navBar.searchBar.placeholder = @"Search for locations";
    self.navBar.searchBar.delegate = self;
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.navBar hideSearchBar];
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    zoneIn = [[UIBarButtonItem alloc] initWithTitle:@"Zone In" style:UIBarButtonItemStylePlain target:self action:@selector(zoneInClicked)];
//    self.navigationItem.leftBarButtonItem = zoneIn;
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.mapView.mapType = MKMapTypeHybrid;
    self.locationManager = [[CLLocationManager alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBookmarks"]) {
        UINavigationController *nav = (UINavigationController *)segue.destinationViewController;
        BookmarksViewController *vc = (BookmarksViewController *)[nav.viewControllers firstObject];
        [vc setDelegate:self];
    }
    else if ([segue.identifier isEqualToString:@"showPosts"]) {
        MapPostsTableViewController *vc = (MapPostsTableViewController *)segue.destinationViewController;
        [vc setDelegate:self];
    }
}

#pragma mark - IBActions

- (IBAction)findMe:(id)sender
{
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

- (IBAction)addBookmark:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bookmark This Zone?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] ;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Zone Name";
    textField.textAlignment = NSTextAlignmentCenter;
    [alertView show];
}

- (IBAction)zoneInClicked:(id)sender
{
    [self performSegueWithIdentifier:@"showPosts" sender:self];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        if ([name length] == 0) {
            return [self addBookmark:nil];
        }
        
        NSValue *value = [NSValue valueWithMKCoordinateRegion:self.mapView.region];
        NSData *data = [NSData dataWithValue:value];
        NSDictionary *bookmark = @{@"name": name, @"data": data};
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *bookmarks = [defaults objectForKey:@"bookmarks"];
        if (bookmarks) {
            bookmarks = [bookmarks arrayByAddingObject:bookmark];
        }
        else {
            bookmarks = @[bookmark];
        }
        [defaults setObject:bookmarks forKey:@"bookmarks"];
        [defaults synchronize];
    }
}

#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    self.mapView.showsUserLocation = YES;
    singletonData *sData = [singletonData sharedID];
    sData.myCoordinates = location.coordinate;
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:searchBar action:@selector(hideKeyboard:)];
    recog.cancelsTouchesInView = NO;
    [tableView addGestureRecognizer:recog];
    
    [self.view addSubview:tableView];
    
    NSLayoutConstraint *cTop = [NSLayoutConstraint
                                constraintWithItem:self.view
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:tableView
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:0];
    
    NSLayoutConstraint *cBottom = [NSLayoutConstraint
                                   constraintWithItem:self.view
                                   attribute:NSLayoutAttributeBottom
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:tableView
                                   attribute:NSLayoutAttributeBottom
                                   multiplier:1.0
                                   constant:0];
    
    NSLayoutConstraint *cTrail = [NSLayoutConstraint
                                  constraintWithItem:self.view
                                  attribute:NSLayoutAttributeTrailing
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:tableView
                                  attribute:NSLayoutAttributeTrailing
                                  multiplier:1.0
                                  constant:0];
    
    NSLayoutConstraint *cLead = [NSLayoutConstraint
                                 constraintWithItem:self.view
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:tableView
                                 attribute:NSLayoutAttributeLeading
                                 multiplier:1.0
                                 constant:0];
    
    [self.view addConstraints:@[cLead, cTrail, cTop, cBottom]];
    
    self.resultsTableView = tableView;
    self.navigationController.toolbarHidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar endEditing:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.navigationController.toolbarHidden = NO;
    [self.resultsTableView removeFromSuperview];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.search cancel];
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = searchText;
    request.region = self.mapView.region;
    self.search = [[MKLocalSearch alloc] initWithRequest:request];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
        self.searchResults = response.mapItems;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.resultsTableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.searchResults count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    MKMapItem *mapItem = (MKMapItem *)self.searchResults[indexPath.row];
    
    cell.textLabel.text = mapItem.name;
    if (mapItem.placemark.locality) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", mapItem.placemark.locality, mapItem.placemark.country];
    }
    else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", mapItem.placemark.country];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKMapItem *mapItem = self.searchResults[indexPath.row];
    CLCircularRegion *cLRegion = (CLCircularRegion *)mapItem.placemark.region;
    MKCoordinateRegion region;
    if (cLRegion) {
        region = MKCoordinateRegionMakeWithDistance(cLRegion.center, cLRegion.radius, cLRegion.radius);
    }
    else {
        region = MKCoordinateRegionMakeWithDistance(mapItem.placemark.coordinate, 12000, 12000);
    }
    
    [self.navBar hideSearchBar];
    [self.mapView setRegion:region animated:YES];
}

- (void)mapPostsTableViewControllerDidLoad:(MapPostsTableViewController *)controller
{
    controller.region = self.mapView.region;
}

#pragma mark - BookmarksViewControllerDelegate methods

- (void)bookmarksViewController:(BookmarksViewController *)bookmarksViewController didSelectBookmark:(NSDictionary *)bookmark
{
    NSData *data = bookmark[@"data"];
    NSValue *region = [data valueWithObjCType:@encode(MKCoordinateRegion)];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.mapView setRegion:[region MKCoordinateRegionValue] animated:YES];
    }];
}

@end
