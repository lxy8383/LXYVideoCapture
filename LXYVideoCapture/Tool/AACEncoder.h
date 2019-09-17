//
//  AACEncoder.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/17.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


NS_ASSUME_NONNULL_BEGIN

@interface AACEncoder : NSObject

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;


- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData * encodedData, NSError* error))completionBlock;

@end

NS_ASSUME_NONNULL_END
