//
//  LoginViewController.m
//  Employees
//
//  Created by fish on 2024/5/22.
//

#import "LoginViewController.h"
#import "SCLAlertView.h"
#import "UserInfoManager.h"
#import "AFNetworking.h"
#import "SafeCast.h"
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

@interface LoginViewController ()

@property (nonatomic, strong) UILabel *bUesrName;
@property (nonatomic, strong) UITextField *userName;
@property (nonatomic, strong) UILabel *bUserKey;
@property (nonatomic, strong) UITextField *userKey;

@property (nonatomic, strong) UIButton *login;
@property (nonatomic, strong) UIButton *registerBtn;

@property (nonatomic, assign) BOOL isLocationAuthOK;
@property (nonatomic, assign) BOOL isContactAuthOK;
@property (nonatomic, assign) BOOL isPhotoAuthOK;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Register/Login";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _bUesrName = [[UILabel alloc] initWithFrame: CGRectMake(50, 100, 300, 70)];
    _bUesrName.text = @"userName：";
    _bUesrName.textColor = [UIColor blackColor];
    [self.view addSubview: _bUesrName];
    
    _userName = [[UITextField alloc] initWithFrame: CGRectMake(50, 150, 300, 50)];
    _userName.borderStyle = UITextBorderStyleLine;
    _userName.placeholder = @"please enter user name......";
    _userName.textColor = [UIColor blackColor];
    _userName.layer.borderColor = [UIColor blackColor].CGColor;
    _userName.layer.borderWidth = 1.0;
    [self.view addSubview: _userName];
    
    _bUserKey = [[UILabel alloc] initWithFrame: CGRectMake(50, 200, 300, 70)];
    _bUserKey.text = @"password:";
    _bUserKey.textColor = [UIColor blackColor];
    [self.view addSubview: _bUserKey];
    
    _userKey = [[UITextField alloc] initWithFrame: CGRectMake(50, 250, 300, 50)];
    _userKey.borderStyle = UITextBorderStyleLine;
    _userKey.placeholder = @"please enter password......";
    _userKey.layer.borderColor = [UIColor blackColor].CGColor;
    _userKey.textColor = [UIColor blackColor];
    _userKey.layer.borderWidth = 1.0;
    _userKey.secureTextEntry = YES;
    [self.view addSubview: _userKey];
    
    _login = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    _login.frame = CGRectMake(100, 350, 100, 60);
    _login.backgroundColor = [UIColor brownColor];
    [_login setTitle: @"Login" forState: UIControlStateNormal];
    [_login setTitleColor: [UIColor blueColor] forState: UIControlStateNormal];
    [_login addTarget: self action: @selector(pressLogin) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: _login];
    
    
    _registerBtn = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    _registerBtn.frame = CGRectMake(250, 350, 100, 60);
    _registerBtn.backgroundColor = [UIColor brownColor];
    [_registerBtn setTitle: @"Register" forState: UIControlStateNormal];
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
        [alert showError:@"please enter password" subTitle:@"Info Error" closeButtonTitle:@"OK" duration:0.0f];
        return;
    }
    
    if([self checkAllAuthIsOk] == NO)
    {
        NSLog(@"auth noy ok, can not login ");
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
            NSLog(@"pressLogin success url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showSuccess:self title:@"Login Success" subTitle:@"" closeButtonTitle:@"OK" duration:0.0f];
            [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else
        {
            NSLog(@"pressLogin Error url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showError:self title:@"Error" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"pressLogin Error url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showError:self title:@"Operation failed please try again" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
        });
    }];
}

- (void)pressRegister
{
    NSLog(@"pressLogin");
    if(self.userName.text.length == 0 || self.userKey.text.length == 0)
    {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showError:@"Please enter your account password" subTitle:@"Error" closeButtonTitle:@"OK" duration:0.0f];
        return;
    }
    NSString *url = @"http://45.91.226.193:8987/api/base/register"; 
    
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
            NSLog(@"pressRegister success url:%@,name:%@,pass:%@", task.currentRequest.URL, responseObject[@"name"], responseObject[@"pass"]);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                
                [alert showSuccess:self title:@"registration success" subTitle:@"请登录" closeButtonTitle:@"好的" duration:0.0f];
            });
        }
        else
        {
            NSLog(@"pressRegister failed url:%@,error:%@", url, rspDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showError:self title:@"registration failed" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
            });
        }
     
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"pressRegister failed url:%@,error:%@", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showError:self title:@"registration failed" subTitle:@"Please try again" closeButtonTitle:@"OK" duration:0.0f];
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



#pragma mark - Auth
- (BOOL)checkAllAuthIsOk
{
    if(self.isLocationAuthOK == NO)
    {
        [self startLocation];
        return NO;
    }
    if(self.isContactAuthOK == NO)
    {
        [self requestContactAuthorAfterSystemVersion];
        return NO;
    }
    
    if(self.isPhotoAuthOK == NO)
    {
        [self requestPhotoLibraryAuthorization];
        return NO;
    }
    return YES;
    
}

- (void)startLocation
{

    
    CLAuthorizationStatus authorizaitonStatus = [self getLocationAuthorizationStatus];
    if(authorizaitonStatus == kCLAuthorizationStatusAuthorizedAlways 
       || authorizaitonStatus == kCLAuthorizationStatusAuthorizedWhenInUse
       ||  authorizaitonStatus == kCLAuthorizationStatusRestricted)
    {
            
        if ([CLLocationManager locationServicesEnabled]) {
            self.isLocationAuthOK = YES;
            
        } else {
            self.isLocationAuthOK = NO;
            [self showAlertViewAboutNotAuthorAccessContact:@"Location auth error"];
            NSLog(@"[Binterest]error");
        }
    }
    else
    {
        self.isLocationAuthOK = NO;
        [self showAlertViewAboutNotAuthorAccessContact:@"Location auth  error"];
        NSLog(@"[Binterest] CLAuthorizationStatus error");
    }
    
}


- (CLAuthorizationStatus)getLocationAuthorizationStatus
{
    static CLLocationManager *locationManager = nil;
    if (@available(iOS 14, *))
    {
        if (locationManager == nil)
        {
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            [locationManager requestWhenInUseAuthorization];
        }
        return  [CLLocationManager locationServicesEnabled] && locationManager.authorizationStatus;
    }
    else
    {
        return [CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus];
    }
}


- (void)requestContactAuthorAfterSystemVersion
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                self.isContactAuthOK = NO;
                NSLog(@"[Binterest]Authorization failed");
                [self showAlertViewAboutNotAuthorAccessContact:@"Contact Authorization failed"];
            }else {
                self.isContactAuthOK = YES;
                NSLog(@"[Binterest]Authorization success");
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"[Binterest]User rejects");
        self.isContactAuthOK = NO;
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        NSLog(@"[Binterest]User rejects");
        self.isContactAuthOK = NO;
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)
    {
     
        self.isContactAuthOK = YES;
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


- (void)requestPhotoLibraryAuthorization {
    __weak typeof(self) weakSelf = self;
    [FYFPhotoAuthorization requestPhotosAuthorizationWithHandler:^(FYFPHAuthorizationStatus status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (status == FYFPHAuthorizationStatusLimited || status == FYFPHAuthorizationStatusAuthorized) {
            strongSelf.isPhotoAuthOK = YES;
        } else {
            if (status == FYFPHAuthorizationStatusRestricted) {
                strongSelf.isPhotoAuthOK = NO;
                NSLog(@"[Binterest]App is not authorized to access the album");
            } else if (status == FYFPHAuthorizationStatusNotDetermined) {
                strongSelf.isPhotoAuthOK = NO;
                NSLog(@"[Binterest]Is the application not authorized to access the photo album?");
                [strongSelf showAlertViewAboutNotAuthorAccessContact:@"Is the application not authorized to access the photo album?"];
            } else if (status == FYFPHAuthorizationStatusDenied) {
                strongSelf.isPhotoAuthOK = NO;
                NSLog(@"[Binterest]App is denied access to photo album");
                [strongSelf showAlertViewAboutNotAuthorAccessContact:@"App is denied access to photo album"];
            }
        }
    }];
}

- (void)showAlertViewAboutNotAuthorAccessContact:(NSString *)tips
{
    if(tips.length > 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:@"Please check your permissions"
                message:tips
                preferredStyle: UIAlertControllerStyleAlert];

            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:OKAction];
            [self presentViewController:alertController animated:YES completion:nil];
        });
     
    }
    

}


@end
