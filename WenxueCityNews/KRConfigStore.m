//
//  KRConfigStore.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-20.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRConfigStore.h"
#import "Reachability.h"
#import "UIColor+Hex.h"
#import "KRAppDelegate.h"

@implementation KRConfigStore
@synthesize pageNum, fontSize, viewType, showNewsCount, readingTheme, downloadMode, autoCachePictures;

+ (KRConfigStore *)sharedStore
{
    static KRConfigStore *sharedStore = nil;
    if(!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if(self) {
        internetReachable = [Reachability reachabilityForInternetConnection];

        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        
        pageNum = [self load:ud key:@"pageNum" min:0 max:KR_PAGE_COUNT def:(KR_PAGE_COUNT - 1)];
        fontSize = [self load:ud key:@"fontSize" min:0 max:KR_FONT_COUNT def:1];
        viewType = [self load:ud key:@"viewType" min:0 max:KR_VIEWTYPE_COUNT def:0];
        showNewsCount = [self load:ud key:@"showNewsCount" min:0 max:1 def:0];
        readingTheme = [self load:ud key:@"readingTheme" min:0 max:KR_THEME_COUNT def:0];
        downloadMode = [self load:ud key:@"downloadMode" min:0 max:KR_MODE_COUNT def:0];
        autoCachePictures = [self load:ud key:@"autoCachePictures" min:0 max:1 def:0];
        
        sizeNameArray = [NSArray arrayWithObjects:@"小",@"中",@"大", @"超大", nil];
        modeNameArray = [NSArray arrayWithObjects:@"仅限WiFi",@"全部网络",@"从不", nil];
        themeNameArray = [NSArray arrayWithObjects:@"默认",@"赭石",@"墨竹",@"星夜", nil];
        
        colorMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(int)validate:(NSNumber*)val min:(int)min max:(int)max def:(int)def
{
    if(!val) return def;
    int p = [val intValue];
    if(p < min || p > max) p = def;
    return p;
}

-(int)load:(NSUserDefaults *)ud key:(NSString*)key min:(int)min max:(int)max def:(int)def
{
    NSNumber *num = [ud objectForKey:key];
    return [self validate:num min:0 max:max def:def];
}

- (void)save
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[NSNumber numberWithInt: pageNum] forKey:@"pageNum"];
    [ud setObject:[NSNumber numberWithInt: fontSize] forKey:@"fontSize"];
    [ud setObject:[NSNumber numberWithInt: viewType] forKey:@"viewType"];
    [ud setObject:[NSNumber numberWithInt: readingTheme] forKey:@"readingTheme"];
    [ud setObject:[NSNumber numberWithInt: showNewsCount] forKey:@"showNewsCount"];
    [ud setObject:[NSNumber numberWithInt: downloadMode] forKey:@"downloadMode"];
    [ud setObject:[NSNumber numberWithInt: autoCachePictures] forKey:@"autoCachePictures"];
}

-(NSString*)sizeName:(int)size
{
    return [sizeNameArray objectAtIndex:size];
}

-(NSString*)modeName:(int)size
{
    return [modeNameArray objectAtIndex:size];
}

-(NSString*)themeName:(int)theme
{
    return [themeNameArray objectAtIndex:theme];
}

-(int)textSize
{
    int textSize = fontSize;
    switch(textSize)
    {
        case 0: textSize = 80; break;
        case 1: textSize = 100; break;
        case 2: textSize = 118; break;
        default: textSize = 132; break;
    }
    return textSize;
}

-(int)itemCount
{
    return (1 + pageNum) * KR_PAGE_SIZE;
}

-(NSString*)foregroundColor
{
    switch(readingTheme) {
        case 1:
            return @"#000000";
        case 2:
            return @"#000000";
        case 3:
            return @"#bbbbbb";
        default:
            return @"#000000"; // default to black
    }
}

-(NSString*)backgroundColor
{
    switch(readingTheme) {
        case 1:
            return @"#f5f5dc";
        case 2:
            return @"#c6e4ca";
        case 3:
            return @"#111111";
        default:
            return @"#ffffff"; // default to white
    }
}

-(NSString*)appColor
{
    switch(readingTheme) {
        case 1:
            return @"#4e68a0";
        case 2:
            return @"#4e68a0";
        case 3:
            return @"#111111";
        default:
            return @"#4e68a0"; // default to APP_COLOR 4e68a0  2a528c
    }
}

-(UIColor*)foregroundUIColor
{
    return [self UIColorFromHexString: [self foregroundColor]];
}

-(UIColor*)backgroundUIColor
{
    return [self UIColorFromHexString: [self backgroundColor]];
}

-(UIColor*)appUIColor
{
    return [self UIColorFromHexString: [self appColor]];
}

-(UIColor*)UIColorFromHexString:(NSString*) hexString
{
    id color = [colorMap objectForKey: hexString];
    if(!color) {
        color = [UIColor colorWithHexString: hexString andAlpha: 1.0];
        [colorMap setObject:color forKey:hexString];
    }
    return color;
}

-(BOOL)hasConnection
{
    NetworkStatus networkStatus = [internetReachable currentReachabilityStatus];
    switch(networkStatus)
    {
        case ReachableViaWiFi:
            if(downloadMode == 0 || downloadMode == 1) return YES;
            break;
        case ReachableViaWWAN:
            if(downloadMode == 1) return YES;
            break;
    }
    return NO;
}

@end
