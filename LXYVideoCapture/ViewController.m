//
//  ViewController.m
//  LXYCapture
//
//  Created by liu on 2019/3/2.
//  Copyright © 2019年 liu. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()
{
    AVCaptureSession *_captureSession;
    
    AVCaptureDevice *_videoDevice;
    
    AVCaptureDeviceInput *_videoInput;
    
    AVCaptureDeviceInput *_audioInput;
    
    AVCaptureMovieFileOutput *_movieOutput;
    
    AVCaptureConnection *_captureConnection;
    
    AVCaptureDevice *_audioDevice;
    
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
}

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
    [self addSession];
    
    [_captureSession beginConfiguration];
    
    [self addVideo];
    
    [self addAudio];
    
    // 添加预览层
    [self addPlaylayer];
    
    [_captureSession commitConfiguration];
    
    [_captureSession startRunning];
    
    
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
    _movieOutput = [[AVCaptureMovieFileOutput alloc]init];
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

@end
