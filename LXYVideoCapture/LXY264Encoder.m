//
//  LXY264Encoder.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/3/12.
//  Copyright © 2019年 liuxy. All rights reserved.
//

#import "LXY264Encoder.h"
@interface LXY264Encoder()

//记录当前的帧数
@property (nonatomic, assign) NSInteger frameID;

// 编码会话
@property (nonatomic, assign) VTCompressionSessionRef compressionSessionRef;

//文件写入对象
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end


@implementation LXY264Encoder
- (instancetype)init{
    if(self = [super init]){
        // 1, 初始化写入文件的对象 (NSFileHandle 用于写入二进制文件)
        [self setupFileHandle];
        
        // 2 . 初始化压缩编码的会话
        [self setUpCompressionSession];
        
        
    }
    return self;
}
- (void)setupFileHandle{
    // 1, 获取沙盒路劲
    NSString *file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.h264"];
    // 如果原来有文件，则删除
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    [[NSFileManager defaultManager] createFileAtPath:file contents:nil attributes:nil];
    
    // 3. 创建对象
    NSError *error;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:file];
    if(error){
        NSLog(@"创建对象失败%@",error);
    }
}
- (void)setUpCompressionSession
{
    //0用于记录当前是第几帧数据
    _frameID = 0;
    
    //1 清空压缩上下文
    if(_compressionSessionRef){
        VTCompressionSessionCompleteFrames(_compressionSessionRef, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_compressionSessionRef);
        CFRelease(_compressionSessionRef);
        _compressionSessionRef = NULL;
    }
    
    //2,录制视频的宽度&高度
    int width = [UIScreen mainScreen].bounds.size.width;
    int height = [UIScreen mainScreen].bounds.size.height;
    
    //3 . 创建压缩会话
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, bbCompressionSessionCallback,(__bridge void * _Nullable)(self), &_compressionSessionRef);
    
    // 判断状态
    if(status != noErr) return;
    
    //5 设置参数
    //profile_level ,h264的协议等级, 不同的清晰度使用不同的profileLevel
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 关键帧最大间隔
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nullable)(@(30)));
    
    // 设置平均码率  单位byte
    int bitRate = [self getResolution];
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    // 码率上限 接受数组类型CFArray[CFNumber] [bytes , seconds ,bytes , seconds...] 单位是bps
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_DataRateLimits , (__bridge CFTypeRef _Nullable)(@[@(bitRate * 1.5 / 8), @1]));
    
    // 设置期望帧率
    int fps = 30;
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    // 设置实时编码
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_RealTime , kCFBooleanTrue);
    
    // 关闭重排Frame
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    
    // 设置比例 16 ：9 分辨率宽高比
    VTSessionSetProperty(_compressionSessionRef, kVTCompressionPropertyKey_AspectRatio16x9, kCFBooleanTrue);
    
    //6 准备编码
    VTCompressionSessionPrepareToEncodeFrames(_compressionSessionRef);
    
}


static void bbCompressionSessionCallback(void * CM_NULLABLE outputCallbackRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CM_NULLABLE CMSampleBufferRef sampleBuffer){
    LXY264Encoder * encoder = (__bridge LXY264Encoder *)(outputCallbackRefCon);
    
    //1, 判断状态是否为没有错误
    if(status != noErr){
        return;
    }
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    BOOL isKeyframe = NO;
    if(attachments != NULL){
        CFDictionaryRef attachement;
        CFBooleanRef dependsOnothers;
        attachement = (CFDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        dependsOnothers = CFDictionaryGetValue(attachement, kCMSampleAttachmentKey_DependsOnOthers);
        dependsOnothers == kCFBooleanFalse ? ( isKeyframe = YES ) : ( isKeyframe = NO );
        
    }
    
    // 2 是否为关键帧
    if(isKeyframe){
        //SPS and PPS
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t spsSize , ppsSzie ;
        size_t parmCount;
        
        const uint8_t *sps , *pps;
        OSStatus status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sps, &spsSize, &parmCount, NULL);
        
        // 获取sps 无错误则继续获取pps
        if(status == noErr){
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pps, &ppsSzie, &parmCount, NULL);
            
            NSData *spsData = [NSData dataWithBytes:sps length:spsSize];
            NSData *ppsData = [NSData dataWithBytes:pps length:ppsSzie];
            
            // 写入文件
            [encoder gotSpsPps:spsData pps:ppsData];
            
        }else{
            return;
        }
    }
    
    // 3, 前4个字节表示长度, 后面的数据的长度
    // 除了关键帧，其他帧只有一个数据
    char  *buffer;
    size_t total;
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, NULL, &total, &buffer);
    
    if (statusCodeRet == noErr) {
        size_t offset = 0;
        //返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        int const headerLenght = 4;
        
        //循环获取NAL unit数据
        while (offset < total - headerLenght) {
            int NALUnitLength = 0;
            // Read the NAL unit length
            memcpy(&NALUnitLength, buffer + offset, headerLenght);
            
            //从大端转系统端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData *data = [NSData dataWithBytes:buffer + headerLenght + offset length:NALUnitLength];
            
            // Move to the next NAL unit in the block buffer
            offset += headerLenght + NALUnitLength;
            
            [encoder gotEncodedData:data isKeyFrame:isKeyframe];
        }
    }
}


// 获取屏幕分辨率
- (int)getResolution
{
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGSize screenSize = screenRect.size;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGFloat screenX = screenSize.width * scale;
    
    CGFloat screenY = screenSize.height * scale;
    
    return screenX * screenY;
    
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    // 1.拼接NALU的header
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    // 2.将NALU的头&NALU的体写入文件
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:sps];
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:pps];
    
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"got EncodedData %d ", (int)[data length]);
    
    if(self.fileHandle != NULL){
        
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1;
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        [self.fileHandle writeData:ByteHeader];
        [self.fileHandle writeData:data];
        
    }
}


#pragma mark - publicMethod
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    //1 .将sampleBuffer 转成imageBuffer
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //2 . 根据当前的帧数 ,创建CMTime 的时间
    CMTime presentationTimeStamp = CMTimeMake(self.frameID++ , 1000);
    VTEncodeInfoFlags flags;
    
    //3 . 开始编码该帧数据
    OSStatus statusCode = VTCompressionSessionEncodeFrame(self.compressionSessionRef, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, (__bridge void * _Nullable)(self), &flags);
    if(statusCode == noErr){
        NSLog(@"H264 : VTCompressionSessionEncodeFrames Success");
    }
}

- (void)endEncode
{
    VTCompressionSessionCompleteFrames(self.compressionSessionRef, kCMTimeInvalid);
    VTCompressionSessionInvalidate(self.compressionSessionRef);
    CFRelease(self.compressionSessionRef);
    self.compressionSessionRef = NULL;
    [self.fileHandle closeFile];
    self.fileHandle = nil;
}
@end
