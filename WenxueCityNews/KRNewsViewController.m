//
//  KRNewsViewController.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-15.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRNewsViewController.h"
#import "KRNews.h"
#import "KRConfigStore.h"

@implementation KRNewsViewController
@synthesize news;

- (void)loadView
{
    // Create an instance of UIWebView as large as the screen
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    webview = [[UIWebView alloc] initWithFrame:screenFrame];
    // Tell web view to scale web content to fit within bounds of webview
    //[webview setScalesPageToFit:YES];

    [self setView:webview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareNews:)];
    [self setToolbarItems:[NSArray arrayWithObjects: space, shareButtonItem, nil]];


    int fontSize = [[KRConfigStore sharedStore] fontSize];
    switch(fontSize)
    {
        case 0: fontSize = 75; break;
        case 1: fontSize = 100; break;
        default: fontSize = 125; break;
    }
    NSString *html = [NSString stringWithFormat:@"<html> \n"
                                   "<head> \n"
                                   "<style type=\"text/css\"> \n"
                                   "body {font-size: %d%% !important;}\n"
                                   "html {-webkit-text-size-adjust: none; /* Never autoresize text */}\n"
                                   "</style> \n"
                                   "</head> \n"
                                   "<body>%@</body> \n"
                                   "</html>", fontSize, [news content]];

    [webview loadHTMLString: html baseURL: mainBundleURL];
}

- (IBAction)shareNews:(id)sender
{
    NSLog(@"Share this news");
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
