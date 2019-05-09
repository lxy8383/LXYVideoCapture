//
//  ViewController.m
//  LXYCapture
//
//  Created by liu on 2019/3/2.
//  Copyright © 2019年 liu. All rights reserved.
//

#import "ViewController.h"
#import "XYCaptureShortVideoTool.h"


// 视频拍摄
@interface ViewController () <PlayControlViewDelegate>
{
    
    BOOL _startCapture;
}

@property (nonatomic, strong) XYCaptureShortVideoTool *shortVideo;
// 播控层
@property (nonatomic, strong) PlayControlView  * playView;

@property (nonatomic, strong) LXY264Encoder *encoder;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setUpView];
}

- (void)setUpView
{
    //录制操作界面在上层
    [self.view addSubview:self.playView];
    self.playView.frame = self.view.frame;
    //录制核心层在下面
    [self.shortVideo insertView:self.view];
}

#pragma mark - PlayControlDelegate
- (void)startCapture:(BOOL)isCapture{
    
    if(isCapture){
        // 开始拍摄
        [self.shortVideo startCapture];
    }else{
        // 停止拍摄
        [self.shortVideo pauseCapture];
    }
}
#pragma mark - lazy
- (XYCaptureShortVideoTool *)shortVideo
{
    if(!_shortVideo){
        _shortVideo = [[XYCaptureShortVideoTool alloc]init];
    }
    return _shortVideo;
}

- (PlayControlView *)playView
{
    if(!_playView){
        _playView = [[PlayControlView alloc]init];
        _playView.delegate = self;
    }
    return _playView;
}
- (LXY264Encoder *)encoder
{
    if(!_encoder){
        _encoder = [[LXY264Encoder alloc]init];
    }
    return _encoder;
}
@end
