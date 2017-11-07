
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NSUInteger CORRECTIONLEVEL;

NS_ENUM(CORRECTIONLEVEL) {
    HIGH = 1,
    MEDIUM = 2,
    LOW = 3
};
    
@interface QRCodeImager : UIImage


/**
 生成默认黑色二维码

 @param message <#message description#>
 @param headImage <#headImage description#>
 @param correctionLevel <#correctionLevel description#>
 @param sideLength <#sideLength description#>
 @return <#return value description#>
 */
+ (UIImage *)imageWithQRMessage:(NSString *)message headImage:(UIImage *)headImage inputCorrectionLevel:(CORRECTIONLEVEL)correctionLevel sideLength:(CGFloat)sideLength;

/**
 *  1.生成一个二维码
 *
 *  @param string 字符串
 *  @param width  二维码宽度
 *
 *  @return <#return value description#>
 */
+ (QRCodeImager *_Nonnull)codeImageWithString:(NSString *_Nullable)string
                                        size:(CGFloat)width;

/**
 *  2.生成一个二维码
 *
 *  @param string 字符串
 *  @param width  二维码宽度
 *  @param color  二维码颜色
 *
 *  @return <#return value description#>
 */
+ (QRCodeImager *_Nonnull)codeImageWithString:(NSString *_Nullable)string
                                        size:(CGFloat)width
                                       color:(UIColor *_Nullable)color;
/**
 *  3.生成一个二维码
 *
 *  @param string    字符串
 *  @param width     二维码宽度
 *  @param color     二维码颜色
 *  @param icon      头像
 *  @param iconWidth 头像宽度，建议宽度小于二维码宽度的1/4
 *
 *  @return <#return value description#>
 */
+ (QRCodeImager *_Nonnull)codeImageWithString:(NSString *_Nullable)string
                                        size:(CGFloat)width
                                       color:(UIColor *_Nullable)color
                                        icon:(UIImage *_Nullable)icon
                                   iconWidth:(CGFloat)iconWidth;

@end
