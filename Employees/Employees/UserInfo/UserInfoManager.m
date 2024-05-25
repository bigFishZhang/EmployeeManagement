//
//  UserInfoManager.m
//  Employees
//
//  Created by leo on 2024/5/25.
//

#import "UserInfoManager.h"

@interface UserInfoManager ()

@property (nonatomic, copy) NSString *userName;
//@property (nonatomic, copy) NSString *passWord;
@property (nonatomic, assign) NSInteger userid;
@property (nonatomic, copy) NSString *token;

@end

static UserInfoManager *manager = nil;

@implementation UserInfoManager

+ (instancetype)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (void)updateUserInfo:(NSString *)userName userid:(NSInteger)userid token:(NSString *)token
{
    self.userName = userName;
    self.userid = userid;
    self.token = token;
}


- (NSInteger )getUserid
{
    return self.userid;
}
- (NSString *)getToken
{
    return self.token;
}


- (NSString*)timestamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time=[date timeIntervalSince1970]*1000;
    return [NSString stringWithFormat:@"%.0f", time];
}
@end
