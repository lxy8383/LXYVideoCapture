//
//  H264Encode.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/10.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYH264Encode : NSObject

// 初始化编码器
- (void)initVideoTool264Encode;

// 开始编码
- (void)encode:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
