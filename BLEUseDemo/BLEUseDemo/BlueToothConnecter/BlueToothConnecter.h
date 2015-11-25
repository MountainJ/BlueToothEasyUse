//
//  BlueToothConnecter.h
//
//
//  Created by jayZY on 15/11/24.
//  Copyright © 2015年 1192129419@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^makeToast)(NSString *toast);
typedef void (^startConnect)(void);
typedef void(^scanNoBlueTeeth)(void);
typedef void(^connectSuccess)(NSDictionary * scanDataDict);


@interface BlueToothConnecter : NSObject

/**
 *  获取连接管理对象
 *
 *  @return
 */
+ (instancetype)shareBlueToothManager;

- (BOOL)judgeBlueTeethOpenOrClose:(makeToast)block;

- (void)startConnect:(startConnect)startConnect ScanNoDevice:(scanNoBlueTeeth)noBlueTeeth Toast:(makeToast)toastBlock Success:(connectSuccess)success;

@end
