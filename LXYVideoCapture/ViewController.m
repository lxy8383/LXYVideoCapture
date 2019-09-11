//
//  ViewController.m
//  LXYCapture
//
//  Created by liu on 2019/3/2.
//  Copyright © 2019年 liu. All rights reserved.
//

#import "ViewController.h"
#import "XYCaptureShortVideoTool.h"
#import "XYRealTimeVideoTool.h"
#import <AVFoundation/AVFoundation.h>
#import "XYH264Decode.h"


// 视频拍摄
@interface ViewController () <PlayControlViewDelegate>
{
    
    BOOL _startCapture;
}

//@property (nonatomic, strong) XYCaptureShortVideoTool *shortVideo;

//视频拍摄
@property (nonatomic, strong) XYRealTimeVideoTool *shortVideo;
// 播控层
@property (nonatomic, strong) PlayControlView  * playView;

@property (nonatomic, strong) LXY264Encoder *encoder;

@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayer;

@property (nonatomic, strong) XYH264Decode *h264Decoder;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setUpView];
    
    
    self.h264Decoder = [[XYH264Decode alloc] init];
    
    [self setupSampleBufferDisplayLayer];
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
        [self.shortVideo stopCapture];
    }
}
- (void)decodeH264:(UIButton *)sender
{
    sender.enabled = false;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.h264Decoder decodeFile:@"test" fileExt:@"h264" andAVSLayer:self.displayer completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                sender.enabled = true;
            });
        }];
    });
}

- (void)closeCapture{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)switchLens{
    
//    [self.shortVideo captureSwitchLens];
}
#pragma mark - lazy
- (XYRealTimeVideoTool *)shortVideo
{
    if(!_shortVideo){
        _shortVideo = [[XYRealTimeVideoTool alloc]init];
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

- (void)setupSampleBufferDisplayLayer {
    
    AVSampleBufferDisplayLayer *avslayer = [[AVSampleBufferDisplayLayer alloc]init];
    avslayer.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 150, 0, 150, 200);
    avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avslayer.backgroundColor = [UIColor yellowColor].CGColor;
    CMTimebaseSetRate(avslayer.controlTimebase, 1.0);
    self.displayer = avslayer;
    [self.playView.layer addSublayer:self.displayer];
}
@end
