//
//  KRNews.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-13.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRNews.h"

@implementation KRNews

@synthesize newsId, read, title, content, dateCreated, bookmark, imageUrls;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.newsId = [coder decodeIntegerForKey:@"newsId"];
        self.read = [coder decodeBoolForKey:@"read"];
        self.bookmark = [coder decodeBoolForKey:@"bookmark"];
        self.title = [coder decodeObjectForKey:@"title"];
        self.content = [coder decodeObjectForKey:@"content"];
        self.imageUrls = [coder decodeObjectForKey:@"imageUrls"];
        self.dateCreated = [coder decodeDoubleForKey:@"dateCreated"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.newsId forKey:@"newsId"];
    [coder encodeBool:self.read forKey:@"read"];
    [coder encodeBool:self.bookmark forKey:@"bookmark"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.content forKey:@"content"];
    [coder encodeObject:self.imageUrls forKey:@"imageUrls"];
    [coder encodeDouble:self.dateCreated forKey:@"dateCreated"];
}

-(NSComparisonResult) compareId:(KRNews*) aNews
{
    if ([self newsId] >= [aNews newsId]) {
        return NSOrderedAscending;
    }else {
        return NSOrderedDescending;
    }
}

- (NSString*)newsKey
{
    return [NSString stringWithFormat:@"%d", [self newsId]];
}
@end
