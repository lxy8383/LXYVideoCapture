//
//  PlayControlView.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/3/12.
//  Copyright © 2019年 liuxy. All rights reserved.
//

#import "PlayControlView.h"

@implementation PlayControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [self layUI];
    }
    return self;
}
- (void)layUI
{
    [self addSubview:self.captureButton];
    self.captureButton.frame = CGRectMake(100, 40, 60, 60);
}

- (void)doCaptureAction:(UIButton *)sender
{
    if([self.delegate respondsToSelector:@selector(startCapture)]){
        [self.delegate startCapture];
    }
}

#pragma mark - lazy
- (UIButton *)captureButton
{
    if(!_captureButton){
        _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _captureButton.backgroundColor = [UIColor redColor];
        [_captureButton addTarget:self action:@selector(doCaptureAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _captureButton;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
