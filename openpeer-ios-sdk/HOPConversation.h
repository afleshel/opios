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
#import "HOPTypes.h"

@class HOPCall;
@class HOPConversationThread;
@class HOPMessage;
@class HOPContact;
@class HOPConversationRecord;
@class HOPConversationEvent;

@interface HOPConversation : NSObject

@property (nonatomic, getter=getTopic, setter=setTopic:) NSString* topic;
@property (nonatomic, getter=getName, setter=setName:) NSString* name;
@property (nonatomic, getter=getCurrentCBCID, setter=setCBCID:) NSString* cbcID;
@property (nonatomic, copy) NSString* conversationID;
@property (nonatomic, copy) NSString* oldConversationID;
@property (nonatomic, getter=getParticipants) NSArray* participants;
@property (nonatomic, strong) NSArray* updatedContacts;
@property (nonatomic, strong) NSArray* unknownContacts;


@property (strong) NSMutableSet* setOfNotSentMessages;
@property (assign) NSUInteger numberOfUnreadMessages;
@property (nonatomic, strong) HOPCall* currentCall;
@property (assign) BOOL redialCall;
@property (assign) HOPConversationThreadType conversationType;

/**
 *  Creates a new conversation.
 *
 *  @param participants list of conversation participants
 *  @param inTitle      conversation name
 *  @param type         type of conversation
 *
 *  @return conversation object
 */
+ (HOPConversation*) conversationWithParticipants:(NSArray*) participants title:(NSString*) inTitle type:(HOPConversationThreadType) type;

/**
 *  Creates a conversation from conversation record
 *
 *  @param inConversationRecord Conversation record
 *
 *  @return conversation object
 */
+ (HOPConversation*) conversationForRecord:(HOPConversationRecord*) inConversationRecord;

/**
 *  Returns existing conversation for specified identifier, or creates a new of specified type with given identitfier and list of participants,
 *
 *  @param conversationID conversation identifier
 *  @param threadType     conversation type type
 *  @param participants   list of participants
 *
 *  @return conversation object
 */
+ (HOPConversation*) conversationForID:(NSString *)conversationID threadType:(NSString *)threadType participants:(NSArray *)participants;

/**
 *  Returns conversation for specified contact based identitfier
 *
 *  @param cbcID contact based identitfier
 *
 *  @return conversation object
 */
+ (HOPConversation*) getConversationForCBCID:(NSString*) cbcID;

/**
 *  Returns conversation for specified indetifier
 *
 *  @param inConversationID conversation identifier
 *
 *  @return conversation object
 */
+ (HOPConversation*) getConversationForID:(NSString*) inConversationID;

/**
 *  Returns list of all active conversations
 *
 *  @return list of active conversations
 */
+ (NSArray*) getConversations;

/**
 *  Add participants to thread based conversation
 *
 *  @param inParticipants list of participants to add
 */
- (void) addParticipants:(NSArray*) inParticipants;

/**
 *  Remove participants from the thread based conversation
 *
 *  @param inParticipants list of participants to remove
 */
- (void) removeParticipants:(NSArray*) inParticipants;

/**
 *  Set composing state in conversation for logged in contact
 *
 *  @param composingState composing state
 */
- (void) setComposingState:(HOPComposingState) composingState;

/**
 *  Retrieves composing state in conversation for specified indentity
 *
 *  @param identity identity whose state is of interest
 *
 *  @return composing state
 */
- (HOPComposingState) getComposingStateForContact:(HOPContact*) identity;

/**
 *  Returns message record for specified message identifier
 *
 *  @param messageID message identifier
 *
 *  @return message record object
 */
- (HOPMessage*) getMessageForID: (NSString*) messageID;

/**
 *  Marks all messages in the conversation read.
 */
- (void) markAllMessagesRead;

/**
 *  Refresh conversation thread
 */
- (void) refresh;

/**
 *  Destroys conversation thread.
 */
- (void) clear;

/**
 *  Sends message packed in HOPMessage object
 *
 *  @param message message object
 */
- (void) sendMessage: (HOPMessage*) message;

/**
 *  Create a call with given list of participants (currently it is supported only call one to one)
 *
 *  @param participants list of participants
 *  @param includeAudio is audio call
 *  @param includeVideo is video call
 *
 *  @return call object
 */
- (HOPCall*) placeCallForParticipants:(NSArray*) participants includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;

/**
 *  Returns conversation identifier
 *
 *  @return conversation identifier
 */
- (NSString*) getConversationID;

/**
 *  Sets conversation identifier
 *
 *  @param conversationID conversation identifier
 */
- (void)setConversationID:(NSString *)conversationID;


/**
 *  Returns default conversation title, that contains names of the participants
 *
 *  @return conversation title
 */
- (NSString*) getDefaultTitle;

/**
 *  Returns string representation for specified message delivery state
 *
 *  @param state message delivery state
 *
 *  @return string representation for message delivery state
 */
+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state;

/**
 *  Returns string representation for specified contact connection state
 *
 *  @param state contact connection state
 *
 *  @return string representation for contact connection state
 */
+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state;

/**
 *  Returns string representation for specified conversation thread type
 *
 *  @param type conversation thread type
 *
 *  @return string representation for conversation thread type
 */
+ (NSString*) stringForConversationThreadType:(HOPConversationThreadType) type;

/**
 *  Returns converstion thread type for specified string
 *
 *  @param type conversation thread type string representation
 *
 *  @return conversation thread type
 */
+ (HOPConversationThreadType) conversationThreadTypeForString:(NSString*) type;

/**
 *  Returns list o conversation participants
 *
 *  @return list of HOPContact objects
 */
- (NSArray*) getParticipants;

/**
 *  Updates list of participants for specified conversation. If specified conversation type is contact base it will be created a new conversation with specified participants. In case it is thread based conversation participants will be just added or removed
 *
 *  @param newParticipantsList new list of particpants
 *  @param conversation        converstion for which is provided new list of participants
 *
 *  @return conversation object with provided list of participants
 */
+ (HOPConversation*) conversationOnParticipantsChanged:(NSArray*) newParticipantsList conversation:(HOPConversation*) conversation;

/**
 *  Create a new conversation or returns existing one with updated list of participants
 *
 *  @param addedParticipants list of participants to add
 *  @param conversation      conversation to which new participants will be added
 *
 *  @return conversation object with updated list of participants
 */
+ (HOPConversation*) conversationOnParticipantsAdded:(NSArray*) addedParticipants conversation:(HOPConversation*) conversation;

/**
 *  Create a new conversation or returns existing one with updated list of participants
 *
 *  @param removedParticipants list of  participants to remove
 *  @param conversation      conversation from which participants should be removed
 *
 *  @return conversation object with updated list of participants
 */
+ (HOPConversation*) conversationOnParticipantsRemoved:(NSArray*) removedParticipants conversation:(HOPConversation*) conversation;

/**
 *  Disable conversation
 *
 *  @param disabled Flag if conversation is disabled or enabled
 */
- (void) setDisabled:(BOOL) disabled;
//NOT YET SUPPORTED SELF REMOVAL FROM CONVERSATION
//- (BOOL) quit;
//- (BOOL) isQuit;
//- (void) onRemovalTimerExpired:(id) object;
//- (BOOL) amIRemoved;
//-()
@end