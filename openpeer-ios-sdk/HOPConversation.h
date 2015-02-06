/*
 
 Copyright (c) 2014, Hookflash Inc.
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
#import "HOPTypes.h"

@class HOPCall;
@class HOPConversationThread;
@class HOPMessageRecord;
@class HOPRolodexContact;
@class HOPConversationRecord;
@class HOPConversationEvent;

@interface HOPConversation : NSObject

//MOVE TO INTERNAL
/*@property (nonatomic, strong) HOPConversationThread* thread;
@property (nonatomic, strong) HOPConversationRecord* record;
@property (nonatomic, strong) HOPConversationEvent* lastEvent;

//TODO: MOVE TO INTERNAL-START
@property (nonatomic, strong) NSTimer* removalTimer;
@property (nonatomic, strong) NSSet* previousParticipants;*/
//TODO: MOVE TO INTERNAL-END

@property (nonatomic, copy) NSString* topic;
@property (nonatomic, copy) NSString* conversationID;
@property (nonatomic, getter=getParticipants) NSArray* participants;
@property (nonatomic, strong) NSArray* updatedContacts;


@property (strong) NSMutableSet* setOfNotSentMessages;
@property (assign) NSUInteger numberOfUnreadMessages;
@property (nonatomic, strong) HOPCall* currentCall;
@property (assign) BOOL redialCall;
@property (assign) HOPConversationThreadType conversationType;

+ (HOPConversation*) conversationWithParticipants:(NSArray*) participants title:(NSString*) inTitle type:(HOPConversationThreadType) type;
+ (HOPConversation*) conversationForRecord:(HOPConversationRecord*) inConversationRecord;
+ (HOPConversation*) conversationForID:(NSString *)conversationID threadType:(NSString *)threadType participants:(NSArray *)participants;
+ (HOPConversation*) getConversationForCBCID:(NSString*) cbcID;
+ (HOPConversation*) getConversationForID:(NSString*) inConversationID;

+ (NSArray*) getConversations;
- (void) addParticipants:(NSArray*) inParticipants;
- (void) removeParticipants:(NSArray*) inParticipants;

- (void) setComposingState:(HOPComposingState) composingState;

- (HOPComposingState) getComposingStateForContact:(HOPRolodexContact*) rolodexCoontact;
- (HOPMessageRecord*) getMessageForID: (NSString*) messageID;
- (void) markAllMessagesRead;

- (void) refresh;
- (void) clear;

- (void) sendMessage: (HOPMessageRecord*) message;
- (HOPCall*) placeCallForParticipants:(NSArray*) participants includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;

- (NSString*) getConversationID;
- (void)setConversationID:(NSString *)conversationID;
- (NSString*) getDefaultTitle;

+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state;
+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state;
+ (NSString*) stringForConversationThreadType:(HOPConversationThreadType) type;
+ (HOPConversationThreadType) conversationThreadTypeForString:(NSString*) type;
- (NSArray*) getParticipants;

+ (HOPConversation*) conversationOnParticipantsAdded:(NSArray*) addedParticipants conversation:(HOPConversation*) conversation;
+ (HOPConversation*) conversationOnParticipantsRemoved:(NSArray*) removedParticipants conversation:(HOPConversation*) conversation;


+ (NSString*) getDefaultTitleForParticipants:(NSArray*) inParticipants;

- (BOOL) quit;
- (BOOL) isQuit;

- (void) onRemovalTimerExpired:(id) object;
@end