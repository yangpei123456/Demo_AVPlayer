//
//  Myplay.h
//  Demo_AVPlayer
//
//  Created by caozhenwei on 16/1/27.
//  Copyright © 2016年 caozhenwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface Myplay : NSObject
//创建播放器
-(AVPlayer*)getAVPlayer;
//创建播放器元素
-(void)initWithAVPlayerAndAVPlayerItem:(AVPlayerItem*)item;
//设置播放器元素参数
-(void)setAVPlayerVolume:(float)volume;
@end
