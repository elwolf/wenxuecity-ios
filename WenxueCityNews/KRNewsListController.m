//
//  NewsListController.m
//
//  Created by Haihua Xiao on 13-3-10.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRNewsListController.h"
#import "KRNewsStore.h"
#import "KRNews.h"
#import "KRNewsViewController.h"
#import "KRSettingViewController.h"
#import "KRDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KRAppDelegate.h"
#import "MBProgressHUD.h"
#import "ODRefreshControl.h"
#import "KRNewsCell.h"
#import "KRImageStore.h"
#import "KRConfigStore.h"
#import "MMDrawerBarButtonItem.h"
#import "UIViewController+MMDrawerController.h"

#define MAX_NEWS_COUNT 200
#define THUMBNAIL_RECT CGRectMake(0, 0, 80, 60)

@implementation KRNewsListController

- (id)init
{
    // Call the superclass's designated initializer
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        UINavigationItem *n = [self navigationItem];
        
        [n setTitle:@"文学城新闻"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storeUpdated:)
                                                     name:@"storeUpdated"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configUpdated:)
                                                     name:@"configUpdated"
                                                   object:nil];
        
        [[self tabBarItem] setTitle: @"新闻"];
        [[self tabBarItem] setImage: [UIImage imageNamed:@"rss"]];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLenient:YES];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        internetReachable = [Reachability reachabilityForInternetConnection];
        
        titleArray = [NSArray arrayWithObjects:@"全部", @"未读", @"收藏", nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(themeChanged:)
                                                     name:@"themeChanged"
                                                   object:nil];
    }
    return self;
}

- (void)viewDidUnload
{
    switcher = nil;
    refreshControl = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
//    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
//    MMDrawerBarButtonItem * rightDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(rightDrawerButtonPress:)];
//    [self.navigationItem setRightBarButtonItem:rightDrawerButton animated:YES];

    [self.navigationController setToolbarHidden:NO];
    
    UIImage *refreshImage = [UIImage imageNamed:@"button_refresh.png"];
    refreshButton = [[UIBarButtonItem alloc] initWithImage:refreshImage landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(refreshNews:)];

    UIImage *configImage = [UIImage imageNamed:@"barbutton_settings.png"];
    UIBarButtonItem* configButton = [[UIBarButtonItem alloc] initWithImage:configImage landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(systemConfig:)];
    
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    switcher = [[SVSegmentedControl alloc] initWithSectionTitles: titleArray];
    [switcher addTarget:self action:@selector(listTypeChanged:) forControlEvents:UIControlEventValueChanged];
	switcher.crossFadeLabelsOnDrag = YES;
	switcher.thumb.tintColor = [[KRConfigStore sharedStore] appUIColor];
	switcher.selectedIndex = [[KRConfigStore sharedStore] viewType];
	switcher.center = CGPointMake(160, 170);
    switcher.font = [UIFont fontWithName:APP_FONT_NORMAL size:15];
    
    UIBarButtonItem *switcherItem = [[UIBarButtonItem alloc] initWithCustomView:switcher];
    
    [self setToolbarItems:[NSArray arrayWithObjects:refreshButton, space, switcherItem, space, configButton, nil]];
            
    refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    [refreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self setSwitchState];
    if(switcher.selectedIndex == 0) {
        int maxNewsId = [[KRNewsStore sharedStore] maxNewsId];
        [self fetchNews:0 to:maxNewsId max:40 appendToTop: YES force: YES slient: NO completion:nil];
    }
}

- (void)setSwitchState
{
    if(switcher.selectedIndex == 2) {
        refreshButton.image = [UIImage imageNamed:@"swipeBar_starOn.png"];
        [refreshControl setEnabled:NO];
        [refreshButton setEnabled:([[KRNewsStore sharedStore] total:switcher.selectedIndex] != 0)];
    } else if(switcher.selectedIndex == 1) {
        refreshButton.image = [UIImage imageNamed:@"swipeBar_keepReadOn.png"];
        [refreshControl setEnabled:NO];
        [refreshButton setEnabled:([[KRNewsStore sharedStore] total:switcher.selectedIndex] != 0)];
    } else {
        refreshButton.image = [UIImage imageNamed:@"button_refresh.png"];
        [refreshControl setEnabled:YES];
        [refreshButton setEnabled:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[KRNewsStore sharedStore] populateUnread];
    [self.tableView setBackgroundColor: [[KRConfigStore sharedStore] backgroundUIColor]];
    [[self tableView] reloadData];
}

- (void)themeChanged:(NSNotification *)notification
{
	switcher.thumb.tintColor = [[KRConfigStore sharedStore] appUIColor];
    [self.tableView setBackgroundColor: [[KRConfigStore sharedStore] backgroundUIColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self.navigationController setToolbarHidden:YES];
}

- (void)listTypeChanged:(id)sender
{
    int viewType = [sender selectedIndex];
    if([[KRConfigStore sharedStore] viewType] != viewType) {
        NSLog(@"Type selected %d - %d", viewType, [[KRNewsStore sharedStore] total:viewType]);
        [[KRConfigStore sharedStore] setViewType: viewType];
        [self setSwitchState];
        [[self tableView] reloadData];
    }
}

- (void)viewDeck:(id)sender
{
    
}

- (void)refreshNews:(id)sender
{
    if(switcher.selectedIndex == 2) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"提示" message:@"确定要取消所有新闻收藏吗?"
                                                     delegate:self cancelButtonTitle:@"确定"
                                            otherButtonTitles:@"取消",nil];
        [alert show];
    } else if(switcher.selectedIndex == 1) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"提示" message:@"确定要标记所有新闻为已读吗?"
                                                        delegate:self cancelButtonTitle:@"确定"
                                            otherButtonTitles:@"取消",nil];
        [alert show];        
    } else {
        int maxNewsId = [[KRNewsStore sharedStore] maxNewsId];
        [self fetchNews: 0 to:maxNewsId max:MAX_NEWS_COUNT appendToTop: YES force: sender != nil slient: sender == nil completion:^() {
            if([sender respondsToSelector:@selector(endRefreshing)]) {
                [sender performSelector:@selector(endRefreshing)];
            }
        }];
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0) {
        if(switcher.selectedIndex == 2) {
            while([[KRNewsStore sharedStore] total:switcher.selectedIndex]) {
                KRNews *news = [[KRNewsStore sharedStore] itemAt:0 forType:switcher.selectedIndex];
                [[KRNewsStore sharedStore] bookmark:news mark:NO];
            }
            [refreshButton setEnabled:([[KRNewsStore sharedStore] total:switcher.selectedIndex] != 0)];
            [[self tableView] reloadData];
        } else {
            int count = [[KRNewsStore sharedStore] total:switcher.selectedIndex];
            for(int i=0;i<count;i++) {
                KRNews *news = [[KRNewsStore sharedStore] itemAt:i forType:switcher.selectedIndex];
                news.read = YES;
            }
            [[KRNewsStore sharedStore] populateUnread];
            [refreshButton setEnabled:([[KRNewsStore sharedStore] total:switcher.selectedIndex] != 0)];
            [[self tableView] reloadData];
        }
    }
}

- (void)loadMore:(id)spinner
{
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if(internetStatus != NotReachable) {
        [spinner startAnimating];
        int minNewsId = [[KRNewsStore sharedStore] minNewsId];
        [self fetchNews: minNewsId to:0 max:20 appendToTop:NO force:YES slient:YES completion:^(){
            [spinner stopAnimating];
        }];
    } else {
        [spinner stopAnimating];
    }
}

- (IBAction)systemConfig:(id)sender
{
    KRSettingViewController *settingController = [[KRSettingViewController alloc] init];
    
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:settingController];
    
    navController.navigationBar.tintColor = [[KRConfigStore sharedStore] appUIColor];
    navController.toolbar.tintColor = [[KRConfigStore sharedStore] appUIColor];
    
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];

    [self presentViewController:navController animated:YES completion:nil];
}

- (void) fetchNews: (int)from to:(int)to max:(int)max appendToTop:(BOOL)appendToTop force:(BOOL)force slient:(BOOL)slient completion:(void (^)())completion
{
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    
    MBProgressHUD *hud = nil;
    BOOL bNetworkDown = internetStatus == NotReachable;
    if(!slient) {
        if(bNetworkDown) {
            hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connect_no"]];
            // Set custom view mode
            hud.mode = MBProgressHUDModeCustomView;
            hud.labelText = @"网络不给力";
            [hud hide:YES afterDelay:2];
        } else {
            hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.labelText = @"正在加载...";
        }
    }
    if(bNetworkDown) {
        if(hud) {
            [hud hide:YES];
        }
        if(completion) completion();
        return;
    }
    
    NSLog(@"Fetch %d items from %d - %d - %d", max, from, to, [self currentViewType]);
    [switcher setEnabled:NO];
    
    [[KRNewsStore sharedStore] loadNews:from to:to max:max appendToTop:appendToTop force:force withHandler:^(NSArray *newsArray, NSError *error) {
        if(newsArray && [self currentViewType] == 0) {
            NSArray *allItems = [[KRNewsStore sharedStore] allItems];
            NSMutableArray  *ips = [[NSMutableArray alloc] initWithCapacity: [newsArray count]];
            for(id news in newsArray)
            {
                //NSLog(@"News(%d) - %@", [news newsId], [news title]);
                int lastRow = [allItems indexOfObject:news];
                
                NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRow inSection:0];
                [ips addObject:ip];
            }
            if([ips count]) {
                [[self tableView] insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationNone];
                [[self tableView] scrollToRowAtIndexPath: [ips objectAtIndex:0] atScrollPosition: UITableViewScrollPositionTop animated:YES];
            }
        }
        if(hud) {
            [hud hide:YES];
        }
        [switcher setEnabled:YES];
        if(completion) completion();
    }];
}

- (void)storeUpdated:(NSNotification *)notification
{
    int type = [self currentViewType];
    int count = [[KRNewsStore sharedStore] total:type];
    NSLog(@"OK! news store updated(%d-%d)", type, count);
   [[self tableView] reloadData];
    if(count) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [[self tableView] scrollToRowAtIndexPath: ip atScrollPosition: UITableViewScrollPositionTop animated:YES];
    }
}

- (void)configUpdated:(NSNotification *)notification
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dropViewDidBeginRefreshing:(ODRefreshControl *)sender
{
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    });
    
    [self refreshNews:refreshControl];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int type = [self currentViewType];
    int count = [[KRNewsStore sharedStore] total:type];
    if(type) {
        return count ? count : 5;
    } else {
        return count + 1;
    }
}

- (NSInteger)currentViewType
{
    return switcher.selectedIndex;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static CGFloat height = -1;
    if(height < 0) height = (IS_IPHONE_5) ? 75.7 : 74.4;
    
    int type = [self currentViewType];
    if(type) {
        return height;
    } else {
        int count = [[KRNewsStore sharedStore] total:type];
        int index = [indexPath row];
        if(index < count) {
            return height;
        } else {
            return 60;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    int type = [self currentViewType];
    int index = [indexPath row];
    if(index < [[KRNewsStore sharedStore] total:type]) {
        KRNews *news = [[KRNewsStore sharedStore] itemAt:[indexPath row] forType:type];
        
        static NSString *KRNewsCellIdentifier = @"KRNewsCell";
        static BOOL nibRegistered = NO;
        if(!nibRegistered) {
            UINib *nib = [UINib nibWithNibName:KRNewsCellIdentifier bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:KRNewsCellIdentifier];
            nibRegistered = YES;
        }
        
        KRNewsCell *cell = [tableView dequeueReusableCellWithIdentifier:KRNewsCellIdentifier];
        [[cell titleLabel] setText: [news title]];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970: [news dateCreated]];
        NSString * dateString = [dateFormatter stringFromDate: date];
        [[cell dateTimeLabel] setText: dateString];
        if([news read]) {
            cell.titleLabel.textColor = [UIColor grayColor];
            cell.dateTimeLabel.textColor = cell.titleLabel.textColor;
        } else {
            cell.titleLabel.textColor = [[KRConfigStore sharedStore] foregroundUIColor];
            cell.dateTimeLabel.textColor = cell.titleLabel.textColor;
        }
        [[cell overviewImage] setTag: [news newsId]];
        [[KRNewsStore sharedStore] setOverviewImage:news inView: [cell overviewImage]];
        CGRect contentViewBound = cell.contentView.bounds;
        UIImage* image = [cell overviewImage].image;
        if(image) {
            [cell overviewImage].bounds = THUMBNAIL_RECT;
            
            CGRect imageViewFrame = cell.overviewImage.frame;
            imageViewFrame.origin.x = contentViewBound.size.width - imageViewFrame.size.width - 8;
            cell.overviewImage.frame = imageViewFrame;
            
            CGRect titleLabelFrame = cell.titleLabel.frame;
            titleLabelFrame.size.width = contentViewBound.size.width - imageViewFrame.size.width - 20;
            cell.titleLabel.frame = titleLabelFrame;
        } else {
            [cell overviewImage].bounds = CGRectMake(0, 0, 0, 10);
            CGRect imageViewFrame = cell.overviewImage.frame;
            imageViewFrame.origin.x = contentViewBound.size.width - 1;
            cell.overviewImage.frame = imageViewFrame;

            CGRect titleLabelFrame = cell.titleLabel.frame;
            titleLabelFrame.size.width = contentViewBound.size.width - 12;
            cell.titleLabel.frame = titleLabelFrame;
        }
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[[KRConfigStore sharedStore] appUIColor]];
        [cell setSelectedBackgroundView:bgColorView];
        [cell.titleLabel sizeToFit];
        return cell;
    } else if(type == 0) {
        static NSString *ReloadCellIdentifier = @"UITableViewReloadCell";

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReloadCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:ReloadCellIdentifier];
            [cell.textLabel setFont: [UIFont fontWithName:APP_FONT_NORMAL size:18]];
            //cell.textLabel.textAlignment = UITextAlignmentCenter;
            [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            UIImage *spacer = [UIImage imageNamed:@"Blank.png"];    
            UIGraphicsBeginImageContext(spinner.frame.size);
            
            [spacer drawInRect:CGRectMake(0,0,spinner.frame.size.width,spinner.frame.size.height)];
            UIImage* resizedSpacer = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            cell.imageView.image = resizedSpacer;
            [cell.imageView addSubview:spinner];
            [spinner setTag: 1001];
            
            [[cell textLabel] setText: @"正在加载更多..."];
            cell.textLabel.textColor = [UIColor grayColor];
        }        
        return cell;
    } else {
        static NSString *InfoCellIdentifier = @"UITableViewInfoCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InfoCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:InfoCellIdentifier];
            [cell.textLabel setFont: [UIFont fontWithName:APP_FONT_NORMAL size:24]];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            [cell setSelectionStyle: UITableViewCellSelectionStyleNone];                        
            cell.textLabel.textColor = [UIColor grayColor];
        }
        if(index == 2) {
            [[cell textLabel] setText: type == 1 ? @"没有未读新闻" : @"没有新闻收藏"];
        } else {
            [[cell textLabel] setText: @""];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int type = [self currentViewType];
    int index = [indexPath row];
    if(index < [[KRNewsStore sharedStore] total:type]) {
        KRNews *selectedNews = [[KRNewsStore sharedStore] itemAt:index forType:type];
        [selectedNews setRead: YES];

        NSString *nibName = [KRAppDelegate nibNameForClass: [KRDetailViewController class]];
        KRDetailViewController *detailViewController = [[KRDetailViewController alloc] initWithNibName:nibName bundle:nil];
        [detailViewController setStartIndex: index];
        [detailViewController setViewType: [self currentViewType]];
        [detailViewController setDateFormatter:dateFormatter];
        
        // Push it onto the top of the navigation controller's stack
        [[self navigationController] pushViewController:detailViewController animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    static BOOL bLoadMoreIsVisible = NO;

    int type = [self currentViewType];
    if(type) return;
    
    UITableViewCell *cell = [self.tableView.visibleCells lastObject];
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSUInteger index = [indexPath row];
    if(index >= [[KRNewsStore sharedStore] total:type]) {
        // last row is visible now
        if(!bLoadMoreIsVisible) {
            bLoadMoreIsVisible = YES;
            id spinner = [cell.imageView viewWithTag:1001];
            [spinner startAnimating];
            [self performSelector:@selector(loadMore:) withObject:spinner afterDelay:1];
        }
    } else {
        bLoadMoreIsVisible = NO;
    }
}

#pragma mark - Button Handlers
-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

-(void)rightDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

-(void)doubleTap:(UITapGestureRecognizer*)gesture{
    [self.mm_drawerController bouncePreviewForDrawerSide:MMDrawerSideLeft completion:nil];
}

-(void)twoFingerDoubleTap:(UITapGestureRecognizer*)gesture{
    [self.mm_drawerController bouncePreviewForDrawerSide:MMDrawerSideRight completion:nil];
}

@end
