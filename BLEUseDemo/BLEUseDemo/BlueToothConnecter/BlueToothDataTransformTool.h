//
//  BlueToothDataTransformTool.h
//  BLEUseDemo
//
//  Created by JayZY on 15/11/26.
//  Copyright © 2015年 jayZY. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface BlueToothDataTransformTool : NSObject

/**
 *  对设备做数据写入
 *
 *  @param serviceUUID  服务UUID
 *  @param characteristicUUID     特征值UUID
 *  @param p         蓝牙设备
 *  @param data
 */
+ (void)writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;

/**
 *  注册监听设备的特征值
 *
 *  @param p 连接的外设
 */
+(void) enableNotifyCBPeripheral:(CBPeripheral *)p;

@end
