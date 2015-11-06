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



@interface RootViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBPeripheral *_peripheral;
    UILabel *_bDeviceLabel; //搜索到的蓝牙设备名称

}

@property(nonatomic,strong) CBCentralManager *manager;

@property (nonatomic,strong) NSMutableArray *peripheralNames;

@end

@implementation RootViewController

- (NSMutableArray *)peripheralNames
{
    if (!_peripheralNames) {
        _peripheralNames = [NSMutableArray array];
    }
    return _peripheralNames;
}


- (void)viewDidLoad {
    [super viewDidLoad];
     self.view.backgroundColor  =[UIColor lightGrayColor];
    [self configUI];
    //创建CBCentralManager *manager ,设置代理,每次都检测蓝牙设备是否开启,如果关闭就会有系统提示开启
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
#pragma mark -1蓝牙开启或者关闭状态实时监测.该方法会根据设备蓝牙的状态多次调用...
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
        default:
            break;
    }
}

#pragma mark -2扫描可用的外设
//点击开始进行扫描
-(void)scanClick
{   /*
     第一个参数为空,即为返回所有的设备;第二个参数设置是否重名等
     */
    [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
}

#pragma mark -2查找到外设过后,回调
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
     NSLog(@"peripheral.name:%@",peripheral.name);
    //RBP1508010664,MI,MiniBeacon_04819,这是搜索到的3个蓝牙设备名称,根据实际情况更改
    /*查找到指定的外设进行操作 [peripheral.name isEqualToString:@"MI"] */
    if (peripheral.name) {
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"找到设备:%@",peripheral.name]];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        _bDeviceLabel.text =[NSString stringWithFormat:@"设备:%@", peripheral.name];
            /*停止扫描*/
            [self.manager stopScan];    
            _peripheral = peripheral;
    }
}

#pragma mark -3假设连接成功了这个设备
//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接成功");
    _bDeviceLabel.text =[NSString stringWithFormat:@"设备:%@连接成功", _peripheral.name];
    [SVProgressHUD showSuccessWithStatus:@"连接成功"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    //
    [SVProgressHUD showWithStatus:@"更新数据..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    /*连接成功过后,设置外设代理*/
    [_peripheral setDelegate:self];
#pragma mark -4发现外设提供了哪些服务,设置    [peripheral discoverServices:nil];传空代表查询全部服务,一般需要获取服务的UUID,参数( NSArray<CBUUID *> *)serviceUUIDs
//    NSArray *cbUUIDS = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"FEE0"],[CBUUID UUIDWithString:@"FEE1"], nil];
    [_peripheral discoverServices:nil];//外设设置了查找服务,会调用 [peripheral:didUpdateValueForCharacteristic:error:]方法
    //读取外设距离
    [_peripheral readRSSI];
}
//外设连接失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s",__func__);
    [SVProgressHUD showErrorWithStatus:@"连接失败..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    NSLog(@"连接失败");
}

#pragma mark -4发现查找设备的服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"%s",__func__);
    if (!error) {
        NSLog(@"已经找到服务%@",peripheral.services);
        /*
         2015-11-06 09:44:45.640 BLEUseDemo[7332:1054771] 已经找到服务(
         "<CBService: 0x17e4d8d0, isPrimary = YES, UUID = FEE0>",
         "<CBService: 0x17e378e0, isPrimary = YES, UUID = FEE1>",
         "<CBService: 0x17e46ba0, isPrimary = YES, UUID = FEE7>",
         "<CBService: 0x17e4ece0, isPrimary = YES, UUID = 1802>"
         )
         */
        [SVProgressHUD showSuccessWithStatus:@"数据更新成功..."];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
#pragma mark -5找到了服务过后去找服务的特征(1个服务会对应多个特征),  [peripheral discoverCharacteristics:nil forService:interestingService];第一个参数传空返回所有服务特征
        //    for (CBService *service in peripheral.services) {
        //        /*设置查找特征,类似服务的查找*/
        //        [_peripheral discoverCharacteristics:nil forService:service];
        //    }
        /*设置查找特征过后会调用2个方法,peripheral: didDiscoverCharacteristicsForService: error:(NSError *)error;然后会调用,peripheral: didUpdateValueForCharacteristic: error:*/
        [_peripheral discoverCharacteristics:nil forService:peripheral.services[0]];
    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
   
}

#pragma mark -5已经查找到了服务的特征
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"%s",__func__);
    if (!error) {
        NSLog(@"已经找到指定服务的特征");
        NSLog(@"找到服务的特征是:%@",service.characteristics);
        /*
         2015-11-06 09:58:00.563 BLEUseDemo[7374:1058331] 找到服务的特征是:(
         "<CBCharacteristic: 0x17e6bfd0, UUID = FF01, properties = 0x2, value = (null), notifying = NO>",
         "<CBCharacteristic: 0x17e7cfd0, UUID = FF02, properties = 0xA, value = (null), notifying = NO>",
         "<CBCharacteristic: 0x17e7f440, UUID = FF03, properties = 0x12, value = (null), notifying = NO>"
         )
         */
        //要获取到指定的特征,通过比较UUID
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            #pragma mark -6找到感兴趣的服务特征,读取特征的值  [peripheral readValueForCharacteristic:interestingCharacteristic];然后回调方法peripheral: didUpdateValueForCharacteristic: error:
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF0F"]]) {
                NSLog(@"查找到制定的UUID后,读取值....");
                [_peripheral readValueForCharacteristic:characteristic];
            }
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF0E"]]) {
                NSLog(@"正在匹配特征的UUID值...");
            }

        }
    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
    
}

#pragma mark -6读服务特征值
//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。不是所有的特征值都可以被读,如果为不可读的数值,返回错误信息
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%s",__func__);
       if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF0F"]]) {
           NSString *value = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
           NSLog(@"characteristic.value:%@",value);
           
#pragma mark -7订阅感兴趣的服务特征值  [peripheral setNotifyValue:YES forCharacteristic:interestingCharacteristic];
        /*当外设服务的值改变的时候调用以下方法启动监听*/
        [_peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
       }else{
        NSLog(@"didUpdateValueForCharacteristicData:::%@",[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
       }
    
}

#pragma mark -7订阅后,每次当外设的特征值发生改变后,都会调用以下的方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%s",__func__);
    if (error) {
        NSLog(@"Error changing notification state: %@",[error localizedDescription]);
//        return;
    }
    if (characteristic.isNotifying) {
        NSLog(@"_peripheral readValueUpdateNotificationStateForCharacteristic");
//        [_peripheral readValueForCharacteristic:characteristic];
        
    } else {
           NSLog(@"noting...//test writing data");
            #pragma mark -8 向外设写入特征数据,比如温度改写  writeValue:forCharacteristic:type:/ CBPeripheral 类中
            NSData *cData = characteristic.value;
            [_peripheral writeValue:cData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    

    
}

#pragma mark -8 写入数据过后,回调的方法,会进行设备与手机配对
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%s",__func__);
    if (error) {
        NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
    }
}

#pragma mark -外设设置代理后更新外设距离
-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s",__func__);
    int rssi = abs([peripheral.RSSI intValue]);
    CGFloat ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"BLT4.0热点:%@,距离:%.1fm",_peripheral,pow(10,ci)];
    NSLog(@"%@",length);
}

#pragma mark - 界面配置...
-(void)configUI
{
    self.title = @"BlueToothUse";
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-140, 64+20, 280, 30)];
    label.backgroundColor = [UIColor yellowColor];
    label.textColor = [UIColor redColor];
    label.text = @"设备....";
    _bDeviceLabel= label;
    [self.view addSubview:label];
    //扫描设备
    UIButton *scanButton=[self quickButton:CGRectMake(self.view.frame.size.width/2-100, 400, 200, 30) backGroundColor:[UIColor blueColor] clickAction:@selector(foundDevice:) textColor:nil buttonText:@"扫描设备"];
    //连接设备
  UIButton *connectButton =[self quickButton:CGRectMake(CGRectGetMinX(scanButton.frame), CGRectGetMaxY(scanButton.frame)+20, 200, 40) backGroundColor:[UIColor greenColor] clickAction:@selector(connectDevice:) textColor:[UIColor darkTextColor] buttonText:@"连接设备"];
    //断开连接
    [self quickButton:CGRectMake(CGRectGetMinX(connectButton.frame), CGRectGetMaxY(connectButton.frame)+20, 200, 30) backGroundColor:[UIColor redColor] clickAction:@selector(cancelConnectDevice:) textColor:nil buttonText:@"断开连接"];
}

- (UIButton *)quickButton:(CGRect)frame backGroundColor:(UIColor *)backGroundColor clickAction:(SEL)actionSel  textColor:(UIColor *)textColor buttonText:(NSString *)btnText;
{
    //
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame =frame;
    btn.backgroundColor = backGroundColor;
    [btn setTitleColor:textColor forState:UIControlStateNormal];
    [btn setTitle:btnText forState:UIControlStateNormal];
    [btn addTarget:self action:actionSel forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}
#pragma mark - 断开连接
- (void)cancelConnectDevice:(UIButton *)btn
{
    [self.manager cancelPeripheralConnection:_peripheral];
    [SVProgressHUD showErrorWithStatus:@"断开连接..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    _bDeviceLabel.text = [NSString stringWithFormat:@"设备%@已经断开",_peripheral.name];
}

#pragma mark - 连接设备
-(void)connectDevice:(UIButton *)btn
{
    if (_peripheral.name ==nil) {
        return;
    }
    [SVProgressHUD showWithStatus:@"正在连接" ];
#pragma mark -3连接发现的这个外设
    /*发现这个设备过后开始连接,连接成功后回调[centralManager: didConnectPeripheral:]*/
    [self.manager connectPeripheral:_peripheral options:nil]; //连接的时候有时候会没有连接上或者时间有点久...
    //连接超时设置
        double delayInSeconds = 30.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [SVProgressHUD dismiss];
            [self.manager cancelPeripheralConnection:_peripheral];
        });
}
#pragma mark -发现设备
- (void)foundDevice:(UIButton *)btn
{
    [SVProgressHUD showWithStatus:@"正在扫描" ];
    [self scanClick];
    //连接超时设置
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        [self.manager stopScan];
    });
}


@end
