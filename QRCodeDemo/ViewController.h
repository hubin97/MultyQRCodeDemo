//
//  ViewController.h
//  QRCodeDemo
//
//  Created by Mac on 2016/11/21.
//  Copyright © 2016年 TUTK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *QRCodeResultLabel;
@property (weak, nonatomic) IBOutlet UITextField *testStrTextField;
//@property (weak, nonatomic) IBOutlet UIImageView *produceQRCodeImageView;


- (IBAction)QRCode:(id)sender;

- (IBAction)produceQRCode:(id)sender;
@end

