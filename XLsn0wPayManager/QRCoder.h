

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

typedef NSUInteger CORRECTIONLEVEL;

NS_ENUM(CORRECTIONLEVEL) {
    HIGH = 1,
    MEDIUM = 2,
    LOW = 3
};

@interface QRCoder : NSObject

+ (UIImage *)imageWithQRMessage:(NSString *)message headImage:(UIImage *)headImage inputCorrectionLevel:(CORRECTIONLEVEL)correctionLevel sideLength:(CGFloat)sideLength;

@end
