//
//  ViewController.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/3/1.
//  Copyright © 2019年 liuxy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL isUsingFrontFacingCamera;
    
    AVCaptureVideoDataOutput * videoDataOutput;
}
// 设备输入
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
// 设备输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;
// session
@property (nonatomic, strong) AVCaptureSession *captureSession;
// AVCaptureSession用来建立和维护AVCaptureInput和AVCaptureOutput之间的连接的。
@property (nonatomic, strong) AVCaptureConnection *captureConnection;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, assign) BOOL isCapturing;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
//    [self catchCameras];
    
    
    UIButton *captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    captureButton.backgroundColor = [UIColor yellowColor];
    captureButton.frame = CGRectMake(100, 400, 50, 50);
    [captureButton addTarget:self action:@selector(doCaptureAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
}
- (void)doCaptureAction:(UIButton *)sender
{
//    BOOL startCapture = [self startCapture];
    
//    NSLog(@" startCapture :%d",startCapture);
}

//- (void)catchCameras
//{
//    //初始化session
//    self.captureSession = [[AVCaptureSession alloc]init];
//    [self.captureSession beginConfiguration];
//    //不使用使用的实例， 避免被异常挂断
//    self.captureSession.usesApplicationAudioSession = NO;
//
//    // 获取所有摄像头
//    NSArray * cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//
//    // 获取前置摄像头
//    NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionFront]];
//    if(!captureDeviceArray.count){
//        printf("获取前置摄像头失败");
//        return;
//    }
//
//    // 转化为输入设备
//    AVCaptureDevice *camera = captureDeviceArray.firstObject;
//    NSError *errorMessage = nil;
//
//    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&errorMessage];
//    if(errorMessage){
//        printf(" AVcaptureDevice 转 AVCaptureDeviceInput 失败");
//        return;
//    }
//    AVCaptureInputPort *videoPort = self.captureDeviceInput.ports[0];
//    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&errorMessage];
//    AVCaptureInputPort *audioPort = audioInput.ports[0];\
//    NSArray<AVCaptureInputPort *> *inputPorts = @[videoPort, audioPort];
//    //设置视频输出
//    self.captureDeviceOutput = [[AVCaptureVideoDataOutput alloc]init];
//
//    // 设置视频数据格式
//    NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
//    [self.captureDeviceOutput setVideoSettings:videoSetting];
//
//    // 设置输出代理， 串行队列和数据回调
//    dispatch_queue_t outputQueue = dispatch_queue_create("ACVideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL);
//    [self.captureDeviceOutput setSampleBufferDelegate:self queue:outputQueue];
//
//    // 丢弃延迟的帧
//    self.captureDeviceOutput.alwaysDiscardsLateVideoFrames = YES;
//
//    // 添加输入设备到会话
//    if([self.captureSession canAddInput:self.captureDeviceInput]){
//        [self.captureSession addInput:self.captureDeviceInput];
//    }
//
//    // 添加输出设备到会话
//    if([self.captureSession canAddOutput:self.captureDeviceOutput]){
//        [self.captureSession addOutput:self.captureDeviceOutput];
//    }
//
//    // 设置分辨率
//    if([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
//        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
//    }
//
//    // 获取连接并设置视频方向为竖屏方向
//    self.captureConnection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
//    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
//    AVCaptureConnection *connection = [AVCaptureConnection connectionWithInputPorts:inputPorts output:self.captureDeviceOutput];
//    //设置是否为镜像 ，  前置摄像头采集到数据本来就是翻转的，这里设置为镜像把画面转回来
//    if(camera.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
//        self.captureConnection.videoMirrored = YES;
//    }
//
//    // 获取预览layer 并设置视频方向 ，注意self.videopreview.connection 跟self.captureConnection 不是同一个对象,要分开设置
//    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
//    self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
//    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    NSLog(@"--> : %@",NSStringFromCGRect(self.view.bounds) );
//    self.videoPreviewLayer.frame = self.view.bounds;
//    self.videoPreviewLayer.backgroundColor = (__bridge CGColorRef _Nullable)([UIColor redColor]);
////    [self.view.layer insertSublayer:self.videoPreviewLayer atIndex:0];
//    [self.view.layer addSublayer:self.videoPreviewLayer];
//}



- (BOOL)startCapture
{
    if(self.isCapturing){
        self.isCapturing = NO;
    }
    
    // 判断摄像头权限
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(videoAuthStatus != AVAuthorizationStatusAuthorized){
        return NO;
    }
    
    [self.captureSession startRunning];
    self.isCapturing = YES;
    return YES;
    
}
@end
