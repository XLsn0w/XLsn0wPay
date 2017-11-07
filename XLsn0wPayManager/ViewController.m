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
#import "QRCodeImage.h"
#import "QRCoder.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *qrcode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    QRCodeImage *qrCodeImage = [QRCodeImage codeImageWithString:@"https://github.com/xlsn0w"
                                                           size:200
                                                          color:[UIColor blackColor]
                                                           icon:[UIImage imageNamed:@"XLsn0w"]
                                                      iconWidth:50];
    UIImageView *qrImageView = [[UIImageView alloc] initWithImage:qrCodeImage];
    qrImageView.center = self.view.center;
//    [self.view addSubview:qrImageView];
    
    
    
    UIImage *QRImage = [QRCoder imageWithQRMessage:@"https://github.com/xlsn0w"
                                            headImage:[UIImage imageNamed:@"XLsn0w"]
                                 inputCorrectionLevel:LOW
                                           sideLength:self.qrcode.bounds.size.width];
    
    self.qrcode.image = QRImage;
}

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


- (IBAction)alipay:(id)sender {
    ///拼接订单信息并且签名后的字符串
    ///实际项目里这段签名字符串是从服务器后台获取
    NSString *orderMessage = @"app_id=2015052600090779&biz_content=%7B%22timeout_express%22%3A%2230m%22%2C%22seller_id%22%3A%22%22%2C%22product_code%22%3A%22QUICK_MSECURITY_PAY%22%2C%22total_amount%22%3A%220.02%22%2C%22subject%22%3A%221%22%2C%22body%22%3A%22%E6%88%91%E6%98%AF%E6%B5%8B%E8%AF%95%E6%95%B0%E6%8D%AE%22%2C%22out_trade_no%22%3A%22314VYGIAGG7ZOYY%22%7D&charset=utf-8&method=alipay.trade.app.pay&sign_type=RSA&timestamp=2016-08-15%2012%3A12%3A15&version=1.0&sign=MsbylYkCzlfYLy9PeRwUUIg9nZPeN9SfXPNavUCroGKR5Kqvx0nEnd3eRmKxJuthNUx4ERCXe552EV9PfwexqW%2B1wbKOdYtDIb4%2B7PL3Pc94RZL0zKaWcaY3tSL89%2FuAVUsQuFqEJdhIukuKygrXucvejOUgTCfoUdwTi7z%2BZzQ%3D";

    
    [XLsn0wPayManager xlsn0wPayWithOrder:orderMessage callBack:^(XLsn0wPayResult payResult, NSString *errorMessage) {
        NSLog(@"errCode = %zd,errStr = %@",payResult, errorMessage);
    }];
}

- (NSString *)generateTradeNO {
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}


- (NSString *)jumpToBizPay {
    
    
    
    //============================================================
    /**
     *  @author Clarence
     *
     *  来自微信文档数据
     */
    //============================================================
    NSString *urlString   = @"http://wxpay.weixin.qq.com/pub_v2/app/app_pay.php?plat=ios";
    //解析服务端返回json数据
    NSError *error;
    //加载一个NSURL对象
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    //将请求的url数据放到NSData对象中
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if ( response != nil) {
        NSMutableDictionary *dict = NULL;
        //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
        dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
        
        NSLog(@"url:%@",urlString);
        if(dict != nil){
            NSMutableString *retcode = [dict objectForKey:@"retcode"];
            if (retcode.intValue == 0){
                NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
                
                //调起微信支付
                PayReq* req             = [[PayReq alloc] init];
                req.partnerId           = [dict objectForKey:@"partnerid"];
                req.prepayId            = [dict objectForKey:@"prepayid"];
                req.nonceStr            = [dict objectForKey:@"noncestr"];
                req.timeStamp           = stamp.intValue;
                req.package             = [dict objectForKey:@"package"];
                req.sign                = [dict objectForKey:@"sign"];
                
                
                [XLsn0wPayManager xlsn0wPayWithOrder:req callBack:^(XLsn0wPayResult payResult, NSString *errorMessage) {
                    NSLog(@"errCode = %zd,errStr = %@",payResult, errorMessage);
                }];
                //日志输出
                NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
                return @"";
            }else{
                return [dict objectForKey:@"retmsg"];
            }
        }else{
            return @"服务器返回错误，未获取到json对象";
        }
    }else{
        return @"服务器返回错误";
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
