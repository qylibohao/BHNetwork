//
//  BHMemoryCache.h
//  BHNetworking
//
//  Created by libohao on 17/8/28.
//  Copyright © 2017年 CMIC. All rights reserved.
//


#import <Foundation/Foundation.h>

/**
 *  可拓展的内存缓存策略
 */
@interface BHMemoryCache : NSObject
/**
 *  将数据写入内存
 *
 *  @param data 数据
 *  @param key  键值
 */
+ (void)writeData:(id) data forKey:(NSString *)key;

/**
 *  从内存中读取数据
 *
 *  @param key 键值
 *
 *  @return 数据
 */
+ (id)readDataWithKey:(NSString *)key;

@end
