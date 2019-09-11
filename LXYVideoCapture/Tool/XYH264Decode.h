//
//  XYH264Decode.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^XYH264DecoderCompletionCallback)(void);


NS_ASSUME_NONNULL_BEGIN

@interface XYH264Decode : NSObject


- (void)decodeFile:(NSString *)fileName fileExt:(NSString *)fileExt andAVSLayer:(AVSampleBufferDisplayLayer *)avslayer completion:(XYH264DecoderCompletionCallback)completion;


@end

NS_ASSUME_NONNULL_END
