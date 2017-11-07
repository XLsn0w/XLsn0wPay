

#import "QRCoder.h"

@implementation QRCoder

+ (UIImage *)imageWithQRMessage:(NSString *)message headImage:(UIImage *)headImage inputCorrectionLevel:(CORRECTIONLEVEL)correctionLevel sideLength:(CGFloat)sideLength {
    
    // 准备滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    //  设置默认值
    [filter setDefaults];
    
    //  生成要显示的字符串数据
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    switch (correctionLevel) {
        case HIGH:
            [filter setValue:@"H" forKeyPath:@"inputCorrectionLevel"];
            break;
        case MEDIUM:
            [filter setValue:@"Q" forKeyPath:@"inputCorrectionLevel"];
            break;
        case LOW:
            [filter setValue:@"M" forKeyPath:@"inputCorrectionLevel"];
            break;
            
        default:
            break;
    }
    
    // 输出
    CIImage *coreImage = [filter outputImage];
    
    //  1. 要把图像无损放大
    UIImage *QRImage = [self imageWithCIImage:coreImage andSize:CGSizeMake(sideLength, sideLength)];
    
    //  2. 要合成头像
    CGSize headSize = CGSizeMake(sideLength * 0.30, sideLength * 0.30);
    
    UIImage *QRCardImage = [self imageWithBackgroundImage:QRImage centerImage:headImage centerImageSize:headSize];
    
    return QRCardImage;
    
}

//  将CIImage转换成指定大小的UIImage
+ (UIImage *)imageWithCIImage:(CIImage *)coreImage andSize:(CGSize)size {
    
    //1. CIImage 转换成 CGImage(CGImageRef)
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef originCGImage = [context createCGImage:coreImage fromRect:coreImage.extent];
    
    //2. 创建一个图形上下文 Bitmap
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, cs, kCGImageAlphaNone);
    
    //3. 将CGImage图片渲染到新的图形上下文中
    CGContextSetInterpolationQuality(bitmapCtx, kCGInterpolationNone);
    
    // 在图形上下文中把图片画出来
    CGRect newRect = CGRectMake(0, 0, size.width, size.height);
    
    CGContextDrawImage(bitmapCtx, newRect, originCGImage);
    
    //4. 取图像
    CGImageRef QRImage = CGBitmapContextCreateImage(bitmapCtx);
    
    // 释放
    CGColorSpaceRelease(cs);
    
    CGImageRelease(originCGImage);
    
    CGContextRelease(bitmapCtx);
    
    
    return [UIImage imageWithCGImage:QRImage];
    
}

+ (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage centerImage:(UIImage *)centerImage centerImageSize:(CGSize)centerSize{
    
    // 开始图形上下文
    UIGraphicsBeginImageContext(backgroundImage.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    
    // 先画背景
    [backgroundImage drawAtPoint:CGPointZero];
    
    // 再画头像
    CGFloat headW = centerSize.width;
    CGFloat headH = centerSize.height;
    CGFloat headX = (backgroundImage.size.width - headW) * 0.5;
    CGFloat headY = (backgroundImage.size.height - headH) * 0.5;
    
    [centerImage drawInRect:CGRectMake(headX, headY, headW, headH)];
    
    // 取图像
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

@end
