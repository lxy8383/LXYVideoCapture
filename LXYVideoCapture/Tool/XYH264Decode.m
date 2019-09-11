//
//  XYH264Decode.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYH264Decode.h"

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

- (void)initVideoDecode
{
    if(_decoderSession) {
        return;
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

- (CVPixelBufferRef)decode:()
@end
