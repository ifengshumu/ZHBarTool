//
//  ZHBarTool.h
//
//  Created by Lee on 2017/9/18.
//  Copyright © 2017年 leezhihua. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZHBarScanType) {
    ZHBarScanTypeQRCode = 0,   //二维码
    ZHBarScanTypeBarCode,      //条形码
    ZHBarScanTypeAll,          //全部
};

@class ZHBarTool;
@protocol ZHBarDelegate <NSObject>
///相机无权限
- (void)ZHBarAuthorizedCameraFailed;
///扫描结果
- (void)ZHBarDidScanBarGetObject:(NSString *)object barType:(ZHBarScanType)barType;
@end

@interface ZHBarTool : NSObject

/**
 初始化
 */
+ (instancetype)barTool;

/**
 开始扫码(已启动)
 
 @param scanRect 扫描区域(相对于layerView)，可以正常的frame，也可以是比例
 @param scanType 扫描类型，默认ZHBarScanTypeQRCode
 @param layerView 承载相机预览layer层的视图
 */
- (void)startScanBarWithScanRect:(CGRect)scanRect scanType:(ZHBarScanType)scanType layerView:(UIView *)layerView;

/**
 扫描间隔,默认2s
 */
@property (nonatomic, assign) CGFloat scanInterval;

/**
 代理
 */
@property (nonatomic, weak) id<ZHBarDelegate> delegate;

/**
 相机无权限Block
 */
@property (nonatomic, copy) void(^authorizedCameraFailed)(void);

/**
 扫描结果Block
 */
@property (nonatomic, copy) void(^scanBarGetObject)(NSString *voidobject, ZHBarScanType type);

/**
 开始扫描
 */
- (void)startScanning;

/**
 结束扫描
 */
- (void)stopScanning;

/**
 开启手电筒
 */
- (void)turnOnFlashlight;

/**
 关闭手电筒
 */
- (void)turnOffFlashlight;

/**
 自动手电筒
 */
- (void)autoFlashlight;

@end


@interface ZHBarTool (QRCode)
/**
 生成二维码图片，默认size = 150
 
 @param content             内容
 @return                    二维码图片
 */
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content;

/**
 生成二维码图片，可配置二维码大小
 
 @param content             内容
 @param size                大小
 @return                    二维码图片
 */
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size;

/**
 生成二维码图片，可配置二维码大小、背景色和主题色
 
 @param content             内容
 @param size                大小
 @param backgroundColor     二维码背景色
 @param themeColor          二维码主题色
 @return                    二维码图片
 */
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size backgroundColor:(UIColor *)backgroundColor themeColor:(UIColor *)themeColor;

/**
 生成二维码图片，可配置二维码大小、背景色和主题色， 可插入图片
 
 @param content             内容
 @param size                大小
 @param backgroundColor     二维码背景色
 @param themeColor          二维码主题色
 @param aImage              插入图片
 @param cornerRadius        插入图片圆角,如果不设圆角可传0
 @return                    二维码图片
 */
+ (UIImage *)encodeQRCodeImageWithContent:(NSString *)content size:(CGFloat)size backgroundColor:(UIColor *)backgroundColor themeColor:(UIColor *)themeColor insetImage:(UIImage *)aImage imageCornerRadius:(CGFloat)cornerRadius;


/**
 解码二维码图片
 
 @param aImage 二维码图片
 @return 解码结果
 */
+ (NSString *)decodeQRCodeImage:(UIImage *)aImage;
@end


@interface ZHBarTool (Barcode)

/**
 生成条形码
 
 @param content 内容
 @param size 尺寸
 @return 条形码
 */
+ (UIImage *)encodeBarcodeImageWithContent:(NSString *)content size:(CGSize)size;

/**
 生成条形码
 
 @param content 内容
 @param size 尺寸
 @param color 颜色
 @return 条形码
 */
+ (UIImage *)encodeBarcodeImageWithContent:(NSString *)content size:(CGSize)size color:(UIColor *)color;
@end

