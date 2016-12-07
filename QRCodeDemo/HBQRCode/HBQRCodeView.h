//
//  HBQRCodeView.h
//  QRCodeDemo
//
//  Created by hubin on 2016/12/7.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HBQRCodeScanDelegate <NSObject>

- (void)hbQRCodeScanResult:(NSString *)string;

@end


@interface HBQRCodeView : UIView

/* 扫描代理 */
@property (nonatomic, weak) id<HBQRCodeScanDelegate> hbQRCodeScanDelegate;

///* 扫描页标题 */
//@property (nonatomic, copy) NSString *hbQRCodeTitle;
//
///* 标题颜色 */
//@property (nonatomic, strong) UIColor  *hbQRCodeTitleColor;

//
@property (nonatomic,copy)UIImageView * readLineView;
@property (nonatomic,assign)BOOL is_Anmotion;
@property (nonatomic,assign)BOOL is_AnmotionFinished;

//开启关闭扫描
- (void)start;
- (void)stop;
- (void)loopDrawLine;//初始化扫描线




@end
