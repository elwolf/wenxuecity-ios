//
//  KRSettingViewController.m
//  WenxueCityNews
//
//  Created by haihxiao on 3/20/13.
//  Copyright (c) 2013 Haihua Xiao. All rights reserved.
//

#import "KRSettingViewController.h"
#import "KRNewsStore.h"
#import "KRConfigStore.h"
#import "KRAppDelegate.h"
#import "KRSelectionViewController.h"
#import "KRImageStore.h"
#import "NSString+PrettyFileSize.h"
#import "MBProgressHUD.h"

@implementation KRSettingViewController

- (id)init
{
    // Call the superclass's designated initializer
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        UINavigationItem *n = [self navigationItem];
        
        [n setTitle:@"设置"];
                
        [[self tabBarItem] setTitle: @"设置"];
        [[self tabBarItem] setImage: [UIImage imageNamed:@"cog"]];
        
        settingMap = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *numArray = [[NSMutableArray alloc] init];
        for(int i=0;i<KR_PAGE_COUNT;i++) {
            int itemCount = (i + 1) * KR_PAGE_SIZE;
            [numArray addObject:[NSString stringWithFormat:@"%d", itemCount]];
        }
        [settingMap setObject: numArray forKey:@"1:0"];
        
        NSMutableArray *modeArray = [[NSMutableArray alloc] init];
        for(int i=0;i<KR_MODE_COUNT;i++) {
            [modeArray addObject:[[KRConfigStore sharedStore] modeName: i]];
        }
        [settingMap setObject: modeArray forKey:@"1:1"];
        
        NSMutableArray *fontArray = [[NSMutableArray alloc] init];
        for(int i=0;i<KR_FONT_COUNT;i++) {
            [fontArray addObject:[[KRConfigStore sharedStore] sizeName: i]];
        }
        [settingMap setObject: fontArray forKey:@"0:0"];
        
        NSMutableArray *themeArray = [[NSMutableArray alloc] init];
        for(int i=0;i<KR_THEME_COUNT;i++) {
            [themeArray addObject:[[KRConfigStore sharedStore] themeName: i]];
        }
        [settingMap setObject: themeArray forKey:@"0:1"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAnimated:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.leftBarButtonItem.tintColor = [[KRConfigStore sharedStore] appUIColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:@"themeChanged"
                                               object:nil];
}

- (IBAction)dismissAnimated:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)themeChanged:(NSNotification *)notification
{
    UIColor* uiColor = [[KRConfigStore sharedStore] appUIColor];
    self.navigationController.navigationBar.tintColor = uiColor;
    self.navigationController.toolbar.tintColor = uiColor;
    self.navigationItem.leftBarButtonItem.tintColor = uiColor;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0: return 2;
        case 1: return 4;
        default: return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int section = [indexPath section];
    int index = [indexPath row];

    if(section == 1) {
        static NSString *CellIdentifier = @"UITableViewCell1";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:CellIdentifier];
            cell.textLabel.font = [UIFont fontWithName:APP_FONT_NORMAL size:16];
        }
        
        if(index == 0) {
            [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];
            [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
            [[cell textLabel] setText: @"新闻缓存数目"];
            
            int pageNum = [[KRConfigStore sharedStore] pageNum];
            int itemCount = [[KRConfigStore sharedStore] itemCount];
            [[cell detailTextLabel] setText: [NSString stringWithFormat:@"%d", itemCount]];
            [cell setTag: pageNum];
        } else if(index == 1) {
            [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];
            [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
            [[cell textLabel] setText: @"图片加载"];
            
            int downloadMode = [[KRConfigStore sharedStore] downloadMode];
            [[cell detailTextLabel] setText: [[KRConfigStore sharedStore] modeName: downloadMode]];
            [cell setTag: downloadMode];
        } else if(index == 2) {
            [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
            [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
            [[cell textLabel] setText: @"图片自动缓存"];
            
            BOOL autoCachePictures = [[KRConfigStore sharedStore] autoCachePictures];
            [cell setTag: 0];
            
            UISwitch* switcher = [[UISwitch alloc] init];
            switcher.on = autoCachePictures;
            switcher.onTintColor = [[KRConfigStore sharedStore] appUIColor];
            [switcher addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switcher;
       } else {
            [cell setAccessoryType: UITableViewCellAccessoryNone];
            [[cell textLabel] setText: @"清除缓存"];
            NSInteger totalSize = [[KRImageStore sharedStore] totalCacheSize];
            [cell setTag: totalSize];
            [[cell detailTextLabel] setText: [NSString prettyFileSize:totalSize]];
        }
        return cell;
    } else if(section == 0) {
        static NSString *CellIdentifier2 = @"UITableViewCell2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        if (!cell) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:CellIdentifier2];
            cell.textLabel.font = [UIFont fontWithName:APP_FONT_NORMAL size:16];
            [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];
            [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
        }
        if(index == 0) {
            [[cell textLabel] setText: @"字体大小"];
            int fontSize = [[KRConfigStore sharedStore] fontSize];
            [[cell detailTextLabel] setText: [[KRConfigStore sharedStore] sizeName: fontSize]];
            [cell setTag: fontSize];
        } else {
            [[cell textLabel] setText: @"主题颜色"];
            int theme = [[KRConfigStore sharedStore] readingTheme];
            [[cell detailTextLabel] setText: [[KRConfigStore sharedStore] themeName: theme]];
            [cell setTag: theme];
        }
       return cell;
    } else {
        static NSString *CellIdentifier4 = @"UITableViewCell4";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
        if (!cell) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:CellIdentifier4];
            cell.textLabel.font = [UIFont fontWithName:APP_FONT_NORMAL size:16];
            [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
        }
        [[cell textLabel] setText: @"版本"];
        [[cell detailTextLabel] setText: [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
        return cell;        
    }
}

-(void)switchAction:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;
    BOOL isButtonOn = [switchButton isOn];
    [[KRConfigStore sharedStore] setAutoCachePictures: isButtonOn];
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0: return @"阅读";
        case 1: return @"下载";
        default: return @"关于";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = [indexPath section];
    if(section == [self numberOfSectionsInTableView: tableView] - 1) return;
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString* key = [NSString stringWithFormat:@"%d:%d", section, [indexPath row]];
    NSArray *selections = [settingMap objectForKey:key];
    if(selections) {
        KRSelectionViewController *viewController = [[KRSelectionViewController alloc] init];
        viewController.title = [cell textLabel].text;
        viewController.selections = selections;
        viewController.selectedIndex = [cell tag];
        viewController.delegate = self;
        viewController.indexPath = indexPath;
        [self.navigationController pushViewController:viewController animated:YES];
    } else if([cell tag] ){
        // clear cache
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"提示" message:@"确定要清除缓存吗?"
                                                     delegate:self cancelButtonTitle:@"确定"
                                            otherButtonTitles:@"取消",nil];
        [alert show];
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.labelText = @"正在清除缓存...";
        [[KRImageStore sharedStore] clearCaches: nil];
        [[self tableView] reloadData];
        [hud hide:YES afterDelay:2];
    }
}

- (void)itemSelected:(KRSelectionViewController *)controller withIndex: (NSInteger)index
{
    int section = [controller.indexPath section];
    int row = [controller.indexPath row];
    
    switch(section) {
        case 1:
            if(row == 0) {
                [[KRConfigStore sharedStore] setPageNum: index];
            } else if(row == 1) {
                [[KRConfigStore sharedStore] setDownloadMode: index];
            } else {
                [[KRConfigStore sharedStore] setAutoCachePictures: index];
            }
            break;
        case 0:
            if(row == 0) {
                [[KRConfigStore sharedStore] setFontSize:index];
            } else {
                [[KRConfigStore sharedStore] setReadingTheme:index];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"themeChanged" object:[KRConfigStore sharedStore]];
            }
            break;
    }
    [[self tableView] reloadData];
}

@end
