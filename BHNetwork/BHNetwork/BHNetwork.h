//
//  BHNetworking.h
//  BH
//
//  Created by libohao on 17/8/28.
//  Copyright © 2017年 CMIC. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<AFNetworking.h>)
#import <AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

typedef NS_ENUM(NSUInteger, BHRequestSerializer) {
    /** 设置请求数据为JSON格式*/
    BHRequestSerializerJSON,
    /** 设置请求数据为二进制格式*/
    BHRequestSerializerHTTP,
    BHRequestSerializerPropertBHist
};

typedef NS_ENUM(NSUInteger, BHResponseSerializer) {
    /** 设置响应数据为JSON格式*/
    BHResponseSerializerJSON,
    /** 设置响应数据为二进制格式*/
    BHResponseSerializerHTTP,
    BHResponseSerializerXml,
    BHResponseSerializerPropertBHist,
    BHResponseSerializerImage,
    BHResponseSerializerCompound,
};

/**
 *  网络状态
 */
typedef NS_ENUM(NSInteger, BHNetworkStatus) {
    /**
     *  未知网络
     */
    BHNetworkStatusUnknown             = 1 << 0,
    /**
     *  无法连接
     */
    BHNetworkStatusNotReachable        = 1 << 1,
    /**
     *  WWAN网络
     */
    BHNetworkStatusReachableViaWWAN    = 1 << 2,
    /**
     *  WiFi网络
     */
    BHNetworkStatusReachableViaWiFi    = 1 << 3
};

/**
 *  请求任务
 */
typedef NSURLSessionTask BHURLSessionTask;

/**
 *  成功回调
 *
 *  @param response 成功后返回的数据
 */
typedef void(^BHResponseSuccessBlock)(id response);

/**
 *  失败回调
 *
 *  @param error 失败后返回的错误信息
 */
typedef void(^BHResponseFailBlock)(NSError *error);

/**
 *  下载进度
 *
 *  @param bytesRead              已下载的大小
 *  @param totalBytes                总下载大小
 */
typedef void (^BHDownloadProgress)(int64_t bytesRead, int64_t totalBytes);

/**
 *  下载成功回调
 *
 *  @param url                       下载存放的路径
 */
typedef void(^BHDownloadSuccessBlock)(NSURL *url);


/**
 *  上传进度
 *
 *  @param bytesWritten              已上传的大小
 *  @param totalBytes                总上传大小
 */
typedef void(^BHUploadProgressBlock)(int64_t bytesWritten,
int64_t totalBytes);
/**
 *  多文件上传成功回调
 *
 *  @param responses 成功后返回的数据
 */
typedef void(^BHMultUploadSuccessBlock)(NSArray *responses);

/**
 *  多文件上传失败回调
 *
 *  @param errors 失败后返回的错误信息
 */
typedef void(^BHMultUploadFailBlock)(NSArray *errors);

typedef BHDownloadProgress BHGetProgress;

typedef BHDownloadProgress BHPostProgress;

typedef BHResponseFailBlock BHDownloadFailBlock;

@interface BHNetwork : NSObject

/**
 *  正在运行的网络任务
 *
 *  @return task
 */
+ (NSArray *)currentRunningTasks;

/**
 *  配置请求头
 *
 *  @param httpHeader 请求头
 */
+ (void)setHttpHeaderFields:(NSDictionary *)httpHeader;

/**
 *  取消GET请求
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/**
 *  取消所有请求
 */
+ (void)cancleAllRequest;

/**
 *	设置超时时间
 *
 *  @param timeout 超时时间
 */
+ (void)setupTimeout:(NSTimeInterval)timeout;

/**
 设置请求数据格式

 @param requestSerializer 请求数据格式
 */
+ (void)setRequestSerializer:(BHRequestSerializer)requestSerializer;

/**
 设置应答数据格式

 @param responseSerializer 应答数据格式
 */
+ (void)setResponseSerializer:(BHResponseSerializer)responseSerializer;

/**
 设置Accept content types
 调用操作之前设置
 */
+ (void)setAcceptableContentTypes:(NSSet*)acceptableContentTypes;

/**
 设置安全策略

 @param securityPolicy 安全策略
 */
+ (void)setAFSecurityPolicy:(AFSecurityPolicy*)securityPolicy;

/**
 *  GET请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          是否刷新请求(遇到重复请求，若为YES，则会取消旧的请求，用新的请求，若为NO，则忽略新请求，用旧请求)
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (BHURLSessionTask *)GET:(NSString *)url
           refreshRequest:(BOOL)refresh
                    cache:(BOOL)cache
                   params:(NSDictionary *)params
            progressBlock:(BHGetProgress)progressBlock
             successBlock:(BHResponseSuccessBlock)successBlock
                failBlock:(BHResponseFailBlock)failBlock;


/**
 *  POST请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          解释同上
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (BHURLSessionTask *)POST:(NSString *)url
            refreshRequest:(BOOL)refresh
                     cache:(BOOL)cache
                    params:(NSDictionary *)params
             progressBlock:(BHPostProgress)progressBlock
              successBlock:(BHResponseSuccessBlock)successBlock
                 failBlock:(BHResponseFailBlock)failBlock;


/**
 PUT请求

 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          解释同上
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (BHURLSessionTask *)PUT:(NSString *)url
           refreshRequest:(BOOL)refresh
                    cache:(BOOL)cache
                   params:(NSDictionary *)params
             successBlock:(BHResponseSuccessBlock)successBlock
                failBlock:(BHResponseFailBlock)failBlock;


/**
 *  文件上传
 *
 *  @param url              上传文件接口地址
 *  @param data             上传文件数据
 *  @param type             上传文件类型
 *  @param name             上传文件服务器文件夹名
 *  @param mimeType         mimeType
 *  @param progressBlock    上传文件路径
 *	@param successBlock     成功回调
 *	@param failBlock		失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (BHURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(BHUploadProgressBlock)progressBlock
                           successBlock:(BHResponseSuccessBlock)successBlock
                              failBlock:(BHResponseFailBlock)failBlock;


/**
 *  多文件上传
 *
 *  @param url           上传文件地址
 *  @param datas         数据集合
 *  @param type          类型
 *  @param name          服务器文件夹名
 *  @param mimeTypes      mimeTypes
 *  @param progressBlock 上传进度
 *  @param successBlock  成功回调
 *  @param failBlock     失败回调
 *
 *  @return 任务集合
 */
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(BHUploadProgressBlock)progressBlock
                      successBlock:(BHMultUploadSuccessBlock)successBlock
                         failBlock:(BHMultUploadFailBlock)failBlock;

/**
 *  文件下载
 *
 *  @param url           下载文件接口地址
 *  @param progressBlock 下载进度
 *  @param successBlock  成功回调
 *  @param failBlock     下载回调
 *
 *  @return 返回的对象可取消请求
 */
+ (BHURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(BHDownloadProgress)progressBlock
                         successBlock:(BHDownloadSuccessBlock)successBlock
                            failBlock:(BHDownloadFailBlock)failBlock;

@end



@interface BHNetwork (cache)

/**
 *  获取缓存目录路径
 *
 *  @return 缓存目录路径
 */
+ (NSString *)getCacheDiretoryPath;

/**
 *  获取下载目录路径
 *
 *  @return 下载目录路径
 */
+ (NSString *)getDownDirectoryPath;

/**
 *  获取缓存大小
 *
 *  @return 缓存大小
 */
+ (NSUInteger)totalCacheSize;

/**
 *  清除所有缓存
 */
+ (void)clearTotalCache;

/**
 *  获取所有下载数据大小
 *
 *  @return 下载数据大小
 */
+ (NSUInteger)totalDownloadDataSize;

/**
 *  清除下载数据
 */
+ (void)clearDownloadData;

@end
