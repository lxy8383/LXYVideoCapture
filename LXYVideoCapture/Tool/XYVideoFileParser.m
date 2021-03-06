//
//  XYVideoFileParser.m
//  LXYVideoCapture
//
//  Created by liuxy on 2019/9/11.
//  Copyright © 2019 liuxy. All rights reserved.
//

#import "XYVideoFileParser.h"

const uint8_t KStartCode[4] = {0, 0, 0, 1};

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

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSInputStream *fileStream;

@end

@implementation XYVideoFileParser

- (BOOL)open:(NSString *)fileName
{
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    self.fileName = fileName;
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];
    
    return YES;
}

- (XYVideoPacket *)nextPacket
{
    if(_bufferSize < _bufferCap && self.fileStream.hasBytesAvailable) {
        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    }
    
    if(memcmp(_buffer, KStartCode, 4) != 0) {
        return nil;
    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + 4;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    XYVideoPacket *vp = [[XYVideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    return nil;
}

- (void)close
{
    free(_buffer);
    [self.fileStream close];
}
@end
