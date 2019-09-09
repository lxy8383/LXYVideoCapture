//
//  XYRealTimeVideoTool.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/9.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYRealTimeVideoTool : NSObject

/**
 开始录制
 */
- (void)startCapture;

/**
 停止录制
 */
- (void)stopCapture;


- (void)insertView:(UIView *)blowView;
@end

NS_ASSUME_NONNULL_END
