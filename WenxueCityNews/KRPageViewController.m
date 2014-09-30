//
//  KRPageViewController.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-4-9.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRPageViewController.h"
#import "KRConfigStore.h"
#import "KRAppDelegate.h"

@interface KRPageViewController ()

@end

@implementation KRPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self brightnessControl] setValue: [[UIScreen mainScreen] brightness]];
    KRConfigStore* configStore = [KRConfigStore sharedStore];
    NSInteger fontSize = [configStore fontSize];
    [[self fontSizeControl] setSelectedSegmentIndex:fontSize];
    [self brightnessControl].minimumTrackTintColor = [[KRConfigStore sharedStore] appUIColor];
    [self fontSizeControl].tintColor = [[KRConfigStore sharedStore] appUIColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (IBAction)fontSizeChanged:(id)sender {
    NSUInteger fontSize = [[self fontSizeControl] selectedSegmentIndex];
    KRConfigStore* configStore = [KRConfigStore sharedStore];
    [configStore setFontSize: fontSize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fontSizeChanged" object:configStore];
}

- (IBAction)brightnessChanged:(id)sender {
    NSLog(@"Brightness changed, %f", [[self brightnessControl] value]);
    [[UIScreen mainScreen] setBrightness: [[self brightnessControl] value]];
}

- (void)themeSelected:(int)theme {
    KRConfigStore* configStore = [KRConfigStore sharedStore];
    [configStore setReadingTheme: theme];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"themeChanged" object:configStore];
}

- (IBAction)theme1Clicked:(id)sender {
    [self themeSelected: 0];
}

- (IBAction)theme2Clicked:(id)sender {
    [self themeSelected: 1];
}

- (IBAction)theme3Clicked:(id)sender {
    [self themeSelected: 2];
}

- (IBAction)theme4Clicked:(id)sender {
    [self themeSelected: 3];
}


@end
