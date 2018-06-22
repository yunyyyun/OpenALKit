
#include "MyOpenALSupport.h"

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei*	outSampleRate)
{
	OSStatus						err = noErr;	
	SInt64							theFileLengthInFrames = 0;
	AudioStreamBasicDescription		theFileFormat;
	UInt32							thePropertySize = sizeof(theFileFormat);
	ExtAudioFileRef					extRef = NULL;
	void*							theData = NULL;
	AudioStreamBasicDescription		theOutputFormat;

	// Open a file with ExtAudioFileOpen()
	err = ExtAudioFileOpenURL(inFileURL, &extRef);
	if(err) {
        printf("MyGetOpenALAudioData: ExtAudioFileOpenURL FAILED, Error = %d\n", (int)err);
        exit(1);
    }
	
	// Get the audio data format
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &theFileFormat);
	if(err) {
        printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %d\n", err);
        exit(1);
    }
	if (theFileFormat.mChannelsPerFrame > 2)  {
        printf("MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n");
        exit(1);
        
    }

	// Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = theFileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame;

	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 16;
	theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	
	// Set the desired client (output) data format
	err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(theOutputFormat), &theOutputFormat);
    if(err) {
        printf("MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %d\n", err);
        exit(1);
        
    }
	
	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if(err) {
        printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %d\n", err);
        exit(1); }
	
	// Read all the data into memory
	UInt32 theFramesToRead = (UInt32)theFileLengthInFrames;		
	UInt32 dataSize = theFramesToRead * theOutputFormat.mBytesPerFrame;;
	theData = malloc(dataSize);
	if (theData)
	{
		AudioBufferList		theDataBuffer;
		theDataBuffer.mNumberBuffers = 1;
		theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
		theDataBuffer.mBuffers[0].mData = theData;
		
		// Read the data into an AudioBufferList
		err = ExtAudioFileRead(extRef, &theFramesToRead, &theDataBuffer);
		if(err == noErr)
		{
			// success
			*outDataSize = (ALsizei)dataSize;
			*outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
			*outSampleRate = (ALsizei)theOutputFormat.mSampleRate;
		}
		else 
		{ 
			// failure
			free (theData);
			theData = NULL; // make sure to return NULL
			printf("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %d\n", err);
            exit(1);
		}	
	}
	
Exit:
	// Dispose the ExtAudioFileRef, it is no longer needed
	if (extRef) ExtAudioFileDispose(extRef);
	return theData;
}
