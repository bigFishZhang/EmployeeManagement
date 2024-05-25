//
//  LoginViewController.m
//  Employees
//
//  Created by leozbzhang on 2024/5/22.
//

#import "LoginViewController.h"
#import "SCLAlertView.h"

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
    _userKey.keyboardType = UIKeyboardTypePhonePad;
    _userKey.placeholder = @"请输入密码......";
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
    
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert showSuccess:self title:@"登录成功" subTitle:@"" closeButtonTitle:@"好的" duration:0.0f];
}



- (void)pressLogin
{
    NSLog(@"pressLogin");
}

- (void)pressRegister
{
    NSLog(@"pressLogin");
}

@end
