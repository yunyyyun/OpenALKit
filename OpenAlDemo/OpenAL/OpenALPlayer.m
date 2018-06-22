//
//  OpenALPlayer.m
//  openalOC
//
//  Created by mengyun on 2017/11/16.
//  Copyright © 2017年 mengyun. All rights reserved.
//

#import "OpenALPlayer.h"

#define MAX_BUFFER_COUNT        4
#define MAX_SOURCE_COUNT        32
#define THRESHOLD               27
#define TYPE_MP3                0
#define TYPE_WMV                1
#define kDefaultDistance        100.0
#define MAX_DURATION_TIME        4//最大播放持续时间，之后开始衰减
#define DECAY_TIME              27//衰减持续时间
typedef ALvoid    AL_APIENTRY    (*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
    static    alBufferDataStaticProcPtr    proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
    
    return;
}
@interface OpenALPlayer ()
{
    ALCcontext  *mContext;
    ALCdevice   *mDevice;
    ALuint      gBuffer[MAX_BUFFER_COUNT];
    ALuint      gSource[MAX_SOURCE_COUNT];
    ALint      gDuration[MAX_SOURCE_COUNT];  //记录sources的持续时间，当source不够用时将最旧的source切掉
    ALint       deadTime[MAX_SOURCE_COUNT]; //sources的最大持续时间，当gDuration>deadTime时开始衰减，直到stop
    ALfloat     originalGain[MAX_SOURCE_COUNT]; //source开始播放时的增益（音量）
    NSArray     *gSourceFile;
    ALuint      threshold;
    ALfloat     currentGain;
    ALint       currentType;
    ALint       steroType;          //0 left 1 right
    float        gSourcePosLeft[3];
    float        gSourcePosRight[3];
    BOOL        isVailed;
    ALfloat     pitchRate;
}

@end

@implementation OpenALPlayer
static OpenALPlayer *_player;

+ (id)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_player == nil) {
            _player = [[OpenALPlayer alloc] init];
            [_player initOpenAL];
        }
    });
    return _player;
}

- (void) setPitchAddTo:(ALfloat)value{
    if (value==0.0) {
        pitchRate = 1.0;
    }
    else{
        pitchRate = pitchRate+value;
    }
}

- (ALfloat) getPitch{
    return pitchRate;
}

- (void) setCurrentGain: (ALfloat)newValue{
    currentGain = newValue;
}

- (void) setSteroType: (ALint)newValue{
    steroType = newValue;
}

- (void) setCurrentType:(ALint)newValue{
    currentType = newValue;
    [self preloadBuffers];
}

// 初始化openAL
- (void) initOpenAL {
    ALenum            error;
    
    // Create a new OpenAL Device
    // Pass NULL to specify the system’s default output device
    mDevice = alcOpenDevice(NULL);
    if (mDevice != NULL)
    {
        // Create a new OpenAL Context
        // The new context will render to the OpenAL Device just created
        mContext = alcCreateContext(mDevice, 0);
        if (mContext != NULL)
        {
            // Make the new context the Current OpenAL Context
            alcMakeContextCurrent(mContext);
            
            alGenSources(MAX_SOURCE_COUNT, gSource);
            if((error = alGetError()) != AL_NO_ERROR) {
                printf("Error Generating Sources: ");
                exit(1);
            }
            
            alGenBuffers(MAX_BUFFER_COUNT, gBuffer);
            if((error = alGetError()) != AL_NO_ERROR) {
                printf("Error Generating Buffers: ");
                exit(1);
            }
            
        }
    }
    pitchRate = 1.0;
    currentGain = 1.0;
    currentType = TYPE_WMV;
    gSourceFile = [[NSArray alloc] initWithObjects:
                   @"flyup",@"hit",@"gg",@"start",nil];
    
    // 听者的位置.
    ALfloat ListenerPos[] = { 0.0, kDefaultDistance, 0.0 };
    // 听者的速度
    ALfloat ListenerVel[] = { 0.0, 0.0, 0.0 };
    // 听者的方向 (first 3 elements are "at", second 3 are "up")
    ALfloat ListenerOri[] = { 0.0, -1.0, 0.0, 0.0, 0.0, 1.0 };
    alListenerfv(AL_POSITION,    ListenerPos);
    alListenerfv(AL_VELOCITY,    ListenerVel);
    alListenerfv(AL_ORIENTATION, ListenerOri);
    alSpeedOfSound(343.3);

    gSourcePosLeft[0] = -kDefaultDistance;
    gSourcePosLeft[1] = 0;
    gSourcePosLeft[2] = 0;

    gSourcePosRight[0] = kDefaultDistance;
    gSourcePosRight[1] = 0;
    gSourcePosRight[2] = 0;
    
    [self preloadBuffers];
    for (int i=0; i<MAX_SOURCE_COUNT; ++i){
        gDuration[i] = 0;
        deadTime[i] = MAX_DURATION_TIME;
    }
    alGetError();
    isVailed = true;
}

- (void) doPlayWithTag:(int32_t)tag{
    //printf("currentGain idisis %lf \n",currentGain);
    [self playSound:(tag) gain:(currentGain)];
}

// 预先加载的buffers，没有数量限制
-(void)preloadBuffers
{
    ALenum  error = AL_NO_ERROR;
    ALenum  format;
    ALvoid* data;
    ALsizei size;
    ALsizei freq;
    UInt32    i;
    
    for (i=0; i<MAX_BUFFER_COUNT; ++i){
        // only the 1st 4 sources get data from a file. The 5th source gets data from capture
        NSString *type = @"mp3";
        if (currentType == TYPE_WMV){
            //type = @"wav";
        }
        NSString *fileString = [[NSBundle mainBundle] pathForResource:gSourceFile[i] ofType:type];
        //NSString *fileString = [[NSBundle mainBundle] pathForResource:gSourceFile[i] ofType:@"mp3"];

        // get some audio data from a wave file
        CFURLRef fileURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)fileString, NULL);
        data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
        
        CFRelease(fileURL);
        
        if((error = alGetError()) != AL_NO_ERROR) {
            printf("error loading ");
        }
        
        alBufferData(gBuffer[i], format, data, size, freq);
        
        // Release the audio data
        free(data);
    }
    
    if((error = alGetError()) != AL_NO_ERROR) {
        printf("error unloading %d\n",error);
    }
}

// 获取声音ID，然后启动声音播放
- (ALuint)playSound:(ALint)bufferID gain:(ALfloat)gain
{
    if (!isVailed){
        [self resume];
    }
    ALenum err = alGetError(); // clear error code
    // now find an available source
    ALuint sourceIndex = [self _nextAvailableSourceIndex];
    ALuint sourceID = gSource[sourceIndex];
    alSourceStop(sourceID);
    gDuration[sourceIndex] = -1;
    //printf("available source is %d\n", sourceID);
    if (sourceID==-1){
        return sourceID;
    }
    
    // 源声音的位置信息
    ALfloat SourceVel[] = { 0.0, 0.0, 0.0 };
    //alSourcef (sourceID, AL_PITCH,  1.0f)；
    alSourcef (sourceID, AL_PITCH,  pitchRate);
    if (steroType==0){
        alSourcefv(sourceID, AL_POSITION, gSourcePosLeft);
    }
    else{
        alSourcefv(sourceID, AL_POSITION, gSourcePosRight);
    }
    alSourcefv(sourceID, AL_VELOCITY, SourceVel);

    // make sure it is clean by resetting the source buffer to 0
    alSourcei(sourceID, AL_BUFFER, 0);
    // attach the buffer to the source
    alSourcei(sourceID, AL_BUFFER, gBuffer[bufferID]);          // set the gain of the source
    alSourcef(sourceID, AL_GAIN, gain);
    originalGain[sourceIndex] = gain;
    
    // check to see if there are any errors
    err = alGetError();
    if (err != 0) {
        NSLog(@"error(%d) in playSound %d\n",err,bufferID);
        //return 0;
    }
    // now play!
    alSourcePlay(sourceID);
    return sourceID; // return the sourceID so I can stop loops easily
}

-(ALuint)_nextAvailableSourceIndex
{
    ALint sourceState; // a holder for the state of the current source
    ALint maxDurationIndex = -1;
    ALint maxDuration = -1;
    // 对每个source，gDuration+1，并且找出当前持续最久、正在播放的source
    for (int i = 0; i < MAX_SOURCE_COUNT; ++i)
    {
        alGetSourcei(gSource[i], AL_SOURCE_STATE, &sourceState);
        if (sourceState == AL_PLAYING){
            if (gDuration[i] > maxDuration){
                maxDuration = gDuration[i];
                maxDurationIndex = i;
            }
            // 延音限制
            if (gDuration[i] > MAX_DURATION_TIME){
                float t = gDuration[i] - MAX_DURATION_TIME;
                if (t>=DECAY_TIME){
                    alSourceStop(gSource[i]);
                    alSourcei(gSource[i], AL_BUFFER, 0);
                    gDuration[i] = -1;
                }
                else{//平滑的降低音量
                    if (i==0) {
                        //printf("888888888888----(%d,%d)------88888888\n",gDuration[i] , MAX_DURATION_TIME);
                    }
                    alSourcef(gSource[i], AL_GAIN, 1.0 * (1 - t/DECAY_TIME));
                }
            }
            gDuration[i] = gDuration[i]+1;
        }
    }
    // 找到一个空闲的source
    for (int i = 0; i < MAX_SOURCE_COUNT; ++i)
    {
        alGetSourcei(gSource[i], AL_SOURCE_STATE, &sourceState);
        if (sourceState != AL_PLAYING){  // 空闲的source
            //gDuration[i] = -1;
            //printf("空闲的source，sourceid 是：%d\n",i);
            return i;//gSource[i];
        }
    }
    //printf("停掉正在播放的source，sourceid 是 %d, maxDuration is %d (%d)\n",maxDurationIndex,maxDuration,threshold);
    threshold = threshold+1;
    if (threshold==THRESHOLD){
        //printf("warning!!!,threshold==THRESHOLD %d %d\n",threshold,THRESHOLD);
//        [self reloadOpenAL];
//        threshold = 0;
    }
    return maxDurationIndex;
}

- (void) stopAllSource{
    ALint sourceState;
    for (int i = 0; i < MAX_SOURCE_COUNT; ++i)
    {
        alGetSourcei(gSource[i], AL_SOURCE_STATE, &sourceState);
        if (sourceState == AL_PLAYING){
            alSourceStop(gSource[i]);
            alSourcei(gSource[i], AL_BUFFER, 0);
            gDuration[i] = -1;
        }
    }
}
- (void) destory{
    alDeleteSources(MAX_SOURCE_COUNT, gSource);
    alDeleteBuffers(MAX_BUFFER_COUNT, gBuffer);
    alcMakeContextCurrent(nil);
    alcDestroyContext(mContext);
    alcCloseDevice(mDevice);
    isVailed = false;
}
- (void) resume{
    printf("OpenAL resume\n");
    if (isVailed){
        return ;
    }
    @synchronized(self){
        ALenum            error;
        // Create a new OpenAL Device
        // Pass NULL to specify the system’s default output device
        mDevice = alcOpenDevice(NULL);
        if (mDevice != NULL)
        {
            // Create a new OpenAL Context
            // The new context will render to the OpenAL Device just created
            mContext = alcCreateContext(mDevice, 0);
            if (mContext != NULL)
            {
                // Make the new context the Current OpenAL Context
                alcMakeContextCurrent(mContext);

                alGenSources(MAX_SOURCE_COUNT, gSource);
                if((error = alGetError()) != AL_NO_ERROR) {
                    printf("Error Generating Sources2: ");
                    //exit(1);
                }

                alGenBuffers(MAX_BUFFER_COUNT, gBuffer);
                if((error = alGetError()) != AL_NO_ERROR) {
                    printf("Error Generating Buffers2: ");
                    //exit(1);
                }
            }
        }
        [self preloadBuffers];
        isVailed = true;
    }
}

@end

