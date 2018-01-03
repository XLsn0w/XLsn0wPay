//
//  ViewController.m
//  XLsn0wPayManager
//
//  Created by XLsn0w on 2017/4/21.
//  Copyright © 2017年 XLsn0w. All rights reserved.
//

#import "ViewController.h"
#import "Order.h"
#import "APAuthV2Info.h"
#import "RSADataSigner.h"
#import <AlipaySDK/AlipaySDK.h>
#import "QRCodeImager.h"

#import "UPPaymentControl.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *qrcode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor grayColor];
    
    
    QRCodeImager *qrCodeImage = [QRCodeImager codeImageWithString:@"https://github.com/xlsn0w"
                                                           size:200
                                                          color:[UIColor blackColor]
                                                           icon:[UIImage imageNamed:@"XLsn0w"]
                                                      iconWidth:50];
    UIImageView *qrImageView = [[UIImageView alloc] initWithImage:qrCodeImage];
    qrImageView.center = self.view.center;
//    [self.view addSubview:qrImageView];
    
    
    
    UIImage *QRImage = [QRCodeImager imageWithQRMessage:@"https://github.com/xlsn0w"
                                            headImage:[UIImage imageNamed:@"XLsn0w"]
                                 inputCorrectionLevel:High
                                           sideLength:self.qrcode.bounds.size.width];
    
    self.qrcode.image = QRImage;
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

///Paypal支付
- (IBAction)paypal:(id)sender {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
