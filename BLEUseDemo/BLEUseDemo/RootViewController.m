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

#import "MLTableAlert.h"


@interface RootViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBPeripheral *_peripheral;
    UILabel *_bDeviceLabel; //搜索到的蓝牙设备名称
    int top;//测试标志
    UILabel *_pressureLabel;

}
@property(nonatomic,strong) CBCentralManager *manager;

@property (nonatomic,strong) NSMutableArray *peripheralNames;
//系统蓝牙连接及进度状态提醒
@property (nonatomic,strong) UIView *indicatorView;
@property (nonatomic,strong) UILabel *indicatorLabel;
//设备
@property (nonatomic,strong) NSMutableArray *devices;

@property (nonatomic,strong) NSMutableDictionary *pdevicesObj;

@property (strong, nonatomic) MLTableAlert *alert;

@property (nonatomic)   float batteryLevel;
@property (nonatomic)   BOOL key1;
@property (nonatomic)   BOOL key2;
@property (nonatomic)   char x;
@property (nonatomic)   char y;
@property (nonatomic)   char z;
@property (nonatomic)   char TXPwrLevel;


@end

@implementation RootViewController


- (NSMutableDictionary *)pdevicesObj
{
    if (!_pdevicesObj) {
        _pdevicesObj = [NSMutableDictionary dictionary ];
    }
    return _pdevicesObj;
}

- (NSMutableArray *)peripheralNames
{
    if (!_peripheralNames) {
        _peripheralNames = [NSMutableArray array];
    }
    return _peripheralNames;
}

- (NSMutableArray *)devices
{
    if (!_devices) {
        _devices = [NSMutableArray array];
    }
    return _devices;
}


- (void)viewDidLoad {
    [super viewDidLoad];
     self.view.backgroundColor  =[UIColor whiteColor];
    [self configUI];
    //创建CBCentralManager *manager ,设置代理,每次都检测蓝牙设备是否开启,如果关闭就会有系统提示开启.当Central Manager被初始化，我们要检查它的状态，以检查运行这个App的设备是不是支持BLE
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark -1蓝牙开启或者关闭状态实时监测.该方法会根据设备蓝牙的状态多次调用...
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStateResetting:
        {
            NSLog(@"CBCentralManagerStateResetting");
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            [self indicatorView];
            self.indicatorLabel.text = @"开始扫描设备";
            self.indicatorLabel.textColor = [UIColor darkTextColor];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundDevice:)];
            [self.indicatorLabel addGestureRecognizer:tap];
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            [self indicatorView];
            self.indicatorLabel.textColor = [UIColor redColor];
            self.indicatorLabel.text = @"蓝牙没有打开,请在设置中连接";
        }
        default:
        {
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        }
    }
}
/*
 第一个参数为空,即为返回所有的设备;第二个参数设置是否重名等
 */
-(void)scanClick
{
    [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
}

#pragma mark - 代理方法
/**
 *  查找到外设过后,回调 RSSI描述蓝牙设备距离的参数
 *
 *  @param central
 *  @param peripheral
 *  @param advertisementData  任何广播、扫描的响应数据保存在advertisementData 中{kCBAdvDataIsConnectable,kCBAdvDataLocalName,kCBAdvDataServiceUUIDs}
 *  @param RSSI              Received Signal Strength Indicator /信号质量
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.peripheralNames containsObject:peripheral.name]&&peripheral.name) {
        [self.peripheralNames addObject:peripheral.name];
        CBPeripheral *peripherals = peripheral;
        [self.devices addObject:peripherals];
    }
//    if ([peripheral.name isEqual:@"Bluetooth BP"]) {
//        //读取外设距离
//        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"找到设备:%@",peripheral.name]];
//        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
//        _bDeviceLabel.text =[NSString stringWithFormat:@"设备:%@", peripheral.name];
//        _peripheral = peripheral;
//        /*停止扫描*/
//        [self.manager stopScan];
//    }
}
/**
 *  弹出搜索到的蓝牙列表进行选择连接
 *
 *  @param pDevices 设备名称(peripheral.name)
 */
- (void)showScanDeviceName:(NSMutableArray *)pDevices
{
    __weak typeof(self) weakSelf = self;
    /*没有搜索到蓝牙设备,提示*/
    if (!pDevices.count) {
    _pressureLabel.text = @"没有搜索到设备,请打开设备电源进行连接!";
        return;
    }
    //展示设备列表,并根据点击列表进行判断连接的设备;
    self.alert = [MLTableAlert tableAlertWithTitle:@"设备" cancelButtonTitle:@"取消" numberOfRows:^NSInteger (NSInteger section)
                  {
                      return pDevices.count;
                  }
                                          andCells:^UITableViewCell* (MLTableAlert *anAlert, NSIndexPath *indexPath)
                  {
                      static NSString *CellIdentifier = @"CellIdentifier";
                      UITableViewCell *cell = [anAlert.table dequeueReusableCellWithIdentifier:CellIdentifier];
                      if (cell == nil)
                          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                      cell.textLabel.text = [NSString stringWithFormat:@"%@", pDevices[indexPath.row]];
                      return cell;
                  }];
    
    self.alert.height = 350;
    [self.alert configureSelectionBlock:^(NSIndexPath *selectedIndex){
       _peripheral = weakSelf.devices[selectedIndex.row];
      [weakSelf connectDevice:nil];
    } andCompletionBlock:^{
        
//        self.resultLabel.text = @"Cancel Button Pressed\nNo Cells Selected";
    }];
    [self.alert show];
    
}

#pragma mark -外设设置代理后更新外设距离
-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    int rssi = abs([RSSI intValue]);
    CGFloat ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"BLT4.0热点:%@,距离:%.1fm",_peripheral,pow(10,ci)];
    NSLog(@"%@",length);
}

#pragma mark -成功连接了设备
/**
 *  成功连接了设备
 *
 *  @param central
 *  @param peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    _bDeviceLabel.text =[NSString stringWithFormat:@"设备:%@连接成功", _peripheral.name];
    [SVProgressHUD showSuccessWithStatus:@"连接成功"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [_peripheral readRSSI];//peripheral:didReadRSSI:error
  
#pragma mark -  [peripheral discoverServices:nil];传空代表查询全部服务,一般需要获取服务的UUID,参数( NSArray<CBUUID *> *)serviceUUIDs
//    NSArray *cbUUIDS = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"FEE0"],[CBUUID UUIDWithString:@"FEE1"], nil];
    [_peripheral discoverServices:nil];//外设设置了查找服务,会调用 [peripheral:didUpdateValueForCharacteristic:error:]方法
}
/**
 *  外设连接失败
 *
 *  @param central
 *  @param peripheral
 *  @param error
 */
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:@"连接失败..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
}
/**
 *  连接中断,一般要设置自动重连
 *
 *  @param central
 *  @param peripheral
 *  @param error
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
//    NSLog(@"连接中突然断开了...");
//需要进行回连
//    [self.manager connectPeripheral:_peripheral options:nil];
}

#pragma mark -查找设备提供的服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (!error) {
        NSLog(@"已经找到服务%@",peripheral.services);
        [SVProgressHUD showSuccessWithStatus:@"数据更新..."];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        /*读出所有服务特征值*/
        [self getAllCharacteristicsFromKeyfob:peripheral];
    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
}
/**
 *  查询所有服务特征值
 *
 *  @param peripheral
 */
-(void) getAllCharacteristicsFromKeyfob:(CBPeripheral *)peripheral{
    for (int i=0; i < peripheral.services.count; i++) {
        CBService *service = [peripheral.services objectAtIndex:i];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

#pragma mark -找到了服务特征值
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (!error) {
//        //要获取到指定的特征,通过比较UUID
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            #pragma mark -找到感兴趣的服务特征,读取特征的值  [peripheral readValueForCharacteristic:interestingCharacteristic];然后回调方法peripheral: didUpdateValueForCharacteristic: error:
            [_peripheral readValueForCharacteristic:characteristic];
        }

    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
    
}

#pragma mark -获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。不是所有的特征值都可以被读,如果为不可读的数值,返回错误信息
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    UInt16 characteristicUUID = [self CBUUIDToInt:characteristic.UUID];
     if (!error) {
        switch(characteristicUUID)
        {
            case _LEVEL_SERVICE_UUID:
            {
                char batlevel;
                [characteristic.value getBytes:&batlevel length:_LEVEL_SERVICE_READ_LEN];
                self.batteryLevel = (float)batlevel;
                break;
            }
            case _KEYS_NOTIFICATION_UUID://FFE1
            {
                unsigned char keys[2048] = {0};
                [characteristic.value getBytes:keys length:[characteristic.value length]];
                [self DisplayRece:keys length:[characteristic.value length]];
                self.key1 = (keys[0] & 0x01);
                self.key2 = (keys[0] & 0x02);
//                [self  keyValuesUpdated: keys[0]];
                break;
            }
            case _ACCEL_X_UUID:
            {
                char xval;
                [characteristic.value getBytes:&xval length:_ACCEL_READ_LEN];
                self.x = xval;
//                [self  accelerometerValuesUpdated:self.x y:self.y z:self.z];
                break;
            }
            case _ACCEL_Y_UUID:
            {
                char yval;
                [characteristic.value getBytes:&yval length:_ACCEL_READ_LEN];
                self.y = yval;
//                [[self delegate] accelerometerValuesUpdated:self.x y:self.y z:self.z];
                break;
            }
            case _ACCEL_Z_UUID:
            {
                char zval;
                [characteristic.value getBytes:&zval length:_ACCEL_READ_LEN];
                self.z = zval;
//                [[self delegate] accelerometerValuesUpdated:self.x y:self.y z:self.z];
                break;
            }
            case _PROXIMITY_TX_PWR_NOTIFICATION_UUID:
            {
                char TXLevel;
                [characteristic.value getBytes:&TXLevel length:_PROXIMITY_TX_PWR_NOTIFICATION_READ_LEN];
                self.TXPwrLevel = TXLevel;
                break;
//                [[self delegate] TXPwrLevelUpdated:TXLevel];
            }
            case ISSC_CHAR_RX_UUID:
            {
                unsigned char buf[4096] = {0};
                [characteristic.value getBytes:buf length:[characteristic.value length]];
                [self DisplayRece:buf length:[characteristic.value length]];
                break;
            }
            default://接收到数据进行展示 FF9E
            {
                unsigned char buf[4096] = {0};
                [characteristic.value getBytes:buf length:[characteristic.value length]];
                [self DisplayRece:buf length:[characteristic.value length]];
                break;
            }
        }
    }else{
        NSLog(@"updateValueForCharacteristic failed !----%@",[error localizedDescription]);
    }
    
}

#pragma mark -订阅,每次当外设的特征值发生改变后,都会调用以下的方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"peripheral    didUpdateNotification   StateForCharacteristic:");
    if (error) {
        NSLog(@"Error state: %@",[error localizedDescription]);
        return;
    }
    if (characteristic.isNotifying) {
        NSLog(@"_peripheral readValueUpdateNotificationStateForCharacteristic");
        
    } else {
           NSLog(@"noting...//test writing data");
        
    }
}

#pragma mark - 关闭设备
- (void)cloceDevice:(UIButton *)btn
{
    //发送关闭信号
    uint8_t b[] = {0xFD,0xFD,0xFE,0x06,0X0D, 0x0A};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:b length:6];
    [self writeValue:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_TX_UUID p:_peripheral data:data];
}

#pragma mark - 开始测量等
- (void)sendConnect:(UIButton *)btn
{
#pragma mark -向外设写入特征数据  writeValue:forCharacteristic:type:/ CBPeripheral 类中
    //手机发[0xFD,0xFD,0xFA,0x05,年,月,日,小时,分,秒,0x0D, 0x0A]
    [self enableButtons:_peripheral];         // Enable button service (if found)
    [self enableTXPower:_peripheral];         // Enable TX power service (if found)
    [self enableRead:_peripheral];
    //发送数据告之血压计,连接成功,并可以进行量测.
    uint8_t b[] = {0xFD,0xFD,0xFA,0x05,0X0D, 0x0A};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:b length:6];
    [self writeValue:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_TX_UUID p:_peripheral data:data];
}

/**
 *  写入数据指令
 *
 *  @param serviceUUID
 *  @param characteristicUUID
 *  @param p
 *  @param data
 */
-(void)writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];  //ISSC
}
#pragma mark - 写入数据过后,回调的方法,会进行设备与手机配对
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
    }else{
        NSLog(@"%s",__func__);
    }
}

-(void) enableButtons:(CBPeripheral *)p {
    [self notification:_KEYS_SERVICE_UUID characteristicUUID:_KEYS_NOTIFICATION_UUID p:p on:YES];
}

-(void) enableTXPower:(CBPeripheral *)p {
    [self notification:_PROXIMITY_TX_PWR_SERVICE_UUID characteristicUUID:_PROXIMITY_TX_PWR_NOTIFICATION_UUID p:p on:YES];
}

-(void)enableRead:(CBPeripheral*)p
{
    [self notification:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_RX_UUID p:p on:YES];
}

-(void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
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
    /*连接成功过后,设置外设代理*/
    [_peripheral setDelegate:self];
    /*发现这个设备过后开始连接,连接成功后回调[centralManager: didConnectPeripheral:]*/
    [self.manager connectPeripheral:_peripheral options:nil]; //连接的时候有时候会没有连接上或者时间有点久...
    //连接超时设置
//        double delayInSeconds = 10.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            [SVProgressHUD dismiss];
//            [self.manager cancelPeripheralConnection:_peripheral];
//        });
}

#pragma mark -开始扫描设备
- (void)foundDevice:(UIButton *)btn
{
    [SVProgressHUD showWithStatus:@"正在扫描" ];
    [self scanClick];
    //连接超时设置
    __weak typeof(self) weakSelf = self;
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        [weakSelf.manager stopScan];
        [weakSelf showScanDeviceName:weakSelf.peripheralNames];
    });
}

#pragma mark--
-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:1];
    return ((b1[0] << 8) | b1[1]);
}

#pragma mark -展示数据
-(void)DisplayRece:(unsigned char*)buf length:(int)len
{
    NSString *err = nil;
    //1：数据至少6个字节
    if (len < 6) {
        return;
    }
    //2：检查命令头
    if (buf[0] != 0xFD || buf[1] != 0xFD) {
        return;
    }
    //3：检查命令尾
    if (buf[len-2] != 0x0D || buf[len-1] != 0x0A) {
        return;
    }
    //4：命令类型
    switch (buf[2])
    {
        case 0xFB: //测过程中发出的压力信号
            [self TestShowGetPressureH:buf[3] PressureL:buf[4]];
            break;
            
        case 0xFC: //测量的结果
        {
            [self TestShowGetData:buf[4] DIA:buf[5] PUL:buf[6]];
             break;
        }
        case 0xFD: //错误代码
            switch (buf[3])
            {
                case 0x0E: //EEPROM异常
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error0E", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x01: //人体心跳信号太小或压力突降
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error01", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x02: //杂讯干扰
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error02", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x03: //充气时间过长
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error03", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x05: //测得的结果异常
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error05", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x0C: //校正异常
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error0C", @"InfoPlist", nil), buf[3]];
                    break;
                case 0x0B: //电源低电压
                    err = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error0B", @"InfoPlist", nil), buf[3]];
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    //显示错误信息
    if (err ) {
        NSLog(@"%@",[err localizedCapitalizedString]);
    }
}

-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
        return s;
    }
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID])
        return c;
    }
    return nil; //Characteristic not found on this service
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:4];
    [UUID2.data getBytes:b2 length:4];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

#pragma mark -测量过程压力值
-(void)TestShowGetPressureH:(uint8_t)pressureH PressureL:(uint8_t)pressureL
{
    //测量过程压力值
    top = pressureH*256 + pressureL;
//    _pressureLabel.text = [NSString stringWithFormat:@"压力的值为%d",top];

}
#pragma mark - 处理接收到的结果数据
-(void)TestShowGetData:(uint8_t)sys DIA:(uint8_t)dia PUL:(uint8_t)pul
{
    _pressureLabel.text = [NSString stringWithFormat:@"结果sys=%d,dia=%d,pul=%d",sys,dia,pul];
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
    UIButton *connectButton =[self quickButton:CGRectMake(CGRectGetMinX(scanButton.frame), CGRectGetMaxY(scanButton.frame)+20, 200, 40) backGroundColor:[UIColor greenColor] clickAction:@selector(connectDevice:) textColor:[UIColor darkTextColor] buttonText:@"连接设备"];
    //断开连接
    UIButton *outButton =[self quickButton:CGRectMake(CGRectGetMinX(connectButton.frame), CGRectGetMaxY(connectButton.frame)+20, 200, 30) backGroundColor:[UIColor redColor] clickAction:@selector(cancelConnectDevice:) textColor:nil buttonText:@"断开连接"];
    //发送请求
    UIButton *startButton = [self quickButton:CGRectMake(CGRectGetMinX(outButton.frame), CGRectGetMaxY(outButton.frame)+20, 200, 30) backGroundColor:[UIColor orangeColor] clickAction:@selector(sendConnect:) textColor:nil buttonText:@"开始测量"];
    [self quickButton:CGRectMake(CGRectGetMinX(startButton.frame), CGRectGetMaxY(startButton.frame)+20, 200, 30) backGroundColor:[UIColor yellowColor] clickAction:@selector(cloceDevice:) textColor:[UIColor darkTextColor] buttonText:@"关闭设备"];
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
