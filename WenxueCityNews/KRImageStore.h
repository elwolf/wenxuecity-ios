//
//  BNRImageStore.h
//  Homepwner
//
//  Created by joeconway on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BASE_URL @"http://wenxuecity.cloudfoundry.com"
#define THUMB_DIR @"_thumbs_"
#define IMAGE_DIR @"_images_"

@interface KRImageStore : NSObject
{
    NSMutableDictionary *dictionary;
    NSRegularExpression *regex;
}
+ (KRImageStore *)sharedStore;

- (NSArray*)imageUrlArray:(NSString *)s;

- (void)mkdir:(NSString*)folder;
- (void)rmdir:(NSString*)folder;

- (void)setImage:(UIImage *)i forKey:(NSString *)s;
- (UIImage *)imageForKey:(NSString *)s;
- (void)deleteImageForKey:(NSString *)s;
- (NSString *)imagePathForKey:(NSString *)key;

- (NSInteger)totalCacheSize;
- (void)clearCaches:(NSArray*)items;

- (void)saveImage:(UIImage *)i forKey:(NSString *)s;
- (UIImage *)loadImage:(NSString *)s;
- (BOOL)hasImage:(NSString *)s;
- (NSString*)encodeImagePath:(NSString*)imageUrl;
- (NSString*)encodeThumbPath:(NSInteger)newsId;

@end
