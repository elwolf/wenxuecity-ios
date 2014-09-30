//
//  KRNewsCell.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-31.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface KRNewsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *overviewImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;

@end
