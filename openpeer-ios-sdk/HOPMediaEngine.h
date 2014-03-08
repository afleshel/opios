/*
 
 Copyright (c) 2012, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HOPMediaEngineRtpRtcpStatistics.h"
#import "HOPTypes.h"
#import "HOPProtocols.h"

@interface HOPMediaEngine : NSObject

/**
 Retrieves string representation of camera type.
 @param type HOPMediaEngineCameraTypes Camera type enum
 @returns String representation of camera type
 */
+ (NSString*) cameraTypeToString: (HOPMediaEngineCameraTypes) type;

/**
 Retrieves string representation of the audio route.
 @param route HOPMediaEngineOutputAudioRoutes Audio route enum
 @returns String representation of audio route
 */
+ (NSString*) audioRouteToString: (HOPMediaEngineOutputAudioRoutes) route;

/**
 Returns singleton object of this class.
 */
+ (id)sharedInstance;

/**
 Sets video parameters for current orientation. Should be called when device orientation changes.
 */
- (void) setVideoOrientation;

/**
 Sets default orientation that is used when defice is in face up / face down position.
 @param orientation Default video orientation
 */
- (void) setDefaultVideoOrientation: (HOPMediaEngineVideoOrientations) orientation;

/**
 Retrieves default orientation that is used when defice is in face up / face down position.
 @return Default video orientation
 */
- (HOPMediaEngineVideoOrientations) getDefaultVideoOrientation;

/**
 Sets orientation that is used when recording is active. Video orientation is locked during video recording. Must be set before video recording is started.
 @param orientation Default video orientation
 */
- (void) setRecordVideoOrientation: (HOPMediaEngineVideoOrientations) orientation;

/**
 Retrieves orientation that is used when recording is active.
 @return Video orientation used during video recording
 */
- (HOPMediaEngineVideoOrientations) getRecordVideoOrientation;

/**
 Sets window for rendering local capture video.
 @param renderView UIImageView Window where local capture video will be rendered
 */
- (void) setCaptureRenderView: (UIImageView*) renderView;

/**
 Sets window for rendering video received from channel.
 @param renderView UIView Window where video received from channel will be rendered
 */
- (void) setChannelRenderView: (UIImageView*) renderView;

/**
 Turns echo cancelation ON/OFF.
 @param enabled BOOL Enabled flag
 */
- (void) setEcEnabled: (BOOL) enabled;

/**
 Turns automatic gain control ON/OFF.
 @param enabled BOOL Enabled flag
 */
- (void) setAgcEnabled: (BOOL) enabled;

/**
 Turns noise suppression ON/OFF.
 @param enabled BOOL Enabled flag
 */
- (void) setNsEnabled: (BOOL) enabled;

/**
 Sets voice recording file name.
 @param fileName NSString Recording file name
 */
- (void) setVoiceRecordFile: (NSString*) fileName;

/**
 Retrieves voice recording file name.
 @return Retrieves recording file name
 */
- (NSString*) getVoiceRecordFile;

/**
 Turns mute ON/OFF.
 @param enabled BOOL Enabled flag
 */
- (void) setMuteEnabled: (BOOL) enabled;

/**
 Retrieves info if audio is muted.
 @return YES if mute is enabled, NO if not
 */
- (BOOL) getMuteEnabled;

/**
 Turns loudspeaker ON/OFF.
 @param enabled BOOL Enabled flag
 */
- (void) setLoudspeakerEnabled: (BOOL) enabled;

/**
 Retrieves info if loudspeakers is muted.
 @return YES if loudspeakers are enabled, NO if not
 */
- (BOOL) getLoudspeakerEnabled;

/**
 Retrieves output audio route.
 @return Output audio route enum
 */
- (HOPMediaEngineOutputAudioRoutes) getOutputAudioRoute;

/**
 Retrieves camera type.
 @return Camera type enum
 */
- (HOPMediaEngineCameraTypes) getCameraType;

/**
 Sets provided camera type as active.
 @param type HOPMediaEngineCameraTypes Camera type
 */
- (void) setCameraType: (HOPMediaEngineCameraTypes) type;

/**
 Retrieves video transport statistics.
 @param stat HOPMediaEngineRtpRtcpStatistics Statistics structure to be filled with stats
 @returns Error code, 0 if success
 */
- (int) getVideoTransportStatistics: (HOPMediaEngineRtpRtcpStatistics*) stat;

/**
 Retrieves video transport statistics.
 @param stat HOPMediaEngineRtpRtcpStatistics Statistics structure to be filled with stats
 @returns Error code, 0 if success
 */
- (int) getVoiceTransportStatistics: (HOPMediaEngineRtpRtcpStatistics*) stat;

/**
 Continuous capture - whether capture should be turned off when call is finished.
 @param enabled BOOL Enabled flag
 */
- (void) setContinuousVideoCapture:(BOOL) continuousVideoCapture;

/**
 Retrieves continuous capture flag.
 @return YES if continuous capture is enabled, NO if not
 */
- (BOOL) getContinuousVideoCapture;

/**
 Sets whether face detection is enabled. Should be set before start capture is called.
 @param enabled BOOL Enabled flag
 */
- (void) setFaceDetection: (BOOL) enabled;

/**
 Retrieves status of face detection flag.
 @return YES if face detection is enabled, NO if not
 */
- (BOOL) getFaceDetection;

/**
 Starts video capture. Video is rendered to Render View that is previously set.
 */
- (void) startVideoCapture;

/**
 Ends video capture. Method will not have effect during the call.
 */
- (void) stopVideoCapture;

/**
 Starts video capture recording. This method must be called after Video Capture has been started.
 @param fileName NSString Recording file name. If saveToLibrary is 'true' only file name, without path,
 sholud be provided. If saveToLibrary is 'false' full recording path should be specified.
 @param saveToLibrary BOOL If 'true' recorded video will be saved to photo album, otherwise the movie will be
 saved to specified path.
 */
- (void) startRecordVideoCapture: (NSString*) fileName saveToLibrary: (BOOL) saveToLibrary;

/**
 Ends video capture recordng. Video capture recording must be started before this method call.
 */
- (void) stopRecordVideoCapture;

- (void) startFaceDetectionForImageView:(UIImageView*) inImageView;
- (void) stopFaceDetection;

- (void) pauseVoice:(BOOL) pause;
@end
