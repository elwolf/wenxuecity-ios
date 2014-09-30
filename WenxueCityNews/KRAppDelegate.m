//
//  KRAppDelegate.m
//  WenxueCityNews
//
//  Created by Haihua Xiao on 13-3-9.
//  Copyright (c) 2013年 Haihua Xiao. All rights reserved.
//

#import "KRAppDelegate.h"
#import "KRNewsListController.h"
#import "KRNewsStore.h"
#import "KRConfigStore.h"
#import "KRSettingViewController.h"
#import "KRBookmarkViewController.h"
#import "Reachability.h"
#import "MLNavigationController.h"
#import "KRUrlCache.h"
#import "MMDrawerController.h"

@implementation KRAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    UIColor *appColor = [[KRConfigStore sharedStore] appUIColor];
    
    KRNewsListController *hc = [[KRNewsListController alloc] init];
    UINavigationController* nhc = [[UINavigationController alloc] initWithRootViewController:hc];
    nhc.delegate = self;    
    nhc.navigationBar.tintColor = appColor;
    nhc.toolbar.tintColor = appColor;
    
    KRBookmarkViewController *bc = [[KRBookmarkViewController alloc] init];
    UINavigationController* nbc = [[UINavigationController alloc] initWithRootViewController:bc];
    nbc.delegate = self;
    nbc.navigationBar.tintColor = appColor;
    nbc.toolbar.tintColor = appColor;
    
    KRSettingViewController *sc = [[KRSettingViewController alloc] init];    
    UINavigationController *nsc = [[UINavigationController alloc] initWithRootViewController:sc];
    nsc.delegate = self;    
    nsc.navigationBar.tintColor = appColor;
    nsc.toolbar.tintColor = appColor;
    
/*
    MMDrawerController * drawerController = [[MMDrawerController alloc]
                                             initWithCenterViewController:nhc
                                             leftDrawerViewController:nsc
                                             rightDrawerViewController:nbc];
    [drawerController setMaximumRightDrawerWidth:[drawerController maximumLeftDrawerWidth]];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
*/
    [[self window] setRootViewController:nhc];
    
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], UITextAttributeTextColor,
      [UIFont fontWithName:APP_FONT_BOLD size:18], UITextAttributeFont,nil]];

    [NSURLCache setSharedURLCache:[[KRUrlCache alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:@"themeChanged"
                                               object:nil];

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //NSLog(@"Available fonts: %@", [UIFont familyNames]);
    
    return YES;
}

- (void)themeChanged:(NSNotification *)notification
{
    UIColor* uiColor = [[KRConfigStore sharedStore] appUIColor];
    UINavigationController *nsc = (UINavigationController *)[[self window] rootViewController];
    nsc.navigationBar.tintColor = uiColor;
    nsc.toolbar.tintColor = uiColor;
}

- (void)navigationController:(UINavigationController *)navController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController respondsToSelector:@selector(willAppearIn:)])
        [viewController performSelector:@selector(willAppearIn:) withObject:navController];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[KRConfigStore sharedStore] save];
    int numbOfItems = [[KRConfigStore sharedStore] itemCount];
    [[KRNewsStore sharedStore] saveItems: numbOfItems];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"Application activated");
    int maxNewsId = [[KRNewsStore sharedStore] maxNewsId];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[KRNewsStore sharedStore] loadNews:0 to:maxNewsId max:100 appendToTop:YES force:NO withHandler:^(NSArray *newsArray, NSError *error) {
        if(newsArray && [newsArray count]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"storeUpdated" object:[KRNewsStore sharedStore]];
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
    NSLog(@"application terminated");
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WenxueCityNews" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"WenxueCityNews.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)nibNameForClass:(Class)class
{
    if(IS_IPHONE && IS_IPHONE_5)
    {
        return [NSString stringWithFormat:@"%@%@", NSStringFromClass(class), @"~iphone_ext"];
    }
    else if(IS_IPHONE)
    {
        return [NSString stringWithFormat:@"%@%@", NSStringFromClass(class), @"~iphone"];
    }
    else
    {
        return [NSString stringWithFormat:@"%@%@", NSStringFromClass(class), @"~ipad"];
    }
}

@end
