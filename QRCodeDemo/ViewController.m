//
//  ViewController.m
//  QRCodeDemo
//
//  Created by Mac on 2016/11/21.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

//#import "lhScanQCodeViewController.h"

#import "HBQRCode.h"

#import "HBScanViewController.h"

//7.设置 view 圆角和边框
#define LRViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]


/**
 二维码扫描的步骤：
 1、创建设备会话对象，用来设置设备数据输入
 2、获取摄像头，并且将摄像头对象加入当前会话中
 3、实时获取摄像头原始数据显示在屏幕上
 4、扫描到二维码/条形码数据，通过协议方法回调
 */
@interface ViewController ()
{
    AVCaptureSession *_session;
    AVCaptureInput   *_input;
    AVCaptureOutput  *_output;
//    AVCaptureMetadataOutput *
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    

    
    //默认字串
    NSString *qrCodestring = @"GVYC6E4E5CBEPDKA111A";
    
    self.testStrTextField.text = qrCodestring;
 
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)QRCode:(id)sender {
    
#if 0
    lhScanQCodeViewController * sqVC = [[lhScanQCodeViewController alloc]init];
    UINavigationController * nVC = [[UINavigationController alloc]initWithRootViewController:sqVC];
    [self presentViewController:nVC animated:YES completion:nil];

#else
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HBScanViewController *scanVc = [storyboard instantiateViewControllerWithIdentifier:@"HBScanViewController"];
    
    scanVc.callBackScanResultBlock = ^(NSString *string)
    {
        NSLog(@"QRCODE:%@",string);
        self.QRCodeResultLabel.text = string;
    };
    
    UINavigationController * nVC = [[UINavigationController alloc]initWithRootViewController:scanVc];
    [self presentViewController:nVC animated:YES completion:nil];
#endif
    
}


- (IBAction)produceQRCode:(id)sender {
    
    NSLog(@"IMAGE:%@",[HBQRCoder qrcodeImageWithString:@"GVYC6E4E5CBEPDKA111A"]);
    
    //[HBQRCode stringToQRCodeInImageView:self.produceQRCodeImageView WithString:@"GVYC6E4E5CBEPDKA111A"];
    
    //TODO:这里可以遮盖一个imageView显示二维码,当点击的时候再RemoveFromSuperView
//    UIView *grayView = [[UIView alloc] initWithFrame:self.view.frame];
//    [self.view addSubview:grayView];
  
    UIImageView *grayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width *0.6, 60, 50, 50)];
    [self.view addSubview:grayImageView];
    
    grayImageView.backgroundColor = [UIColor grayColor];
    //grayImageView.alpha = 0.5;
    grayImageView.alpha = 0.9;

    grayImageView.tag = 100;
    
    grayImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapQRCodeImageView:)];
    [grayImageView addGestureRecognizer:tap];
    
    //LRViewBorderRadius(grayImageView, 1, 5, [UIColor redColor]);
    
    [UIView animateWithDuration:0.3 animations:^{
      
        grayImageView.frame =  self.view.frame;
        
    } completion:^(BOOL finished) {
        
        //qrcode imgV
        CGFloat imageViewH = (self.view.frame.size.width > self.view.frame.size.height)? self.view.frame.size.height : self.view.frame.size.width;
        
        CGFloat imageViewY = (self.view.frame.size.height - imageViewH)/2;
        
        UIImageView *qrcodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, imageViewY, imageViewH, imageViewH)];
        qrcodeImageView.center = grayImageView.center;
        [grayImageView addSubview:qrcodeImageView];
        qrcodeImageView.backgroundColor = [UIColor whiteColor];
        
        [HBQRCoder stringToQRCodeInImageView:qrcodeImageView WithString:self.testStrTextField.text];
    }];
}

- (void)tapQRCodeImageView:(UITapGestureRecognizer *)tap
{
    UIImageView *grayImageView = [self.view viewWithTag:100];
    [grayImageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [UIView animateWithDuration:0.5 animations:^{
        
        grayImageView.bounds = CGRectMake(0, 0, 50, 50);
        grayImageView.center = CGPointMake(self.view.frame.size.width *0.7, 60);
        
    } completion:^(BOOL finished) {

        [grayImageView removeFromSuperview];
    }];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.testStrTextField resignFirstResponder];
}

@end
