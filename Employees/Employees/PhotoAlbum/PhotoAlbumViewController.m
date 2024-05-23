//
//  PhotoAlbumViewController.m
//  Employees
//
//  Created by leozbzhang on 2024/5/23.
//

#import "PhotoAlbumViewController.h"
#import "LoginViewController.h"

@interface PhotoAlbumViewController ()

@end

@implementation PhotoAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self jumpToLogin];
}

#pragma mark - Private

- (void)jumpToLogin
{
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    [self.navigationController pushViewController:loginVC animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
