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
#import "HOPTypes.h"

@class HOPContact;
@class HOPRolodexContact;
@class HOPMessage;
@class HOPAccount;
@class HOPIdentity;

//HOP_NOTICE: Don't expose this till group conversations are not enabled
@interface ContactInfo
{
  HOPContact* mContact;
  NSString* mProfileBundleEl;
};

@end

@interface HOPConversationThread : NSObject

/**
 Creation of new conversation thread.
 @param account HOPAccount Account which owns the conversation thread
 @param profileBundleEl NSString Profile bundle
 @returns HOPConversationThread object if core conversation thread object is created
 */
//+ (id) conversationThreadWithProfileBundle:(NSString*) profileBundle;
+ (id) conversationThreadWithIdentities:(NSArray*) identities;
/**
 Retrieves list of all created conversation threads.
 @returns NSArray List of HOPConversationThread objects
 */
+ (NSArray*) getConversationThreadsForAccount;

/**
 Retrieves conversation thread object for specific thread id
 @param threadID NSString Id of disered conversation thread.
 @returns HOPConversationThread Conversation thread object
 */
+ (HOPConversationThread*) getConversationThreadForID:(NSString*) threadID;

/**
 Retrieves string representation of the message delivery state.
 @param state HOPConversationThreadMessageDeliveryStates Message delivery state to convert to string
 @returns String representation of message delivery state
 */
+ (NSString*) deliveryStateToString: (HOPConversationThreadMessageDeliveryStates) state __attribute__((deprecated("use method stringForMessageDeliveryState instead")));
+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryStates) state;

/**
 Retrieves string representation of the contact state.
 @param state HOPConversationThreadContactStates Contact state to convert to string
 @returns String representation of contact state
 */
+ (NSString*) stateToString: (HOPConversationThreadContactStates) state __attribute__((deprecated("use method stringForContactState instead")));
+ (NSString*) stringForContactState:(HOPConversationThreadContactStates) state;


/**
 Retrieves conversation thread ID.
 @returns String representation of conversation thread ID
 */
- (NSString*) getThreadId;

/**
 Check if self is host of the conversation thread.
 @returns YES if self is host, NO if not
 */
- (BOOL) amIHost;

/**
 Retrieves the associated account object.
 @returns HOPAccount account object
 */
- (HOPAccount*) getAssociatedAccount;

/**
 Retrieves the array of contacts participating in current conversation thread.
 @returns Array of conversation thread contacts
 */
- (NSArray*) getContacts;

/**
 Retrieves profile bundle for provided contact.
 @param contact HOPContact Contact object reference
 @returns String representation of profile bundle of the provided contact object
 */
//- (NSString*) getProfileBundle: (HOPContact*) contact;
- (NSArray*) getIdentityContactListForContact:(HOPContact*) contact;

/**
 Retrieves state of the provided contact.
 @param contact HOPContact Contact object reference
 @returns Contact state enum
 */
- (HOPConversationThreadContactStates) getContactState: (HOPContact*) contact;

/**
 Adds array of contacts to the conversation thread.
 @param contacts NSArray Array of contacts to be added to conversation thread
 */
- (void) addContacts: (NSArray*) contacts;

/**
 Removes an array of contacts from conversation thread.
 @param contacts NSArray Array of contacts to be removed from conversation thread
 */
- (void) removeContacts: (NSArray*) contacts;

/**
 Send message to all contacts in conversation thread.
 @param messageID NSString Message ID
 @param messageType NSString Message type
 @param message NSString Message
 */
- (void) sendMessage: (NSString*) messageID messageType:(NSString*) messageType message:(NSString*) message DEPRECATED_ATTRIBUTE;

/**
 Send message to all contacts in conversation thread.
 @param message HOPMessage message object
 */
- (void) sendMessage: (HOPMessage*) message;

/**
 Receive message to from conversation thread.
 @param messageID NSString Received message ID
 @param outFrom HOPContact Message owner contact object 
 @param outMessageType NSString Received message type
 @param outMessage NSString Received message
 @param outTime NSDate Received message timestamp
 */
- (BOOL) getMessage: (NSString*) messageID outFrom:(HOPContact**) outFrom outMessageType:(NSString**) outMessageType outMessage:(NSString**) outMessage outTime:(NSDate**) outTime DEPRECATED_ATTRIBUTE;

/**
 Receive message to from conversation thread.
 @param messageID NSString Received message ID
 @return message object
 */
- (HOPMessage*) getMessageForID: (NSString*) messageID;

/**
 Retrieves delivery state of the message.
 @param messageID NSString Message ID
 @param outDeliveryState HOPConversationThreadMessageDeliveryStates Message delivery state
 @returns YES if delivery state is retrieved, NO if failure
 */
- (BOOL) getMessageDeliveryState: (NSString*) messageID outDeliveryState:(HOPConversationThreadMessageDeliveryStates*) outDeliveryState;

/**
 Destroy core object.
 */
- (void) destroyCoreObject;
@end
