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

@class HOPCoreContact;
@class HOPRolodexContact;
@class HOPMessageRecord;
@class HOPAccount;
@class HOPAccountIdentity;
@class HOPOpenPeerContact;
//HOP_NOTICE: Don't expose this till group conversations are not enabled
@interface ContactInfo
{
  HOPCoreContact* mContact;
  NSString* mProfileBundleEl;
};

@end

@interface HOPConversationThread : NSObject

@property (assign) HOPConversationThreadType conversationType;

/**
*  Creates a new conversation thread.
*
*  @param identities List of identities that are shared with conversation thread participants
*
*  @return HOPConversationThread object
*/
+ (id) conversationThreadWithIdentities:(NSArray*) identities;


+ (id) conversationThreadWithIdentities:(NSArray*) identities participants:(NSArray*) participants conversationThreadID:(NSString*) conversationThreadID  threadType:(HOPConversationThreadType) threadType;

/**
 Returns list of all active conversation threads.
 @return List of HOPConversationThread objects
 */
+ (NSArray*) getActiveConversationThreads;

/**
 Returns a conversation thread object for specific thread ID
 @param threadID Conversation thread ID
 @return HOPConversationThread object
 */
+ (HOPConversationThread*) getConversationThreadForID:(NSString*) threadID;

/**
 Returns a string representation of the message delivery state.
 @param state Message delivery state to convert to string
 @return A string representation of message delivery state
 */
+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state;

/**
 Returns a enum representation of the message delivery state.
 @param messageDeliveryStateString Message delivery state string
 @return A enum representation of message delivery state
 */
+ (HOPConversationThreadMessageDeliveryState) toMessageDeliveryStates:(NSString*) messageDeliveryStateString;


/**
 Returns a  string representation of the contact connection state.
 @param state Contact connection state to convert to string
 @return A string representation of contact state
 */
+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state;


/**
 Returns a conversation thread ID.
 @return A conversation thread ID
 */
- (NSString*) getThreadId;

- (NSString*) getConversationThreadID;

/**
 Checks if self is host of the conversation thread.
 @return YES if self is host, NO if not
 */
- (BOOL) amIHost;

/**
 Returns the associated account object.
 @Returns HOPAccount  object
 */
- (HOPAccount*) getAssociatedAccount;

/**
 Returns the array of contacts participating in the conversation thread.
 @returns Array of HOPCoreContact objects
 */
//- (NSArray*) getContacts;

/**
 Adds array of contacts to the conversation thread.
 @param contacts  Array of HOPCoreContact objects to be added to the conversation thread
 */
- (void) addContacts: (NSArray*) contacts;

/**
 Removes an array of contacts from the conversation thread.
 @param contacts Array of HOPCoreContact objects to be removed from the conversation thread
 */
- (void) removeContacts: (NSArray*) contacts;

/**
 Returns list of HOPAccountIdentity objects for associated with HOPCoreContact object.
 @param coAn array for HOPAccountIdentity objects
 */
- (NSArray*) getIdentityContactListForContact:(HOPCoreContact*) contact;

/**
 Returns a state of the provided contact.
 @param contact HOPCoreContact object
 @returns Contact connection state enum
 */
- (HOPConversationThreadContactConnectionState) getContactConnectionState: (HOPRolodexContact*) contact;

/**
 *  Creates an empty JSON status blob ready to fill with additional structure data. Use "ComposingStatus" to insert composing status information into this JSON blob.
 *
 *  @return empty JSON status string
 */
- (NSString*) createEmptyStatus;

/**
 *  Get the composing status of a contact in the conversation thread.
 *
 *  @param contact Contact in the conversation thread
 *
 *  @return Contact composing status 
 */
- (HOPComposingState) getComposingStateForContact:(HOPRolodexContact*) contact;


/**
 *  Set the composing status of yourself in the conversation thread.
 *
 *  @param status  Contact composing status
 */
- (void) setComposingStatusInThread:(HOPComposingState) status;

/**
 Sends message to all contacts in the conversation thread. Deprecated.
 @param messageID  Message ID
 @param messageType Message type
 @param message Message
 */
//- (void) sendMessage: (NSString*) messageID messageType:(NSString*) messageType message:(NSString*) message DEPRECATED_ATTRIBUTE;

/**
 Sends message to all contacts in the conversation thread.
 @param message Message object
 */
- (void) sendMessage: (HOPMessageRecord*) message;


/**
 Returns message for specified message ID.
 @param messageID  A received message ID
 @return HOPMessageRecord object
 */
- (HOPMessageRecord*) getMessageForID: (NSString*) messageID;

/**
 Retrieves delivery state of the message.
 @param messageID A message ID
 @param outDeliveryState A message delivery state
 @returns YES if delivery state is retrieved, otherwise NO
 */
- (BOOL) getMessageDeliveryState: (NSString*) messageID outDeliveryState:(HOPConversationThreadMessageDeliveryState*) outDeliveryState;

- (void) setMessageDeliveryState: (NSString*) messageID deliveryState:(HOPConversationThreadMessageDeliveryState) deliveryState;
/**
 *  Mark all received messages thus far as read
 */
- (void) markAllMessagesRead;

/**
 Creates a sysmtem message of specific type.
 @param systemMessageType  System message type
 @param messageType SubType of system message
 @param contact Message recepient
 @return NSString formated system message
 */
//+ (NSString*) createSystemMessage:(HOPSystemMessageType) systemMessageType messageType:(int) messageType contact:(HOPCoreContact*) contact;

/**
 *  Returns system message type string.
 */
+ (NSString*) getSystemMessageType;

/**
  Destroys conversation thread core object.
 */
- (void) destroyCoreObject;
@end
