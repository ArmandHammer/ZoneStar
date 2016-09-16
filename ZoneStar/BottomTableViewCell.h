//
//  BottomTableViewCell.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BottomTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *postCountLabel;

@end
