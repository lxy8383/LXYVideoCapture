//
//  H264Encode.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/10.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYH264Encode.h"
#import <VideoToolbox/VideoToolbox.h>

@interface XYH264Encode()
{
    int frameNO;//帧号
}
@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, assign) VTCompressionSessionRef compressionSessionRef;


@end

@implementation XYH264Encode

- (void)initVideoTool264Encode
{
    
//1,创建VTCompressionSessionRef  对象
// CoreFoundation 创建方式 NULL -> Default
//    编码视频高度
//    编码视频宽度
//    编码标准 h.264
//    NULL
//    编码成功-帧数据后的函数回调
//    回调函数的第一个参数
    frameNO = 0;
    VTCompressionSessionCreate(kCFAllocatorDefault, 200, 200, kCMVideoCodecType_H264, NULL, NULL, NULL, encodeOutputCallback, (__bridge void *)(self), &_compressionSessionRef);
    
    //2 . 设置VTcompressionSessionRef 属性
    //2.1 如果是直播 需要设置视频编码是实时输出
    VTSessionSetProperty(self.compressionSessionRef, kVTCompressionPropertyKey_RealTime, (__bridge CFTypeRef _Nullable)(@(YES)));
    //2.2 设置帧率
    // 帧/s
    VTSessionSetProperty(self.compressionSessionRef, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nullable)(@(30)));
    
    //2.3 设置比特率（码率） bit/s 单位时间的数据量
    VTSessionSetProperty(self.compressionSessionRef, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nullable)(@(1500000)));
    CFArrayRef dataLimits = (__bridge CFArrayRef)(@[@(1500000 / 8), @1]);
    VTSessionSetProperty(self.compressionSessionRef, kVTCompressionPropertyKey_DataRateLimits, dataLimits);
    // 2.4 设置GOP的大小
    VTSessionSetProperty(self.compressionSessionRef, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nullable)(@(20)));
    
    //3 准备开始编码
    VTCompressionSessionPrepareToEncodeFrames(self.compressionSessionRef);
}


void encodeOutputCallback(void * CM_NULLABLE outputCallbackRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CM_NULLABLE CMSampleBufferRef sampleBuffer){
    
    //0 获取到当前对象
    XYH264Encode *encoder = (__bridge XYH264Encode *)(outputCallbackRefCon);
    
    //1 CMSampleBufferRef
    //2 判断该帧是否为关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    BOOL isKeyFrame = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    // 3, 如果是关键帧 ，那么将关键帧写入文件之前，先写入PPS / SPS 数据
    if(isKeyFrame){
        //3.1 获取参数信息
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        //3.2 从format 中获取sps信息
        //参数二： sps0, pps1
        //参数三
        const uint8_t *spsPointer;
        size_t spsSize, spsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsPointer, &spsSize, &spsCount, NULL);
        //3.3 从format中获取pps信息
        const uint8_t *ppsPointer;
        size_t ppsSize, ppsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsPointer, &ppsSize, &ppsCount, NULL);
        //3.4 将sps pps写入到NAL单元
        NSData *spsData = [NSData dataWithBytes:spsPointer length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsPointer length:ppsSize];
        //3.5 写入文件
        [encoder gotSpsPps:spsData pps:ppsData];
    }
    // 4 将编码后的数据写入文件
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    // 4.3 从datapinter 开始读取数据，并且写入NALU->slice
    if(statusCodeRet == noErr){
        size_t bufferOffset = 0;
        static const int h264HeaderLength = 4;
        // 4.4 通过循环，不断的读取slice的切片数据 ，并且封装成NALU 写入文件
        while (bufferOffset < totalLength - h264HeaderLength) {
            // 4.5 读取slice 的长度
            uint32_t naluLength;
            memcpy(&naluLength, dataPointer + bufferOffset, h264HeaderLength);
            // 4.6 H264 大端字节序/ 小端字序
            naluLength = CFSwapInt32BigToHost(naluLength);
            // 4.7 根据长度读取字节，并且成NSdata
            NSData *data = [NSData dataWithBytes:dataPointer + bufferOffset + h264HeaderLength length:naluLength];
            // 4.8 写入文件
            [encoder gotEncodedData:data isKeyFrame:isKeyFrame];
            // 4.9 设置offsetlength
            bufferOffset += naluLength + h264HeaderLength;
            
        }
    }
}


- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps
{
    //拼接NALU 的header
    const char bytes[] = "\x00\x00\x00\x01";
    
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    
    // 将NALU的头 &NALU x的体写入文件
    [self.fileHandle writeData:byteHeader];
    [self.fileHandle writeData:sps];
    [self.fileHandle writeData:byteHeader];
    [self.fileHandle writeData:pps];
}


- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"gotEncodedData %d", (int)[data length]);
    if(self.fileHandle != NULL){
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = sizeof(bytes) - 1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
        [self.fileHandle writeData:byteHeader];
        [self.fileHandle writeData:data];
    }
}




#pragma mark - publicMethod
- (void)encode:(CMSampleBufferRef)sampleBuffer
{
    // 获取imagebuffer
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    // 帧时间，如果不设置会导致时间抽过长。
    // 利用 VTCompressionSessionRef 编码 CMSampleBufferRef
    // pts(presentationTimeStamp) 展示时间戳，用来解码时， 计算m每一帧时间的
    // dts(DecodeTimeStamp) 解码时间戳,决定该帧在什么时间展示
    // 第几帧
    CMTime pts = CMTimeMake( frameNO ++ , 30);
    
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(self.compressionSessionRef,
                                                          imageBuffer,
                                                          pts,
                                                          kCMTimeInvalid,
                                                          NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        VTCompressionSessionInvalidate(self.compressionSessionRef);
        CFRelease(self.compressionSessionRef);
        self.compressionSessionRef = NULL;
        return;
    }
    NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
}
@end
