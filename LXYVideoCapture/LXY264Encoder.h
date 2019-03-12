//
//  LXY264Encoder.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/3/12.
//  Copyright © 2019年 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>
NS_ASSUME_NONNULL_BEGIN

@interface LXY264Encoder : NSObject

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)endEncode;

@end

NS_ASSUME_NONNULL_END
