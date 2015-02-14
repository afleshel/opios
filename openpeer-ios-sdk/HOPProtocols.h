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


#import "HOPTypes.h"

/**
 *  SDK uses method in this protocol to notify application that Stack is shutdown.
 */
@protocol HOPStackDelegate <NSObject>

@optional

/**
 *  Notifies the receiver that stack is shutdown.
 */
- (void) onStackShutdown;
@end

@protocol HOPLoggerDelegate <NSObject>

@optional
- (void) onNewSubsystem:(unsigned short) subsystemUniqueID subsystemName:(NSString*) subsystemName;
- (void) onLog:(unsigned short) subsystemUniqueID subsystemName:(NSString*)subsystemName severity:(HOPLoggerSeverity) severity level:(HOPLoggerLevel) level message:(NSString*) message function:(NSString*) function filePath:(NSString*) filePath lineNumber:(unsigned long) lineNumber;
@end


/**
 *  SDK uses methods in this protocol to notify application about events from the media engine.
 */
@protocol HOPMediaEngineDelegate <NSObject>

@required
/**
 *  Notifies the receiver about audio route change (built in speaker, headphones).
 *
 *  @param audioRoute New active audio route.
 */
- (void) onMediaEngineAudioRouteChanged:(HOPMediaEngineOutputAudioRoute) audioRoute;
- (void) onMediaEngineFaceDetected;
- (void) onMediaEngineVideoCaptureRecordStopped;
/**
 *  Notifies the receiver about audio interruption has began (incomming call etc.).
 */
- (void) onMediaEngineAudioSessionInterruptionBegan;
/**
 *  Notifies the receiver about audio interruption has ended.
 */
- (void) onMediaEngineAudioSessionInterruptionEnded;
@end


@class HOPAccount;

/**
 *  SDK uses methods in this protocol to notify application about account events.
 */
@protocol HOPAccountDelegate <NSObject>

@required
/**
 *  Notifies the receiver about account object state change.
 *
 *  @param account      HOPAccount object whose state is changed.
 *  @param accountState A new account object state
 */
- (void) account:(HOPAccount*) account stateChanged:(HOPAccountState) accountState;
/**
 *  Notifies the receiver about change in list of associated identities.
 *
 *  @param account HOPAccount object whose list of associated identities has changed.
 */
- (void) onAccountAssociatedIdentitiesChanged:(HOPAccount*) account;
/**
 *  Notifies the receiver about core message for inner browser frame.
 *
 *  @param account HOPAccount object.
 */
- (void) onAccountPendingMessageForInnerBrowserWindowFrame:(HOPAccount*) account;
@end


@class HOPCall;
/**
 *  SDK uses method in this protocol to notify application about call events.
 */
@protocol HOPCallDelegate <NSObject>

@required
/**
 *  Notifies the receiver about call  state change.
 *
 *  @param call      Call object whose state is changed.
 *  @param callState A new call state.
 */
- (void) onCallStateChanged:(HOPCall*) call callState:(HOPCallState) callState;
@end


@class HOPConversationThread;
@class HOPContact;

/**
 *  SDK uses methods in this protocol to notify application about conversation thread events.
 */
@protocol HOPConversationThreadDelegate <NSObject>

@required
/**
 *  Notifies the receiver that new conversation thread is created.
 *
 *  @param conversationThread Created conversation thread object.
 */
- (void) onConversationThreadNew:(HOPConversationThread*) conversationThread;

/**
 *  Notifies the receiver about change in list of participants.
 *
 *  @param conversationThread Conversation thread object.
 */
- (void) onConversationThreadContactsChanged:(HOPConversationThread*) conversationThread;
/**
 *  Notifies the receiver about conversation thread participant connection state.
 *
 *  @param conversationThread     Conversation thread object.
 *  @param contact                Participant whose state in conversation thredad has changed.
 *  @param contactConnectionState A new participant state
 */
- (void) onConversationThreadContactConnectionStateChanged:(HOPConversationThread*) conversationThread contact:(HOPContact*) contact contactConnectionState:(HOPConversationThreadContactConnectionState) contactConnectionState;
/**
 *  Notifies the receiver about conversation thread participant status.
 *
 *  @param conversationThread     Conversation thread object.
 *  @param contact                Participant whose status in conversation thredad has changed.
 */
- (void) onConversationThreadContactStatusChanged:(HOPConversationThread*) conversationThread contact:(HOPContact*) contact;
/**
 *  Notifies the receiver about new message for conversation.
 *
 *  @param conversationThread Conversation thread object.
 *  @param messageID          A message ID. This ID will be used for retrieving message from the conversation thread.
 */
- (void) onConversationThreadMessage:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID;
/**
 *  Notifies the receiver about change in message delivery state.
 *
 *  @param conversationThread    Conversation thread object.
 *  @param messageID             An ID of message whose delivery state has changed.
 *  @param messageDeliveryStates A new message delivery state.
 */
- (void) onConversationThreadMessageDeliveryStateChanged:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID messageDeliveryStates:(HOPConversationThreadMessageDeliveryState) messageDeliveryStates;
/**
 *  Notifies the receiver that message is not delivered and it is good time to send a push notification if application supports it.
 *
 *  @param conversationThread Conversation thread object.
 *  @param messageID          An ID of undelivered message.
 *  @param contact            A message recepient.
 */
- (void) onConversationThreadPushMessage:(HOPConversationThread*) conversationThread messageID:(NSString*) messageID contact:(HOPContact*) contact;
@end



@class HOPAccountIdentity;
/**
 *  SDK uses methods in this protocol to notify application about identity events.
 */
@protocol HOPAccountIdentityDelegate <NSObject>
@required
/**
 *  Notifies the receiver about identity object state change.
 *
 *  @param account      Identity object whose state is changed.
 *  @param accountState A new identity object state
 */
- (void) identity:(HOPAccountIdentity*) accountIdentity stateChanged:(HOPAccountIdentityState) state;

/**
 *  Notifies the receiver about core message for inner browser frame.
 *
 *  @param identity HOPAccountIdentity object.
 */
- (void) onIdentityPendingMessageForInnerBrowserWindowFrame:(HOPAccountIdentity*) accountIdentity;

/**
 *  Notifies the receiver that identitues has been downloaded.
 *
 *  @param identity HOPAccountIdentity object.
 */
- (void) onIdentityContactsDownloaded:(HOPAccountIdentity*) accountIdentity;

/**
 *  Notifies the receiver that identity has been downloaded.
 *
 *  @param identity New HOPAccountIdentity object.
 */
- (void) onNewIdentity:(HOPAccountIdentity*) accountIdentity;
@end

@class HOPIdentityLookup;

/**
 *  SDK uses methods in this protocol to notify application about identity lookup events.
 */
@protocol HOPIdentityLookupDelegate <NSObject>
/**
 *  Notifies the receiver that identity lookup has been finished.
 *
 *  @param lookup HOPIdentityLookup object
 */
- (void) onIdentityLookupCompleted:(HOPIdentityLookup*) lookup;

@end

@class HOPCache;

/**
 *  SDK uses methods in this protocol to notify application about cache actions. This needs to be implemented only if you don't want to use default cache logic, and you are implementing a new one.
 */
@protocol HOPCacheDelegate <NSObject>

/**
 *  Returns a cookie for specified path.
 *
 *  @param cookieNamePath Cookie's path
 *
 *  @return Cookie
 */
- (NSString*) fetchCookieWithPath:(NSString*) cookieNamePath;

/**
 *  Stores cookie.
 *
 *  @param cookie         Cookie
 *  @param cookieNamePath Cookie's path
 *  @param expireTime     Cookie's expiry time
 */
- (void) storeCookie:(NSString*) cookie cookieNamePath:(NSString*) cookieNamePath expireTime:(NSDate*) expireTime;

/**
 *  Delete cookie at specified path.
 *
 *  @param cookieNamePath Cookie's path
 */
- (void) clearCookieWithPath:(NSString*) cookieNamePath;

@end

/**
 *  SDK uses methods in this protocol to notify application when application is ready for going to background.
 */
@protocol HOPBackgroundingCompletionDelegate <NSObject>

/**
 *  Notifies the receiver that SDK has finished all ongoing tasks and it is ready to go to background.
 */
- (void) onBackgroundingReady;

@end

@class HOPBackgroundingSubscription;
@class HOPBackgroundingNotifier;

/**
 *  SDK uses methods in this protocol to notify application about changes in backgrounding flow.
 */
@protocol HOPBackgroundingDelegate <NSObject>

/**
 *  Notifies application that is going to background. Finish any ongoing task in application.
 *
 *  @param subscription HOPBackgroundingSubscription object
 *  @param notifier     HOPBackgroundingNotifier object
 */
- (void) onBackgroundingGoingToBackground:(HOPBackgroundingSubscription*) subscription notifier:(HOPBackgroundingNotifier*)notifier;

/**
 *  Notifies application that is going to background now, without time to finish ongoing tasks.
 *
 *  @param subscription HOPBackgroundingNotifier object
 */
- (void) onBackgroundingGoingToBackgroundNow:(HOPBackgroundingSubscription*) subscription;

/**
 *  Notifies application that is returning from the background.
 *
 *  @param subscription HOPBackgroundingNotifier object
 */
- (void) onBackgroundingReturningFromBackground:(HOPBackgroundingSubscription*) subscription;

/**
 *  Notifies application that it will be closed.
 *
 *  @param subscription HOPBackgroundingNotifier object
 */
- (void) onBackgroundingApplicationWillQuit:(HOPBackgroundingSubscription*) subscription;


@end


@class HOPConversation;
@class HOPMessageRecord;


/**
 *  SDK uses methods in this protocol to notify application about conversation thread events.
 */
@protocol HOPConversationDelegate <NSObject>

@required
/**
 *  Notifies the receiver that new conversation thread is created.
 *
 *  @param conversationThread Created conversation thread object.
 */
- (void) onConversationNew:(HOPConversation*) conversation;

/**
 *  Notifies the receiver about change in list of participants.
 *
 *  @param conversationThread Conversation thread object.
 */
- (void) onConversationContactsChanged:(HOPConversation*) conversation;
/**
 *  Notifies the receiver about conversation thread participant connection state.
 *
 *  @param conversationThread     Conversation thread object.
 *  @param contact                Participant whose state in conversation thredad has changed.
 *  @param contactConnectionState A new participant state
 */
- (void) onConversationContactConnectionStateChanged:(HOPConversation*) conversation contact:(HOPContact*) contact contactConnectionState:(HOPConversationThreadContactConnectionState) contactConnectionState;
/**
 *  Notifies the receiver about conversation thread participant status.
 *
 *  @param conversationThread     Conversation thread object.
 *  @param contact                Participant whose status in conversation thredad has changed.
 */
- (void) onConversationContactStatusChanged:(HOPConversation*) conversation contact:(HOPContact*) contact;
- (void) onConversationContactComposingStateChanged:(HOPConversation*) conversation state:(HOPComposingState)state contact:(HOPContact*) contact;
/**
 *  Notifies the receiver about new message for conversation.
 *
 *  @param conversationThread Conversation thread object.
 *  @param messageID          A message ID. This ID will be used for retrieving message from the conversation thread.
 */
- (void) onConversationMessage:(HOPConversation*) conversation messageID:(NSString*) messageID;
- (void) onConversationNewMessage:(HOPConversation*) conversation message:(HOPMessageRecord*) message;
- (void) onConversationCallSystemMessageReceived:(HOPConversation*) conversation jsonMessage:(NSString*) jsonMessage;
- (void) onConversationSwitch:(HOPConversation*) conversation fromConversationId:(NSString*)fromConversationId toConversationId:(NSString*)toConversationId;


/**
 *  Notifies the receiver about change in message delivery state.
 *
 *  @param conversationThread    Conversation thread object.
 *  @param messageID             An ID of message whose delivery state has changed.
 *  @param messageDeliveryStates A new message delivery state.
 */
- (void) onConversationMessageDeliveryStateChanged:(HOPConversation*) conversation messageID:(NSString*) messageID messageDeliveryStates:(HOPConversationThreadMessageDeliveryState) messageDeliveryStates;
/**
 *  Notifies the receiver that message is not delivered and it is good time to send a push notification if application supports it.
 *
 *  @param conversationThread Conversation thread object.
 *  @param messageID          An ID of undelivered message.
 *  @param contact            A message recepient.
 */
- (void) onConversationPushMessage:(HOPConversation*) conversation messageID:(NSString*) messageID contact:(HOPContact*) contact;
- (void) onConversationPushMessageRequired:(HOPConversation*) conversation message:(HOPMessageRecord*) message recipient:(HOPContact*) recipient;

//- (void) onConversationTopicChanged:(HOPConversation*) conversation newTopic:(NSString*) newTopic;

@end