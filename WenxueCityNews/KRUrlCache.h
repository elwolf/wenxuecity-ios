//
//  KRUrlCache.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-5-12.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSURLCache.h>

@interface KRUrlCache : NSURLCache
{
    NSSet* validImageExtensions;
}
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request;
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;

-(BOOL)hasDataForURL:(NSString*) pathString;
-(NSData*)dataForURL:(NSString*) pathString;
-(void)storeData:(NSData*)data forURL:(NSString*)pathString;

@end
