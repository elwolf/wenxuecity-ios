//
//  KRDetailViewController.h
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

#import "VerticalSwipeScrollView.h"
#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"
#import "FGalleryViewController.h"
#import "KRNews.h"

@interface KRDetailViewController : UIViewController <VerticalSwipeScrollViewDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, MBProgressHUDDelegate, UIWebViewDelegate, FGalleryViewControllerDelegate>
{
    UIBarButtonItem* bookmarkButton;
    UIBarButtonItem* galleryButton;
    NSMutableArray* unmarkedNews;
    FGalleryViewController *galleryController;
}
@property (nonatomic, retain) IBOutlet UIView* headerView;
@property (nonatomic, retain) IBOutlet UIImageView* headerImageView;
@property (nonatomic, retain) IBOutlet UILabel* headerLabel;
@property (nonatomic, retain) IBOutlet UIView* footerView;
@property (nonatomic, retain) IBOutlet UIImageView* footerImageView;
@property (nonatomic, retain) IBOutlet UILabel* footerLabel;
@property (nonatomic, retain) VerticalSwipeScrollView* verticalSwipeScrollView;
@property (nonatomic) NSUInteger startIndex;
@property (nonatomic) NSUInteger stopIndex;
@property (nonatomic) NSInteger viewType;
@property (nonatomic, retain) UIWebView* previousPage;
@property (nonatomic, retain) UIWebView* nextPage;
@property (nonatomic, retain) NSDateFormatter* dateFormatter;

@end

