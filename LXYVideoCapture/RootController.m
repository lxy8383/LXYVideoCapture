//
//  RootController.m
//  LXYVideoCapture
//
//  Created by liu on 2019/6/3.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "RootController.h"
#import "ViewController.h"
@interface RootController ()

@property (nonatomic, strong) UIButton *startCapture;

@end

@implementation RootController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.startCapture];
    
    self.startCapture.frame = CGRectMake(100, 100, 90, 45);
    
}

- (void)PlayViewAction:(UIButton *)sender
{
    ViewController *captureController = [[ViewController alloc]init];
    [self presentViewController:captureController animated:YES completion:nil];
}
- (UIButton *)startCapture
{
    if(!_startCapture){
        _startCapture = [UIButton buttonWithType:UIButtonTypeCustom];
        _startCapture.backgroundColor = [UIColor grayColor];
        [_startCapture addTarget:self action:@selector(PlayViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [_startCapture setTitle:@"拍摄" forState:UIControlStateNormal];
    }
    return _startCapture;
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
