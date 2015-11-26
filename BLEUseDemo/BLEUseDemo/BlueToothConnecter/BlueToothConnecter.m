//
//  BlueToothConnecter.m
//
//
//  Created by jayZY on 15/11/24.
//  Copyright © 2015年 1192129419@qq.com. All rights reserved.
//

#import "BlueToothConnecter.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MLTableAlert.h"
#import "BleDefines.h"
#import "SVProgressHUD.h"
#import "BlueToothDataTransformTool.h"



@interface BlueToothConnecter ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) NSMutableArray *peripheralNames;
@property (nonatomic,strong) NSMutableArray *devices;
@property (strong, nonatomic) MLTableAlert *alert;
//
@property (nonatomic)   float batteryLevel;
@property (nonatomic)   BOOL key1;
@property (nonatomic)   BOOL key2;
@property (nonatomic)   char x;
@property (nonatomic)   char y;
@property (nonatomic)   char z;
@property (nonatomic)   char TXPwrLevel;

@property (nonatomic, copy) measureSuccess successMeasure;
@property (nonatomic, copy) measureFailure failureMeasure;

@property (nonatomic, copy) blueToothPowerOn blueToothPowerOn;
@property (nonatomic, copy) blueToothPowerOff blueToothPowerOff;


@end

@implementation BlueToothConnecter
{
    CBPeripheral *_peripheral;
}

-(void)registerBlueToothManager
{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

+ (instancetype )shareBlueToothConnecter
{
    static BlueToothConnecter * connectManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        connectManager = [[BlueToothConnecter alloc] init];
    });
    return connectManager;
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

- (void)scanPeripheralsCompletion:(void (^)(NSArray *))scanPepipheralArray
{
    [SVProgressHUD showWithStatus:@"正在扫描" ];
    [self scanClick];
     WS(weakSelf);
    //扫描超时设置
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        [weakSelf.centralManager stopScan];
        [weakSelf showScanDeviceName:weakSelf.peripheralNames];
        scanPepipheralArray(weakSelf.devices);
    });
}

-(void)startHandleMeasureSuccess:(measureSuccess)success failure:(measureFailure)failure
{
    [self startMeasure];
    _successMeasure = success;
    _failureMeasure = failure;
}

#pragma mark -中央设备蓝牙状态监测
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
            NSLog(@"CBCentralManagerStatePoweredOn");
            _blueToothPowerOn();
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            _blueToothPowerOff();
            [self.devices removeAllObjects];
            NSLog(@"CBCentralManagerStatePoweredOff");
        }
            break;
        default:
        {
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        }
    }
}

-(void)checkBlueToothPowerOn:(blueToothPowerOn)blueToothPowerOn powerOff:(blueToothPowerOff)blueToothPowerOff
{
    _blueToothPowerOn = blueToothPowerOn;
    _blueToothPowerOff = blueToothPowerOff;
}

#pragma mark -写数据, 关闭设备
-(void)shutDownDevice
{
    //发送关闭信号
    uint8_t b[] = {0xFD,0xFD,0xFE,0x06,0X0D, 0x0A};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:b length:6];
    [BlueToothDataTransformTool writeValue:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_TX_UUID p:_peripheral data:data];
}

#pragma mark -开始扫描设备
- (void)foundDevice
{
    [SVProgressHUD showWithStatus:@"正在扫描" ];
    [self scanClick];
    __weak typeof(self) weakSelf = self;
    //扫描限时时设置
    double delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        [weakSelf.centralManager stopScan];
        [weakSelf showScanDeviceName:weakSelf.peripheralNames];
        
    });
}

-(void)scanClick
{
    [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

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
//     NSLog(@"advertisementData:%@ \n %@",advertisementData,peripheral.name);
    if (![self.peripheralNames containsObject:peripheral.name]&&peripheral.name) {
        [self.peripheralNames addObject:peripheral.name];
        CBPeripheral *peripherals = peripheral;
        [self.devices addObject:peripherals];
    }
}

#pragma mark - 展示搜索到的蓝牙设备,并进行连接
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
        NSLog(@"没有搜索到设备,请打开设备电源进行连接!");
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
        /*连接选择的蓝牙设备*/
        [weakSelf connectDevice];
    } andCompletionBlock:^{
        
    }];
    [self.alert show];
}

-(void)connectDevice
{
    if (_peripheral.name ==nil) {
        return;
    }
    [SVProgressHUD showWithStatus:@"正在连接" ];
    /*连接成功过后,设置外设代理*/
    [_peripheral setDelegate:self];
    /*发现这个设备过后开始连接,连接成功后回调[centralManager: didConnectPeripheral:]*/
    [self.centralManager connectPeripheral:_peripheral options:nil];
    //连接超时设置
//            double delayInSeconds = 10.0;
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                [SVProgressHUD dismiss];
//            });
}

/**
 *  成功连接了设备
 *
 *  @param central
 *  @param peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [SVProgressHUD showSuccessWithStatus:@"连接成功"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [_peripheral readRSSI];
    [_peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:@"连接失败..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //需要进行回连
        [self.centralManager connectPeripheral:_peripheral options:nil];
}

#pragma mark -查找已经连接设备提供的服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (!error) {
        [SVProgressHUD showSuccessWithStatus:@"读取数据..."];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        /*读出所有服务特征值*/
        [self getAllCharacteristicsFromKeyfob:peripheral];
    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
}
/**
 *  查询设备提供的服务
 *
 *  @param peripheral
 */
-(void) getAllCharacteristicsFromKeyfob:(CBPeripheral *)peripheral{
    for (int i=0; i < peripheral.services.count; i++) {
        CBService *service = [peripheral.services objectAtIndex:i];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
/**
 *  查询服务特征的所有值
 *
 *  @param peripheral
 *  @param service
 *  @param error
 */
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (!error) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            [_peripheral readValueForCharacteristic:characteristic];
        }
    }else {
        NSLog(@"%@",[error localizedDescription]);
    }
    
}

#pragma mark -订阅,当外设的特征值发生改变后调用
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

#pragma mark -获取数据，不论是read和notify,获取数据都是从这取。不是所有的特征值都可以被读,如果为不可读的数值,返回错误信息
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

-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:1];
    return ((b1[0] << 8) | b1[1]);
}

#pragma mark - 写数据,开始测量
- (void)startMeasure
{
    [SVProgressHUD showWithStatus:@"正在测量" ];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    //发送数据告之血压计,连接成功,并可以进行量测.
    uint8_t b[] = {0xFD,0xFD,0xFA,0x05,0X0D, 0x0A};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:b length:6];
    [BlueToothDataTransformTool enableNotifyCBPeripheral:_peripheral];
    [BlueToothDataTransformTool writeValue:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_TX_UUID p:_peripheral data:data];
}

#pragma mark -断开连接
- (void)cancelConnectDevice:(UIButton *)btn
{
    [self.centralManager cancelPeripheralConnection:_peripheral];
    [SVProgressHUD showErrorWithStatus:@"断开连接..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
}



#pragma mark - 写入数据过后回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
    }else{
        NSLog(@"peripheral  didWriteValueForCharacteristic");
    }
}

#pragma mark ----数据结果展示----
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
         NSError *error = [NSError errorWithDomain:err code:555 userInfo:nil];
         _failureMeasure(error);
    }
}

#pragma mark -测量过程中的压力值
-(void)TestShowGetPressureH:(uint8_t)pressureH PressureL:(uint8_t)pressureL
{
    //测量过程压力值
    //    top = pressureH*256 + pressureL;
    //    _pressureLabel.text = [NSString stringWithFormat:@"压力的值为%d",top];
}
#pragma mark - 接收到的最后结果
-(void)TestShowGetData:(uint8_t)sys DIA:(uint8_t)dia PUL:(uint8_t)pul
{
    [SVProgressHUD dismiss];
    NSDictionary * senderDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",sys],@"sys",
                                                                           [NSString stringWithFormat:@"%d",dia],@"dia",
                                                                           [NSString stringWithFormat:@"%d",pul],@"pul",nil];
    _successMeasure(senderDict);
}

@end
