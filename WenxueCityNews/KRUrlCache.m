//
//  KRUrlCache.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-5-12.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRUrlCache.h"
#import <Foundation/NSURLCache.h>
#import "KRImageStore.h"
#import "KRConfigStore.h"

@implementation KRUrlCache

- (id)init
{
    self = [super init];
    if(self) {
        validImageExtensions = [NSSet setWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"bmpf", @"ico", @"cur", @"xbm", nil];
    }
    return self;
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSString *pathString = [[request URL] absoluteString];
    NSString *loweredExtension = [[pathString pathExtension] lowercaseString];
    
    if ([validImageExtensions containsObject:loweredExtension]) {        
        NSString* imageKey = [[KRImageStore sharedStore] encodeImagePath: pathString];

        if ([self hasDataForURL:imageKey]) {
            NSData *data = [self dataForURL:imageKey];
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL]
                                                                MIMEType: [NSString stringWithFormat: @"image/%@", loweredExtension]
                                                   expectedContentLength:[data length]
                                                        textEncodingName:nil];
            return [[NSCachedURLResponse alloc] initWithResponse:response data:data];
        } else if(![[KRConfigStore sharedStore] hasConnection]) {;
            UIImage* placeHolder = [UIImage imageNamed:@"placeholder_trans.png"];
            NSData *data = UIImagePNGRepresentation(placeHolder);
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL]
                                                                MIMEType: [NSString stringWithFormat: @"image/png"]
                                                   expectedContentLength:[data length]
                                                        textEncodingName:nil];
            return [[NSCachedURLResponse alloc] initWithResponse:response data:data];            
        }
    }
    NSLog(@"Requesting %@", pathString);

    return [super cachedResponseForRequest:request];
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {    
    NSString *pathString = [[request URL] absoluteString];
    if (![pathString hasSuffix:@".jpg"]) {
        [super storeCachedResponse:cachedResponse forRequest:request];
        return;
    }
    NSString* imageKey = [[KRImageStore sharedStore] encodeImagePath: pathString];
    [self storeData:cachedResponse.data forURL:imageKey];
}

-(BOOL)hasDataForURL:(NSString*) imageKey
{
    return [[KRImageStore sharedStore] hasImage:imageKey];
}

-(NSData*)dataForURL:(NSString*) imageKey
{
    UIImage *img = [[KRImageStore sharedStore] loadImage:imageKey];
    if([imageKey hasSuffix:@"jpg"]) {
        return UIImageJPEGRepresentation(img,1.0);
    } else {
        return UIImagePNGRepresentation(img);
    }
}

-(void)storeData:(NSData*)data forURL:(NSString*)imageKey
{
    UIImage* img = [UIImage imageWithData:data];
    [[KRImageStore sharedStore] saveImage:img forKey:imageKey];
    //NSLog(@"Cached %@", imageKey);
}

@end
