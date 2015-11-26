//
//  BleDefines.h
//  BLEUseDemo
//
//  Created by JayZY on 15/11/17.
//  Copyright © 2015年 jayZY. All rights reserved.
//

#ifndef BleDefines_h
#define BleDefines_h


#define _PROXIMITY_ALERT_UUID                      0x1802
#define _PROXIMITY_ALERT_PROPERTY_UUID             0x2a06
#define _PROXIMITY_ALERT_ON_VAL                    0x01
#define _PROXIMITY_ALERT_OFF_VAL                   0x00
#define _PROXIMITY_ALERT_WRITE_LEN                 1
#define _PROXIMITY_TX_PWR_SERVICE_UUID             0x1804
#define _PROXIMITY_TX_PWR_NOTIFICATION_UUID        0x2A07
#define _PROXIMITY_TX_PWR_NOTIFICATION_READ_LEN    1

//#define _BATT_SERVICE_UUID                         0xFFB0
//#define _LEVEL_SERVICE_UUID                        0xFFB1
#define _BATT_SERVICE_UUID                         0x180F
#define _LEVEL_SERVICE_UUID                        0x2A19
#define _POWER_STATE_UUID                          0xFFB2
#define _LEVEL_SERVICE_READ_LEN                    1

#define _ACCEL_SERVICE_UUID                        0xFFA0
#define _ACCEL_ENABLER_UUID                        0xFFA1
#define _ACCEL_RANGE_UUID                          0xFFA2
#define _ACCEL_READ_LEN                            1
#define _ACCEL_X_UUID                              0xFFA3
#define _ACCEL_Y_UUID                              0xFFA4
#define _ACCEL_Z_UUID                              0xFFA5

#define _KEYS_SERVICE_UUID                         0xFFE0

#define _KEYS_NOTIFICATION_UUID                    0xFFE1
#define _KEYS_NOTIFICATION_READ_LEN                1

//Service
#define ISSC_SERVICE_UUID                          0xFFF0
//接收
#define ISSC_CHAR_RX_UUID                          0xFFF1
//发送
#define ISSC_CHAR_TX_UUID                          0xFFF2

#define WS(weakSelf) __weak typeof(self)weakSelf = self

#endif /* BleDefines_h */
