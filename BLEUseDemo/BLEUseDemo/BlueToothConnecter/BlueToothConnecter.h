//
//  BlueToothConnecter.h
//
//
//  Created by jayZY on 15/11/24.
//  Copyright © 2015年 1192129419@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
//测量成功或者失败的回掉
typedef void(^measureSuccess)(NSDictionary * resultDict);
typedef void(^measureFailure)(NSError * error);
//检查蓝牙是关闭或者打开
typedef void(^blueToothPowerOn)();
typedef void(^blueToothPowerOff)();

@interface BlueToothConnecter : NSObject

/**
 *  注册中央maneger
 */
- (void)registerBlueToothManager;

/**
 *  获取连接管理对象
 *
 *  @return
 */
+ (instancetype)shareBlueToothConnecter;

/**
 *  检测蓝牙是否打开或者关闭
 *
 *  @param blueToothOn
 *  @param blueToothOff
 */
- (void)checkBlueToothPowerOn:(blueToothPowerOn)blueToothPowerOn powerOff:(blueToothPowerOff)blueToothPowerOff;

/**
 *  找到外设
 */
- (void)scanPeripheralsCompletion: (void (^)(NSArray *scanPeripherals))scanPepipheralArray;
/**
 *  开始测量
 *
 *  @param success
 *  @param failure
 */

- (void)startHandleMeasureSuccess:(measureSuccess)success  failure:(measureFailure)failure;

/**
 *  关闭设备
 */
- (void)shutDownDevice;

@end
