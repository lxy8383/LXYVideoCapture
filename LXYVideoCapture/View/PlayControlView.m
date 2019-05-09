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
    self.captureButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2.f - 40, [UIScreen mainScreen].bounds.size.height - 140, 60, 60);
}

- (void)doCaptureAction:(UIButton *)sender
{
    if(!sender.selected){
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"拍摄" forState:UIControlStateNormal];
    }
    if([self.delegate respondsToSelector:@selector(startCapture:)]){
        [self.delegate startCapture:!sender.selected];
    }
    sender.selected = !sender.selected;
}

#pragma mark - lazy
- (UIButton *)captureButton
{
    if(!_captureButton){
        _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _captureButton.backgroundColor = [UIColor redColor];
        [_captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_captureButton addTarget:self action:@selector(doCaptureAction:) forControlEvents:UIControlEventTouchUpInside];
        [_captureButton setTitle:@"拍摄" forState:UIControlStateNormal];
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
