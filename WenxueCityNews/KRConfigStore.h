//
//  KRConfigStore.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-20.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

#define KR_PAGE_SIZE 50
#define KR_PAGE_COUNT 5
#define KR_FONT_COUNT 4
#define KR_VIEWTYPE_COUNT 3
#define KR_THEME_COUNT 4
#define KR_MODE_COUNT 3

//#define APP_COLOR [UIColor colorWithRed:42/255.0f  green:82/255.0f  blue:140/255.0f alpha:1.0f]
#define APP_COLOR [UIColor colorWithRed:0/255.0f  green:72/255.0f  blue:108/255.0f alpha:1.0f]

#define APP_FONT_NORMAL @"FZLanTingHei-R-GBK"
#define APP_FONT_BOLD @"FZLanTingHei-DB-GBK"

@interface KRConfigStore : NSObject
{
    NSArray *sizeNameArray;
    NSArray *modeNameArray;
    NSArray *themeNameArray;
    NSMutableDictionary* colorMap;
    Reachability* internetReachable;
}

@property(nonatomic, assign) NSInteger pageNum;
@property(nonatomic, assign) NSInteger fontSize;
@property(nonatomic, assign) NSInteger viewType;
@property(nonatomic, assign) NSInteger showNewsCount;
@property(nonatomic, assign) NSInteger readingTheme;
@property(nonatomic, assign) NSInteger downloadMode;
@property(nonatomic, assign) NSInteger autoCachePictures;

+ (KRConfigStore *)sharedStore;
- (void)save;
-(NSString*)sizeName:(int)size;
-(NSString*)modeName:(int)mode;
-(NSString*)themeName:(int)theme;

-(UIColor*)UIColorFromHexString:(NSString*) hexString;

-(NSString*)foregroundColor;
-(NSString*)backgroundColor;

-(UIColor*)foregroundUIColor;
-(UIColor*)backgroundUIColor;

-(UIColor*)appUIColor;

-(BOOL)hasConnection;

-(int)textSize;
-(int)itemCount;
@end

