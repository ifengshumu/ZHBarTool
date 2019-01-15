//
//  ZHBarTool.m
//
//  Created by Lee on 2017/9/18.
//  Copyright © 2017年 leezhihua. All rights reserved.
//


#import "ZHBarTool.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

@interface ZHBarTool ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@end

static ZHBarTool *barTool = nil;
@implementation ZHBarTool

+ (instancetype)barTool {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        barTool = [[ZHBarTool alloc] init];
    });
    return barTool;
}

- (void)startScanBarWithScanRect:(CGRect)scanRect scanType:(ZHBarScanType)scanType layerView:(UIView *)layerView {
    //初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    //获取摄像设备
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    //添加输入流
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    //创建输出流
    self.output = [[AVCaptureMetadataOutput alloc] init];
    //设置代理在主线程里刷新(Tip:如果封装的类不是单利或者被属性全局引用，代理AVCaptureMetadataOutputObjectsDelegated不会被调用)
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //添加输出流
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    //设置扫码支持的编码格式，Tip:必须在添加输出流之后
    if ([self.output availableMetadataObjectTypes].count) {
        if (scanType == ZHBarScanTypeQRCode) {
            self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        } else if (scanType == ZHBarScanTypeBarCode) {
            self.output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
                                                AVMetadataObjectTypeEAN8Code,
                                                AVMetadataObjectTypeCode128Code];
        } else {
            self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,
                                                AVMetadataObjectTypeEAN13Code,
                                                AVMetadataObjectTypeEAN8Code,
                                                AVMetadataObjectTypeCode128Code];
        }
    }
    //设置有效的扫描区域，Tip：rectOfInterest是比值，默认为CGRectMake(0, 0, 1, 1)
    /* 手动计算
     计算为CGRectMake(y1/h, x1/w, h1/h, w1/w);
     y1,x1,h1,w1为扫描区域的frame，h,w是layer视图的宽高
     手动计算要在session运行前设置
     */
    
    /* 自动转换
     - (CGRect)metadataOutputRectOfInterestForRect:(CGRect)rectInLayerCoordinatesl;
     这个方法可以把扫描区域的frame转成rectOfInterest的坐标系
     这个方法必须在session运行后设置
     */
    
    //如果传入的scanArea的宽不大于1，说明是手动计算
    if (scanRect.size.width <= 1) {
        self.output.rectOfInterest = scanRect;
    }
    //创建相机渲染层
    self.layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.layer.frame = layerView.layer.bounds;
    [layerView.layer insertSublayer:self.layer atIndex:0];
    
    [ZHBarTool requestCameraAuthorizedResult:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.session startRunning];
                self.isAvailable = YES;
                self.scanInterval = self.scanInterval ? self.scanInterval : 2;
                //如果传入的scanArea的宽大于1，调用系统方法转换
                if (scanRect.size.width > 1) {
                    self.scanRect = scanRect;
                    CGRect rectOfInterest = [self.layer metadataOutputRectOfInterestForRect:scanRect];
                    self.output.rectOfInterest = rectOfInterest;
                }
            });
        } else {
            if ([self.delegate respondsToSelector:@selector(ZHBarAuthorizedCameraFailed)]) {
                [self.delegate ZHBarAuthorizedCameraFailed];
            }
            if (self.authorizedCameraFailed) {
                self.authorizedCameraFailed();
            }
        }
    }];
}

#pragma mark - 相机权限
+ (void)requestCameraAuthorizedResult:(void(^)(BOOL granted))result {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            result(granted);
        }];
    } else if (authStatus == AVAuthorizationStatusAuthorized){
        result(YES);
    } else {
        result(NO);
    }
}

#pragma mark - 代理
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (self.isAvailable) {
        if (metadataObjects.count > 0) {
            AVMetadataMachineReadableCodeObject *object = [metadataObjects objectAtIndex:0];
            ZHBarScanType type = object.type==AVMetadataObjectTypeQRCode?ZHBarScanTypeQRCode:ZHBarScanTypeBarCode;
            NSString *obj = [object stringValue];
            if (self.scanBarGetObject) {
                self.scanBarGetObject(obj,type);
            }
            if ([self.delegate respondsToSelector:@selector(ZHBarDidScanBarGetObject:barType:)]) {
                [self.delegate ZHBarDidScanBarGetObject:obj barType:type];
            }
            self.isAvailable = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.scanInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.isAvailable = YES;
            });
        }
    }
}

#pragma mark - 开启/关闭扫描
- (void)startScanning {
    if (self.session) {
        if (!self.session.isRunning) {
            [self.session startRunning];
            [self configRectOfInterest];
        }
    }else{
        NSAssert(self.session, @"请先初始化扫描工具");
    }
}

- (void)stopScanning {
    if (self.session) {
        if (self.session.isRunning) {
            [self.session stopRunning];
        }
    } else {
        NSAssert(self.session, @"请先初始化扫描工具");
    }
}
- (void)configRectOfInterest {
    if (self.scanRect.size.width > 1) {
        CGRect rectOfInterest = [self.layer metadataOutputRectOfInterestForRect:self.scanRect];
        self.output.rectOfInterest = rectOfInterest;
    }
}

#pragma mark - 手电筒
- (void)turnOnFlashlight {
    if (self.device.hasTorch && self.device.focusMode != AVCaptureTorchModeOn) {
        [self.device lockForConfiguration:nil];
        [self.device setTorchMode:AVCaptureTorchModeOn];
        [self.device unlockForConfiguration];
    }
}
- (void)turnOffFlashlight {
    if (self.device.hasTorch && self.device.focusMode != AVCaptureTorchModeOff) {
        [self.device lockForConfiguration:nil];
        [self.device setTorchMode:AVCaptureTorchModeOff];
        [self.device unlockForConfiguration];
    }
}
- (void)autoFlashlight {
    if (self.device.hasTorch && self.device.focusMode != AVCaptureTorchModeAuto) {
        [self.device lockForConfiguration:nil];
        [self.device setTorchMode:AVCaptureTorchModeAuto];
        [self.device unlockForConfiguration];
    }
}

@end

@implementation ZHBarTool (QRCode)

#pragma mark - 生成二维码
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content {
    return [self encodeQRCodeImageWithContent:content size:150];
}
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size {
    return [self encodeQRCodeImageWithContent:content size:size backgroundColor:nil themeColor:nil];
}
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size backgroundColor:(UIColor *)backgroundColor themeColor:(UIColor *)themeColor {
    return [self encodeQRCodeImageWithContent:content size:size backgroundColor:backgroundColor themeColor:themeColor insetImage:nil imageCornerRadius:0];
}
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size backgroundColor:(UIColor *)backgroundColor themeColor:(UIColor *)themeColor insetImage:(UIImage *)aImage imageCornerRadius:(CGFloat)cornerRadius {
    //二维码过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //将二维码过滤器设置为默认属性
    [filter setDefaults];
    //将内容转换成NSData
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    //赋值
    [filter setValue:data forKey:@"inputMessage"];
    //取出图片
    CIImage *outputImage = [filter outputImage];
    //放大图片
    CGRect extent = CGRectIntegral(outputImage.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    outputImage = [outputImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    //二维码上色
    if (themeColor || backgroundColor) {
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [colorFilter setDefaults];
        [colorFilter setValue:outputImage forKey:@"inputImage"];
        if (themeColor) {
            //主颜色
            NSDictionary *rgb = [[ZHBarTool barTool] rgbByColor:themeColor];
            [colorFilter setValue:[CIColor colorWithRed:[rgb[@"red"] floatValue] green:[rgb[@"green"] floatValue] blue:[rgb[@"blue"] floatValue] alpha:[rgb[@"alpha"] floatValue]] forKey:@"inputColor0"];
        }
        if (backgroundColor) {
            //背景颜色
            NSDictionary *rgb1 = [[ZHBarTool barTool] rgbByColor:backgroundColor];
            [colorFilter setValue:[CIColor colorWithRed:[rgb1[@"red"] floatValue] green:[rgb1[@"green"] floatValue] blue:[rgb1[@"blue"] floatValue] alpha:[rgb1[@"alpha"] floatValue]] forKey:@"inputColor1"];
        }
        //图片
        outputImage = colorFilter.outputImage;
    }
    
    //转换图片
    UIImage *image = [UIImage imageWithCIImage:outputImage];
    //1.开启绘图上下文
    UIGraphicsBeginImageContext(image.size);
    //2.把二维码图片绘上去
    CGSize imageSize = image.size;
    [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    //添加自定义图片
    if (aImage) {
        CGSize aSize = aImage.size;
        //3.给自定义图片添加圆角
        if (cornerRadius > 0) aImage = [self image:aImage cornerRadius:cornerRadius];
        //3.将自定义图片绘上去
        [aImage drawInRect:CGRectMake((imageSize.width-aSize.width)/2.0, (imageSize.height-aSize.height)/2.0, aSize.width, aSize.width)];
    }
    //合成的图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    //关闭绘图
    UIGraphicsEndImageContext();
    return image;
}
//把颜色转成rgb
- (NSDictionary *)rgbByColor:(UIColor *)color {
    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
    } else {
        const CGFloat *compoments = CGColorGetComponents(color.CGColor);
        red = compoments[0];
        green = compoments[1];
        blue = compoments[2];
        alpha = compoments[3];
    }
    return @{@"red":@(red), @"green":@(green), @"blue":@(blue), @"alpha":@(alpha)};
}
//给图片添加圆角w
+ (UIImage *)image:(UIImage *)aImage cornerRadius:(CGFloat)radius {
    CGSize aSize = aImage.size;
    CGRect rect = (CGRect){0.f,0.f,aSize};
    
    UIGraphicsBeginImageContext(aSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // 添加一个圆
    CGContextAddEllipseInRect(ctx, rect);
    // 裁剪(裁剪成刚才添加的图形形状)
    CGContextClip(ctx);
    [aImage drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - 解码二维码图片
+ (NSString *)decodeQRCodeImage:(UIImage *)aImage {
    if (!aImage) {
        return nil;
    }
    NSString *url = nil;
    //初始化一个监测器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    //监测到的结果数组
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:aImage.CGImage]];
    if (features.count >=1) {
        //结果对象
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *result = feature.messageString;
        url = result;
    }
    return url;
}

@end


@implementation ZHBarTool (Barcode)
+ (UIImage *)encodeBarcodeImageWithContent:(NSString *)content size:(CGSize)size {
    return [self encodeBarcodeImageWithContent:content size:size color:nil];
}
+ (UIImage *)encodeBarcodeImageWithContent:(NSString *)content size:(CGSize)size color:(UIColor *)color {
    //条形码过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    //将条形码过滤器设置为默认属性
    [filter setDefaults];
    //将内容转换成NSData
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    //赋值
    [filter setValue:data forKey:@"inputMessage"];
    //上下左右距离
    [filter setValue:@(0.00) forKey:@"inputQuietSpace"];
    //取出图片
    CIImage *outputImage = [filter outputImage];
    //放大图片
    CGRect extent = CGRectIntegral(outputImage.extent);
    CGFloat scale = MIN(size.width/CGRectGetWidth(extent), size.height/CGRectGetHeight(extent));
    outputImage = [outputImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    if (color) {
        //颜色
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [colorFilter setDefaults];
        [colorFilter setValue:outputImage forKey:@"inputImage"];
        //主颜色
        NSDictionary *rgb = [[ZHBarTool barTool] rgbByColor:color];
        [colorFilter setValue:[CIColor colorWithRed:[rgb[@"red"] floatValue] green:[rgb[@"green"] floatValue] blue:[rgb[@"blue"] floatValue] alpha:[rgb[@"alpha"] floatValue]] forKey:@"inputColor0"];
        //背景-白色
        [colorFilter setValue:[CIColor colorWithRed:1 green:1 blue:1 alpha:1] forKey:@"inputColor1"];
        outputImage = colorFilter.outputImage;
    }
    UIImage *image = [UIImage imageWithCIImage:outputImage];
    UIGraphicsBeginImageContext(image.size);
    CGSize imageSize = image.size;
    [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

