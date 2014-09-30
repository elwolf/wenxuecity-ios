//
//  KRPageViewController.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-4-9.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KRPageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *fontSizeControl;
@property (weak, nonatomic) IBOutlet UISlider *brightnessControl;


- (IBAction)fontSizeChanged:(id)sender;
- (IBAction)brightnessChanged:(id)sender;

- (IBAction)theme1Clicked:(id)sender;
- (IBAction)theme2Clicked:(id)sender;
- (IBAction)theme3Clicked:(id)sender;
- (IBAction)theme4Clicked:(id)sender;

@end
