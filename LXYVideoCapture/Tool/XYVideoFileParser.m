//
//  XYVideoFileParser.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYVideoFileParser.h"

const uint8_t kStartCode[4] = {0, 0, 0, 1};

@implementation XYVideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    if(self){
        self.buffer = malloc(size);
        self.size = size;
    }
    return self;
}

- (void)dealloc
{
    free(self.buffer);
}

@end

@interface XYVideoFileParser()
{
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
}
@end

@implementation XYVideoFileParser

@end
