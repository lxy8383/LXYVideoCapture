//
//  XYCaptureShortVideoTool.m
//  LXYVideoCapture
//
//  Created by liu on 2019/5/8.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYCaptureShortVideoTool.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface XYCaptureShortVideoTool() <AVCaptureFileOutputRecordingDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureMovieFileOutput *videoFileOutput;

@property (nonatomic, strong) AVCaptureConnection *captureConnection;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation XYCaptureShortVideoTool

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
            [self addDevice];
        }
            break;
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){
                    [self addDevice];
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

- (instancetype)init
{
    if(self = [super init]){
        
        [self getAuthorization];
    }
    return self;
}
- (void)addDevice
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for(AVCaptureDevice *camera in cameras){
        if(camera.position == AVCaptureDevicePositionFront){
            NSError *error = nil;
            self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:camera error:&error];;
        }
    }
    
    NSError *audioError;
    // 添加一个音频设备
    AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    // 音频输入对象
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:mic error:&audioError];
    
    if(audioError){
        NSLog(@"获取音频设备出错");
    }
    [self.captureSession beginConfiguration];
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}


#pragma mark - delegate
- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    NSLog(@"- 结束: %@",output);
}
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections
{
    NSLog(@"- 开始: %@",output);
}

- (void)captureOutput:(AVCaptureFileOutput *)output didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections
{
    NSLog(@"- 暂停: %@",output);
}

#pragma mark - public

/**
 开始录制
 */
- (void)startCapture
{
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataFilePath = [docsdir stringByAppendingPathComponent:@"CertImage"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:dataFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [dataFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"liuxytemp"]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    [self.videoFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
}

/**
 暂停拍摄
 */
- (void)pauseCapture
{
    if([self.videoFileOutput isRecording]){
        [self.videoFileOutput stopRecording];
    }
}

/**
 停止录制
 */
- (void)stopCapture
{
    [self.videoFileOutput stopRecording];
}

- (void)insertView:(UIView *)blowView
{
    // 视频拍摄层在最底下
    self.captureVideoPreviewLayer.frame = blowView.frame;
    [blowView.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
}


#pragma mark - lazy
- (AVCaptureSession *)captureSession
{
    if(!_captureSession){
        //创建session
        _captureSession = [[AVCaptureSession alloc] init];
        
        //设置分辨率
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            _captureSession.sessionPreset=AVCaptureSessionPreset1280x720;
        }
        
        //添加后置摄像头的输入
        if ([_captureSession canAddInput:self.videoInput]) {
            [_captureSession addInput:self.videoInput];
        }
        
        //添加后置麦克风的输入
        if ([_captureSession canAddInput:self.audioInput]) {
            [_captureSession addInput:self.audioInput];
        }
        
        //将设备输出添加到会话中
        if ([_captureSession canAddOutput:self.videoFileOutput]) {
            [_captureSession addOutput:self.videoFileOutput];
        }
        //设置视频录制的方向
        self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;

    }
    return _captureSession;
}

- (AVCaptureConnection *)captureConnection
{
    if(!_captureConnection){
        _captureConnection = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([_captureConnection isVideoStabilizationSupported ]) {
            _captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    return _captureConnection;
}

- (AVCaptureMovieFileOutput *)videoFileOutput
{
    if(!_videoFileOutput){
        _videoFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _videoFileOutput;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    if (!_captureVideoPreviewLayer ) {
        //通过AVCaptureSession初始化
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        //设置比例为铺满全屏
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _captureVideoPreviewLayer;
}


@end
