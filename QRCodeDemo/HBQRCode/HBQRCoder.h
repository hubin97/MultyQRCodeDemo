//
//  HBQRCoder.h
//  QRCodeDemo
//
//  Created by hubin on 2016/11/21.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HBQRCoder : NSObject

//!!!!:以下为二维码扫描
//TODO: XXXX



//!!!!:以下为二维码生成
/**
 转换字串string生成二维码到imageView上
 
 @param imageView 二维码展示视图
 @param string 需要转换的字串
 */
+ (void)stringToQRCodeInImageView:(UIImageView *)imageView WithString:(NSString *)string;


/**
 直接由字串返回二维码
 
 @param string 字串
 @return 二维码
 */
+ (UIImage *)qrcodeImageWithString:(NSString *)string;

@end
