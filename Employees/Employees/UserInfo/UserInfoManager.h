//
//  UserInfoManager.h
//  Employees
//
//  Created by fish on 2024/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserInfoManager : NSObject
+ (instancetype)shareManager;
- (void)updateUserInfo:(NSString *)userName userid:(NSInteger )userid token:(NSString *)token;

- (NSInteger )getUserid;
- (NSString *)getToken;
- (NSString*)timestamp;

- (void)cleanLoginInfo;
- (BOOL)checkNeedUploadWithKey:(NSString *)key;
- (void)addImageUploadMark:(NSString *)key;
- (void)cleanAllUploadMark;

@end

NS_ASSUME_NONNULL_END
