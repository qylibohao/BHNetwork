//
//  BHNetworking.m
//  BH
//
//  Created by libohao on 17/8/28.
//  Copyright © 2017年 CMIC. All rights reserved.
//


#import "BHNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "BHNetworking+RequestManager.h"
#import "BHCacheManager.h"

#define BH_ERROR_IMFORMATION @"网络出现错误，请检查网络连接"

#define BH_ERROR [NSError errorWithDomain:@"com.hBH.BHNetworking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:BH_ERROR_IMFORMATION}]

static NSMutableArray   *requestTasksPool;

static NSDictionary     *headers;

static BHNetworkStatus  networkStatus;

static NSTimeInterval   requestTimeout = 20.f;

static AFSecurityPolicy *_securityPolicy;

static NSSet *_acceptableContentTypes;

static AFHTTPResponseSerializer<AFURLResponseSerialization> *_responseSerializer;

static AFHTTPRequestSerializer<AFURLRequestSerialization> *_requestSerializer;

@interface BHNetworking()



@end

@implementation BHNetworking
#pragma mark - manager
+ (AFHTTPSessionManager *)manager {
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //默认解析模式
    
    manager.requestSerializer = _requestSerializer ? _requestSerializer  : [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = _responseSerializer ? _responseSerializer : [AFJSONResponseSerializer serializer];
    
    //配置请求序列化
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    
    [serializer setRemovesKeysWithNullValues:YES];
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    manager.requestSerializer.timeoutInterval = requestTimeout;
    
    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    if (_acceptableContentTypes) {
        NSMutableSet *mutableAcceptTypes = [[NSMutableSet alloc]initWithSet:manager.responseSerializer.acceptableContentTypes];
        for (id obj in _acceptableContentTypes) {
            if (obj) {
                [mutableAcceptTypes addObject:obj];
            }
            
        }
        manager.responseSerializer.acceptableContentTypes = mutableAcceptTypes;
    }else {
        //配置响应序列化
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                  @"text/html",
                                                                                  @"text/json",
                                                                                  @"text/plain",
                                                                                  @"text/javascript",
                                                                                  @"text/xml",
                                                                                  @"image/*",
                                                                                  @"application/octet-stream",
                                                                                  @"application/zip"]];
    }
    
    if (_securityPolicy) {
        manager.securityPolicy = _securityPolicy;
    }
    
    
    [self checkNetworkStatus];
    
    //每次网络请求的时候，检查此时磁盘中的缓存大小，阈值默认是40MB，如果超过阈值，则清理LRU缓存,同时也会清理过期缓存，缓存默认SSL是7天，磁盘缓存的大小和SSL的设置可以通过该方法[BHCacheManager shareManager] setCacheTime: diskCapacity:]设置
    [[BHCacheManager shareManager] clearLRUCache];
    
    return manager;
}

#pragma mark - 配置网络
+ (void)setRequestSerializer:(BHRequestSerializer)requestSerializer {
    switch (requestSerializer) {
        case BHRequestSerializerJSON:
            _requestSerializer = [AFJSONRequestSerializer serializer];
            break;
            
        case BHRequestSerializerHTTP:
            _requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
            
        case BHRequestSerializerPropertBHist:
            _requestSerializer = [AFPropertyListRequestSerializer serializer];
            break;
            
        default:
            break;
    }
}

+ (void)setResponseSerializer:(BHResponseSerializer)responseSerializer {
    switch (responseSerializer) {
        case BHResponseSerializerJSON:
            _responseSerializer = [AFJSONResponseSerializer serializer];
            break;
            
        case BHResponseSerializerHTTP:
            _responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
            
        case BHResponseSerializerXml:
            _responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
            
        case BHResponseSerializerPropertBHist:
            _responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
            
        case BHResponseSerializerImage:
            _responseSerializer = [AFImageResponseSerializer serializer];
            break;
            
        case BHResponseSerializerCompound:
            _responseSerializer = [AFCompoundResponseSerializer serializer];
            break;
            
        default:
            break;
    }


}

+ (void)setAcceptableContentTypes:(NSSet*)acceptableContentTypes {
    
    /*
    NSMutableSet *mutableAcceptTypes = [[NSMutableSet alloc]initWithSet:[self manager].responseSerializer.acceptableContentTypes];
    for (id obj in acceptableContentTypes) {
        [mutableAcceptTypes safeAddObject:obj];
    }*/
    
    
    //[[self manager].responseSerializer setAcceptableContentTypes:mutableAcceptTypes];
    
    _acceptableContentTypes = acceptableContentTypes;
    
}

+ (void)setAFSecurityPolicy:(AFSecurityPolicy*)securityPolicy {
    //[self manager].securityPolicy = securityPolicy;
    _securityPolicy = securityPolicy;
}

#pragma mark - 检查网络
+ (void)checkNetworkStatus {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus = BHNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusUnknown:
                networkStatus = BHNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus = BHNetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus = BHNetworkStatusReachableViaWiFi;
                break;
            default:
                networkStatus = BHNetworkStatusUnknown;
                break;
        }
        
    }];
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasksPool == nil) requestTasksPool = [NSMutableArray array];
    });
    
    return requestTasksPool;
}

#pragma mark - get
+ (BHURLSessionTask *)GET:(NSString *)url
                  refreshRequest:(BOOL)refresh
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(BHGetProgress)progressBlock
                    successBlock:(BHResponseSuccessBlock)successBlock
                       failBlock:(BHResponseFailBlock)failBlock {
    //将session拷贝到堆中，block内部才可以获取得到session
    __block BHURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == BHNetworkStatusNotReachable) {
        if (failBlock) failBlock(BH_ERROR);
        return session;
    }
    
    id responseObj = [[BHCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager GET:url
                parameters:params
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount,
                                                       downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) successBlock(responseObject);
                      
                      if (cache) [[BHCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                      
                      [[self allTasks] removeObject:session];
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) failBlock(error);
                      [[self allTasks] removeObject:session];
                      
                  }];
    
    if ([self haveSameRequestInTasksPool:session] && !refresh) {
        //取消新请求
        [session cancel];
        return session;
    }else {
        //无论是否有旧请求，先执行取消旧请求，反正都需要刷新请求
        BHURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:session];
        if (oldTask) [[self allTasks] removeObject:oldTask];
        if (session) [[self allTasks] addObject:session];
        [session resume];
        return session;
    }
}

#pragma mark - post
+ (BHURLSessionTask *)POST:(NSString *)url
                   refreshRequest:(BOOL)refresh
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(BHPostProgress)progressBlock
                     successBlock:(BHResponseSuccessBlock)successBlock
                        failBlock:(BHResponseFailBlock)failBlock {
    __block BHURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == BHNetworkStatusNotReachable) {
        if (failBlock) failBlock(BH_ERROR);
        return session;
    }
    
    id responseObj = [[BHCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager POST:url
                 parameters:params
                   progress:^(NSProgress * _Nonnull uploadProgress) {
                       if (progressBlock) progressBlock(uploadProgress.completedUnitCount,
                                                        uploadProgress.totalUnitCount);
                       
                   } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       if (successBlock) successBlock(responseObject);
                       
                       if (cache) [[BHCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                       
                       if ([[self allTasks] containsObject:session]) {
                           [[self allTasks] removeObject:session];
                       }
                       
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       if (failBlock) failBlock(error);
                       [[self allTasks] removeObject:session];
                       
                   }];
    
    
    if ([self haveSameRequestInTasksPool:session] && !refresh) {
        [session cancel];
        return session;
    }else {
        BHURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:session];
        if (oldTask) [[self allTasks] removeObject:oldTask];
        if (session) [[self allTasks] addObject:session];
        [session resume];
        return session;
    }
}

+ (BHURLSessionTask *)PUT:(NSString *)url
           refreshRequest:(BOOL)refresh
                    cache:(BOOL)cache
                   params:(NSDictionary *)params
             successBlock:(BHResponseSuccessBlock)successBlock
                failBlock:(BHResponseFailBlock)failBlock
{
    __block BHURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == BHNetworkStatusNotReachable) {
        if (failBlock) failBlock(BH_ERROR);
        return session;
    }
    
    id responseObj = [[BHCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) successBlock(responseObject);
        
        if (cache) [[BHCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
        
        if ([[self allTasks] containsObject:session]) {
            [[self allTasks] removeObject:session];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) failBlock(error);
        [[self allTasks] removeObject:session];
    }];
    
    if ([self haveSameRequestInTasksPool:session] && !refresh) {
        [session cancel];
        return session;
    }else {
        BHURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:session];
        if (oldTask) [[self allTasks] removeObject:oldTask];
        if (session) [[self allTasks] addObject:session];
        [session resume];
        return session;
    }
    
    return nil;
}
#pragma mark - 文件上传
+ (BHURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(BHUploadProgressBlock)progressBlock
                           successBlock:(BHResponseSuccessBlock)successBlock
                              failBlock:(BHResponseFailBlock)failBlock {
    __block BHURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == BHNetworkStatusNotReachable) {
        if (failBlock) failBlock(BH_ERROR);
        return session;
    }
    
    session = [manager POST:url
                 parameters:nil
  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
      NSString *fileName = nil;
      
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      
      NSString *day = [formatter stringFromDate:[NSDate date]];
      
      fileName = [NSString stringWithFormat:@"%@.%@",day,type];
      
      [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
      
  } progress:^(NSProgress * _Nonnull uploadProgress) {
      if (progressBlock) progressBlock (uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
      
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      if (successBlock) successBlock(responseObject);
      [[self allTasks] removeObject:session];
      
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      if (failBlock) failBlock(error);
      [[self allTasks] removeObject:session];
      
  }];
    
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
}

#pragma mark - 多文件上传
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(BHUploadProgressBlock)progressBlock
                      successBlock:(BHMultUploadSuccessBlock)successBlock
                         failBlock:(BHMultUploadFailBlock)failBlock {
    
    if (networkStatus == BHNetworkStatusNotReachable) {
        if (failBlock) failBlock(@[BH_ERROR]);
        return nil;
    }
    
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    NSInteger count = datas.count;
    for (int i = 0; i < count; i++) {
        __block BHURLSessionTask *session = nil;
        
        dispatch_group_enter(uploadGroup);
        
        session = [self uploadFileWithUrl:url
                                 fileData:datas[i]
                                     type:type name:name
                                 mimeType:mimeTypes
                            progressBlock:^(int64_t bytesWritten, int64_t totalBytes) {
                                if (progressBlock) progressBlock(bytesWritten,
                                                                 totalBytes);
                                
                            } successBlock:^(id response) {
                                [responses addObject:response];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                                
                            } failBlock:^(NSError *error) {
                                NSError *Error = [NSError errorWithDomain:url code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
                                
                                [failResponse addObject:Error];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                            }];
        
        [session resume];
        
        if (session) [sessions addObject:session];
    }
    
    [[self allTasks] addObjectsFromArray:sessions];
    
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (successBlock) {
                successBlock([responses copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
        if (failResponse.count > 0) {
            if (failBlock) {
                failBlock([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
    });
    
    return [sessions copy];
}

#pragma mark - 下载
+ (BHURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(BHDownloadProgress)progressBlock
                         successBlock:(BHDownloadSuccessBlock)successBlock
                            failBlock:(BHDownloadFailBlock)failBlock {
    NSString *type = nil;
    NSArray *subStringArr = nil;
    __block BHURLSessionTask *session = nil;
    
    NSURL *fileUrl = [[BHCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
    
    if (fileUrl) {
        if (successBlock) successBlock(fileUrl);
        return nil;
    }
    
    if (url) {
        subStringArr = [url componentsSeparatedByString:@"."];
        if (subStringArr.count > 0) {
            type = subStringArr[subStringArr.count - 1];
        }
    }
    
    AFHTTPSessionManager *manager = [self manager];
    //响应内容序列化为二进制
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    session = [manager GET:url
                parameters:nil
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) {
                          NSData *dataObj = (NSData *)responseObject;
                          
                          [[BHCacheManager shareManager] storeDownloadData:dataObj requestUrl:url];
                          
                          NSURL *downFileUrl = [[BHCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
                          
                          successBlock(downFileUrl);
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) {
                          failBlock (error);
                      }
                  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
    
}

#pragma mark - other method
+ (void)setupTimeout:(NSTimeInterval)timeout {
    requestTimeout = timeout;
}

+ (void)cancleAllRequest {
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(BHURLSessionTask  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[BHURLSessionTask class]]) {
                [obj cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) return;
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(BHURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[BHURLSessionTask class]]) {
                if ([obj.currentRequest.URL.absoluteString hasSuffix:url]) {
                    [obj cancel];
                    *stop = YES;
                }
            }
        }];
    }
}

+ (void)setHttpHeaderFields:(NSDictionary *)httpHeader {
    headers = httpHeader;
}

+ (NSArray *)currentRunningTasks {
    return [[self allTasks] copy];
}

@end

@implementation BHNetworking (cache)
+ (NSUInteger)totalCacheSize {
    return [[BHCacheManager shareManager] totalCacheSize];
}

+ (NSUInteger)totalDownloadDataSize {
    return [[BHCacheManager shareManager] totalDownloadDataSize];
}

+ (void)clearDownloadData {
    [[BHCacheManager shareManager] clearDownloadData];
}

+ (NSString *)getDownDirectoryPath {
    return [[BHCacheManager shareManager] getDownDirectoryPath];
}

+ (NSString *)getCacheDiretoryPath {
    
    return [[BHCacheManager shareManager] getCacheDiretoryPath];
}

+ (void)clearTotalCache {
    [[BHCacheManager shareManager] clearTotalCache];
}

@end
