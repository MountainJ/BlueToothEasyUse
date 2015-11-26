//
//  BlueToothDataTransformTool.m
//  BLEUseDemo
//
//  Created by JayZY on 15/11/26.
//  Copyright © 2015年 jayZY. All rights reserved.
//

#import "BlueToothDataTransformTool.h"
#import "BleDefines.h"

@implementation BlueToothDataTransformTool

/**
 *  写入数据指令
 *
 *  @param serviceUUID
 *  @param characteristicUUID
 *  @param p
 *  @param data
 */
+ (void)writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    //手机发[0xFD,0xFD,0xFA,0x05,年,月,日,小时,分,秒,0x0D, 0x0A]
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
/**
 *  注册监听设备的特征值
 *
 *  @param p 连接的外设
 */
+(void)enableNotifyCBPeripheral:(CBPeripheral *)p
{
    [self notification:_KEYS_SERVICE_UUID characteristicUUID:_KEYS_NOTIFICATION_UUID p:p on:YES];
    [self notification:_PROXIMITY_TX_PWR_SERVICE_UUID characteristicUUID:_PROXIMITY_TX_PWR_NOTIFICATION_UUID p:p on:YES];
    [self notification:ISSC_SERVICE_UUID characteristicUUID:ISSC_CHAR_RX_UUID p:p on:YES];

}

+(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

+(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

+(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }
    return nil; //Service not found on this peripheral
}

+(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID])
            return c;
    }
    return nil; //Characteristic not found on this service
}

+(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:4];
    [UUID2.data getBytes:b2 length:4];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}
/**
 *  监听数据
 *
 *  @param serviceUUID
 *  @param characteristicUUID
 *  @param p
 *  @param on
 */
+(void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
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

@end
