//
//  XYH264Decode.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYH264Decode.h"
#import "XYVideoFileParser.h"


@interface XYH264Decode()
{
    VTDecompressionSessionRef   _decoderSession;
    CMVideoFormatDescriptionRef  _decoderFormatDescription;
    
    
    uint8_t *_sps;
    long _spsSize;
    uint8_t *_pps;
    long _ppsSize;
    
}
@end


@implementation XYH264Decode

static void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus  status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer,CMTime presentationTimeStamp,CMTime presentationDuration){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

- (BOOL)initH264Decoder {
    
    if(_decoderSession) {
        return YES;
    }
    const uint8_t *parameterSetPoints[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPoints, parameterSetSizes, 4, &_decoderFormatDescription);
    if(status == noErr){
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        //      kCVPixelFormatType_24RGB    //使用24位bitsPerPixel
        //      kCVPixelFormatType_32BGRA   //使用32位bitsPerPixel，kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
        
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        
        uint32_t v = kCVPixelFormatType_32BGRA;
        const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &v)};
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL, attrs, &callBackRecord, &_decoderSession);
        
        CFRelease(attrs);
        
    }else{
        NSLog(@"iOS8VT:reset decoder session failed status = %d", (int)status);
    }
    return YES;
}

- (void)clearH264Decoder
{
    if(_decoderSession){
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = NULL;
    }
    
    if(_decoderFormatDescription){
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_pps);
    free(_sps);
    
    _spsSize = _ppsSize = 0;
}

- (CVPixelBufferRef)decode:(XYVideoPacket *)vp {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void *)vp.buffer, vp.size, kCFAllocatorNull, NULL, 0, vp.size, 0, &blockBuffer);
    
    if(status == kCMBlockBufferNoErr){
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decoderFormatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
        if(status == kCMBlockBufferNoErr && sampleBuffer){
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decoderSession, sampleBuffer, flags, &outputPixelBuffer, &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT:Invalid session, reset decoder session");
            }else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status = %d(Bad data)",(int)decodeStatus);
            }else if(decodeStatus != noErr){
                NSLog(@"IOS8VT: decode failed status = %d",(int)decodeStatus);
            }
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    return outputPixelBuffer;
}

- (CMSampleBufferRef)decodeToSampleBufferRef:(XYVideoPacket *)vp {
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void*)vp.buffer, vp.size,
                                                         kCFAllocatorNull,
                                                         NULL, 0, vp.size,
                                                         0, &blockBuffer);
    if (status == kCMBlockBufferNoErr) {
        const size_t sampleSizeArray[] = {vp.size};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        CFRelease(blockBuffer);
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        
        return sampleBuffer;
    } else {
        return NULL;
    }
}


- (void)decodeFile:(NSString *)fileName fileExt:(NSString *)fileExt andAVSLayer:(AVSampleBufferDisplayLayer *)avslayer completion:(XYH264DecoderCompletionCallback)completion
{
     NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.h264"];
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:fileExt];
    
    
    XYVideoFileParser *parser = [[XYVideoFileParser alloc]init];
    [parser open:path];
    
    XYVideoPacket *vp = nil;
    
    while (true) {
        vp = [parser nextPacket];
        if(vp == nil){
            break;
        }
        
        uint32_t nalSize = (uint32_t)(vp.size - 4);
        uint8_t *pNalSize = (uint8_t *)(&nalSize);
        
        vp.buffer[0] = *(pNalSize + 3);
        vp.buffer[1] = *(pNalSize + 2);
        vp.buffer[2] = *(pNalSize + 1);
        vp.buffer[3] = *(pNalSize);
        
        CMSampleBufferRef sampleBuffer = NULL;
        int nalType = vp.buffer[4] & 0x1F;
        
        switch (nalType) {
            case 0x05:
                NSLog(@"Nal type is IDR frame");
                if([self initH264Decoder]){
                    sampleBuffer = [self decodeToSampleBufferRef:vp];
                }
                break;
                
            case 0x07:
                NSLog(@"Nal type is SPS");
                _spsSize = vp.size - 4;
                _sps = malloc(_spsSize);
                memcpy(_sps, vp.buffer + 4, _spsSize);
                break;
            case 0x08:
                NSLog(@"Nal type is PPS");
                _ppsSize = vp.size - 4;
                _pps = malloc(_ppsSize);
                memcpy(_pps, vp.buffer + 4, _ppsSize);
                break;
                
            default:
                NSLog(@"Nal type is B/P frame");
                sampleBuffer = [self decodeToSampleBufferRef:vp];
                break;
        }
        
        if (sampleBuffer) {
            if (avslayer != nil && [avslayer isReadyForMoreMediaData]) {
                dispatch_sync(dispatch_get_main_queue(),^{
                    [avslayer enqueueSampleBuffer:sampleBuffer];
                });
            }
            
            CFRelease(sampleBuffer);
        }
        
        NSLog(@"Read Nalu size %ld", (long)vp.size);
    }
    
    [parser close];
    [self clearH264Decoder];
    
    if (completion) {
        completion();
    }
}
@end
