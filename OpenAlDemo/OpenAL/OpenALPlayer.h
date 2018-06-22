//
//  OpenALPlayer.h
//  openalOC
//
//  Created by mengyun on 2017/11/16.
//  Copyright © 2017年 mengyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import "MyOpenALSupport.h"

@interface OpenALPlayer : NSObject
+ (id)shared;

- (void) setPitchAddTo:(ALfloat)value;
- (ALfloat) getPitch;
- (void) setSteroType: (ALint)newValue;
- (void) setCurrentGain:(ALfloat)newValue;
- (void) setCurrentType:(ALint)newValue;
- (void) doPlayWithTag:(int32_t)tag;
- (void) stopAllSource;
- (void) initOpenAL;
- (void) resume;
- (void) destory;

/**
 *  停止播放
 */
//-(void)stopSound;
@end

