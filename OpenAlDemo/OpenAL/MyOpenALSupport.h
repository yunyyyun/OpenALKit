
#include <CoreFoundation/CoreFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei* outSampleRate);
