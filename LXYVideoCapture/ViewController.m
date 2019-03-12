//
//  ViewController.m
//  LXYCapture
//
//  Created by liu on 2019/3/2.
//  Copyright © 2019年 liu. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
@interface ViewController () <PlayControlViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_captureSession;
    
    AVCaptureDevice *_videoDevice;
    
    AVCaptureDeviceInput *_videoInput;
    
    AVCaptureDeviceInput *_audioInput;
    
    AVCaptureVideoDataOutput *_movieOutput;
    
    AVCaptureConnection *_captureConnection;
    
    AVCaptureDevice *_audioDevice;
    
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    
    BOOL _startCapture;
}

// 播控层
@property (nonatomic, strong) PlayControlView  * playView;

@property (nonatomic, strong) LXY264Encoder *encoder;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self getAuthorization];
}
- (void)getAuthorization
{
    /*
     AVAuthorizationStatusNoteDetermined = 0,  //未进行授权选择
     AVAuthorizationStatusRestricted,           // 未授权 ， 且用户无法更新， 入家长控制情况下
     AVAuthorizationStatusDenied,               // 用户拒绝app使用
     AVAuthorizationStatusAuthorized,          // 已授权，可使用
     */
    
    // 此处获取摄像头权限
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusDenied:{
            NSLog(@"权限被拒绝");
            //            [self setUpAVCaptureInfo];
        }
            break;
        case AVAuthorizationStatusAuthorized:{
            NSLog(@"授权摄像头使用成功");
            [self setUpAVCaptureInfo];
        }
            break;
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){
                    [self setUpAVCaptureInfo];
                    return ;
                }else{
                    return;
                    
                }
            }];
        }
            break;
            
        default:
            break;
    }
}

- (void)setUpAVCaptureInfo
{
    [self.view addSubview:self.playView];
    self.playView.frame = self.view.frame;
    self.playView.backgroundColor = [UIColor clearColor];
    
    [self addSession];
    
    [_captureSession beginConfiguration];
    
    [self addVideo];
    
    [self addAudio];
    
    // 添加预览层
    [self addPlaylayer];
    
    [_captureSession commitConfiguration];
    

}

- (void)addSession
{
    _captureSession = [[AVCaptureSession alloc]init];
    if([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
}


- (void)addVideo
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for(AVCaptureDevice *camera in cameras){
        if(camera.position == AVCaptureDevicePositionFront){
            _videoDevice = camera;
        }
    }
    
    [self addVideoInput];
    
    [self addMovieOutPut];
    
}

- (void)addVideoInput
{
    NSError *videoError;
    //视频输入对象
    //根据输入设备初始化输入对象，用户获取输入数据
    _videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:_videoDevice error:&videoError];
    if(videoError){
        NSLog(@"取得摄像头设备出错");
        return;
    }
    
    // 将视频输入对象添加到会话
    if([_captureSession canAddInput:_videoInput]){
        [_captureSession addInput:_videoInput];
    }
}

- (void)addMovieOutPut
{
    //拍摄视频输出对象
    _movieOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    [_movieOutput setVideoSettings:videoSetting];
    [_movieOutput setSampleBufferDelegate:self queue:dispatch_queue_create("ACVideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL)];
    _movieOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if([_captureSession canAddOutput:_movieOutput]){
        [_captureSession addOutput:_movieOutput];
        
        _captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];

        //设置视频旋转方向
        if([_captureConnection isVideoOrientationSupported]){
            [_captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        //视频稳定设置
        if([_captureConnection isVideoStabilizationSupported]){
            _captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        _captureConnection.videoScaleAndCropFactor = _captureConnection.videoMaxScaleAndCropFactor;
    }
}

- (void)addAudio
{
    NSError *audioError;
    // 添加一个音频设备
    _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    // 音频输入对象
    _audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:_audioDevice error:&audioError];
    
    if(audioError){
        NSLog(@"获取音频设备出错");
    }
    
    // 将音频输入对象添加到会话
    if([_captureSession canAddInput:_audioInput]){
        [_captureSession addInput:_audioInput];
    }
}

- (void)addPlaylayer
{
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
    _captureVideoPreviewLayer.frame = self.view.frame;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
}


#pragma mark -
/**
 摄像头采集的数据回调
 @param output 输出设备
 @param sampleBuffer 帧缓存数据，描述当前帧信息
 @param connection 连接
 */
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"输出 output：%@",output);
    
    //采集过来的数据
    NSLog(@"信息buffer：%@",sampleBuffer);
    [self.encoder encodeSampleBuffer:sampleBuffer];
}


#pragma mark - PlayControlDelegate
- (void)startCapture
{
    if(!_startCapture){
        // 开始拍摄
        _startCapture = YES;
        [_captureSession startRunning];
    }else{
        // 停止拍摄
        _startCapture = NO;
        [_captureSession stopRunning];
    }
}
#pragma mark - lazy
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
