//
//  KRNewsCell.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-31.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRNewsCell.h"

@implementation KRNewsCell
@synthesize titleLabel;
@synthesize dateTimeLabel;
@synthesize overviewImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
