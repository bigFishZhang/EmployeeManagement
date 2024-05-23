//
//  MainViewController.m
//  Employees
//
//  Created by leozbzhang on 2024/5/23.
//

#import "MainViewController.h"

#import "UIColor+QLSGradient.h"
#import "PhotoAlbumViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    self.navigationBackgroundColor =  [UIColor colorWithRed:arc4random_uniform (256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
//    self.navigationBackgroundImage = [UIImage imageNamed:@"NavBar64"];

    self.navTitleColor =  [UIColor colorWithRed:arc4random_uniform (256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];

    self.tabbarBackgroundColor =  [UIColor colorWithRed:arc4random_uniform (256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
    
    UIColor *gradientColor = [UIColor gradientColorWithSize:CGSizeMake(1, 30) direction:GradientColorDirectionVertical colors:@[[UIColor colorWithRed:33/255.0 green:37/255.0 blue:47/255.0 alpha:1.0], [UIColor colorWithRed:52/255.0 green:58/255.0 blue:70/255.0 alpha:1.0], [UIColor colorWithRed:33/255.0 green:37/255.0 blue:47/255.0 alpha:1.0]]];
                                  
    self.topSeparatorColor = [UIColor orangeColor];
    self.itemSeparatorColor = gradientColor;

    // 设置自定义高度
    self.tabbarHeight = 60;
    
    self.childControllerAndIconArr = @[

                                       /************第一个控制器配置信息*********************/
                                       @{
                                           TAB_VC_VIEWCONTROLLER : [[PhotoAlbumViewController alloc]init],  //控制器对象
                                           TAB_NORMAL_ICON : @"icon_classTable",             //正常状态的Icon 名称
                                           TAB_SELECTED_ICON : @"icon_classTable_selected",  //选中状态的Icon 名称
                                           TAB_TITLE_COLOR: [UIColor blackColor],
                                           TAB_TITLE_COLOR_SEL: [UIColor systemRedColor],
                                           TAB_TITLE : @"我的图片"                                 //Nav和Tab的标题
                                           },
//                                       /************第二个控制器配置信息*********************/
//                                       @{
//                                           TAB_VC_VIEWCONTROLLER : [[TwoController alloc]init],
//                                           TAB_NORMAL_ICON : @"icon_me",
//                                           TAB_SELECTED_ICON : @"icon_me_selected",
//                                           TAB_TITLE_COLOR: [UIColor blackColor],
//                                           TAB_TITLE_COLOR_SEL: [UIColor systemRedColor],
//                                           TAB_TITLE : @"通讯录"
//                                           },
//                                       @{
//
//                            /*
//                                如果在此处使用storyboard,需要给storyboard设置storyboardID
//                                storyboardID 与 VC_STORYBOARD的value 同名 此处为Three
//                             */
//                                           TAB_VC_STORYBOARD :@"Three",
//                                           TAB_NORMAL_ICON : @"icon_discover",
//                                           TAB_SELECTED_ICON : @"icon_discover_selected",
//                                           TAB_TITLE_COLOR: [UIColor blackColor],
//                                           TAB_TITLE_COLOR_SEL: [UIColor systemRedColor],
//                                           TAB_TITLE : @"发现"
//                                           },
                                       
                                       ];
    
//    [self jumpToLogin];
}




@end
