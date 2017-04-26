

#import <Foundation/Foundation.h>
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>

#define XLsn0wPayManager [XLsn0wPay defaultManager]

/**
 *  回调状态码
 */
typedef NS_ENUM(NSInteger, XLsn0wPayResult){
    XLsn0wPayResultSuccess,// 成功
    XLsn0wPayResultFailure,// 失败
    XLsn0wPayResultCancel  // 取消
};

typedef void(^XLsn0wPayResultCallBack)(XLsn0wPayResult payResult, NSString *errorMessage);

@interface XLsn0wPay : NSObject

+ (instancetype)defaultManager;
/**
 *  处理跳转url，回到应用，需要在delegate中实现
 */
- (BOOL)handleOpenURL:(NSURL *)url;
/**
 *  注册App，需要在 didFinishLaunchingWithOptions 中调用
 */
- (void)registerWeChatWithAlipay;

/**
 *  @author gitKong
 *
 *  发起支付
 *
 * @param order 传入订单信息,如果是字符串，则对应是跳转支付宝支付；如果传入PayReq 对象，这跳转微信支付,注意，不能传入空字符串或者nil
 * @param callBack     回调，有返回状态信息
 */
- (void)xlsn0wPayWithOrder:(id)order callBack:(XLsn0wPayResultCallBack)callBack;

@end
