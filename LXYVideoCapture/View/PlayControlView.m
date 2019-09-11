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
    self.captureButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2.f - 40, [UIScreen mainScreen].bounds.size.height - 100, 60, 60);
    
    [self addSubview:self.closeButton];
    self.closeButton.frame = CGRectMake(20, 30, 20, 20);
    
    [self addSubview:self.switchLens];
    self.switchLens.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 80, 30, 32, 32);
    
    [self addSubview:self.decodeButton];
    self.decodeButton.frame = CGRectMake(100, 200, 45, 30);
}

- (void)PlayViewAction:(UIButton *)sender
{
    switch (sender.tag) {
        case 100001:{
            if(!_captureButton.selected){
                [_captureButton setImage:[UIImage imageNamed:@"shoot_Pause"] forState:UIControlStateNormal];
            }else{
                [_captureButton setImage:[UIImage imageNamed:@"shoot_Play"] forState:UIControlStateNormal];
            }
            if([self.delegate respondsToSelector:@selector(startCapture:)]){
                [self.delegate startCapture:!_captureButton.selected];
            }
            _captureButton.selected = !_captureButton.selected;

        }break;
        case 100002:{
            if([self.delegate respondsToSelector:@selector(closeCapture)]){
                [self.delegate closeCapture];
            }
        }break;
        case 100003:{
            if([self.delegate respondsToSelector:@selector(closeCapture)]){
                [self.delegate switchLens];
            }
        } break;
        case 100004:{
            if([self.delegate respondsToSelector:@selector(decodeH264:)]){
                [self.delegate decodeH264:sender];
            }
        }
            break;

            
        default:
            break;
    }
    
    
}

#pragma mark - lazy
- (UIButton *)captureButton
{
    if(!_captureButton){
        _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_captureButton addTarget:self action:@selector(PlayViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [_captureButton setImage:[UIImage imageNamed:@"shoot_Play"] forState:UIControlStateNormal];
        _captureButton.tag = 100001;
    }
    return _captureButton;
}

- (UIButton *)closeButton
{
    if(!_closeButton){
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(PlayViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:[UIImage imageNamed:@"shoot_close"] forState:UIControlStateNormal];
        _closeButton.tag = 100002;
    }
    return _closeButton;
}

- (UIButton *)switchLens
{
    if(!_switchLens){
        _switchLens = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchLens addTarget:self action:@selector(PlayViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [_switchLens setImage:[UIImage imageNamed:@"shoot_Switch"] forState:UIControlStateNormal];
        _switchLens.tag = 100003;
    }
    return _switchLens;
}

- (UIButton *)decodeButton
{
    if(!_decodeButton){
        _decodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_decodeButton addTarget:self action:@selector(PlayViewAction:) forControlEvents:UIControlEventTouchUpInside];
        [_decodeButton setTitle:@"解码" forState:UIControlStateNormal];
        _decodeButton.tag = 100004;
    }
    return _decodeButton;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
