
#import "XLsn0wPay.h"

/**
 *  此处必须保证在Info.plist 中的 URL Types 的 Identifier 对应一致
 */
#define WeChat_URLTypesIdentifier @"wechatpay"
#define Alipay_URLTypesIdentifier @"alipay"

// 回调url地址为空
#define callBackURL @"url地址不能为空！"

// 订单信息为空字符串或者nil
#define orderMessage_nil @"订单信息不能为空！"
// 没添加 URL Types
#define addURLTypes @"请先在Info.plist 添加 URLTypes"
// 添加了 URL Types 但信息不全
#define addURLSchemes(URLTypes) [NSString stringWithFormat:@"请先在Info.plist对应的 URLTypes 添加 %@ 对应的 URL Schemes", URLTypes]

@interface XLsn0wPay () <WXApiDelegate>

// 支付结果缓存回调
@property (nonatomic, copy) XLsn0wPayResultCallBack callBack;
// 缓存appScheme
@property (nonatomic, strong)NSMutableDictionary *appSchemeDict;

@end

@implementation XLsn0wPay


+ (instancetype)defaultManager {
    static XLsn0wPay *xlsn0wPay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xlsn0wPay = [[self alloc] init];
    });
    return xlsn0wPay;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    
    NSAssert(url, callBackURL);
    if ([url.host isEqualToString:@"pay"]) {// 微信
        return [WXApi handleOpenURL:url delegate:self];
    }
    else if ([url.host isEqualToString:@"safepay"]) {// 支付宝
        // 支付跳转支付宝钱包进行支付，处理支付结果(在app被杀模式下，通过这个方法获取支付结果）
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSString *resultStatus = resultDic[@"resultStatus"];
            NSString *errStr = resultDic[@"memo"];
            XLsn0wPayResult errorCode = XLsn0wPayResultSuccess;
            switch (resultStatus.integerValue) {
                case 9000:// 成功
                    errorCode = XLsn0wPayResultSuccess;
                    break;
                case 6001:// 取消
                    errorCode = XLsn0wPayResultCancel;
                    break;
                default:
                    errorCode = XLsn0wPayResultFailure;
                    break;
            }
            if (XLsn0wPayManager.callBack) {
                [XLsn0wPay defaultManager].callBack(errorCode,errStr);
            }
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
        return YES;
    }
    else{
        return NO;
    }
}

- (void)registerWeChatWithAlipay {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *urlTypes = dict[@"CFBundleURLTypes"];
    NSAssert(urlTypes, addURLTypes);
    
    for (NSDictionary *urlTypeDict in urlTypes) {
        NSString *urlName = urlTypeDict[@"CFBundleURLName"];
        NSArray *urlSchemes = urlTypeDict[@"CFBundleURLSchemes"];
        NSAssert(urlSchemes.count, addURLSchemes(urlName));
        // 一般对应只有一个
        NSString *urlScheme = urlSchemes.lastObject;
        if ([urlName isEqualToString:WeChat_URLTypesIdentifier]) {
            [self.appSchemeDict setValue:urlScheme forKey:WeChat_URLTypesIdentifier];
            // 注册微信
            [WXApi registerApp:urlScheme];
        }
        else if ([urlName isEqualToString:Alipay_URLTypesIdentifier]){
            // 保存支付宝scheme，以便发起支付使用
            [self.appSchemeDict setValue:urlScheme forKey:Alipay_URLTypesIdentifier];
        }
        else{
            
        }
    }
}

- (void)xlsn0wPayWithOrder:(id)order callBack:(XLsn0wPayResultCallBack)callBack {
    NSAssert(order, orderMessage_nil);
    // 缓存block
    self.callBack = callBack;
    // 发起支付
    if ([order isKindOfClass:[PayReq class]]) {
        // 微信
        NSAssert(self.appSchemeDict[WeChat_URLTypesIdentifier], addURLSchemes(WeChat_URLTypesIdentifier));
        
        [WXApi sendReq:(PayReq *)order];
    }
    else if ([order isKindOfClass:[NSString class]]){
        // 支付宝
        NSAssert(![order isEqualToString:@""], orderMessage_nil);
        NSAssert(self.appSchemeDict[Alipay_URLTypesIdentifier], addURLSchemes(Alipay_URLTypesIdentifier));
        [[AlipaySDK defaultService] payOrder:(NSString *)order fromScheme:self.appSchemeDict[Alipay_URLTypesIdentifier] callback:^(NSDictionary *resultDic){
            NSString *resultStatus = resultDic[@"resultStatus"];
            NSString *errStr = resultDic[@"memo"];
            XLsn0wPayResult errorCode = XLsn0wPayResultSuccess;
            switch (resultStatus.integerValue) {
                case 9000:// 成功
                    errorCode = XLsn0wPayResultSuccess;
                    break;
                case 6001:// 取消
                    errorCode = XLsn0wPayResultCancel;
                    break;
                default:
                    errorCode = XLsn0wPayResultFailure;
                    break;
            }
            if (XLsn0wPayManager.callBack) {
                XLsn0wPayManager.callBack(errorCode,errStr);
            }
        }];
    }
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    // 判断支付类型
    if([resp isKindOfClass:[PayResp class]]){
        //支付回调
        XLsn0wPayResult errorCode = XLsn0wPayResultSuccess;
        NSString *errStr = resp.errStr;
        switch (resp.errCode) {
            case 0:
                errorCode = XLsn0wPayResultSuccess;
                errStr = @"订单支付成功";
                break;
            case -1:
                errorCode = XLsn0wPayResultFailure;
                errStr = resp.errStr;
                break;
            case -2:
                errorCode = XLsn0wPayResultCancel;
                errStr = @"用户中途取消";
                break;
            default:
                errorCode = XLsn0wPayResultFailure;
                errStr = resp.errStr;
                break;
        }
        if (self.callBack) {
            self.callBack(errorCode,errStr);
        }
    }
}

#pragma mark -- Setter & Getter

- (NSMutableDictionary *)appSchemeDict{
    if (_appSchemeDict == nil) {
        _appSchemeDict = [NSMutableDictionary dictionary];
    }
    return _appSchemeDict;
}

@end
