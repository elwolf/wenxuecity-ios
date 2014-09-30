//
//  ViewController.h
//  ODRefreshControlDemo
//
//  Created by Fabio Ritrovato on 7/4/12.
//  Copyright (c) 2012 orange in a day. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "SVSegmentedControl.h"
#import "ODRefreshControl.h"

@interface KRNewsListController : UITableViewController
{
    NSDateFormatter *dateFormatter;
    Reachability* internetReachable;
    SVSegmentedControl* switcher;
    ODRefreshControl *refreshControl;
    UIBarButtonItem* refreshButton;
    NSArray* titleArray;
}
- (void)refreshNews:(id)sender;

@end
