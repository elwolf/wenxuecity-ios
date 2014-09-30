//
//  KRSettingViewController.h
//  WenxueCityNews
//
//  Created by haihxiao on 3/20/13.
//  Copyright (c) 2013 Haihua Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KRSelectionViewController.h"

@interface KRSettingViewController : UITableViewController<KRSelectionViewControllerDelegate>
{
    NSMutableDictionary* settingMap;
}
- (void)itemSelected:(KRSelectionViewController *)controller withIndex: (NSInteger)index;

@end
