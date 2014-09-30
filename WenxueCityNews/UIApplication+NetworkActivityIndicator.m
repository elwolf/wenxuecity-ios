//
//  UIApplication (NYX_NetworkActivityIndicator).m
//  WenxueCityNews
//
//  Created by haihxiao on 5/23/13.
//  Copyright (c) 2013 Haihua Xiao. All rights reserved.
//

#import "UIApplication+NetworkActivityIndicator.h"

static NSInteger __nyxNetworkActivityCount = 0;

@implementation UIApplication (NYX_NetworkActivityIndicator)

-(void)nyxRefreshNetworkActivityIndicator
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(nyxRefreshNetworkActivityIndicator) withObject:nil waitUntilDone:NO];
        return;
    }
    self.networkActivityIndicatorVisible = (__nyxNetworkActivityCount > 0);
}

-(void)nyx_pushNetworkActivity
{
    @synchronized(self)
    {
        __nyxNetworkActivityCount++;
    }
    [self nyxRefreshNetworkActivityIndicator];
}

-(void)nyx_popNetworkActivity
{
    @synchronized(self)
    {
        if (__nyxNetworkActivityCount > 0)
            __nyxNetworkActivityCount--;
        else
            __nyxNetworkActivityCount = 0;
        [self nyxRefreshNetworkActivityIndicator];
    }
}

@end
