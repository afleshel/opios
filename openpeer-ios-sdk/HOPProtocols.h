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


#ifndef openpeer_ios_sdk_OpenPeerProtocols_h
#define openpeer_ios_sdk_OpenPeerProtocols_h

#import "HOPTypes.h"

@protocol HOPStackDelegate <NSObject>

@optional
- (void) onStackShutdown;
@end

@protocol HOPLoggerDelegate <NSObject>

@optional
- (void) onNewSubsystem:(unsigned short) subsystemUniqueID subsystemName:(NSString*) subsystemName;
- (void) onLog:(unsigned short) subsystemUniqueID subsystemName:(NSString*)subsystemName severity:(HOPLoggerSeverities) severity level:(HOPLoggerLevels) level message:(NSString*) message function:(NSString*) function filePath:(NSString*) filePath lineNumber:(unsigned long) lineNumber;
@end


@protocol HOPMediaEngineDelegate <NSObject>

@required
- (void) onMediaEngineAudioRouteChanged:(HOPMediaEngineOutputAudioRoutes) audioRoute;
- (void) onMediaEngineFaceDetected;
- (void) onMediaEngineVideoCaptureRecordStopped;
- (void) onMediaEngineAudioSessionInterruptionBegan;
- (void) onMediaEngineAudioSessionInterruptionEnded;
@end


@class HOPAccount;

@protocol HOPAccountDelegate <NSObject>

@required
- (void) account:(HOPAccount*) account stateChanged:(HOPAccountStates) accountState;
- (void) onAccountAssociatedIdentitiesChanged:(HOPAccount*) account;
- (void) onAccountPendingMessageForInnerBrowserWindowFrame:(HOPAccount*) account;
@end


@class HOPCall;

@protocol HOPCallDelegate <NSObject>

@required
- (void) onCallStateChanged:(HOPCall*) call callState:(HOPCallStates) callState;
@end


@class HOPConversationThread;
@class HOPContact;

@protocol HOPConversationThreadDelegate <NSObject>

@required
- (void) onConversationThreadNew:(HOPConversationThread*) conversationThread;
- (void) onConversationThreadContactsChanged:(HOPConversationThread*) conversationThread;
- (void) onConversationThreadContactStateChanged:(HOPConversationThread*) conversationThread contact:(HOPContact*) contact contactState:(HOPConversationThreadContactStates) contactState;
- (void) onConversationThreadMessage:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID;
- (void) onConversationThreadMessageDeliveryStateChanged:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID messageDeliveryStates:(HOPConversationThreadMessageDeliveryStates) messageDeliveryStates;;
- (void) onConversationThreadPushMessage:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID contact:(HOPContact*) contact;
@end


@class HOPIdentity;

@protocol HOPIdentityDelegate <NSObject>
@required
- (void) identity:(HOPIdentity*) identity stateChanged:(HOPIdentityStates) state;

- (void) onIdentityPendingMessageForInnerBrowserWindowFrame:(HOPIdentity*) identity;

- (void) onIdentityRolodexContactsDownloaded:(HOPIdentity*) identity;

- (void) onNewIdentity:(HOPIdentity*) identity;
@end
#endif

@class HOPIdentityLookup;

@protocol HOPIdentityLookupDelegate <NSObject>

- (void) onIdentityLookupCompleted:(HOPIdentityLookup*) lookup;

@end

@class HOPCache;

@protocol HOPCacheDelegate <NSObject>

- (NSString*) fetchCookieWithPath:(NSString*) cookieNamePath;
- (void) storeCookie:(NSString*) cookie cookieNamePath:(NSString*) cookieNamePath expireTime:(NSDate*) expireTime;
- (void) clearCookieWithPath:(NSString*) cookieNamePath;

@end

@protocol HOPSettingsDelegate <NSObject>

/*- (NSString*) getString:(NSString*) key;
- (long) getInt:(NSString*) key;
- (unsigned long) getUInt:(NSString*) key;
- (BOOL) getBool:(NSString*) key;
- (float) getFloat:(NSString*) key;
- (double) getDouble:(NSString*) key;

- (void) setString:(NSString*) value key:(NSString*) key;
- (void) setInt:(long) value key:(NSString*) key;
- (void) setUInt:(unsigned long) value key:(NSString*) key;
- (void) setBool:(BOOL) value key:(NSString*) key;
- (void) setFloat:(float) value key:(NSString*) key;
- (void) setDouble:(double) value key:(NSString*) key;

- (void) clearForKey:(NSString*) key;
*/
@end
