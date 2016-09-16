//
//  BookmarksViewController.m
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-28.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "BookmarksViewController.h"
#import "UIColor+App.h"

@interface BookmarksViewController ()

@property (nonatomic) NSArray *bookmarks;

@end

@implementation BookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //nav bar gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarPic.png"] forBarMetrics:UIBarMetricsDefault];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.bookmarks = [defaults objectForKey:@"bookmarks"];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)doneEditing:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.bookmarks forKey:@"bookmarks"];
    [defaults synchronize];
    
    [self.tableView setEditing:NO animated:YES];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    [self.navigationItem setRightBarButtonItem:item animated:YES];
}

#pragma mark - IBActions

- (IBAction)edit:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];
    [self.navigationItem setRightBarButtonItem:item animated:YES];
}

- (IBAction)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.bookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const CellIdentifier = @"BookmarkCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *bookmark = self.bookmarks[indexPath.row];
    cell.textLabel.text = bookmark[@"name"];
    
    return cell;
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(bookmarksViewController:didSelectBookmark:)]) {
        NSDictionary *bookmark = self.bookmarks[indexPath.row];
        [self.delegate bookmarksViewController:self didSelectBookmark:bookmark];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *temp = [self.bookmarks mutableCopy];
    [temp removeObjectAtIndex:indexPath.row];
    self.bookmarks = temp;
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    id bookmark = self.bookmarks[sourceIndexPath.row];
    NSMutableArray *temp = [self.bookmarks mutableCopy];
    [temp removeObjectAtIndex:sourceIndexPath.row];
    [temp insertObject:bookmark atIndex:destinationIndexPath.row];
    self.bookmarks = temp;
}

@end
