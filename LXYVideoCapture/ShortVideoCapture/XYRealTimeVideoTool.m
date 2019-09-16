//
//  XYRealTimeVideoTool.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/9.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYRealTimeVideoTool.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "XYH264Encode.h"


@interface XYRealTimeVideoTool() <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
// 场景
@property (nonatomic, strong) AVCaptureSession *captureSession;
// 音频输入
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
// 视频输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
// 音频输入
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
// 音频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic, strong) XYH264Encode *encode;

@property (nonatomic, strong) AVCaptureDevice *inputMicphone;





@end

@implementation XYRealTimeVideoTool

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
    self = [super init];
    if(self){
        [self getAuthorization];
    }
    return self;
}

- (void)addDevice
{
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t audioCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 设置录制640 * 480
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *inputCamera = [self cameraWithPostion:AVCaptureDevicePositionBack];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if([self.captureSession canAddInput:self.videoInput]){
        [self.captureSession addInput:self.videoInput];
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // 设置YUV420p 输出
    [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    // 添加输入设备
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    
    //建立连接
    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    
    NSError *audioError = nil;
    // Device for Audio
    _inputMicphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    _audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:_inputMicphone error:&audioError];
    if(audioError){
        NSLog(@"micphone Error");
    }
    if([self.captureSession canAddInput:_audioInput]){
        [self.captureSession addInput:_audioInput];
    }
    
    //initiaze an AVCaptureAudioDataOutput instance and set capture session
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    [self.audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];

}




#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(output == self.videoDataOutput){
        NSLog(@"videoOutSampleBuffer %@",sampleBuffer);
        [self.encode encode:sampleBuffer];
    }else if(output == self.audioDataOutput){
        NSLog(@"audioOutSampleBuffer %@",sampleBuffer);
    }
}

- (void)startCapture
{
    //开始采集
    [self.captureSession startRunning];
    
}


- (void)stopCapture
{
    [self.captureSession stopRunning];
    
    [self.encode endEncode];
    
}
- (void)insertView:(UIView *)blowView
{
    // 视频拍摄层在最底下
    self.captureVideoPreviewLayer.frame = blowView.frame;
    [blowView.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];

}

// 获取AVCaptureDevice iOS10 之前与之后
- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position{
    
    if(@available(iOS 10.0, *)){
        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        NSArray *devicesArr = devicesIOS10.devices;
        for(AVCaptureDevice *device in devicesArr){
            if(device.position == position){
                return device;
            }
        }
        return nil;
    }else{
        NSArray * deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice * device in deviceArr){
            if(device.position == position){
                return device;
            }
        }
        return nil;
    }
}

#pragma mark - lazy
- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    if (!_captureVideoPreviewLayer ) {
        //通过AVCaptureSession初始化
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        //设置比例为铺满全屏
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _captureVideoPreviewLayer.backgroundColor = [UIColor grayColor].CGColor;
    }
    return _captureVideoPreviewLayer;
}
- (XYH264Encode *)encode
{
    if(!_encode){
        _encode = [[XYH264Encode alloc]init];
    }
    return _encode;
}

@end
