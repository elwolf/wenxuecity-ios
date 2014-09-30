//
//  KRSelectionViewController.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-5-11.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRSelectionViewController.h"
#import "KRConfigStore.h"

@interface KRSelectionViewController ()

@end

@implementation KRSelectionViewController

@synthesize title, selections, selectedIndex, indexPath;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [selections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
    static NSString *CellIdentifier = @"UIOptionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:APP_FONT_NORMAL size:16];
        [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];
    }
    // Configure the cell...
    NSUInteger index = [ip row];
    cell.textLabel.text = [selections objectAtIndex:index];    
    if(index == selectedIndex) {
        [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    int section = [ip section];

    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow:selectedIndex inSection:section]];
    [oldCell setAccessoryType:UITableViewCellAccessoryNone];
    [oldCell setSelected:NO animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
    [cell setSelected:YES animated:YES];
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

    selectedIndex = [ip row];
    
    if([self delegate]) {
        [[self delegate] itemSelected: self withIndex: selectedIndex];
    }
}

@end
