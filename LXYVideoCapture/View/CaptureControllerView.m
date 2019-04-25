//
//  CaptureControllerView.m
//  LXYVideoCapture
//
//  Created by liu on 2019/4/25.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "CaptureControllerView.h"

@interface CaptureControllerView()

@property (nonatomic, strong) UIButton *captureButton;  //采集按钮

@end

@implementation CaptureControllerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        
        [self setUpView];
        
    }
    return self;
}

- (void)setUpView
{
    [self addSubview:self.captureButton];
    self.captureButton.frame = CGRectMake(80, 100, 90, 45);
}

- (UIButton *)captureButton
{
    if(!_captureButton){
        _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_captureButton setTitle:@"采集" forState:UIControlStateNormal];
        [_captureButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_captureButton addTarget:self action:@selector(doCaptureAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _captureButton;
}

- (void)doCaptureAction:(UIButton *)sender
{
    if(_ClickButton){
        _ClickButton();
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
