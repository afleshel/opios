/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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

@class HOPIdentity;
@class HOPConversationRecord;
@class HOPMessage;
@class HOPConversationEvent;
@class HOPConversation;

@interface SessionManager : NSObject

//@property (strong) NSMutableDictionary* sessionsDictionary;
//@property (strong) NSMutableDictionary* conversationsDictionaryForContacts;
@property (assign) HOPConversation* lastEndedCallConversation;

+ (id) sharedSessionManager;


- (void) makeCallForConversation:(HOPConversation*) inConversation includeVideo:(BOOL) includeVideo isRedial:(BOOL) isRedial;
- (void) answerCallForConversation:(HOPConversation*) inConversation;
- (void) endCallForConversation:(HOPConversation*) inConversation;

- (void) onCallPreparing:(HOPCall*) call;
- (void) onCallIncoming:(HOPCall*) call;
- (void) onCallRinging:(HOPCall*) call;
- (void) onCallOpened:(HOPCall*) call;
- (void) onCallClosing:(HOPCall*) call;

- (void) redialCallForConversation:(HOPConversation*) inConversation;

- (void) onCallEnded:(HOPCall*) call;

- (void) startVideoRecording;
- (void) stopVideoRecording;

- (BOOL) isCallInProgress;
- (void) recreateExistingSessions;

- (void) stopAnyActiveCall;
- (void) clearAllSessions;

- (int) totalNumberOfUnreadMessages;
- (NSString* )getSystemMessage:(HOPMessage *)messageRecord;
- (NSString*) getLastTextMessageForConversationRecord:(HOPConversationRecord*) record;

- (void) onParticipantsInConversationUpdate:(HOPConversation*) conversation;

- (void) removeSelfFromConversation:(HOPConversation*) conversation;

- (NSString*) getNavigationTitleForConversation:(HOPConversation*) conversation;

- (void) fileUploadFinishedForMessageID:(NSString*) messageID;

- (void) fileDownloadFinishedForMessageID:(NSString*) messageID;
@end
