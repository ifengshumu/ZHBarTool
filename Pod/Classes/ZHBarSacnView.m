//
//  ZHBarSacnView.m
//
//  Created by Lee on 2017/9/18.
//  Copyright © 2017年 leezhihua. All rights reserved.
//


#import "ZHBarSacnView.h"
#import "ZHBarTool.h"

@interface ZHBarSacnView ()
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) UIButton *picBtn;
@end

@implementation ZHBarSacnView
+ (instancetype)barSacnView {
    CGSize size = UIScreen. mainScreen.bounds.size;
    BOOL X = ((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)&&(size.height>800));
    CGFloat statusNavH = X?88+34:64;
    return [[ZHBarSacnView alloc] initWithFrame:CGRectMake(0, statusNavH, size.width, size.height-statusNavH) scanRect:CGRectZero];
}
+ (instancetype)barSacnViewWithFrame:(CGRect)frame {
    return [[self alloc] initWithFrame:frame scanRect:CGRectZero];
}
+ (instancetype)barSacnViewWithFrame:(CGRect)frame scanRect:(CGRect)scanRect {
    return [[self alloc] initWithFrame:frame scanRect:scanRect];
}
- (instancetype)initWithFrame:(CGRect)frame scanRect:(CGRect)scanRect {
    self = [super initWithFrame:frame];
    if (self) {
        if (CGRectEqualToRect(scanRect, CGRectZero)) {
            CGFloat min = MIN(frame.size.width, frame.size.height);
            CGFloat wh = min*2/3.0;
            _scanRect = CGRectMake((frame.size.width-wh)/2.0, (frame.size.height-wh)/2.0, wh, wh);
        } else {
            _scanRect = scanRect;
        }
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [imageView setUserInteractionEnabled:YES];
    [imageView.image drawInRect:imageView.bounds];
    [self addSubview:imageView];
    //获取图形上下文
    UIGraphicsBeginImageContext(imageView.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //画布颜色、大小
    CGContextSetRGBFillColor(ctx, 40 / 255.0,40 / 255.0,40 / 255.0,0.5);
    CGContextFillRect(ctx, self.bounds);
    //透明框
    //1.把中间挖空
    CGContextClearRect(ctx, self.scanRect);
    //2.四周线颜色，宽度
    CGContextStrokeRect(ctx, self.scanRect);
    CGFloat r = 1, g = 1, b = 1, a = 1;//白色
    if (self.aroundLineColor) {
        NSDictionary *rgb = [self rgbByColor:self.aroundLineColor];
        r = [rgb[@"red"] floatValue];
        g = [rgb[@"green"] floatValue];
        b = [rgb[@"blue"] floatValue];
        a = [rgb[@"alpha"] floatValue];
    }
    CGContextSetRGBStrokeColor(ctx, r, g, b, a);
    CGContextSetLineWidth(ctx, 0.8);//线宽
    CGContextAddRect(ctx, self.scanRect);
    CGContextStrokePath(ctx);//合并线
    //四个角的线条
    [self addCornerLineWithContext:ctx rect:self.scanRect];
    [self animatedScanLine];
    //提醒文字
    [self drawText];
    //闪光灯
    [self flashlight];
    //图片选择
    [self picButton];
    //获取图片,关闭画布
    imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
- (void)addCornerLineWithContext:(CGContextRef)ctx rect:(CGRect)rect{
    CGContextSetLineWidth(ctx, 2);
    CGFloat r = 83 /255.0, g = 239/255.0, b = 111/255.0, a = 1;//绿色
    if (self.cornerLineColor) {
        NSDictionary *rgb = [self rgbByColor:self.cornerLineColor];
        r = [rgb[@"red"] floatValue];
        g = [rgb[@"green"] floatValue];
        b = [rgb[@"blue"] floatValue];
        a = [rgb[@"alpha"] floatValue];
    }
    CGContextSetRGBStrokeColor(ctx, r, g, b, a);
    
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat w = CGRectGetMaxX(rect);
    CGFloat h = CGRectGetMaxY(rect);
    CGFloat lh = 15;
    
    //左上角
    CGPoint poinsTopLeftA[] = {rect.origin, CGPointMake(x, y + lh)};//上下
    CGPoint poinsTopLeftB[] = {rect.origin, CGPointMake(x + lh, y)};//左右
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:ctx];
    
    //左下角
    CGPoint poinsBottomLeftA[] = {CGPointMake(x, h - lh),CGPointMake(x,h)};//上下
    CGPoint poinsBottomLeftB[] = {CGPointMake(x, h) ,CGPointMake(x + lh, h)};//左右
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:ctx];
    
    //右下角
    CGPoint poinsBottomRightA[] = {CGPointMake(w, h - lh),CGPointMake(w,h)};//上下
    CGPoint poinsBottomRightB[] = {CGPointMake(w - lh, h),CGPointMake(w,h)};//左右
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:ctx];
    
    //右上角
    CGPoint poinsTopRightA[] = {CGPointMake(w, y),CGPointMake(w, y + lh)};//上下
    CGPoint poinsTopRightB[] = {CGPointMake(w - lh, y),CGPointMake(w, y)};//左右
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:ctx];
    
    CGContextStrokePath(ctx);
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx {
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}

- (void)drawText {
    if (!self.hitText.length) {
        self.hitText = @"请将扫描框对准二维码、条形码";
    }
    if (!self.hitTextAttributes) {
        NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle alloc] init];
        textStyle.lineSpacing = 5;
        textStyle.lineBreakMode = NSLineBreakByWordWrapping;
        textStyle.alignment = NSTextAlignmentCenter;
        NSMutableDictionary *textAttributes = [[NSMutableDictionary alloc] init];
        [textAttributes setValue:textStyle forKey:NSParagraphStyleAttributeName];
        [textAttributes setValue:[UIFont systemFontOfSize:18] forKey:NSFontAttributeName];
        [textAttributes setValue:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        self.hitTextAttributes = textAttributes.copy;
    }
    CGFloat h = [self.hitText boundingRectWithSize:CGSizeMake(self.bounds.size.width-20, self.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:self.hitTextAttributes context:nil].size.height;
    CGRect rect = CGRectMake(10, CGRectGetMaxY(self.scanRect)+10, self.bounds.size.width-20, h);
    [self.hitText drawInRect:rect withAttributes:self.hitTextAttributes];
}

- (void)animatedScanLine {
    if (!self.line) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.scanRect.origin.x, self.scanRect.origin.y, self.scanRect.size.width, 1)];
        self.line = line;
        if (!self.animatedLineColor) {
            self.animatedLineColor = [UIColor colorWithRed:83 /255.0 green:239/255.0 blue:111/255.0 alpha:1];
        }
        line.backgroundColor = self.animatedLineColor;
        [self addSubview:line];
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.keyPath = @"transform.translation.y";
        animation.byValue = @(self.scanRect.size.height);
        animation.duration = 2.5;
        animation.repeatCount = MAXFLOAT;
        animation.removedOnCompletion = NO;
        [line.layer addAnimation:animation forKey:@"animationLine"];
    }
}

- (void)flashlight {
    if (!self.flashBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"ZHBarTool.bundle/flash"];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.layer.cornerRadius = 30;
        btn.layer.masksToBounds = YES;
        [btn setFrame:CGRectMake((self.frame.size.width-120)/3.0, CGRectGetMaxY(self.scanRect)+60, 60, 60)];
        [btn setImage:image forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(flashlightAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
}

- (void)flashlightAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [[ZHBarTool barTool] turnOnFlashlight];
        sender.backgroundColor = [UIColor blueColor];
    } else {
        [[ZHBarTool barTool] turnOffFlashlight];
        sender.backgroundColor = [UIColor lightGrayColor];
    }
}

- (void)picButton {
    if (!self.picBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"ZHBarTool.bundle/picture.png"];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.layer.cornerRadius = 30;
        btn.layer.masksToBounds = YES;
        [btn setFrame:CGRectMake((self.frame.size.width-120)/3.0*2+60, CGRectGetMaxY(self.scanRect)+60, 60, 60)];
        [btn setImage:image forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(choosePic:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
}
- (void)choosePic:(UIButton *)sender {
    if (self.choosePicture) {
        self.choosePicture(sender);
    }
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

@end
