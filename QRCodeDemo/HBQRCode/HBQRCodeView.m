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

    [self setOverlayPickerView:self];

    //开始捕获
    [session startRunning];
}



/**
 设置扫描区域,并返回cgrect
 */
- (CGRect)setScanAreaWithBgImg
{
    //扫描区域
    //NSString *bundlePath  = [[NSBundle mainBundle] pathForResource:@"Resource" ofType:@"bundle"];

    NSString *hbImagePath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"scanscanBg" ofType:@"png" inDirectory:@"Images"];
    
//    NSLog(@"hbImagePath: %@", hbImagePath);

    UIImage *hbImage = [UIImage imageNamed:hbImagePath];
    UIImageView * scanZomeBack = [[UIImageView alloc] init];
    scanZomeBack.backgroundColor = [UIColor clearColor];
    scanZomeBack.layer.borderColor = [UIColor whiteColor].CGColor;
    scanZomeBack.layer.borderWidth = 2.5;
    scanZomeBack.image = hbImage;
    //添加一个背景图片
    CGRect mImagerect = CGRectMake(60*widthRate, (DeviceMaxHeight-200*widthRate)/2, 200*widthRate, 200*widthRate);
    [scanZomeBack setFrame:mImagerect];
    [self addSubview:scanZomeBack];
    
    //(origin = (x = 0.323943661971831, y = 0.1875), size = (width = 0.352112676056338, height = 0.625))
    return [self getScanCrop:mImagerect readerViewBounds:self.frame];
}


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
