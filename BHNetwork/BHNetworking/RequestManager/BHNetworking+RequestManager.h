//
//  BHNetworking+RequestManager.h
//  BHNetworking
//
//  Created by libohao on 17/8/28.
//  Copyright © 2017年 CMIC. All rights reserved.
//


#import "BHNetworking.h"

@interface BHNetworking (RequestManager)
/**
 *  判断网络请求池中是否有相同的请求
 *
 *  @param task 网络请求任务
 *
 *  @return bool
 */
+ (BOOL)haveSameRequestInTasksPool:(BHURLSessionTask *)task;

/**
 *  如果有旧请求则取消旧请求
 *
 *  @param task 新请求
 *
 *  @return 旧请求
 */
+ (BHURLSessionTask *)cancleSameRequestInTasksPool:(BHURLSessionTask *)task;

@end
