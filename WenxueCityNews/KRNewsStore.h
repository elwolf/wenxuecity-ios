//
//  KRNewsStore.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-13.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>

#define FETCH_INTERVAL 300 // 5 minutes
#define BASE_URL_PATTERN @"http://wenxuecity.cloudfoundry.com/news/mobilelist?full=false&from=%d&to=%d&max=%d&appKey=H5T7GDF9KJS"

@class KRNews;

@interface KRNewsStore : NSObject
{
    NSMutableArray *allItems;
    NSMutableDictionary *keyedItems;
    
    NSMutableArray *unreadItems;
    
    NSMutableArray *markItems;
    NSMutableDictionary *keyedMarkItems;
    
    NSMutableSet *readItems;

    BOOL loading;
    NSTimeInterval dateFetched;
}

+ (KRNewsStore *)sharedStore;

- (void)removeItem:(KRNews *)news;

- (NSArray *)allItems;

- (void)cacheNews:(KRNews*)news;

- (void)addItem:(KRNews *)news;

- (void)saveItems:(int)itemCount;

- (int) total:(NSInteger)type;

- (int) maxNewsId;

- (int) minNewsId;

- (BOOL) loading;

- (void) populateUnread;

- (BOOL)isBookmarked:(KRNews *)news;

- (void)bookmark:(KRNews *)news mark:(BOOL)mark;

- (KRNews *)itemAt:(NSInteger)index forType:(NSInteger)type;

- (void) loadNews: (int)from to:(int)to max:(int)max appendToTop:(BOOL)appendToTop force:(BOOL)force withHandler:(void (^)(NSArray *newsArray, NSError *error))handler;

- (void)setOverviewImage:(KRNews *)news inView:(UIImageView*)imageView;

@end
