//
//  HBQRCodeView.m
//  QRCodeDemo
//
//  Created by hubin on 2016/12/7.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import "HBQRCodeView.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Masonry.h"

#define DeviceMaxHeight ([UIScreen mainScreen].bounds.size.height)
#define DeviceMaxWidth ([UIScreen mainScreen].bounds.size.width)
#define widthRate DeviceMaxWidth/320

#define contentTitleColorStr @"666666" //正文颜色较深

#define bundlePath [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"]


#define LRViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]


@interface HBQRCodeView()<AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *session;
    CGPoint lastPoint;
    //UIImageView * scanZomeBack;
    
    //UIView *_scanZomeBoundView;
    UIView *_scanZomeView;
    UIView *_gridView; // 网格控件
    NSUInteger _styleCol;
}
@end
@implementation HBQRCodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        //初始化UI
        //[self setup];
        
        //初始化扫描设备
        [self initScanDevice];
    }
    return self;
}

-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
 
    x = (CGRectGetHeight(readerViewBounds)-CGRectGetHeight(rect))/2/CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds)-CGRectGetWidth(rect))/2/CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect)/CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect)/CGRectGetWidth(readerViewBounds);
    
    return CGRectMake(x, y, width, height);
}

/**
 二维码扫描的步骤：
 1、创建设备会话对象，用来设置设备数据输入
 2、获取摄像头，并且将摄像头对象加入当前会话中
 3、实时获取摄像头原始数据显示在屏幕上
 4、扫描到二维码/条形码数据，通过协议方法回调
 */
- (void)initScanDevice
{
    //创建会话对象
    session = [[AVCaptureSession alloc]init];
    
    //设置采集率等级
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //将摄像头对象生成的输入流加入当前会话中
    if (input) [session addInput:input];

    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    
    //输出流加入当前会话中
    if(output) [session addOutput:output];
    
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    if(output)
    {
        NSMutableArray *a = [[NSMutableArray alloc] init];
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [a addObject:AVMetadataObjectTypeQRCode];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [a addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [a addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [a addObject:AVMetadataObjectTypeCode128Code];
        }
        output.metadataObjectTypes=a;
    }
    
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //设置元数据识别搜索的区域; rectOfInterest不是普通的CGRect,四个值都需要在0~1之间
    //备注:http://stackoverflow.com/questions/32401364/how-do-i-use-the-metadataoutputrectofinterestforrect-method-and-rectofinterest-p
    output.rectOfInterest = [self setScanAreaWithBgImg];
    

    //预览窗口
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    //填充模式
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    //frame
    layer.frame = self.layer.bounds;
    
#warning ... 必须加入layer才能展示
    [self.layer insertSublayer:layer atIndex:0];

    //[self setOverlayPickerView:self];

    //开始捕获 // saom
    [session startRunning];
}


#pragma mark ---
/**
 设置扫描区域,并返回cgrect
 */
- (CGRect)setScanAreaWithBgImg
{
    CGRect mImagerect = CGRectMake(20*widthRate, (DeviceMaxHeight-300*widthRate)/2, 280*widthRate, 300*widthRate);

    _scanZomeView = [[UIView alloc]initWithFrame:mImagerect];
    [self addSubview:_scanZomeView];

    [self createViewWithRect:mImagerect];

    //(origin = (x = 0.323943661971831, y = 0.1875), size = (width = 0.352112676056338, height = 0.625))
    return [self getScanCrop:mImagerect readerViewBounds:self.frame];
}

- (void)createViewWithRect:(CGRect)centerRect
{
//    _scanZomeView.layer.borderWidth = 1.5;
//    _scanZomeView.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.2].CGColor;
    
    CGFloat iconFlagH = 30.0f;

    // 网格控件 规格 2*4  4*4
    _gridView = [[UIView alloc]init];
    _gridView.layer.borderWidth = 1.5;
    _gridView.layer.borderColor = [UIColor redColor].CGColor;
    _gridView.userInteractionEnabled = YES;
    
    [_scanZomeView addSubview:_gridView];
    [_gridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scanZomeView).insets(UIEdgeInsetsMake(iconFlagH/2, iconFlagH/2, iconFlagH/2, iconFlagH/2));
    }];
    
    // row
    for (int row = 0; row < 3; row ++)
    {
        UILabel *lineLabel = [[UILabel alloc]init];
        lineLabel.layer.borderWidth = 1.5;
        lineLabel.layer.borderColor = [UIColor redColor].CGColor;
        [_gridView addSubview:lineLabel];
        [lineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_gridView);
            //!!!!:注意此时gridView高度仍为0
            //make.top.equalTo(gridView.mas_bottom).multipliedBy(1/4);
            make.top.equalTo(_gridView).offset((_scanZomeView.bounds.size.height - iconFlagH) * (row + 1)/4);
            make.height.mas_equalTo(@1);
        }];
    }
    
    // col  2 ~ 4
    _styleCol = 3;  // 1/3
    for (int col = 0; col < _styleCol; col ++)
    {
        UILabel *lineLabel = [[UILabel alloc]init];
        lineLabel.layer.borderWidth = 1.5;
        lineLabel.layer.borderColor = [UIColor redColor].CGColor;
        [_gridView addSubview:lineLabel];
        [lineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_gridView);
            //!!!!:注意此时gridView宽度仍为0
            make.left.equalTo(_gridView).offset((_scanZomeView.bounds.size.width - iconFlagH) * (col + 1)/(_styleCol + 1));
            make.width.mas_equalTo(@1);
        }];
    }
    
    // ------
    // 操作控件
    NSArray *icons = @[@"gis_rect_lt",@"gis_rect_rt",@"gis_rect_lb",@"gis_rect_rb"];
    for (int i = 101; i <= 105; i++)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_scanZomeView addSubview:button];
        [button setTag:i];
        
        [button addTarget:self action:@selector(touchesBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(touchesMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [button addTarget:self action:@selector(touchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        if(i > 101)[button setImage:[UIImage imageNamed:icons[i - 102]] forState:UIControlStateNormal];
       
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(iconFlagH);
            if(i== 101) make.edges.equalTo(_scanZomeView);
            
            if(i== 102) make.left.top.equalTo(_scanZomeView);
            if(i== 103) make.right.top.equalTo(_scanZomeView);
            if(i== 104) make.left.bottom.equalTo(_scanZomeView);
            if(i== 105) make.right.bottom.equalTo(_scanZomeView);
        }];
    }
}

#pragma mark - Touch Event
- (void)touchesBegan:(UIControl *)touches withEvent:(UIEvent *)event {
    NSLog(@"touchesBegan---");
    
    UITouch *touch = [[event allTouches] anyObject];
    lastPoint = [touch locationInView:self];
}

- (void)touchesMoved:(UIControl *)touches withEvent:(UIEvent *)event {
    
    NSLog(@"touchesMoved---");
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    float moveX = currentPoint.x - lastPoint.x;
    float moveY = currentPoint.y - lastPoint.y;
    lastPoint = currentPoint;
    CGRect frame = _scanZomeView.frame;
    if (touch.view.tag == 101) {
        frame.origin.x += moveX;
        frame.origin.y += moveY;
        
    } else if (touch.view.tag == 102) {
        frame.origin.x += moveX;
        frame.origin.y += moveY;
        frame.size.width -= moveX;
        frame.size.height -= moveY;
    } else if (touch.view.tag == 103) {
        frame.origin.y += moveY;
        frame.size.width += moveX;
        frame.size.height -= moveY;
    } else if (touch.view.tag == 104) {
        frame.origin.x += moveX;
        frame.size.width -= moveX;
        frame.size.height += moveY;
    } else if (touch.view.tag == 105) {
        frame.size.width += moveX;
        frame.size.height += moveY;
    }
    
    // !!!!:限制view的大小
    int height = [UIScreen mainScreen].bounds.size.height>480 ? 504.0 : 416.0;
    frame.origin.x = frame.origin.x < 0 ? 0 : frame.origin.x;
    frame.origin.y = frame.origin.y < 0 ? 0 : frame.origin.y;
    frame.origin.x = (frame.origin.x + frame.size.width) > 320.0 ? (320.0 - frame.size.width) : frame.origin.x;
    frame.origin.y = (frame.origin.y + frame.size.height) > height ? (height - frame.size.height) : frame.origin.y;
    frame.size.width = frame.size.width < 100.0 ? 100.0 : frame.size.width;
    frame.size.height = frame.size.height < 66.7 ? 66.7 : frame.size.height;
    frame.size.width = frame.size.width > 320.0 ? 320.0 : frame.size.width;
    frame.size.height = frame.size.height > height ? height : frame.size.height;
    _scanZomeView.frame = frame;
    _scanZomeView.userInteractionEnabled = YES;
    
    CGFloat iconFlagH = 30.0f;
    for (int i = 101; i <= 105; i ++)
    {
        UIButton *button = (UIButton *)[self viewWithTag:i];
        
        [button mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(iconFlagH);
            
            if(i== 101) make.edges.equalTo(_scanZomeView);
            if(i== 102) make.left.top.equalTo(_scanZomeView);
            if(i== 103) make.right.top.equalTo(_scanZomeView);
            if(i== 104) make.left.bottom.equalTo(_scanZomeView);
            if(i== 105) make.right.bottom.equalTo(_scanZomeView);
        }];
        
//        [button setNeedsLayout];
//        [button layoutIfNeeded];
    }
    
//    [_gridView mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(_scanZomeView).insets(UIEdgeInsetsMake(iconFlagH/2, iconFlagH/2, iconFlagH/2, iconFlagH/2));
//    }];
//
    // ---
    [_gridView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // row
    for (int row = 0; row < 3; row ++)
    {
        UILabel *lineLabel = [[UILabel alloc]init];
        lineLabel.layer.borderWidth = 1.5;
        lineLabel.layer.borderColor = [UIColor redColor].CGColor;
        [_gridView addSubview:lineLabel];
        [lineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_gridView);
            //!!!!:注意此时gridView高度仍为0
            //make.top.equalTo(gridView.mas_bottom).multipliedBy(1/4);
            make.top.equalTo(_gridView).offset((_scanZomeView.bounds.size.height - iconFlagH) * (row + 1)/4);
            make.height.mas_equalTo(@1);
        }];
    }

    // col  2 ~ 4
    for (int col = 0; col < _styleCol; col ++)
    {
        UILabel *lineLabel = [[UILabel alloc]init];
        lineLabel.layer.borderWidth = 1.5;
        lineLabel.layer.borderColor = [UIColor redColor].CGColor;
        [_gridView addSubview:lineLabel];
        [lineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_gridView);
            //!!!!:注意此时gridView宽度仍为0
            make.left.equalTo(_gridView).offset((_scanZomeView.bounds.size.width - iconFlagH) * (col + 1)/(_styleCol + 1));
            make.width.mas_equalTo(@1);
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSLog(@"touchesEnded---");
    //if(!self.choiceView.isHidden)
    //    [self performSelectorOnMainThread:@selector(selectCell) withObject:nil waitUntilDone:YES];
}




#pragma mark --
/**
 布局扫描页边框

 @param reader self
 */
- (void)setOverlayPickerView:(HBQRCodeView *)reader
{
    CGFloat wid = 60*widthRate;
    CGFloat heih = (DeviceMaxHeight-200*widthRate)/2;

    //最上部view
    CGFloat alpha = 0.6;
    UIView* upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DeviceMaxWidth, heih)];
    upView.alpha = alpha;
    upView.backgroundColor = [self colorFromHexRGB:contentTitleColorStr];
    [reader addSubview:upView];
    
    
    //LRViewBorderRadius(upView, 1, 2, [UIColor redColor]);
    
    //用于说明的label/ 二维码扫描页的标题
    UILabel * labIntroudction = [[UILabel alloc] init];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.frame = CGRectMake(0, 64 + (heih-64-50*widthRate)/2, DeviceMaxWidth, 50*widthRate);
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.textColor = [UIColor whiteColor];
   
    labIntroudction.text = @"请扫描XXX二维码";
    
    [upView addSubview:labIntroudction];
    
    //左侧的view
    UIView * cLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, heih, wid, 200*widthRate)];
    cLeftView.alpha = alpha;
    cLeftView.backgroundColor = [self colorFromHexRGB:contentTitleColorStr];
    [reader addSubview:cLeftView];
    
    //LRViewBorderRadius(cLeftView, 1, 2, [UIColor redColor]);

    //右侧的view
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(DeviceMaxWidth-wid, heih, wid, 200*widthRate)];
    rightView.alpha = alpha;
    rightView.backgroundColor = [self colorFromHexRGB:contentTitleColorStr];
    [reader addSubview:rightView];
    
    //底部view
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, heih+200*widthRate, DeviceMaxWidth, DeviceMaxHeight - heih-200*widthRate)];
    downView.alpha = alpha;
    downView.backgroundColor = [self colorFromHexRGB:contentTitleColorStr];
    [reader addSubview:downView];
    
    //LRViewBorderRadius(downView, 1, 2, [UIColor brownColor]);

    //开关灯button
    UIButton * turnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    turnBtn.backgroundColor = [UIColor clearColor];
    
    NSString *turnBtnSelectPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"lightSelect" ofType:@"png" inDirectory:@"Images"];
    NSString *turnBtnNormalPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"lightNormal" ofType:@"png" inDirectory:@"Images"];

    [turnBtn setBackgroundImage:[UIImage imageNamed:turnBtnNormalPath] forState:UIControlStateNormal];
    [turnBtn setBackgroundImage:[UIImage imageNamed:turnBtnSelectPath] forState:UIControlStateSelected];
    turnBtn.frame = CGRectMake((DeviceMaxWidth-50*widthRate)/2, (CGRectGetHeight(downView.frame)-50*widthRate)/2, 50*widthRate, 50*widthRate);
    [turnBtn addTarget:self action:@selector(turnBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [downView addSubview:turnBtn];
}


#pragma mark - 闪光灯
- (void)turnBtnEvent:(UIButton *)button_
{
    button_.selected = !button_.selected;
    if (button_.selected)
    {
        [self turnTorchOn:YES];
    }
    else
    {
        [self turnTorchOn:NO];
    }
}

- (void)turnTorchOn:(bool)on
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}



#pragma mark - 颜色
//获取颜色
- (UIColor *)colorFromHexRGB:(NSString *)inColorString
{
    UIColor *result = nil;
    unsigned int colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner *scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char) (colorCode >> 16);
    greenByte = (unsigned char) (colorCode >> 8);
    blueByte = (unsigned char) (colorCode); // masks off high bits
    result = [UIColor
              colorWithRed: (float)redByte / 0xff
              green: (float)greenByte/ 0xff
              blue: (float)blueByte / 0xff
              alpha:1.0];
    return result;
}


#pragma mark -
-(void)loopDrawLine
{
    _is_AnmotionFinished = NO;
    CGRect rect = CGRectMake(60*widthRate, (DeviceMaxHeight-200*widthRate)/2, 200*widthRate, 2);
    if (_readLineView) {
        _readLineView.alpha = 1;
        _readLineView.frame = rect;
    }
    else{
        _readLineView = [[UIImageView alloc] initWithFrame:rect];
        
        NSString *readLineViewPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"scanLine" ofType:@"png" inDirectory:@"Images"];

        NSLog(@"readLineViewPath: %@", readLineViewPath);

        [_readLineView setImage:[UIImage imageNamed:readLineViewPath]];
        [self addSubview:_readLineView];
    }
    
    [UIView animateWithDuration:1.5 animations:^{
        //修改fream的代码写在这里
        _readLineView.frame =CGRectMake(60*widthRate, (DeviceMaxHeight-200*widthRate)/2+200*widthRate-5, 200*widthRate, 2);
    } completion:^(BOOL finished) {
        if (!_is_Anmotion) {
            [self loopDrawLine];
        }
        _is_AnmotionFinished = YES;
    }];
}

- (void)start
{
    [session startRunning];
}

- (void)stop
{
    [session stopRunning];
}

#pragma mark - 扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if(metadataObjects && metadataObjects.count > 0)
    {
        //播放扫描二维码的声音
        SystemSoundID soundID;
        NSString *strSoundFile = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"noticeMusic" ofType:@"wav"inDirectory:@"Sounds"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:strSoundFile],&soundID);
        AudioServicesPlaySystemSound(soundID);
        
        //获取扫描结果
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        NSLog(@"扫描结果:metadataObject.stringValue :%@",metadataObject.stringValue);
        
        //代理存在,并且存在代理方法(respondsToSelector 检测是否响应)
        if (_hbQRCodeScanDelegate && [_hbQRCodeScanDelegate respondsToSelector:@selector(hbQRCodeScanResult:)])
        {
            //返回结果给委托者
            [_hbQRCodeScanDelegate hbQRCodeScanResult:metadataObject.stringValue];
        }
    }
}

@end
