
#import "PayViewController.h"
#import "Order.h"
#import "APAuthV2Info.h"
#import "RSADataSigner.h"
#import <AlipaySDK/AlipaySDK.h>

#import "UPPaymentControl.h"

#import "PayPalMobile.h"

@interface PayViewController () <PayPalPaymentDelegate>

@property(nonatomic, strong) PayPalConfiguration *payPalConfig;

@end

@implementation PayViewController

/// 真实交易环境-也就是上架之后的环境
extern NSString * _Nonnull const PayPalEnvironmentProduction;
/// 模拟环境-也就是沙盒环境
extern NSString * _Nonnull const PayPalEnvironmentSandbox;
/// 无网络连接环境-具体用处，咳咳，自行摸索
extern NSString * _Nonnull const PayPalEnvironmentNoNetwork;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentSandbox];
    [self initPayPalConfiguration];
}

/**--->实际项目代码
NSString *url = [NSString stringWithFormat:@"%@/api/parkOrder/payParkCost", kHTTP];
NSLog(@"微信支付___URL=== %@", url);
[XLNetworkManager POST:url token:nil params:@{@"platform":@(2), @"orderId":@(orderId)} success:^(NSURLSessionDataTask *task, NSDictionary *JSONDictionary, NSString *JSONString) {
    NSLog(@"%@", JSONString);
    
    NSData *JSONData = [[JSONDictionary objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *JSONDic = [NSJSONSerialization JSONObjectWithData:JSONData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&error];
    NSLog(@"微信支付args=== %@", JSONDic);
    
    PayReq *req = [[PayReq alloc] init];
    req.openID = [JSONDic objectForKey:@"appid"];//AppID
    req.partnerId = [JSONDic objectForKey:@"partnerid"];
    req.prepayId = [JSONDic objectForKey:@"prepayid"];
    req.nonceStr = [JSONDic objectForKey:@"noncestr"];
    req.timeStamp = [[JSONDic objectForKey:@"timestamp"] intValue];
    req.package = [JSONDic objectForKey:@"package"];
    req.sign = [JSONDic objectForKey:@"sign"];
    
    if ([WXApi isWXAppInstalled] == YES) {
        [WXApi sendReq:req];
    } else {
        [XLsn0wShow showCenterWithText:@"微信未安装"];
    }
    
} failure:^(NSURLSessionDataTask *task, NSError *error, NSInteger statusCode, NSString *requestFailedReason) {
    NSLog(@"error= %@", error);
}];
*/

- (IBAction)wechatpay:(id)sender {
    ///实际项目里面partnerId prepayId package nonceStr timeStamp sign 都是从服务器后台获取赋值给req的属性即可
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = @"10000100";
    req.prepayId= @"1101000000140415649af9fc314aa427";
    req.package = @"Sign=WXPay";
    req.nonceStr= @"a462b76e7436e98e0ed6e13c64b4fd1c";
    req.timeStamp= @"1397527777".intValue;
    req.sign= @"582282D72DD2B03AD892830965F428CB16E7A256";

    [XLsn0wPayManager xlsn0wPayWithOrder:req callBack:^(XLsn0wPayResult payResult, NSString *errorMessage) {
        NSLog(@"errCode = %zd,errStr = %@",payResult, errorMessage);
    }];
}

/*--->实际项目代码
NSString *url = [NSString stringWithFormat:@"%@/api/parkOrder/getAlipayOrderInfo", kHTTP];
NSLog(@"支付宝___URL=== %@", url);
[XLNetworkManager POST:url token:nil params:@{@"platform":@(2), @"orderId":@(orderId)} success:^(NSURLSessionDataTask *task, NSDictionary *JSONDictionary, NSString *JSONString) {
    NSLog(@"%@", JSONString);
    
    //将签名成功字符串格式化为订单字符串
    NSString *orderSignString = [JSONDictionary objectForKey:@"data"];
    
    NSString *AppID = @"你的支付宝商户AppID";
    if (AppID.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少appId"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    //调用支付的app注册在info.plist中对应的URL Schemes
    NSString *URLSchemes = AppID;
    
    //如果加签成功，则继续执行支付
    if (orderSignString != nil) {
        
        //调用支付结果开始支付
        //服务器 把订单签名后的字符串穿过来 然后在info URL Schemes里面配置统一的字符串
        //然后执行支付宝的 支付方法 在回调里面写支付结果的代码
        [[AlipaySDK defaultService] payOrder:orderSignString fromScheme:URLSchemes callback:^(NSDictionary *resultDic) {
            NSLog(@"resultDic=== %@", resultDic);
            NSLog(@"memo=== %@", resultDic[@"memo"]);
            NSLog(@"result=== %@", resultDic[@"result"]);
            NSLog(@"resultStatus=== %@", resultDic[@"resultStatus"]);
            NSInteger result = 0;
            NSString *message = @"";
            NSString *resultStatus = resultDic[@"resultStatus"];
            
            switch (resultStatus.integerValue) {
                    
                case 9000:    //支付成功
                    result = 0;
                    message = @"支付成功";
                    break;
                    
                case 8000:
                    result = 10;
                    message = @"正在处理中，支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态";
                    break;
                    
                case 4000:
                    result = 10;
                    message = @"订单支付失败";
                    break;
                    
                case 5000:
                    result = 10;
                    message = @"重复请求";
                    break;
                    
                case 6001:
                    result = 10;
                    message = @"用户中途取消";
                    break;
                    
                    
                case 6002:
                    result = 10;
                    message = @"网络连接出错";
                    break;
                    
                case 6004:
                    result = 10;
                    message = @"支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态";
                    break;
                    
                default:
                    result = 10;
                    message = @"支付失败";
                    break;
            }
            
            NSDictionary *messageAsDictionary = @{@"result":@(result), @"message":message};
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:messageAsDictionary]
                                        callbackId:callbackId];
        }];
    }
    
} failure:^(NSURLSessionDataTask *task, NSError *error, NSInteger statusCode, NSString *requestFailedReason) {
    NSLog(@"error= %@", error);
}];
*/
- (IBAction)alipay:(id)sender {
    ///拼接订单信息并且签名后的字符串
    ///实际项目里这段签名字符串是从服务器后台获取
    NSString *orderMessage = @"app_id=2015052600090779&biz_content=%7B%22timeout_express%22%3A%2230m%22%2C%22seller_id%22%3A%22%22%2C%22product_code%22%3A%22QUICK_MSECURITY_PAY%22%2C%22total_amount%22%3A%220.02%22%2C%22subject%22%3A%221%22%2C%22body%22%3A%22%E6%88%91%E6%98%AF%E6%B5%8B%E8%AF%95%E6%95%B0%E6%8D%AE%22%2C%22out_trade_no%22%3A%22314VYGIAGG7ZOYY%22%7D&charset=utf-8&method=alipay.trade.app.pay&sign_type=RSA&timestamp=2016-08-15%2012%3A12%3A15&version=1.0&sign=MsbylYkCzlfYLy9PeRwUUIg9nZPeN9SfXPNavUCroGKR5Kqvx0nEnd3eRmKxJuthNUx4ERCXe552EV9PfwexqW%2B1wbKOdYtDIb4%2B7PL3Pc94RZL0zKaWcaY3tSL89%2FuAVUsQuFqEJdhIukuKygrXucvejOUgTCfoUdwTi7z%2BZzQ%3D";

    
    [XLsn0wPayManager xlsn0wPayWithOrder:orderMessage callBack:^(XLsn0wPayResult payResult, NSString *errorMessage) {
        NSLog(@"errCode = %zd,errStr = %@",payResult, errorMessage);
    }];
}

///银联支付

/**招商银行借记卡：6226090000000048     手机号：18100000000     密码：111101     短信验证码：123456（先点获取验证码之后再输入）     证件类型：01身份证     证件号：510265790128303     姓名：张三
 
 * ViewController必须支持Objective-C++ 即.mm
 */
- (IBAction)unionpay:(id)sender {
    /**
     *  支付接口
     *
     *  @param tn             订单信息
     *  @param schemeStr      调用支付的app注册在info.plist中的scheme
     *  @param mode           支付环境
     *  @param viewController 启动支付控件的viewController
     *  @return 返回成功失败
     */

    [[UPPaymentControl defaultControl] startPay:@"989657791968367788701"
                                     fromScheme:@"unionpayScheme"
                                           mode:@"01"
                                 viewController:self];
}

- (void)initPayPalConfiguration {
    //是否接受信用卡
    _payPalConfig.acceptCreditCards = NO;
    
    //商家名称
    _payPalConfig.merchantName = @"商家名";
    
    //商家隐私协议网址和用户授权网址-说实话这个没用到
    _payPalConfig.merchantPrivacyPolicyURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/privacy-full"];
    _payPalConfig.merchantUserAgreementURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/useragreement-full"];
    

    //paypal账号下的地址信息
    _payPalConfig.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
    
    //配置语言环境
    _payPalConfig.languageOrLocale = [NSLocale preferredLanguages][0];
    
}

///在viewDidLoad里面初始化PayPalConfiguration；
- (void)initPayPalConfig {
    self.payPalConfig = [[PayPalConfiguration alloc] init];
    self.payPalConfig.merchantName = @"xx科技有限公司";//公司名称
    self.payPalConfig.acceptCreditCards = NO;
    self.payPalConfig.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
}

///支付页面的viewWillAppear里面代码，上线的时候注意修改；
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[self SetNavigationStyle:NO];
#warning ----------------上线的时候修改成正式环境----------------
    // 开始与测试环境工作！当你准备好时，切换到paypalenvironmentproduction。
    [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentNoNetwork];
}

///Paypal支付
- (IBAction)paypal:(id)sender {
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    
    //订单总额
    payment.amount = [NSDecimalNumber decimalNumberWithString:@"100"];
    
    //货币类型-RMB是没用的
    payment.currencyCode = @"USD";
    
    //订单描述
    payment.shortDescription = @"Hipster clothing";
    
    //生成paypal控制器，并模态出来(push也行)
    //将之前生成的订单信息和paypal配置传进来，并设置订单VC为代理
    PayPalPaymentViewController *paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment
                                                                                                configuration:self.payPalConfig
                                                                                                     delegate:self];
    //模态展示
    [self presentViewController:paymentViewController animated:YES completion:nil];
}

///调用PayPal支付界面
//amount:金额
//currencyCode:获取单位 比如：USD
//shortDescription:商品标题 简短描述
- (void)PayPalWithAmount:(NSString *)amount currencyCode:(NSString *)currencyCode shortDescription:(NSString *)shortDescription{
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = [[NSDecimalNumber alloc] initWithString:@"100"];
    payment.currencyCode = currencyCode;
    payment.shortDescription = @"购买商品购买商品购买商品";
    payment.items = nil;  // if not including multiple items, then leave payment.items as nil
    payment.paymentDetails = nil; // if not including payment details, then leave payment.paymentDetails as nil
    payment.intent = PayPalPaymentIntentSale;
    if (!payment.processable) {
        NSLog(@"-------------");
    }
    
    PayPalPaymentViewController *paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment configuration:self.payPalConfig delegate:self];
    [self presentViewController:paymentViewController animated:YES completion:nil];
}


///PayPalPaymentDelegate代理方法，支付成功和失败；
#pragma mark - PayPalPaymentDelegate methods
//订单支付完成后回调此方法
- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    [self verifyCompletedPayment:completedPayment];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//用户取消支付回调此方法
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    ///[self SHOWPrompttext:@"支付有误,请稍后再试"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

///给你的服务器发送支付成功、支付失败等信息请求
- (void)verifyCompletedPayment:(PayPalPayment *)completedPayment {
    // Send the entire confirmation dictionary
    NSData *confirmation = [NSJSONSerialization dataWithJSONObject:completedPayment.confirmation options:0 error:nil];
    [self setCartOrderNotifyWith:@"_order_id"];
    NSLog(@"completedPayment.confirmation= %@", completedPayment.confirmation);
    NSLog(@"confirmation= %@",confirmation);
}

- (void)setCartOrderNotifyWith:(NSString *)order_ids {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
