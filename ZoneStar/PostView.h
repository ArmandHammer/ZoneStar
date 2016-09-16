//
//  PostView.h
//  ZoneStar
//
//  Created by Armand Obreja on 2014-09-06.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaceholderTextView.h"
#import "GTMNSString+HTML.h"
@class BLPost;

@interface PostView : UIView

//header - post functions
@property (nonatomic, weak) IBOutlet UITextView *messageView;
@property (nonatomic, weak) IBOutlet UIButton *postUpstarButton;
@property (nonatomic, weak) IBOutlet UIButton *postZone;
@property (nonatomic, weak) IBOutlet UILabel *postUpstarLabel;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;

- (void)setContent:(BLPost *)content;

@end