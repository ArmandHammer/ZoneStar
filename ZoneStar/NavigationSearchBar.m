//
//  NavigationSearchBar.m
//  Belloh
//
//  Created by Eric Webster on 12/26/2013.
//  Copyright (c) 2013 Eric Webster. All rights reserved.
//

#import "NavigationSearchBar.h"
#import "UIColor+App.h"

@interface NavigationSearchBar ()

@property (nonatomic) UIBarButtonItem *searchButton;
@property (nonatomic) UIBarButtonItem *cancelButton;
@property (nonatomic) UIBarButtonItem *removedButton;
@property (nonatomic) UIBarButtonItem *removedZoneButton;
@property (nonatomic) NSArray *barButtons;
@end

@implementation NavigationSearchBar

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.searchBar = [[UISearchBar alloc] init];
        self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
        
        if ([self.searchBar respondsToSelector:@selector(barTintColor)]) {
            // iOS7
            self.searchBar.barTintColor = [UIColor mainColor];
            self.searchBar.tintColor = [UIColor darkTextColor];
        }
        
        self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_searchCancelled)];
    }
    return self;
}

- (void)setLeftSide:(BOOL)leftSide
{
    if (leftSide) {
        self.searchButton = self.topItem.rightBarButtonItem;
    }
    else {
        self.searchButton = self.topItem.leftBarButtonItem;
    }
    self.searchButton.action = @selector(_displaySearchBar);
    _leftSide = leftSide;
}

- (BOOL)active
{
    UINavigationItem *item = self.topItem;
    return item.titleView != nil;
}

#pragma mark - IBActions

-(void)hideSearchBar
{
    [self _searchCancelled];
}

#pragma mark - Search Bar

- (void)_displaySearchBar
{
    UINavigationItem *item = self.topItem;
    
    if (self.leftSide) {
        self.removedButton = item.leftBarButtonItem;
        item.leftBarButtonItem = nil;
        item.hidesBackButton = YES;
        item.titleView = self.searchBar;
        self.searchBar.frame = CGRectMake(-5.0, 0.0, 320.0, CGRectGetHeight(self.bounds));
        [item setRightBarButtonItem:self.cancelButton animated:YES];
    }
    else {
        //save compose and zone buttons and remove them to make room for search bar.
        self.barButtons = item.rightBarButtonItems;
        item.rightBarButtonItems = nil;
        item.titleView = self.searchBar;
        self.searchBar.frame = CGRectMake(-5.0, 0.0, 320.0, CGRectGetHeight(self.bounds));
        [item setLeftBarButtonItem:self.cancelButton animated:YES];
    }
    
    [item.titleView becomeFirstResponder];
}

- (void)_searchCancelled
{
    UINavigationItem *item = self.topItem;
    item.titleView = nil;
    if (self.leftSide) {
        item.hidesBackButton = NO;
        [item setLeftBarButtonItem:self.removedButton animated:YES];
        [item setRightBarButtonItem:self.searchButton animated:YES];
    }
    else {
        [item setRightBarButtonItems:self.barButtons animated:YES];
        [item setLeftBarButtonItem:self.searchButton animated:YES];
    }
    
    if ([self.searchBar.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.searchBar.delegate searchBarCancelButtonClicked:self.searchBar];
    }
}

@end
