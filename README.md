# ZHBarTool
原生封装二维码、条形码扫描工具；生成、识别（彩色）二维码、条形码图片

# cocoapods support
```
pod 'ZHBarTool'
```

## 生成二维码
```
UIImage *image = [ZBarTool encodeQRCodeImageWithContent:@"https://www.apple.com" size:300 backgroundColor:[UIColor clearColor] themeColor:[UIColor purpleColor] insetImage:[UIImage imageNamed:@"beautiful"] imageCornerRadius:50];
self.imageView.image = image;
```
## 识别二维码
```
NSString *content = [ZBarTool decodeQRCodeImage:self.imageView.image];
self.label.text = content;
```
## 扫描
```
ZBarTool *tool = [ZBarTool barTool];  
[tool startScanBarWithScanRect:self.scanRect scanType:ZBarScanTypeAll layerView:self.view];
tool.scanBarGetObject = ^(NSString * _Nonnull objects) {
  NSLog(@"%@", objects);
};
```
## 生成条形码
```
UIImage *image = [ZHBarTool encodeBarcodeImageWithContent:@"12345678" size:CGSizeMake(self.view.frame.size.width-20, 100) color:[UIColor yellowColor]];
self.barcodeImageView.image = image;
```

# 内部有封装好的扫描视图，可以直接使用
```
ZBarSacnView *scanView = [[ZBarSacnView alloc] initWithFrame:self.view.bounds scanRect:self.scanRect];
[self.view addSubview:scanView];
[scanView startScanBar];
```

# 更多使用方法详见Demo
