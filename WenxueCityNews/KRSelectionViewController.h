//
//  KRSelectionViewController.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-5-11.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KRSelectionViewController;

@protocol KRSelectionViewControllerDelegate <NSObject>

- (void)itemSelected:(KRSelectionViewController *)controller withIndex: (NSInteger)index;

@end

@interface KRSelectionViewController : UITableViewController

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *selections;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) id delegate;

@end


