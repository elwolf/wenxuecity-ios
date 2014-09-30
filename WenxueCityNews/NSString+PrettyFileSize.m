//
//  UIString+PrettyFileSize.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-5-12.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "NSString+PrettyFileSize.h"

@implementation NSString (PrettyFileSize)

+(NSString*) prettyFileSize:(NSInteger)totalSize
{
    static float ONE_KB = 0;
    static float ONE_MB = 0;
    if(ONE_KB == 0) {
        ONE_KB = 1024.0;
        ONE_MB = ONE_KB * 1024.0;
    }
    
    if(totalSize > ONE_MB) {
        return [NSString stringWithFormat:@"%.1f M", (totalSize / ONE_MB)];
    } else if(totalSize > ONE_KB) {
        return [NSString stringWithFormat:@"%.1f K", (totalSize / ONE_KB)];
    } else if(totalSize) {
        return [NSString stringWithFormat:@"%d B", (totalSize)];
    } else {
        return @"空";
    }
}


@end
