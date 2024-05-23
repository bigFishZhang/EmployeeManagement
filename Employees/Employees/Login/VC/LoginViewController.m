//
//  LoginViewController.m
//  Employees
//
//  Created by leozbzhang on 2024/5/22.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@property (nonatomic, strong) UITextField *nameTextView;

@property (nonatomic, strong) UITextField *pastWordTextView;

@end

@implementation LoginViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    
    UILabel *mainLabel = [[UILabel alloc] initWithFrame: CGRectMake(20, 100, screenWidth - 40, 30)];
    mainLabel.textColor = [UIColor whiteColor];
    mainLabel.textAlignment = NSTextAlignmentCenter;
    mainLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    mainLabel.text = @"注册/登录";
    [self.view addSubview:mainLabel];
    // 输入框
//    self.nameTextView = [[UITextField alloc] initWithFrame:CGRectMake(40, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)];
    
    // 按钮
    
    
}



@end
