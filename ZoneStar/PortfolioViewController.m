//
//  PortfolioViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-28.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "PortfolioViewController.h"
#import "NewsTableViewCell.h"
#import "NSValue+MKCoordinateRegion.h"
#import "NSData+NSValue.h"
#import "UIColor+App.h"
#import "GSKeyChain.h"

@interface PortfolioViewController ()
{
    NSInteger tapCount, tappedRow;
    NSTimer *tapTimer;
    BLPost *postToFlag;
    NSUserDefaults *defaults;
    NSMutableArray *userPosts;
    __block NSMutableArray *postObjects;
    CLLocationCoordinate2D postCoordinates;
    CLLocationCoordinate2D myCoordinates;
    MKCoordinateRegion postRegion;
    NSMutableArray *tempPosts;
    int userTotalStars;
    NSString *title;
    NSString *message;
    NSString *imageName;
}
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSIndexPath *previousVisibleIndexPath;
@property (nonatomic) Belloh *belloh;

@end

@implementation PortfolioViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.belloh = [[Belloh alloc] init];
        self.belloh.delegate = self;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    userTotalStars = 0;
    self.tabBarController.tabBar.translucent=NO;
    [self handleRefresh];
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
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    myCoordinates = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    
    //setup timer while loading coordinates
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(detectingLocation:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)detectingLocation:(NSTimer *)timer
{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - refresh handle

-(void)loadUserPosts
{
    defaults = [NSUserDefaults standardUserDefaults];
    userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];
    tempPosts = [NSMutableArray array];
    __block NSUInteger count = 0;
    //__weak typeof(self) weakSelf = self;
    if ([userPosts count] == 0){
        [self.refreshControl endRefreshing];
    }
    else{
        [self.starsBarButton setEnabled:NO];
        [self.postsBarButton setEnabled:NO];
        for (NSString *postID in userPosts){
            [self.belloh getPostWithIdentifier:postID completion:^(NSError *err, BLPost *post){
                if (post) {
                    [tempPosts addObject:post];
                }
                else {
                    NSLog(@"error: %@", err);
                }
                count++;
                if (count == [userPosts count]) {
                    postObjects = tempPosts;
                    [self loadingPostsSucceeded];
                }
            }];
        }
    }
}
- (void)handleRefresh
{
    [self.refreshControl beginRefreshing];
    [self loadUserPosts];
}

- (void)loadingPostsSucceeded
{
    [postObjects sortUsingComparator:^NSComparisonResult(BLPost *p1, BLPost *p2){
        return [p2.identifier compare:p1.identifier];
    }];
    [self.tableView reloadData];
    [self setStats];
    [self.refreshControl endRefreshing];
    [self.starsBarButton setEnabled:YES];
    [self.postsBarButton setEnabled:YES];
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [postObjects count] == 0 ? 1 : [postObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *NoThumbCellIdentifier = @"ImageCell";
    static NSString *NoPostsCellIdentifier = @"BottomCell";
    
    defaults = [NSUserDefaults standardUserDefaults];
    userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];
    
    if (userPosts.count == 0){
        BottomTableViewCell *bottomCell = [tableView dequeueReusableCellWithIdentifier:NoPostsCellIdentifier forIndexPath:indexPath];
        bottomCell.postCountLabel.text = @"You have no posts, no fame and no meaning in life.";
        bottomCell.postCountLabel.hidden = NO;
        [bottomCell.activityIndicator stopAnimating];
        return bottomCell;
    }
    else if (indexPath.row >= [postObjects count]){
        BottomTableViewCell *bottomCell = [tableView dequeueReusableCellWithIdentifier:NoPostsCellIdentifier forIndexPath:indexPath];
        [bottomCell.activityIndicator startAnimating];
        bottomCell.postCountLabel.hidden = YES;
        return bottomCell;
    }
    
    BLPost *post = postObjects[indexPath.row];
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoThumbCellIdentifier forIndexPath:indexPath];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    cell.upstar.enabled = NO;
    cell.upstar.alpha = 0.5;
    cell.starScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)post.totalStars];
    
    if ([post isReply]){
        //a reply cell has a context button to see the original post
        [cell.reply setTitle:@"Context" forState:UIControlStateNormal];
    }
    else{
        //Regular post
        [cell.reply setTitle:[NSString stringWithFormat:@"Reply(%lu)", (unsigned long)post.totalReplies] forState:UIControlStateNormal];
    }
    
    //check if post is an image
    if (post.imageURLString) {
        NSURL *url = [NSURL URLWithString:post.imageURLString];
        [cell.image setImageWithURL:url placeholderImage:nil];
    }
    else {
        cell.image.image = nil;
    }
    
    //reply button tag
    cell.reply.tag = indexPath.row;
    [cell.reply addTarget:self action:@selector(replyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

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
    if (indexPath.row >= [postObjects count]){
        //do NOTHING
    }
    else if (tapCount == 1 && tapTimer != nil && tappedRow == indexPath.row)
    {
        // double tap - Put your double tap code here
        [tapTimer invalidate];
        tapTimer = nil;
        
        //load post into singleton data
        BLPost *post = postObjects[indexPath.row];
        singletonData *sData = [singletonData sharedID];
        sData.postToFlag = post.identifier;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Delete this post?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alert show];
        
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
    //OK pressed, delete this message
    if (buttonIndex == 1){
        //send URL request to increase flag count on post
        NSString *urlString = [NSString stringWithFormat:@"http://api.zonestarapp.com/post/%@", sData.postToFlag];
        NSURL *webURL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        [request setHTTPMethod:@"DELETE"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSError *error;
        
        NSURLResponse *response;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (returnData){
            NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            if ([returnString isEqualToString:@"Not found"]){
                UIAlertView *responseError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unknown error occurred trying to delete this message." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [responseError show];
                sData.postToFlag=nil;
            }
            else{
                for (BLPost *item in postObjects){
                    if ([item.identifier isEqualToString:sData.postToFlag]){
                        [postObjects removeObjectIdenticalTo:item];
                        break;
                    }
                }
                
                [self setStats];
                defaults = [NSUserDefaults standardUserDefaults];
                userPosts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"posts"]];
                [userPosts removeObjectIdenticalTo:sData.postToFlag];
                [defaults setObject:userPosts forKey:@"posts"];
                [defaults synchronize];
                
                [self.tableView reloadData];
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

-(void)setStats
{
    //posts/stars label
    int userStars = 0;
    for (BLPost *item in postObjects){
        userStars += item.totalStars;
    }
    userTotalStars = userStars - postObjects.count;
    self.starsBarButton.title = [NSString stringWithFormat:@"Fame: %i", userTotalStars];
    self.postsBarButton.title = [NSString stringWithFormat:@"Posts: %lu", (unsigned long)postObjects.count];
}

-(IBAction)postsButtonClick:(UIBarButtonItem *)sender
{
    CustomIOS7AlertView *customAlertView = [[CustomIOS7AlertView alloc] init];
    if ([postObjects count] == 0){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"...", nil]];
        title = @"You Have Left 0 Messages";
        message = @"No one knows you exist.";
        imageName = @"whoami.png";
    }
    else if ([postObjects count] < 10){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Damn Right They Will", nil]];
        title = @"You're Just Getting Started";
        message = @"You are taking your first steps into the world of glamour and fame.  You're sure your messages will soon get you noticed for the 'amazing' person you are.";
        imageName = @"fame.jpeg";
    }
    else if ([postObjects count] < 20){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"I Don't Need No Man!", nil]];
        title = @"Don't Be Afraid To Speak Up";
        message = @"It can be hard to speak your mind at times, but don't be afraid of what people will think. You are a strong, independent woman.";
        imageName = @"woman.png";
    }
    else if ([postObjects count] < 30){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"She Is An Inspiration To Girls Everywhere", nil]];
        title = @"You Are A Productive Member Of Society";
        message = @"The more messages you leave, the more you get to impose your will on other people.  Remember that a true star can shape the future of our culture and mold youth into the adults of tomorrow. Like Miley!";
        imageName = @"miley.png";
    }
    else if ([postObjects count] < 40){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Words Are Like Poems Of The Soul", nil]];
        title = @"You're Touching Lives With Your Words";
        message = @"Zoning in on ZoneStar is a safe, fun and afforadble way to get your message across to other people about what's happening in your area or what's on your mind. Keep up the great work.";
        imageName = @"changing.jpeg";
    }
    else if ([postObjects count] < 50){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Free Puppies For Everybody!", nil]];
        title = @"You Are An Outstanding Human Being";
        message = @"You have a recurring dream that is likely a vision of the future where you stand behind a podium facing hundreds of cameras when someone looks over and says, 'What would you like to say to the nation, Mr. President.'";
        imageName = @"president.png";
    }
    else{
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"OK", nil]];
        title = @"You Are A Star";
        message = @"You're loud, obnoxious, and you think you're all that. You zone so hard this shit crazy.";
        imageName = @"obnoxious.jpg";
    }
    [customAlertView setContainerView:[self createCustomView]];
    [customAlertView setUseMotionEffects:TRUE];
    [customAlertView setDelegate:self];
    [customAlertView show];
}

-(IBAction)starsButtonClick:(UIBarButtonItem *)sender
{
    CustomIOS7AlertView *customAlertView = [[CustomIOS7AlertView alloc] init];
    if (userTotalStars == 0){
        title = @"You Have No Fame";
        message = @"Everyone has to start somewhere.  Have you tried being an interesting person?";
        imageName = @"interesting.jpeg";
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Not Yet...", nil]];
    }
    else if (userTotalStars < 5){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Her Loss...", nil]];
        title = @"RANK 1: High School Chess Club";
        message = @"You thought taking that queen with your bishop during the championships would certainly get you the attention of Heather, the school's cheer captain.  But no, she still doesn't know you exist.";
        imageName = @"chess.jpeg";
    }
    else if (userTotalStars < 10){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Totally!", nil]];
        title = @"RANK 2: Garage Band";
        message = @"You're sure this will be your big break in life or something.  All your grandma's friends thinks you guys totally rock.";
        imageName = @"band.jpeg";
    }
    else if (userTotalStars < 20){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"I'll Perservere", nil]];
        title = @"RANK 3: College Freshman";
        message = @"The world is a scary and confusing place for you. You've already lost 4 clickers.";
        imageName =@"freshman.png";
    }
    else if (userTotalStars < 30){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"They Sacrificed So Much For Me...", nil]];
        title = @"RANK 4: Football Team";
        message = @"Scoring all those touchdowns isn't easy, but someone's gotta do it. Your popularity has you so busy you haven't been keeping up with your parents lives. You wipe away a tear as Cats In The Cradle starts playing on the radio.";
        imageName = @"sports.png";
    }
    else if (userTotalStars < 40){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"I'm Networking", nil]];
        title = @"RANK 5: Outgoing and Popular";
        message = @"You can't walk anywhere on campus without someone validating your existence through props and hugs. You stopped trying in school because who needs an education when you can spend all your free time trying to impress people.";
        imageName = @"popular.png";
    }
    else if (userTotalStars < 50){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Who's Laughing Now, Mom?", nil]];
        title = @"RANK 6: High Paying Job";
        message = @"People treat you differently because you make more money then them. Growing up, your mom would laugh at your bad grades, reminding you weekly that you'd never amount to anything in your life.";
        imageName = @"job.jpeg";
    }
    else if (userTotalStars < 60){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"It's For A Good Cause", nil]];
        title = @"RANK 7: Founded A Charity";
        message = @"You're racking in six figures and have multiple vacation homes around the world. A homeless man once asked you for change, and you told him to get a job.";
        imageName = @"charity.png";
    }
    else if (userTotalStars < 70){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"I'm A Good Person", nil]];
        title = @"RANK 8: First Television Appearance";
        message = @"It's just a cooking show, but you use the small time frame given to you to talk about your charity. There's like, poor people in the world, or something, and you totally care about their well-being.";
        imageName = @"tv.png";
    }
    else if (userTotalStars < 80){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Why...", nil]];
        title = @"RANK 9: Rich and Famous";
        message = @"You party with celebrities, make regular TV appearances, and even starred in your own Christian music video.  You're doing everything you've ever wanted to, yet somehow you still feel empty inside.";
        imageName = @"faith.jpeg";
    }
    else if (userTotalStars < 90){
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"It's All I Ever Wanted", nil]];
        title = @"RANK 10: Hollywood Celebrity";
        message = @"That emptiness inside that plagues most humans has been replaced by a coke habit, excessive attention and high class parties with Hollywood's A-List.";
        imageName = @"hollywood.png";
    }
    else{
        [customAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"My Wife Is Not A Hobbit", nil]];
        title = @"FINAL RANK: Kanye West";
        message = @"Your fame is second to none. You are a lyrical genius and you like fish sticks.";
        imageName = @"kanye.png";
    }
    [customAlertView setContainerView:[self createCustomView]];
    [customAlertView setUseMotionEffects:TRUE];
    [customAlertView setDelegate:self];
    [customAlertView show];
}

-(UIView *)createCustomView
{
    //create view components
    UIView *contentSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 310, 200)];
    contentSubView.layer.cornerRadius = 10.0;
    UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(2, 45, 140, 140)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 310, 30)];
    UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(145, 37, 163, 153)];
    UILabel *line = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 310, 1)];
    
    [titleLabel setFont:[UIFont fontWithName:@"Thonburi" size:16]];
    [commentLabel setFont:[UIFont fontWithName:@"Thonburi" size:12]];
    titleLabel.textColor = [UIColor whiteColor];
    commentLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel setText:title];
    [commentLabel setText:message];
    [line setBackgroundColor:[UIColor orangeColor]];
    [commentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [commentLabel setNumberOfLines:0];
    [titleLabel setNumberOfLines:1];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor=0.5;
    image.image = [UIImage imageNamed:imageName];
    
    //add subviews to contentSubView
    [contentSubView addSubview:image];
    [contentSubView addSubview:titleLabel];
    [contentSubView addSubview:commentLabel];
    [contentSubView addSubview:line];
    return contentSubView;
}

- (void)customIOS7dialogButtonTouchUpInside: (CustomIOS7AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        [alertView close];
    }
}

-(void)zoneButtonClicked:(UIButton*)sender
{
    BLPost *post = [postObjects objectAtIndex:sender.tag];
    postCoordinates = CLLocationCoordinate2DMake(post.latitude, post.longitude);
    MKCoordinateRegion rgn = MKCoordinateRegionMakeWithDistance(postCoordinates, 250, 250);
    postRegion = MKCoordinateRegionMake(postCoordinates, rgn.span);
    [self performSegueWithIdentifier:@"showMap" sender:self];
}

-(void)replyButtonClicked:(UIButton*)sender
{
    BLPost *replyPost = [postObjects objectAtIndex:sender.tag];
    
    //check if post is a reply
    if ([replyPost isReply]){
        BLPost *getPost = [self getContextPost:replyPost.reply_to_identifier];
        if ([self shouldPerformSegueWithIdentifier:@"showReplies" sender:getPost]){
            [self performSegueWithIdentifier:@"showReplies" sender:getPost];
        }
        else{
            UIAlertView *contextError = [[UIAlertView alloc] initWithTitle:@"Context Error" message:@"The original post has been deleted." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [contextError show];
        }
    }
    else{
        [self performSegueWithIdentifier:@"showReplies" sender:sender];
    }
}

#pragma mark - UITableView Delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [postObjects count]) {
        if ([postObjects count] == 0){
            return 70.f;
        }
        return 44.f;
    }
    
    BLPost *post = postObjects[indexPath.row];
    NSString *text = post.message.gtm_stringByUnescapingFromHTML;
    CGFloat width = CGRectGetWidth(tableView.bounds) - 52.f;
    
    UIFont *font = [UIFont fontWithName:@"Thonburi" size:14.f];
    CGSize size = (CGSize){width, CGFLOAT_MAX};
    
    size.width -= 2.f;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];
    
    size = [attributedText boundingRectWithSize:size
                                        options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        context:nil].size;
    
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

#pragma mark - Create Reply View Controller Delegate

- (void)createReplyViewControllerDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createReplyViewControllerDidLoad:(CreateReplyViewController *)controller
{
    [self.locationManager startUpdatingLocation];
    controller.myLocation = myCoordinates;
}

#pragma mark - Segues

- (void)mapViewControllerDidLoad:(MapViewController *)controller
{
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = postRegion.center;
    [controller.mapView addAnnotation:point];
    controller.mapRegion = postRegion;
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([sender isKindOfClass:[BLPost class]])
        return YES;
    
    return NO;
}

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
        if ([sender isKindOfClass:[BLPost class]]){
            UINavigationController *nav = (UINavigationController *)dest;
            CreateReplyViewController *vc = (CreateReplyViewController *)[nav.viewControllers firstObject];
            vc.post = sender;
            [vc setDelegate:self];
        }
        else{
            UIView *view = (UIView *)sender;
            BLPost *replyPost = [postObjects objectAtIndex:view.tag];
            UINavigationController *nav = (UINavigationController *)dest;
            CreateReplyViewController *vc = (CreateReplyViewController *)[nav.viewControllers firstObject];
            vc.post = replyPost;
            [vc setDelegate:self];
        }
    }
}

-(BLPost*)getContextPost:(NSString*)identifier
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.zonestarapp.com/post/%@", identifier];
    NSURL *webURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *error;
    
    NSURLResponse *response;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSDictionary *postDictionary = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:&error];
    BLPost *post = nil;
    
    if ([postDictionary isKindOfClass:[NSDictionary class]])
        post = [[BLPost alloc] initWithDictionary:postDictionary];
    
    return post;
}

@end
