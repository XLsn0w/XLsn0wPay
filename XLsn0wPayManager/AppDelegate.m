//
//  AppDelegate.m
//  XLsn0wPayManager
//
//  Created by XLsn0w on 2017/4/21.
//  Copyright © 2017年 XLsn0w. All rights reserved.
//

#import "AppDelegate.h"
#import "PayPalMobile.h"
#import "UPPaymentControl.h"
#import <CommonCrypto/CommonDigest.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    //注册微信支付&支付宝SDK init
    [XLsn0wPayManager registerWeChatAppIDWithAlipayURLSchemes];
    
    ///Paypal init
    [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction : @"你的真实交易模式ClientID",
                                                              PayPalEnvironmentSandbox : @"你的测试模式ClientID"}];
    
    return YES;
}

#pragma mark - 微信支付&支付宝SDK
//最老的版本，最好也写上
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [XLsn0wPayManager handleOpenURL:url];
}

//iOS 9.0 之前 会调用
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        
        if([code isEqualToString:@"success"]) {
            
            //如果想对结果数据验签，可使用下面这段代码，但建议不验签，直接去商户后台查询交易结果
            if(data != nil){
                //数据从NSDictionary转换为NSString
                NSData *signData = [NSJSONSerialization dataWithJSONObject:data
                                                                   options:0
                                                                     error:nil];
                NSString *sign = [[NSString alloc] initWithData:signData encoding:NSUTF8StringEncoding];
                
                //此处的verify建议送去商户后台做验签，如要放在手机端验，则代码必须支持更新证书
                if([self verify:sign]) {
                    //验签成功
                }
                else {
                    //验签失败
                }
            }
            
            //结果code为成功时，去商户后台查询一下确保交易是成功的再展示成功
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
        }
    }];
    
    return YES;
    return [XLsn0wPayManager handleOpenURL:url];
}

//iOS 9.0 以上（包括iOS9.0）
- (BOOL)application:(UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *,id> *)options {
    
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        
        if([code isEqualToString:@"success"]) {
            
            //如果想对结果数据验签，可使用下面这段代码，但建议不验签，直接去商户后台查询交易结果
            if(data != nil){
                //数据从NSDictionary转换为NSString
                NSData *signData = [NSJSONSerialization dataWithJSONObject:data
                                                                   options:0
                                                                     error:nil];
                NSString *sign = [[NSString alloc] initWithData:signData encoding:NSUTF8StringEncoding];
                
                //此处的verify建议送去商户后台做验签，如要放在手机端验，则代码必须支持更新证书
                if([self verify:sign]) {
                    //验签成功
                }
                else {
                    //验签失败
                }
            }
            
            //结果code为成功时，去商户后台查询一下确保交易是成功的再展示成功
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
        }
    }];
    
    return YES;
    
    return [XLsn0wPayManager handleOpenURL:url];
}

#pragma mark - Union Pay

- (NSString *) readPublicKey:(NSString *) keyName
{
    if (keyName == nil || [keyName isEqualToString:@""]) return nil;
    
    NSMutableArray *filenameChunks = [[keyName componentsSeparatedByString:@"."] mutableCopy];
    NSString *extension = filenameChunks[[filenameChunks count] - 1];
    [filenameChunks removeLastObject]; // remove the extension
    NSString *filename = [filenameChunks componentsJoinedByString:@"."]; // reconstruct the filename with no extension
    
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:filename ofType:extension];
    
    NSString *keyStr = [NSString stringWithContentsOfFile:keyPath encoding:NSUTF8StringEncoding error:nil];
    
    return keyStr;
}

-(BOOL) verify:(NSString *) resultStr {
    
    //此处的verify，商户需送去商户后台做验签
    return NO;
}

- (NSString*)sha1:(NSString *)string
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_CTX context;
    NSString *description;
    
    CC_SHA1_Init(&context);
    
    memset(digest, 0, sizeof(digest));
    
    description = @"";
    
    
    if (string == nil)
    {
        return nil;
    }
    
    // Convert the given 'NSString *' to 'const char *'.
    const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Check if the conversion has succeeded.
    if (str == NULL)
    {
        return nil;
    }
    
    // Get the length of the C-string.
    int len = (int)strlen(str);
    
    if (len == 0)
    {
        return nil;
    }
    
    
    if (str == NULL)
    {
        return nil;
    }
    
    CC_SHA1_Update(&context, str, len);
    
    CC_SHA1_Final(digest, &context);
    
    description = [NSString stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                   digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                   digest[ 8], digest[ 9], digest[10], digest[11],
                   digest[12], digest[13], digest[14], digest[15],
                   digest[16], digest[17], digest[18], digest[19]];
    
    return description;
}


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
