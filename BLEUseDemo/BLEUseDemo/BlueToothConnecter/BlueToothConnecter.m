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

@property (nonatomic, copy) makeToast toastBlock;
@property (nonatomic, copy) startConnect startBlock;
@property (nonatomic, copy) scanNoBlueTeeth noDeviceBlock;
@property (nonatomic, copy) connectSuccess successBlock;

@end

@implementation BlueToothConnecter
{
    CBPeripheral *_peripheral;
}

+ (instancetype )shareBlueToothManager
{
    static BlueToothConnecter * connectManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        connectManager = [[BlueToothConnecter alloc] init];
    });
    return connectManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
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

- (BOOL)judgeBlueTeethOpenOrClose:(makeToast)block
{
    _toastBlock = block;
    if (_centralManager.state ==CBCentralManagerStatePoweredOff) {
        _toastBlock(@"蓝牙未连接");
        return NO;
    }
    [self foundDevice];
    return YES;
}

- (void)startConnect:(startConnect)startConnect ScanNoDevice:(scanNoBlueTeeth)noBlueTeeth Toast:(makeToast)toastBlock Success:(connectSuccess)success
{
    _startBlock = startConnect;
    _noDeviceBlock = noBlueTeeth;
    _successBlock = success;
    _toastBlock = toastBlock;
    if (_peripheral.state ==CBPeripheralStateConnected) {
        [self sendConnect];
    }else{
        _toastBlock(@"设备未连接");
    }
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
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
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

#pragma mark -开始扫描设备
- (void)foundDevice
{
    [SVProgressHUD showWithStatus:@"正在扫描" ];
    [self scanClick];
    __weak typeof(self) weakSelf = self;
    //扫描超时设置
    double delayInSeconds = 2.0;
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
     NSLog(@"advertisementData:%@ \n %@",advertisementData,peripheral.name);
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
        _toastBlock(@"没有搜索到设备,请打开设备电源进行连接!");
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
    [self.centralManager connectPeripheral:_peripheral options:nil]; //连接的时候有时候会没有连接上或者时间有点久...
    //连接超时设置
            double delayInSeconds = 10.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [SVProgressHUD dismiss];
            });
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
    //    [self.manager connectPeripheral:_peripheral options:nil];
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
//UUID处理部分
#pragma mark-
-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:1];
    return ((b1[0] << 8) | b1[1]);
}

#pragma mark - 写数据,开始测量
- (void)sendConnect
{
    [SVProgressHUD showWithStatus:@"正在测量" ];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    //手机发[0xFD,0xFD,0xFA,0x05,年,月,日,小时,分,秒,0x0D, 0x0A]
    [self enableButtons:_peripheral];
    [self enableTXPower:_peripheral];
    [self enableRead:_peripheral];
    //发送数据告之血压计,连接成功,并可以进行量测.
    uint8_t b[] = {0xFD,0xFD,0xFA,0x05,0X0D, 0x0A};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:b length:6];
    [self writeValue:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_TX_UUID p:_peripheral data:data];
}

#pragma mark -断开连接
- (void)cancelConnectDevice:(UIButton *)btn
{
    [self.centralManager cancelPeripheralConnection:_peripheral];
    [SVProgressHUD showErrorWithStatus:@"断开连接..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
}

#pragma mark -写数据, 关闭设备
- (void)cloceDevice:(UIButton *)btn
{
    //发送关闭信号
    uint8_t b[] = {0xFD,0xFD,0xFE,0x06,0X0D, 0x0A};
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

#pragma mark - 写入数据过后回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
    }else{
        NSLog(@"peripheral  didWriteValueForCharacteristic");
    }
}

#pragma mark -注册指定特征值监听,方便值改变时获取最新数据
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
    _successBlock(senderDict);
}

@end
