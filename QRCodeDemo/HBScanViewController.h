//
//  HBScanViewController.h
//  QRCodeDemo
//
//  Created by Mac on 2016/12/7.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HBScanViewController : UIViewController

@property (copy, nonatomic) void (^callBackScanResultBlock) (NSString *scanResult);


@end
