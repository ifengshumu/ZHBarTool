//
//  ViewController.m
//  ZHBarTool
//
//  Created by Lee on 2018/10/11.
//  Copyright © 2018年 leezhihua. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import "ZHBarTool.h"
#import "ZHBarSacnView.h"

@interface ViewController ()<ZHBarDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
//    CGRect scanRect = CGRectMake(50, (SCREEN_HEIGHT-kWidth)/2.0, kWidth, kWidth);
    ZHBarSacnView *scanview = [ZHBarSacnView barSacnView];
    [scanview setChoosePicture:^(UIButton *sender) {
        [self choosePic];
    }];
    [self.view addSubview:scanview];
    
    [ZHBarTool barTool].delegate = self;
    [[ZHBarTool barTool] startScanBarWithScanRect:scanview.scanRect scanType:ZHBarScanTypeAll layerView:scanview];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[ZHBarTool barTool] startScanning];
}
- (void)choosePic {
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentViewController:picker animated:YES completion:nil];
            }else{
                NSAssert(status == PHAuthorizationStatusAuthorized, @"无相册权限，请到“设置”中开启相册权限");
            }
        }];
    } else if (authStatus == PHAuthorizationStatusAuthorized){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        NSAssert(authStatus == PHAuthorizationStatusAuthorized, @"无相册权限，请到“设置”中开启相册权限");
    }
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSString *content = [ZHBarTool decodeQRCodeImage:image];
    [self handleScanObject:content type:ZHBarScanTypeQRCode];
}

- (void)ZHBarAuthorizedCameraFailed {
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
-(void)ZHBarDidScanBarGetObject:(NSString *)object barType:(ZHBarScanType)barType {
    [self handleScanObject:object type:barType];
}

- (void)handleScanObject:(NSString *)object type:(ZHBarScanType)type {
    [[ZHBarTool barTool] stopScanning];
    if ([object isKindOfClass:[NSString class]] && object.length) {
        if ([object containsString:@"://"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:object]];
            [[ZHBarTool barTool] startScanning];
        } else {
            NSLog(@"扫描结果=%@", object);
        }
    }
}

@end
