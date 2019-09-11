//
//  XYVideoFileParser.h
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@interface XYVideoPacket : NSObject

@property (nonatomic, assign) uint8_t *buffer;
@property (nonatomic, assign) NSInteger size;

@end

@interface XYVideoFileParser : NSObject

- (void)open:(NSString *)fileName;
- (XYVideoPacket *)nextPacket;
- (void)close;

@end


NS_ASSUME_NONNULL_END
