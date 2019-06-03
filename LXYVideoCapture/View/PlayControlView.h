//
//  PlayControlView.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/3/12.
//  Copyright © 2019年 liuxy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PlayControlViewDelegate <NSObject>

//开始拍摄
- (void)startCapture:(BOOL)isCapture;

/**
 关闭拍摄
 */
- (void)closeCapture;

/**
 切换摄像头
 */
- (void)switchLens;

@end


@interface PlayControlView : UIView

@property (nonatomic, assign) id <PlayControlViewDelegate> delegate;


/**
 拍摄按钮
 */
@property (nonatomic, strong) UIButton * captureButton;

/**
 关闭按钮
 */
@property (nonatomic, strong) UIButton * closeButton;


/**
 切换镜头
 */
@property (nonatomic, strong) UIButton * switchLens;

@end

NS_ASSUME_NONNULL_END
