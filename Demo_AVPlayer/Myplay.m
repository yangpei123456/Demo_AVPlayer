//
//  Myplay.m
//  Demo_AVPlayer
//
//  Created by caozhenwei on 16/1/27.
//  Copyright © 2016年 caozhenwei. All rights reserved.
//

#import "Myplay.h"
@interface Myplay ()
{

    AVPlayer* player;


}
@end
@implementation Myplay
-(AVPlayer *)getAVPlayer{
    if (!player) {
        return nil;
        
    }
    return player;

}

//设置播放器元素
-(void)initWithAVPlayerAndAVPlayerItem:(AVPlayerItem *)item{

     player = [AVPlayer playerWithPlayerItem:item];

}
//设置元素参数(一般为1)
-(void)setAVPlayerVolume:(float)volume{
    [player setVolume:1];
}
@end
