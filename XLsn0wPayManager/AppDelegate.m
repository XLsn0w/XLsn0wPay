//
//  AppDelegate.m
//  XLsn0wPayManager
//
//  Created by XLsn0w on 2017/4/21.
//  Copyright © 2017年 XLsn0w. All rights reserved.
//

#import "AppDelegate.h"
#import "PayPalMobile.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    //注册微信支付&支付宝SDK
    [XLsn0wPayManager registerWeChatAppIDWithAlipayURLSchemes];
    
    [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction : @"你的真实交易模式ClientID",PayPalEnvironmentSandbox : @"你的测试模式ClientID"}];
    
  
    
    
    return YES;
}

#pragma mark - 微信支付&支付宝SDK
//最老的版本，最好也写上
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [XLsn0wPayManager handleOpenURL:url];
}

//iOS 9.0 之前 会调用
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [XLsn0wPayManager handleOpenURL:url];
}

//iOS 9.0 以上（包括iOS9.0）
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options{
    
    return [XLsn0wPayManager handleOpenURL:url];
}

#pragma mark - 

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
