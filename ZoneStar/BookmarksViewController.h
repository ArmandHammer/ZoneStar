//
//  BookmarksViewController.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-07-28.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BookmarksViewController;

@protocol BookmarksViewControllerDelegate <NSObject>

@optional
- (void)bookmarksViewController:(BookmarksViewController *)bookmarksViewController didSelectBookmark:(NSDictionary *)bookmark;

@end

@interface BookmarksViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, weak) id<BookmarksViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)edit:(id)sender;
- (IBAction)cancel:(id)sender;

@end
