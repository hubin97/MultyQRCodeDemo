//
//  HBScanViewController.m
//  QRCodeDemo
//
//  Created by Mac on 2016/12/7.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import "HBScanViewController.h"
#import "HBQRCode.h"

#import <AVFoundation/AVFoundation.h>


//设置 view 圆角和边框
#define LRViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]

@interface HBScanViewController ()<HBQRCodeScanDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    HBQRCodeView *_qrCodeView;
}

@end

@implementation HBScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
    self.title = @"扫描";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem * lbbItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonEvent)];
    self.navigationItem.leftBarButtonItem = lbbItem;
    
    
    //=====调用HBQRCodeView=====
    /**
     注意扫描完成或者返回时停用扫描
     _qrCodeView.is_Anmotion = YES;
     [_qrCodeView stop];
     */
    if (_qrCodeView)
    {
        [_qrCodeView removeFromSuperview];
        _qrCodeView = nil;
    }
    
    _qrCodeView = [[HBQRCodeView alloc]initWithFrame:self.view.frame];
    _qrCodeView.hbQRCodeScanDelegate = self;
    [self.view addSubview:_qrCodeView];

    _qrCodeView.is_AnmotionFinished = YES;

    _qrCodeView.backgroundColor = [UIColor clearColor];
    _qrCodeView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        _qrCodeView.alpha = 1;
    }];
    
//    _qrCodeView.hbQRCodeTitle = @"扫描---uid---";
//    _qrCodeView.hbQRCodeTitleColor = [UIColor brownColor];
    
    if (_qrCodeView)
    {
        [self reStartScan];
    }
    //=============================
    //LRViewBorderRadius(qrCodeView, 2, 5, [UIColor brownColor]);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    if (_qrCodeView)
//    {
//        [self reStartScan];
//    }
}

- (void)reStartScan
{
    _qrCodeView.is_Anmotion = NO;
    
//    if (_qrCodeView.is_AnmotionFinished)
//    {
//        [_qrCodeView loopDrawLine];
//    }
    
    [_qrCodeView start];
}

#pragma mark - 返回
- (void)backButtonEvent
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


//返回结果的代理方法
- (void)hbQRCodeScanResult:(NSString *)string
{
    _qrCodeView.is_Anmotion = YES;
    [_qrCodeView stop];

    NSLog(@"HBScanViewController||收到扫描结果:%@ ",string);
    
    [self performSelector:@selector(reStartScan) withObject:nil afterDelay:1.5];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (_callBackScanResultBlock)
        {
            _callBackScanResultBlock(string);
        }
        
       // [self dismissViewControllerAnimated:YES completion:nil];
        
    });
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_qrCodeView)
    {
        [_qrCodeView stop];
        _qrCodeView.is_Anmotion = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
