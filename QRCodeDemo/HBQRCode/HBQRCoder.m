//
//  HBQRCoder.m
//  QRCodeDemo
//
//  Created by hubin on 2016/11/21.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import "HBQRCoder.h"

@implementation HBQRCoder


#pragma mark - 二维码生成字串
//!!!!:二维码生成字串
//TODO:调用摄像头扫描



#pragma mark - 字串生成二维码
/**
 转换字串string生成二维码到imageView上
 
 @param imageView 二维码展示视图
 @param string 需要转换的字串
 */
+ (void)stringToQRCodeInImageView:(UIImageView *)imageView WithString:(NSString *)string
{
    return [[self alloc] initWithStringToQRCodeInImageView:imageView WithString:string];
}



/**
 直接由字串返回二维码

 @param string 字串
 @return 二维码
 */
+ (UIImage *)qrcodeImageWithString:(NSString *)string
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复默认
    [filter setDefaults];
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    NSString *dataString = string;
    
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    // 5.将CIImage转换成UIImage，并放大显示
    return [[[self alloc] init] createNonInterpolatedUIImageFormCIImage:outputImage withSize:200];
}

/**
 转换字串string生成二维码到imageView上
 
 @param imageView 二维码展示视图
 @param string 需要转换的字串
 */
- (void)initWithStringToQRCodeInImageView:(UIImageView *)imageView WithString:(NSString *)string
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复默认
    [filter setDefaults];
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    NSString *dataString = string;
    
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    // 5.将CIImage转换成UIImage，并放大显示
    imageView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:200];
}
/**
 * 根据CIImage生成指定大小的UIImage
 *
 * @param image CIImage
 * @param size 图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}


@end
