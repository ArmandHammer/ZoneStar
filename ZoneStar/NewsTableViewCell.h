//
//  CustomTableViewCell.h
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import "NewsTableViewCell.h"
#import "GTMNSString+HTML.h"
@class BLPost;

@interface NewsTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *image;
@property (nonatomic, weak) IBOutlet UITextView *messageView;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UILabel *starScore;
@property (nonatomic, weak) IBOutlet UIButton *upstar;
@property (nonatomic, weak) IBOutlet UIButton *zone;
@property (nonatomic, weak) IBOutlet UIButton *reply;

- (void)setContent:(BLPost *)content;

@end