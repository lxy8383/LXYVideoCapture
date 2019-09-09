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


@interface XYRealTimeVideoTool() <AVCaptureVideoDataOutputSampleBufferDelegate>
// 场景
@property (nonatomic, strong) AVCaptureSession *captureSession;
// 输入
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
// 输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

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
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 设置录制640 * 480
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *inputCamera = [self cameraWithPostion:AVCaptureDevicePositionBack];
    
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if([self.captureSession canAddInput:self.captureDeviceInput]){
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    self.captureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureDeviceOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // 设置YUV420p 输出
    [self.captureDeviceOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8PlanarFullRange)}];
    
    [self.captureDeviceOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    // 添加输入设备
    if([self.captureSession canAddOutput:self.captureDeviceOutput]){
        [self.captureSession addOutput:self.captureDeviceOutput];
    }
    
    //建立连接
    AVCaptureConnection *connection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}




#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0))
{
    
}

- (void)startCapture
{
    //开始采集
    [self.captureSession startRunning];
}


- (void)stopCapture
{
    [self.captureSession stopRunning];
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
    }
    return _captureVideoPreviewLayer;
}

@end
