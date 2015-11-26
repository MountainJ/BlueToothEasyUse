//
//  RootViewController.m
//  BLEUseDemo
//
//  Created by JayZY on 15/11/3.
//  Copyright © 2015年 jayZY. All rights reserved.
//

#import "RootViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SVProgressHUD.h"

#import "BleDefines.h"
#import "ResultsViewController.h"

#import "BlueToothConnecter.h"

@interface RootViewController ()
{
    UILabel *_bDeviceLabel; //搜索到的蓝牙设备名称
    UILabel *_pressureLabel;
}

//系统蓝牙连接及进度状态提醒
@property (nonatomic,strong) UIView *indicatorView;
@property (nonatomic,strong) UILabel *indicatorLabel;

@end

@implementation RootViewController

- (void)viewDidLoad {
     [super viewDidLoad];
      self.view.backgroundColor  =[UIColor whiteColor];
     [self configUI];
      WS(weakSelf);
    //注册蓝牙中心管理
     [[BlueToothConnecter shareBlueToothConnecter] registerBlueToothManager];
    //创建一个中央管理对象检查手机的蓝牙是否打开
    [[BlueToothConnecter shareBlueToothConnecter] checkBlueToothPowerOn:^{
        [weakSelf indicatorView];
        weakSelf.indicatorLabel.text = @"开始扫描设备";
        weakSelf.indicatorLabel.textColor = [UIColor darkTextColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(foundDevice:)];
        [weakSelf.indicatorLabel addGestureRecognizer:tap];
    } powerOff:^{
       [weakSelf indicatorView];
        weakSelf.indicatorLabel.textColor = [UIColor redColor];
        weakSelf.indicatorLabel.text = @"蓝牙没有打开,请在设置中连接";
    }];
}
#pragma mark -开始扫描设备
- (void)foundDevice:(UIButton *)btn
{
    [[BlueToothConnecter shareBlueToothConnecter] scanPeripheralsCompletion:^(NSArray *scanPeripherals) {
        NSLog(@"%@",scanPeripherals);
    }];
}

#pragma mark - 开始测量
- (void)sendConnect:(UIButton *)btn
{
    [[BlueToothConnecter shareBlueToothConnecter] startHandleMeasureSuccess:^(NSDictionary *resultDict) {
        _pressureLabel.text = [NSString stringWithFormat:@"结果sys=%@,dia=%@,pul=%@",resultDict[@"sys"] ,resultDict[@"dia"],resultDict[@"pul"]];
        NSLog(@"%@",resultDict);
    } failure:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}

#pragma mark - 界面配置...
- (UIView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 40)];
        _indicatorView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_indicatorView];
         self.indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _indicatorView.frame.size.width, _indicatorView.frame.size.height)];
        self.indicatorLabel.textAlignment = NSTextAlignmentCenter;
        self.indicatorLabel.font = [UIFont systemFontOfSize:11.0f];
        self.indicatorLabel.userInteractionEnabled = YES;
        [_indicatorView addSubview:self.indicatorLabel];
    }
    return _indicatorView;
}

-(void)configUI
{
    self.title = @"BlueToothUse";
    UILabel *deviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-140, 64+80, 280, 30)];
    deviceLabel.backgroundColor = [UIColor yellowColor];
    deviceLabel.textColor = [UIColor redColor];
    deviceLabel.text = @"设备:";
    _bDeviceLabel= deviceLabel;
    [self.view addSubview:deviceLabel];
    //
    UILabel *pressureLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(deviceLabel.frame), CGRectGetMaxY(deviceLabel.frame)+20, CGRectGetWidth(deviceLabel.frame), CGRectGetHeight(deviceLabel.frame))];
    pressureLabel.backgroundColor = [UIColor yellowColor];
    _pressureLabel = pressureLabel;
    [self.view addSubview:pressureLabel];
    //扫描设备
    UIButton *scanButton=[self quickButton:CGRectMake(self.view.frame.size.width/2-100, 300, 200, 30) backGroundColor:[UIColor blueColor] clickAction:@selector(foundDevice:) textColor:nil buttonText:@"扫描设备"];
    //连接设备
    UIButton *connectButton =[self quickButton:CGRectMake(CGRectGetMinX(scanButton.frame), CGRectGetMaxY(scanButton.frame)+20, 200, 40) backGroundColor:[UIColor greenColor] clickAction:@selector(connectDevice) textColor:[UIColor darkTextColor] buttonText:@"连接设备"];
    //断开连接
    UIButton *outButton =[self quickButton:CGRectMake(CGRectGetMinX(connectButton.frame), CGRectGetMaxY(connectButton.frame)+20, 200, 30) backGroundColor:[UIColor redColor] clickAction:@selector(cancelConnectDevice) textColor:nil buttonText:@"断开连接"];
    //发送请求
    UIButton *startButton = [self quickButton:CGRectMake(CGRectGetMinX(outButton.frame), CGRectGetMaxY(outButton.frame)+20, 200, 30) backGroundColor:[UIColor orangeColor] clickAction:@selector(sendConnect:) textColor:nil buttonText:@"开始测量"];
    [self quickButton:CGRectMake(CGRectGetMinX(startButton.frame), CGRectGetMaxY(startButton.frame)+20, 200, 30) backGroundColor:[UIColor yellowColor] clickAction:@selector(cloceDevice) textColor:[UIColor darkTextColor] buttonText:@"关闭设备"];
}

- (void)connectDevice
{
    NSLog(@"连接设备");
}

- (void)cancelConnectDevice
{
    NSLog(@"取消连接");
}

#pragma 关闭设备连接
- (void)cloceDevice
{
    [[BlueToothConnecter shareBlueToothConnecter] shutDownDevice];
}

#pragma mark - QuickControls
- (UILabel *)quickLabel:(CGRect)frame  backGroundColor:(UIColor *)backGroundColor  textColor:(UIColor *)textColor textFont:(UIFont *)font labelText:(NSString *)labelText
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = backGroundColor;
    label.textColor = textColor;
    label.font = font;
    label.text = labelText;
    [self.view addSubview:label];
    return label;
}

- (UIButton *)quickButton:(CGRect)frame backGroundColor:(UIColor *)backGroundColor clickAction:(SEL)actionSel  textColor:(UIColor *)textColor buttonText:(NSString *)btnText
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame =frame;
    btn.backgroundColor = backGroundColor;
    [btn setTitleColor:textColor forState:UIControlStateNormal];
    [btn setTitle:btnText forState:UIControlStateNormal];
    [btn addTarget:self action:actionSel forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}


@end
