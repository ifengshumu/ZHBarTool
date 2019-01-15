//
//  ZHBarSacnView.h
//
//  Created by Lee on 2017/9/18.
//  Copyright © 2017年 leezhihua. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ZHBarSacnView : UIView
///frame默认为全屏(除去状态栏和导航栏高度)；扫描区域居中，宽高为frame的2/3
+ (instancetype)barSacnView;
///frame自定义；扫描区域居中，宽高为frame的2/3
+ (instancetype)barSacnViewWithFrame:(CGRect)frame;
///frame、扫描区域自定义(如果扫描区域为Zero，则居中，宽高为frame的2/3)
+ (instancetype)barSacnViewWithFrame:(CGRect)frame scanRect:(CGRect)scanRect;

@property (nonatomic, assign, readonly) CGRect scanRect;
///扫描区域框颜色
@property (nonatomic, strong) UIColor *aroundLineColor;
///扫描区域四个角颜色
@property (nonatomic, strong) UIColor *cornerLineColor;
///扫描区线颜色
@property (nonatomic, strong) UIColor *animatedLineColor;
///提醒文字
@property (nonatomic, copy) NSString *hitText;
///提醒文字属性
@property (nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *hitTextAttributes;
///选择相册照片
@property (nonatomic, copy) void(^choosePicture)(UIButton *sender);
@end

