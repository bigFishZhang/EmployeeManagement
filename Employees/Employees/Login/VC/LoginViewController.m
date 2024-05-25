//
//  LoginViewController.m
//  Employees
//
//  Created by leo on 2024/5/22.
//

#import "LoginViewController.h"
#import "SCLAlertView.h"
#import "UserInfoManager.h"
#import "AFNetworking.h"
#import "SafeCast.h"

@interface LoginViewController ()

@property (nonatomic, strong) UILabel *bUesrName;
@property (nonatomic, strong) UITextField *userName;
@property (nonatomic, strong) UILabel *bUserKey;
@property (nonatomic, strong) UITextField *userKey;

@property (nonatomic, strong) UIButton *login;
@property (nonatomic, strong) UIButton *registerBtn;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"注册/登录";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _bUesrName = [[UILabel alloc] initWithFrame: CGRectMake(50, 100, 300, 70)];
    _bUesrName.text = @"用户名：";
    [self.view addSubview: _bUesrName];
    
    _userName = [[UITextField alloc] initWithFrame: CGRectMake(50, 150, 300, 50)];
    _userName.borderStyle = UITextBorderStyleLine;
    _userName.placeholder = @"请输入用户名......";
    [self.view addSubview: _userName];
    
    _bUserKey = [[UILabel alloc] initWithFrame: CGRectMake(50, 200, 300, 70)];
    _bUserKey.text = @"密码:";
    [self.view addSubview: _bUserKey];
    
    _userKey = [[UITextField alloc] initWithFrame: CGRectMake(50, 250, 300, 50)];
    _userKey.borderStyle = UITextBorderStyleLine;
    _userKey.placeholder = @"请输入密码......";
    _userKey.secureTextEntry = YES;
    [self.view addSubview: _userKey];
    
    _login = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    _login.frame = CGRectMake(100, 350, 100, 60);
    _login.backgroundColor = [UIColor brownColor];
    [_login setTitle: @"登陆" forState: UIControlStateNormal];
    [_login setTitleColor: [UIColor blueColor] forState: UIControlStateNormal];
    [_login addTarget: self action: @selector(pressLogin) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: _login];
    
    
    _registerBtn = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    _registerBtn.frame = CGRectMake(250, 350, 100, 60);
    _registerBtn.backgroundColor = [UIColor brownColor];
    [_registerBtn setTitle: @"注册" forState: UIControlStateNormal];
    [_registerBtn setTitleColor: [UIColor blueColor] forState: UIControlStateNormal];
    [_registerBtn addTarget: self action: @selector(pressRegister) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: _registerBtn];
}



- (void)pressLogin
{
    NSLog(@"pressLogin");
    if(self.userName.text.length == 0 || self.userKey.text.length == 0)
    {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showError:@"请输入账号密码" subTitle:@"信息错误" closeButtonTitle:@"好的" duration:0.0f];
        return;
    }
    NSString *url = @"http://45.91.226.193:8987/api/base/login"; // 登录
    
    NSDictionary *parameters = @{
        @"username":self.userName.text,
        @"password":self.userKey.text,
    };
    NSDictionary *headers = @{
        @"timestamp":[self timestamp]
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 15;
    NSSet *sets = [NSSet
                   setWithObjects:@"application/json",@"text/html",@"text/plain",nil];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObjectsFromSet:sets];
    
    [manager POST:url parameters:parameters headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *rspDic = [self safeCastObject:responseObject toClass:NSDictionary.class];
        NSInteger code = [self getIntegerFromDictionary:rspDic forKey:@"code" withDefault:1];

        if(code == 0)
        {
            NSDictionary *dic = SAFE_CAST([rspDic objectForKey:@"data"], NSDictionary.class);
            NSDictionary *userInfo = [self safeCastObject:[dic objectForKey:@"user"] toClass:NSDictionary.class];

            NSString *token = [self getStringFromDictionary:dic forKey:@"token" withDefault:nil];
            NSString *userName = [self getStringFromDictionary:userInfo forKey:@"userName" withDefault:nil];
            int64_t userID = [self getIntegerFromDictionary:userInfo forKey:@"ID" withDefault:0];
            [[UserInfoManager shareManager] updateUserInfo:userName userid:userID token:token];
            NSLog(@"pressLogin请求成功url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showSuccess:self title:@"登录成功" subTitle:@"" closeButtonTitle:@"好的" duration:0.0f];
            [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else
        {
            NSLog(@"pressLogin请求失败url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"pressLogin请求失败url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
        });
    }];
}

- (void)pressRegister
{
    NSLog(@"pressLogin");
    if(self.userName.text.length == 0 || self.userKey.text.length == 0)
    {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showError:@"请输入账号密码" subTitle:@"信息错误" closeButtonTitle:@"好的" duration:0.0f];
        return;
    }
    NSString *url = @"http://45.91.226.193:8987/api/base/register"; // 注册
    
    NSDictionary *parameters = @{
        @"username":self.userName.text,
        @"password":self.userKey.text,
    };
    NSDictionary *headers = @{
        @"timestamp":[self timestamp]
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 15;
    NSSet *sets = [NSSet
                   setWithObjects:@"application/json",@"text/html",@"text/plain",nil];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObjectsFromSet:sets];
    
    [manager POST:url parameters:parameters headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *rspDic = [self safeCastObject:responseObject toClass:NSDictionary.class];
        NSInteger code = [self getIntegerFromDictionary:rspDic forKey:@"code" withDefault:1];
        if(code == 0)
        {
            NSLog(@"pressRegister请求成功url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showSuccess:self title:@"注册成功" subTitle:@"请登录" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
        else
        {
            NSLog(@"pressRegister请求失败url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showError:self title:@"注册失败" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
     
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"pressRegister请求失败url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showError:self title:@"注册失败" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
        });
    }];
}

- (NSString*)timestamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time=[date timeIntervalSince1970]*1000;
    return [NSString stringWithFormat:@"%.0f", time];
}


- (id)safeCastObject:(id)obj toClass:(Class)classType
{
    if ([obj isKindOfClass:classType])
    {
        return obj;
    }
    return classType ? nil : obj;
}

- (int64_t)getIntegerFromDictionary:(NSDictionary *)dict forKey:(id<NSCopying>)key withDefault:(int64_t)withDefault
{
    dict = SAFE_CAST(dict, NSDictionary);
    if ((dict != nil) && (key != nil))
    {
        id value = [dict objectForKey:key];
        withDefault = [self getIntegerFromObject:value withDefault:withDefault];
    }
    return withDefault;
}

- (int64_t)getIntegerFromObject:(id)object withDefault:(uint64_t)withDefault
{
    NSString *string = [self safeCastObject:object toClass:NSString.class];
    NSNumber *number = [self safeCastObject:object toClass:NSNumber.class];

    if (nil != number)
    {
        withDefault = [number longLongValue];
    }
    else if (nil != string)
    {
        withDefault = strtoll([string UTF8String], NULL, 10);
    }
    return withDefault;
}

- (NSString *)getStringFromDictionary:(NSDictionary *)dict 
                               forKey:(id<NSCopying>)key
                          withDefault:(NSString *)withDefault
{
    dict = SAFE_CAST(dict, NSDictionary);
    if ((dict != nil) && (key != nil))
    {
        NSString *value = SAFE_CAST([dict objectForKey:key], NSString);
        if (value != nil)
        {
            withDefault = value;
        }
    }
    return withDefault;
}

@end
