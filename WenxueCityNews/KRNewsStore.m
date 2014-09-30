//
//  KRNewsStore.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-13.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRNewsStore.h"
#import "KRNews.h"
#import "Base64.h"
#import "AFJSONRequestOperation.h"
#import "KRImageStore.h"
#import "UIImage+Resize.h"
#import "UIImageView+WebCache.h"
#import "KRConfigStore.h"
#import "UIApplication+NetworkActivityIndicator.h"

@implementation KRNewsStore

#define THUMBNAIL_SIZE CGSizeMake(160, 120)
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)

+ (KRNewsStore *)sharedStore
{
    static KRNewsStore *sharedStore = nil;
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
        readItems = [NSKeyedUnarchiver unarchiveObjectWithFile: [self itemArchivePath:@"histdata"]];
        if(!readItems) readItems = [[NSMutableSet alloc] init];
        
        keyedItems = [[NSMutableDictionary alloc] init];
        keyedMarkItems = [[NSMutableDictionary alloc] init];
        unreadItems = [[NSMutableArray alloc] init];
        
        markItems = [self loadEntity:@"markdata" andIndexKey:keyedMarkItems];
        allItems = [self loadEntity:@"newsdata" andIndexKey:keyedItems];
        
        [self populateUnread];
    }
    return self;
}

-(NSMutableArray*) loadEntity:(NSString*) entityName andIndexKey:(NSMutableDictionary*)keyedItemMap
{
    NSMutableArray* ret = [NSKeyedUnarchiver unarchiveObjectWithFile: [self itemArchivePath:entityName]];
    if(ret) {
        for(id item in ret) {
            [keyedItemMap setObject:item forKey: [item newsKey]];
        }
    } else {
    	ret = [[NSMutableArray alloc] init];
    }
    return ret;
}

- (void) populateUnread {
    [unreadItems removeAllObjects];
    for(id item in allItems) {
        if(![item read]) {
            [unreadItems addObject:item];
        }
    }
}

-(void)cacheAllNews:(NSArray*)newsItems
{
    if([[KRConfigStore sharedStore] hasConnection] && [[KRConfigStore sharedStore] autoCachePictures]) {
        for(id news in newsItems) {
            [self cacheNews:news];
        }
    }
}

- (void)cacheNews:(KRNews*)news
{
    dispatch_async(kBgQueue, ^{
        KRImageStore* imgStore = [KRImageStore sharedStore];
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        __block BOOL thumbnailCaptured = NO;
        for(id pic in [[news imageUrls] reverseObjectEnumerator]) {
            NSURL *imageURL = [NSURL URLWithString:pic];
            NSString* imageKey = [imgStore encodeImagePath: pic];
            if(![imgStore hasImage: imageKey]) {
                [[UIApplication sharedApplication] nyx_pushNetworkActivity];
                [manager downloadWithURL:imageURL
                                 options:SDWebImageDownloaderUseNSURLCache | SDWebImageRetryFailed
                                progress:^(NSUInteger receivedSize, long long expectedSize) {
                                }
                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                   if (image) {
                                       if(finished) {
                                           if(!thumbnailCaptured) {
                                               thumbnailCaptured = YES;
                                               NSString* thumbKey = [imgStore encodeThumbPath:[news newsId]];
                                               UIImage* thumbnail = [image imageByScalingAndCroppingForSize: THUMBNAIL_SIZE];
                                               [[KRImageStore sharedStore] setImage:thumbnail forKey:thumbKey];
                                           }
                                           [imgStore saveImage:image forKey:imageKey];
                                       }
                                   }
                                   [[UIApplication sharedApplication] nyx_popNetworkActivity];
                               }];
            }
        }
    });
}

- (NSString *)itemArchivePath:(NSString*)name
{
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // Get one and only document directory from that list
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString *fname = [NSString stringWithFormat:@"wxnews.%@", name];
    return [documentDirectory stringByAppendingPathComponent:fname];
}


- (BOOL)isBookmarked:(KRNews *)news
{
    if ([keyedMarkItems objectForKey: [news newsKey]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)bookmark:(KRNews *)news mark:(BOOL)mark
{
    NSString* newsKey = [news newsKey];
    news.bookmark = mark;
    
    if(mark) {
        if(![self isBookmarked:news]) {
            [markItems addObject:news];            
            [markItems sortUsingSelector:@selector(compareId:)];            
            [keyedMarkItems setObject:news forKey:newsKey];
        }
    } else {
        if([self isBookmarked:news]) {
            KRNews *cloned = [keyedMarkItems objectForKey:newsKey];
            [markItems removeObject: cloned];
            [keyedMarkItems removeObjectForKey:newsKey];
        }
        if(![self imageInUse:news]) {
            NSString *imageKey = [[KRImageStore sharedStore] encodeThumbPath:[news newsId]];
            [[KRImageStore sharedStore] deleteImageForKey:imageKey];
        }
    }
}

- (void)saveItems:(int)itemCount
{
    for(id news in allItems) {
        if([news read]) {
            [readItems addObject: [news newsKey]];
        }
    }
    
    int totalCount = [allItems count];
    if(totalCount > itemCount) {
        NSLog(@"Will remove: %d items", totalCount - itemCount);
        for(int i=totalCount - 1;i>=itemCount;i--) {
            KRNews *news = [allItems objectAtIndex:i];
            [self removeItem: news];
            
            if(![self isBookmarked:news]) {
                NSString *imageKey = [[KRImageStore sharedStore] encodeThumbPath:[news newsId]];
                [[KRImageStore sharedStore] deleteImageForKey:imageKey];
                [[KRImageStore sharedStore] clearCaches: [news imageUrls]];
            }
        }
        [self populateUnread];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"storeUpdated" object:self];
    }
    
    [NSKeyedArchiver archiveRootObject:readItems toFile:[self itemArchivePath:@"hist"]];
    [NSKeyedArchiver archiveRootObject:markItems toFile:[self itemArchivePath:@"mark"]];
    [NSKeyedArchiver archiveRootObject:allItems toFile:[self itemArchivePath:@"data"]];
}

-(int) total:(NSInteger)type
{
    if(type > 1) return [markItems count];
    if(type == 1) return [unreadItems count];
    return [allItems count];
}

-(BOOL) imageInUse:(KRNews*)news
{
    if([self isBookmarked:news]) return YES;
    return [keyedItems objectForKey: [news newsKey]] != nil;
}

-(int) maxNewsId
{
    int count = [allItems count];
    if(count > 0) return [[allItems objectAtIndex:0] newsId];
    return 0;
}

-(int) minNewsId
{
    int count = [allItems count];
    if(count > 0) return [[allItems objectAtIndex:(count-1)] newsId];
    return 0;
}

- (void)removeItem:(KRNews *)news
{
    [allItems removeObjectIdenticalTo:news];
}

- (void)addItem:(KRNews *)news
{
    [allItems addObject:news];
    [keyedItems setObject:news forKey: [news newsKey]];
}

- (void)insertItem:(KRNews *)news atIndex:(int)atIndex
{
    [allItems insertObject:news atIndex:atIndex];
    [keyedItems setObject:news forKey: [news newsKey]];
}

- (NSArray *)allItems
{
    return allItems;
}

- (KRNews *)itemAt:(NSInteger)index forType:(NSInteger)type
{
    KRNews* news = nil;
    if(type > 1) {
        news = [markItems objectAtIndex:index];
    } else if(type == 1) {
        news = [unreadItems objectAtIndex:index];
    } else {
        news = [allItems objectAtIndex:index];
    }
    if(![news imageUrls]) {
        [news setImageUrls:[[KRImageStore sharedStore] imageUrlArray: [news content]]];
    }
    return news;
}

- (BOOL)loading
{
    return loading;
}

- (void) loadNews: (int)from to:(int)to max:(int)max appendToTop:(BOOL)appendToTop force:(BOOL)force withHandler:(void (^)(NSArray *newsArray, NSError *error))handler
{
    if(loading) {
        handler([NSArray arrayWithObjects: nil], nil);
        return;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if(force == NO) {
        if(now - dateFetched < FETCH_INTERVAL) {
            handler([NSArray arrayWithObjects: nil], nil);
            return;
        }
    }
    loading = YES;
        
    NSString * url = [[NSString alloc] initWithFormat:BASE_URL_PATTERN, from, to, max];
    NSURL* targetUrl = [[NSURL alloc] initWithString: url];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetUrl];
    [[UIApplication sharedApplication] nyx_pushNetworkActivity];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSMutableArray *jsonNewsArray = [JSON mutableArrayValueForKey:@"newsList"];
        NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity: [jsonNewsArray count]];
        NSLog(@"%d news fetched", [jsonNewsArray count]);
        int index = 0;
        for (id jsonNews in jsonNewsArray)
        {
            NSString *newsId = [NSString stringWithFormat:@"%@", [jsonNews valueForKeyPath:@"id"]];
            id oldKey = [keyedItems objectForKey:newsId];
            if(!oldKey) {
                KRNews *news = [[KRNews alloc] init];
                NSString *title = [jsonNews valueForKeyPath:@"title"];
                NSString *content = [jsonNews valueForKeyPath:@"content"];
                NSString *dateCreated = [jsonNews valueForKeyPath:@"dateCreated"];

                [news setNewsId: [newsId intValue]];
                [news setTitle:[title base64DecodedString]];
                [news setContent:[content base64DecodedString]];
                [news setDateCreated:(NSTimeInterval)[dateCreated longLongValue] / 1000];
                [news setRead:[readItems containsObject: newsId]];
                [news setBookmark:[self isBookmarked:news]];
                [news setImageUrls:[[KRImageStore sharedStore] imageUrlArray: [news content]]];
                if(appendToTop == NO) {
                    [self addItem:news];
                } else {
                    [self insertItem:news atIndex:index ++];
                }
                [ret addObject:news];
            }
        }
        loading = NO;
        dateFetched = now;
        [self populateUnread];
        [self cacheAllNews:ret];
        handler(ret, nil);
        [[UIApplication sharedApplication] nyx_popNetworkActivity];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        handler(nil, error);
        loading = NO;
        [[UIApplication sharedApplication] nyx_popNetworkActivity];
    }];
    
    [operation start];
}

- (void)setOverviewImage:(KRNews *)news inView:(UIImageView*)imageView
{
    NSString *imageKey = [[KRImageStore sharedStore] encodeThumbPath:[news newsId]];
    UIImage* image = [[KRImageStore sharedStore] imageForKey: imageKey];
    if(image) {
        [imageView setImage: image];
        return;
    };
    
    if([[news imageUrls] count]) {
        [imageView setImage:[UIImage imageNamed:@"placeholder.png"]];
        
        if([[KRConfigStore sharedStore] hasConnection]) {
            NSURL *imageURL = [NSURL URLWithString:[[news imageUrls] objectAtIndex:0]];
            [[UIApplication sharedApplication] nyx_pushNetworkActivity];
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadWithURL:imageURL
                             options:SDWebImageDownloaderUseNSURLCache | SDWebImageRetryFailed
                            progress:^(NSUInteger receivedSize, long long expectedSize) {
                            }
                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                               if (image) {
                                   if(finished) {
                                       UIImage* thumbnail = [image imageByScalingAndCroppingForSize: THUMBNAIL_SIZE];
                                       if([imageView tag] == [news newsId]) {
                                           [imageView setImage: thumbnail];
                                       }
                                       [[KRImageStore sharedStore] setImage:thumbnail forKey:imageKey];
                                   }
                               } else {
                                   NSLog(@"Failed to load image for %@ from %@", imageKey, imageURL);
                               }
                               [[UIApplication sharedApplication] nyx_popNetworkActivity];
                           }];
        }
    } else {
        [imageView setImage:nil];
    }
}

@end