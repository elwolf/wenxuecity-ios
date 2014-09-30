//
//  KRAppDelegate.h
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-9.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)

@class KRNewsListController;

@interface KRAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>
{
}
@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
+ (NSString *)nibNameForClass:(Class)class;

@end
