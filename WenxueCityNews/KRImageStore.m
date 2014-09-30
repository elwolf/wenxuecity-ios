//
//  BNRImageStore.m
//  Homepwner
//
//  Created by joeconway on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KRImageStore.h"
#import "UIImage+Resize.h"
#import "MD5.h"
#import "UIImageView+WebCache.h"

#define kImagePattern @"<img(.*?)\\ssrc=(.*?)\"(.*?)\"(.*?)>"
// <img src="http://image.xinmin.cn/2013/03/31/20130331192835506656.jpg" style="display: block; margin-left: auto; margin-right: auto;">

@implementation KRImageStore
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

+ (KRImageStore *)sharedStore
{
    static KRImageStore *sharedStore = nil;
    if (!sharedStore) {
        // Create the singleton
        sharedStore = [[super allocWithZone:NULL] init];
    }
    return sharedStore;
}

- (id)init {
    self = [super init];
    if (self) {
        regex = [NSRegularExpression
                 regularExpressionWithPattern:kImagePattern
                 options:NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionCaseInsensitive
                 error:NULL];
        dictionary = [[NSMutableDictionary alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self 
               selector:@selector(clearCache:) 
                   name:UIApplicationDidReceiveMemoryWarningNotification 
                 object:nil];
        
        [self mkdir:THUMB_DIR];
        [self mkdir:IMAGE_DIR];
    }
    return self;
}

- (void)clearCache:(NSNotification *)note
{
    NSLog(@"[KRImageStore] didReceiveMemoryWarning! flushing %d images out of the cache", [dictionary count]);
    [dictionary removeAllObjects];
}

- (void)mkdir:(NSString*)folder
{
    NSString *imagePath = [self imagePathForKey:folder];
    [[NSFileManager defaultManager] createDirectoryAtPath:imagePath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
}

- (void)rmdir:(NSString*)folder
{
    NSString *imagePath = [self imagePathForKey:folder];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath
                                                    error:nil];
}

- (void)setImage:(UIImage *)i forKey:(NSString *)s
{
    [dictionary setObject:i forKey:s];
    // Create full path for image
    NSString *imagePath = [self imagePathForKey:s];
    
    // Turn image into JPEG data,
    NSData *d = UIImageJPEGRepresentation(i, 1);
    
    // Write it to full path
    [d writeToFile:imagePath atomically:YES];
}

- (UIImage *)imageForKey:(NSString *)s
{
    // If possible, get it from the dictionary
    UIImage *result = [dictionary objectForKey:s];
    
    if (!result) {
        // Create UIImage object from file
        result = [UIImage imageWithContentsOfFile:[self imagePathForKey:s]];
        
        // If we found an image on the file system, place it into the cache
        if (result)
            [dictionary setObject:result forKey:s];
    }
    return result;
}

- (void)saveImage:(UIImage *)i forKey:(NSString *)s
{
    // Create full path for image
    NSString *imagePath = [self imagePathForKey:s];
    
    // Turn image into JPEG data,
    NSData *d = UIImageJPEGRepresentation(i, 1);
    
    // Write it to full path
    [d writeToFile:imagePath atomically:YES];
}

- (UIImage *)loadImage:(NSString *)s
{
    // If possible, get it from the dictionary
    UIImage *result = [dictionary objectForKey:s];    
    if (!result) {
        // Create UIImage object from file
        result = [UIImage imageWithContentsOfFile:[self imagePathForKey:s]];
    }
    return result;
}

- (BOOL)hasImage:(NSString *)s
{
    NSString* imagePath = [self imagePathForKey:s];
    return [[NSFileManager defaultManager] fileExistsAtPath:imagePath];   
}

- (void)deleteImageForKey:(NSString *)s
{
    if(!s) return;
    [dictionary removeObjectForKey:s];
    NSString *path = [self imagePathForKey:s];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

- (NSString *)imagePathForKey:(NSString *)key
{
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask, 
                                        YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:key];
}

-(NSArray*)imageUrlArray:(NSString *)s
{
    NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
    
    [regex enumerateMatchesInString:s options:0 range:NSMakeRange(0, [s length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *url = [s substringWithRange:[result rangeAtIndex:3]];
        if(![url hasPrefix:@"http"]) {
            url = [BASE_URL stringByAppendingString:url];
        }
        [imageUrls addObject:url];
    }];
    
    return imageUrls;
}

- (NSInteger)totalCacheSize
{
    NSInteger totalSize = 0;
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString* docDir = [[documentDirectories objectAtIndex:0] stringByAppendingPathComponent:IMAGE_DIR];
    
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"SELF beginswith '__'"];
    NSError * error;
    NSArray* allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDir error:&error];
    allFiles = [allFiles filteredArrayUsingPredicate:fltr];
    
	for(id file in allFiles) {
        NSString* fullPath = [docDir stringByAppendingPathComponent:file];
        NSDictionary *attributes = [[NSFileManager defaultManager]
                                    attributesOfItemAtPath:fullPath error:&error];        
        if (!error) {
            NSNumber *size = [attributes objectForKey:NSFileSize];
            totalSize += [size integerValue];
        }
    }
    return totalSize;
}

- (void)clearCaches:(NSArray*)items
{
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString* docDir = [documentDirectories objectAtIndex:0];
    NSError * error;
    
    if(items) {
        for(id item in items) {
            NSString* fullPath = [docDir stringByAppendingPathComponent:[self encodeImagePath:item]];
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
        }
    } else {
        docDir = [docDir stringByAppendingPathComponent:IMAGE_DIR];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"SELF beginswith '__'"];
        NSArray* allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDir error:&error];
        allFiles = [allFiles filteredArrayUsingPredicate:fltr];

        for(id file in allFiles) {
            NSString* fullPath = [docDir stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
        }
        NSLog(@"Cache cleared - %d", [allFiles count]);
    }
}

- (NSString*)encodeImagePath:(NSString*)imageUrl
{
    MD5 *md5 = [MD5 md5WithString:imageUrl];
    NSString* ext = [imageUrl pathExtension];
    return [NSString stringWithFormat:@"%@/__%@.%@", IMAGE_DIR, md5, ext];
}

- (NSString*)encodeThumbPath:(NSInteger)newsId
{
    return [NSString stringWithFormat:@"%@/%d_index.jpg", THUMB_DIR, newsId];
}

@end
