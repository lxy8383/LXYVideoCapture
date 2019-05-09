//
//  XYCaptureShortVideoTool.h
//  LXYVideoCapture
//
//  Created by liu on 2019/5/8.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface XYCaptureShortVideoTool : NSObject

/**
 开始录制
 */
- (void)startCapture;


/**
 暂停拍摄
 */
- (void)pauseCapture;


/**
 停止录制
 */
- (void)stopCapture;


- (void)insertView:(UIView *)blowView;

@end

NS_ASSUME_NONNULL_END
