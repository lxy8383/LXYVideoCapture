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
- (void)startCapture;

@end


@interface PlayControlView : UIView

@property (nonatomic, assign) id <PlayControlViewDelegate> delegate;

@property (nonatomic, strong) UIButton * captureButton;



@end

NS_ASSUME_NONNULL_END
