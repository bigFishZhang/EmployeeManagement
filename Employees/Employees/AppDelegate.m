//
//  AppDelegate.m
//  Employees
//
//  Created by leozbzhang on 2024/5/22.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    MainViewController *mainVc = [[MainViewController alloc]init];

    // 设置根控制器
    self.window.rootViewController = mainVc;

    // 设置为主控制器并可见
    [self.window makeKeyAndVisible];
    return YES;
}





@end
