//
//  PYNetRequest.m
//  PYFund
//
//  Created by 郭杰智 on 2018/10/18.
//  Copyright © 2019 PY. All rights reserved.
//

#import "PYNetRequest.h"
#import "PYHTTPRequestManager.h"

@implementation PYNetRequest

+ (void)batchWork:(NSString *)url 
       parameters:(NSDictionary *)params
            group:(dispatch_group_t)workGroup
       completion:(void (^)(NSDictionary *responseDic))handler {
    
    NSMutableDictionary *formateParams = [PYNetRequest getParams:params];
    if (!workGroup) {
        NSAssert(workGroup, @"参数： group 创建失败");		
    }else {
        dispatch_group_enter(workGroup);
        [[PYHTTPRequestManager sharedManager] POST:url parameters:formateParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSDictionary *data = [PYNetRequest handleResponseObject:responseObject];
            NSLog(@"urlStr:%@\n params:%@ \n response: %@",url, params, data);
            if (handler) {
                handler(data);
            }
            dispatch_group_leave(workGroup);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"urlStr:%@\n params:%@ \n error:%@",url, params,error);
            if (handler) {
                handler(nil);
            }
            dispatch_group_leave(workGroup);
        }];
    }
}

@end



