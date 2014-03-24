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
#import <OpenpeerSDK/HOPProtocols.h>

@class Session;
@class HOPConversationThread;
@class HOPMessage;
@class HOPContact;
@class HOPRolodexContact;

@interface SessionManager : NSObject

@property (strong) NSMutableDictionary* sessionsDictionary;
@property (assign) Session* lastEndedCallSession;
@property (nonatomic, assign) Session* sessionWithFaceDetectionOn;

+ (id) sharedSessionManager;

- (Session*) createSessionForContact:(HOPRolodexContact*) contact;
- (Session*) createSessionForConversationThread:(HOPConversationThread*) inConversationThread;
- (Session*) createSessionInitiatedFromSession:(Session*) inSession forContactPeerURIs:(NSString*) peerURIs;
- (Session*) createRemoteSessionForContacts:(NSArray*) participants;
- (Session*) proceedWithExistingSessionForContact:(HOPContact*) contact newConversationThread:(HOPConversationThread*) inConversationThread;
- (Session*) getSessionForContact:(HOPRolodexContact*) contact;
- (Session*) getSessionForSessionId:(NSString*) sessionId;

- (void)setValidSession:(Session *)inSession newSessionId:(NSString *)newSessionId oldSessionId:(NSString *)oldSessionId;

- (void) makeCallForSession:(Session*) inSession includeVideo:(BOOL) includeVideo isRedial:(BOOL) isRedial;
- (void) answerCallForSession:(Session*) inSession;
- (void) endCallForSession:(Session*) inSession;

- (void) onCallPreparing:(HOPCall*) call;
- (void) onCallIncoming:(HOPCall*) call;
- (void) onCallRinging:(HOPCall*) call;
- (void) onCallOpened:(HOPCall*) call;
- (void) onCallClosing:(HOPCall*) call;

- (void) redialCallForSession:(Session*) inSession;

- (void) onCallEnded:(HOPCall*) call;
- (void) onFaceDetected;

- (void) startVideoRecording;
- (void) stopVideoRecording;

- (BOOL) isCallInProgress;
- (void) recreateExistingSessions;

- (void) stopAnyActiveCall;
- (void) clearAllSessions;

- (void) setLatestValidConversationThread:(HOPConversationThread*) inConversationThread;
@end
