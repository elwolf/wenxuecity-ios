//
//  KRDetailViewController.m
//  VerticalSwipeArticles
//
//  Created by Peter Boctor on 12/26/10.
//
// Copyright (c) 2011 Peter Boctor
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE
//

#import "KRDetailViewController.h"
#import "KRConfigStore.h"
#import "KRImageStore.h"
#import "KRNewsStore.h"
#import "KRNews.h"
#import "MBProgressHUD.h"
#import "FPPopoverController.h"
#import "KRPageViewController.h"
#import "KRAppDelegate.h"

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@interface KRDetailViewController (PrivateMethods)
-(void)hideGradientBackground:(UIView*)theView;
-(UIWebView*) createWebViewForIndex:(NSUInteger)index;
@end

@implementation KRDetailViewController

@synthesize headerView, headerImageView, headerLabel;
@synthesize footerView, footerImageView, footerLabel;
@synthesize verticalSwipeScrollView, startIndex, stopIndex, viewType;
@synthesize previousPage, nextPage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if(self = [super initWithNibName: nibNameOrNil bundle:nibBundleOrNil]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fontSizeChanged:)
                                                     name:@"fontSizeChanged"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(themeChanged:)
                                                     name:@"themeChanged"
                                                   object:nil];
        self.hidesBottomBarWhenPushed = YES;
        unmarkedNews = [[NSMutableArray alloc] init];        
    }
    return self;
}

- (void)fontSizeChanged:(NSNotification *)notification
{
    int fontSize = [[KRConfigStore sharedStore] textSize];
    NSLog(@"OK! font size updated: %d", fontSize);
    [self setFontSize: fontSize inView: self.verticalSwipeScrollView.currentPageView];
    if([self previousPage]) {
        [self setFontSize: fontSize inView: self.previousPage];
    }
    if([self nextPage]) {
        [self setFontSize: fontSize inView: self.nextPage];
    }
}

- (void)themeChanged:(NSNotification *)notification
{
    int readingTheme = [[KRConfigStore sharedStore] readingTheme];
    NSLog(@"OK! theme updated: %d", readingTheme);
    NSString* foreColor = [[KRConfigStore sharedStore] foregroundColor];
    NSString* backColor = [[KRConfigStore sharedStore] backgroundColor];
    [self setThemeColor: foreColor withBackground: backColor inView: self.verticalSwipeScrollView.currentPageView];
    if([self previousPage]) {
        [self setThemeColor: foreColor withBackground: backColor inView: self.previousPage];
    }
    if([self nextPage]) {
        [self setThemeColor: foreColor withBackground: backColor inView: self.nextPage];
    }
    self.navigationItem.rightBarButtonItem.tintColor = [[KRConfigStore sharedStore] appUIColor];
}

-(void)willAppearIn:(UINavigationController *)navigationController
{
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound && self.startIndex != self.stopIndex) {
        id tableView = [[self.navigationController.viewControllers objectAtIndex:0] tableView];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:stopIndex inSection:0];
        [tableView scrollToRowAtIndexPath: ip atScrollPosition: UITableViewScrollPositionTop animated:NO];
    }
    for(id news in unmarkedNews) {
        [[KRNewsStore sharedStore] bookmark:news mark:NO];
    }
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    //[self.navigationController setToolbarHidden:YES];
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    headerImageView.transform = CGAffineTransformMakeRotation(DegreesToRadians(180));
    
    UIBarButtonItem* configButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"font.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(changeConfig:)];
        
    bookmarkButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"swipeBar_starOff.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(bookmarkNews:)];
    
    galleryButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cartoon_button_into.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(showGallery:)];

    UIBarButtonItem* space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    
    UIBarButtonItem *shareButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareNews:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = configButton;
    self.navigationItem.rightBarButtonItem.tintColor = [[KRConfigStore sharedStore] appUIColor];
    
    [self setToolbarItems:[NSArray arrayWithObjects: bookmarkButton, space, galleryButton, space, shareButton, nil]];
    
    self.verticalSwipeScrollView = [[[VerticalSwipeScrollView alloc] initWithFrame:self.view.frame headerView:headerView footerView:footerView startingAt:startIndex delegate:self] autorelease];
    self.verticalSwipeScrollView.scrollsToTop = NO;
    [self.view addSubview:verticalSwipeScrollView];
}

- (IBAction)bookmarkNews:(id)sender
{
    KRNews* news = [self activeNews];
    BOOL marked = [news bookmark];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star.png"]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = marked ? @"已取消收藏" : @"新闻已收藏";
    [hud hide:YES afterDelay:1];
    news.bookmark = !marked;
    [self updateStarImage: news];
    if(news.bookmark) {
        [[KRNewsStore sharedStore] bookmark:news mark:YES];
        [unmarkedNews removeObject:news];
    } else {
        [unmarkedNews addObject:news];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if(marked) NSLog(@"News %d is out of your bookmark", [news newsId]);
        else NSLog(@"News %d is in your bookmark", [news newsId]);
    });    
}

- (void)showGallery:(id)sender
{
    galleryController = [[FGalleryViewController alloc] initWithPhotoSource:self];
    [galleryController setUseThumbnailView:YES];
    [galleryController setStartingIndex:0];
    [galleryController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:galleryController animated:YES];
    [galleryController release];    
}

- (KRNews*) activeNews
{
    return [[KRNewsStore sharedStore] itemAt: self.verticalSwipeScrollView.currentPageIndex forType:viewType];
}

- (void) updateStarImage: (KRNews*)news
{
    if([news bookmark]) {
        [bookmarkButton setImage: [UIImage imageNamed:@"swipeBar_starOn.png"]];
    } else {
        [bookmarkButton setImage: [UIImage imageNamed:@"swipeBar_starOff.png"]];
    }
    galleryButton.enabled = [[news imageUrls] count] != 0;
}

- (IBAction)changeConfig:(id)sender
{
    UIBarButtonItem * button = (UIBarButtonItem*)sender;
    KRPageViewController *viewController = [[[KRPageViewController alloc] init] autorelease];
    FPPopoverController * popover = [[[FPPopoverController alloc] initWithViewController:viewController] autorelease];
    popover.arrowDirection = FPPopoverArrowDirectionAny;
    popover.tint = FPPopoverWhiteTint;
    popover.border = NO;
    popover.title = nil;
    popover.contentSize = CGSizeMake(280, 230);
    [popover presentPopoverFromView:[button view]];
}

- (IBAction)shareNews:(id)sender {
    // if this is iOS6
    if(NSClassFromString(@"UIActivityViewController")) {
        KRNews* news = [self activeNews];
        NSString* htmlString = [self htmlContentOfNews: news];
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems: @[htmlString] applicationActivities:nil];
        
        activityController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeMessage, UIActivityTypePostToTwitter,
                                             UIActivityTypeSaveToCameraRoll, UIActivityTypePrint, UIActivityTypePostToWeibo];

        [self presentViewController: activityController animated:YES completion: nil];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:@"分享"
                                      delegate:self
                                      cancelButtonTitle:@"取消"
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:@"邮件", @"复制", nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [actionSheet showFromToolbar: [[self navigationController] toolbar]];
    }
}

- (void)shareNewsWithMail
{
    KRNews* news = [self activeNews];
    NSString* htmlString = [self htmlContentOfNews: news];
    
	MFMailComposeViewController *tempMailCompose = [[MFMailComposeViewController alloc] init];
	
	tempMailCompose.mailComposeDelegate = self;	
	[tempMailCompose setSubject:[NSString stringWithFormat:@"[分享自文学城新闻]%@", [news title]]];
	[tempMailCompose setMessageBody:htmlString isHTML:YES];
	
	[self presentModalViewController:tempMailCompose animated:YES];
    [tempMailCompose release];
}

- (void)copyNewsWithClipboard
{
    KRNews* news = [self activeNews];
    NSString* htmlString = [self htmlContentOfNews: news];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = htmlString;
    
	MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:hud];
	
	hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
	
	// Set custom view mode
	hud.mode = MBProgressHUDModeCustomView;
	
	hud.delegate = self;
	hud.labelText = @"复制成功";
	
	[hud show:YES];
	[hud hide:YES afterDelay:2];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
	[hud release];
}

# pragma mark UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self shareNewsWithMail];
    } else if(buttonIndex == 1) {
        [self copyNewsWithClipboard];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet{
    
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
}
-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex{
    
}

# pragma mark MFMailComposeViewControllerDelegate

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			break;
		default:
			break;
	}
	[self dismissModalViewControllerAnimated:YES];
}

- (void) rotateImageView:(UIImageView*)imageView angle:(CGFloat)angle
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    imageView.transform = CGAffineTransformMakeRotation(DegreesToRadians(angle));
    [UIView commitAnimations];
}

# pragma mark VerticalSwipeScrollViewDelegate

-(void) headerLoadedInScrollView:(VerticalSwipeScrollView*)scrollView
{
    [self rotateImageView:headerImageView angle:0];
}

-(void) headerUnloadedInScrollView:(VerticalSwipeScrollView*)scrollView
{
    [self rotateImageView:headerImageView angle:180];
}

-(void) footerLoadedInScrollView:(VerticalSwipeScrollView*)scrollView
{
    [self rotateImageView:footerImageView angle:180];
}

-(void) footerUnloadedInScrollView:(VerticalSwipeScrollView*)scrollView
{
    [self rotateImageView:footerImageView angle:0];
}

-(UIView*) viewForScrollView:(VerticalSwipeScrollView*)scrollView atPage:(NSUInteger)page
{
    UIWebView* webView = nil;
    
    if (page < scrollView.currentPageIndex)
        webView = [[previousPage retain] autorelease];
    else if (page > scrollView.currentPageIndex)
        webView = [[nextPage retain] autorelease];
    
    if (!webView)
        webView = [self createWebViewForIndex:page];
    
    KRNewsStore *sharedStore = [KRNewsStore sharedStore];
    
    self.previousPage = page > 0 ? [self createWebViewForIndex:page-1] : nil;
    self.nextPage = (page == ([self pageCount]-1)) ? nil : [self createWebViewForIndex:page+1];
    self.stopIndex = page;
    
    KRNews* news = [sharedStore itemAt: page forType:viewType];
    [news setRead: YES];
    
    CGRect frame = CGRectMake(0, 0, 400, 44);
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:APP_FONT_NORMAL size:14.0];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = [news title];
    self.navigationItem.titleView = label;
    [self updateStarImage: news];
    
    if (page > 0)
        headerLabel.text = [[sharedStore itemAt:page-1 forType:viewType] title];
    if (page != [self pageCount]-1)
        footerLabel.text = [[sharedStore itemAt:page+1 forType:viewType] title];
        
    return webView;
}

-(NSUInteger) pageCount
{
    return [[KRNewsStore sharedStore] total:viewType];
}

-(UIWebView*) createWebViewForIndex:(NSUInteger)index
{
    UIWebView* webView = [[[UIWebView alloc] initWithFrame:self.view.frame] autorelease];
    webView.opaque = NO;
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
    UIColor* backColor = [[KRConfigStore sharedStore] backgroundUIColor];
    [webView setBackgroundColor: backColor];
    webView.delegate = self;
    
    [self hideGradientBackground:webView];    
    [self loadNewsContent: index intoView:webView];
    
    UISwipeGestureRecognizer *mSwipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(returnToHome)];
    [mSwipeUpRecognizer setDirection: UISwipeGestureRecognizerDirectionRight];
    [webView addGestureRecognizer:mSwipeUpRecognizer];    
    [mSwipeUpRecognizer release];

    return webView;
}

- (void)setFontSize:(int)size inView:(id)webView
{
    NSString* js = [NSString stringWithFormat:@"changeFontSize('%d%%')", size];
    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setThemeColor: (NSString*)foreColor withBackground: (NSString*)backColor inView: (id)webView
{
    NSString* js = [NSString stringWithFormat:@"changeColor('%@', '%@')", foreColor, backColor];
    [webView stringByEvaluatingJavaScriptFromString:js];
    [webView setBackgroundColor: [[KRConfigStore sharedStore] backgroundUIColor]];
}

- (void) loadNewsContent:(int)newsIndex intoView:(id)webview
{
    KRNews* news = [[KRNewsStore sharedStore] itemAt: newsIndex forType:viewType];
    NSString* htmlString = [self htmlContentOfNews: news];
    [webview loadHTMLString:htmlString baseURL: [NSURL URLWithString: BASE_URL]];
}

- (void) loadJavaScript:(NSString*)jsName intoView:(id)webview
{
    NSString *jqPath = [[NSBundle mainBundle] pathForResource:jsName ofType:@"js" inDirectory:@""];
    NSData *jqData = [NSData dataWithContentsOfFile:jqPath];
    NSString *jsString = [[NSMutableString alloc] initWithData:jqData encoding:NSUTF8StringEncoding];
    [webview stringByEvaluatingJavaScriptFromString:jsString];
}

- (NSString*) htmlContentOfNews:(KRNews*)news
{
    NSString* htmlFile = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/DetailView.html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    int fontSize = [[KRConfigStore sharedStore] textSize];
    NSString* foregroundColor = [[KRConfigStore sharedStore] foregroundColor];
    NSString* backgroundColor = [[KRConfigStore sharedStore] backgroundColor];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: [news dateCreated]];
    NSString * dateString = [[self dateFormatter] stringFromDate: date];
    
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- title -->" withString:[news title]];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- date -->" withString:dateString];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- content -->" withString:[news content]];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- font -->" withString: [NSString stringWithFormat:@"%d", fontSize]];
    
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- fore -->" withString:foregroundColor];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- back -->" withString:backgroundColor];
    
    return htmlString;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self loadJavaScript: @"jquery-1.9.1.min" intoView:webView];
    [self loadJavaScript: @"app" intoView:webView];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlString = [[request URL] absoluteString];
    
    if ([urlString hasPrefix:@"image:"]) {
        NSString* indexStr = [[urlString componentsSeparatedByString:@"image:"] lastObject];
        NSInteger index = [indexStr intValue];
        NSLog(@"Image clicked: %d - %@", index, [[[self activeNews] imageUrls] objectAtIndex:index]);
        
        galleryController = [[FGalleryViewController alloc] initWithPhotoSource:self];
        [galleryController setUseThumbnailView:YES];
        [galleryController setStartingIndex:index];
        [galleryController setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:galleryController animated:YES];
        [galleryController release];

        return NO;
    }
    
    return YES;
}

- (void) returnToHome
{
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void) hideGradientBackground:(UIView*)theView
{
    for (UIView * subview in theView.subviews)
    {
        if ([subview isKindOfClass:[UIImageView class]])
            subview.hidden = YES;
        
        [self hideGradientBackground:subview];
    }
}

- (void)viewDidUnload
{
    self.headerView = nil;
    self.headerImageView = nil;
    self.headerLabel = nil;
    
    self.footerView = nil;
    self.footerImageView = nil;
    self.footerLabel = nil;
}

- (void)dealloc
{
    [headerView release];
    [headerImageView release];
    [headerLabel release];
    
    [footerView release];
    [footerImageView release];
    [footerLabel release];
    
    [verticalSwipeScrollView release];
    [previousPage release];
    [nextPage release];
    
    [[self dateFormatter] release];
    
    [super dealloc];
}

#pragma mark - FGalleryViewControllerDelegate Methods


- (int)numberOfPhotosForPhotoGallery:(FGalleryViewController *)gallery
{
    KRNews* news = [self activeNews];
	return [[news imageUrls] count];
}


- (FGalleryPhotoSourceType)photoGallery:(FGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index
{
	return FGalleryPhotoSourceTypeNetwork;
}


- (NSString*)photoGallery:(FGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index
{
    KRNews* news = [self activeNews];
	return [news title];
}

- (NSString*)photoGallery:(FGalleryViewController *)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    KRNews* news = [self activeNews];
    return [[news imageUrls] objectAtIndex:index];
}

@end
