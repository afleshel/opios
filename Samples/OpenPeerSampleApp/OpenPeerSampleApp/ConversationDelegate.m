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

#import "ConversationDelegate.h"
#import "SessionManager.h"
#import "ContactsManager.h"
#import "MessageManager.h"
#import "AppConsts.h"
#import "Utility.h"
#import "OpenPeer.h"
#import "SessionViewController_iPhone.h"
#import "MainViewController.h"

#import <OpenpeerSDK/HOPConversation.h>
//#import <OpenpeerSDK/HOPConversationThread.h>
#import <OpenpeerSDK/HOPIdentity+External.h>
#import <OpenpeerSDK/HOPMessageRecord+External.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPSystemMessage.h>
#import <OpenpeerSDK/HOPCallSystemMessage.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPContact+External.h>

#ifdef APNS_ENABLED
#import "APNSManager.h"
#import <OpenpeerSDK/HOPModelManager.h>
#endif

@implementation ConversationDelegate

- (void) onConversationNew:(HOPConversation*) conversation
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Handling a new conversation thread creation.");
    [[ContactsManager sharedContactsManager] identityLookupForContacts:conversation.updatedContacts];
}

- (void) onConversationContactsChanged:(HOPConversation*) conversation
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Conversation thread id %@  - number of contacts: %d.",[conversation getConversationID], conversation.participants.count);
    [[ContactsManager sharedContactsManager] identityLookupForContacts:conversation.updatedContacts];
    dispatch_async(dispatch_get_main_queue(), ^
   {
       [[SessionManager sharedSessionManager] onParticipantsInConversationUpdate:conversation];
   });
}

- (void) onConversationContactConnectionStateChanged:(HOPConversation*) conversation contact:(HOPContact*) contact contactConnectionState:(HOPConversationThreadContactConnectionState) contactConnectionState
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Conversation thread id: <%@> contact peer URI:<%@> state: %@",[conversation getConversationID], [contact getPeerURI],[HOPConversation stringForContactConnectionState:contactConnectionState]);
}

- (void) onConversationContactStatusChanged:(HOPConversation*) conversation contact:(HOPContact*) contact
{
    HOPComposingState contactState = [conversation getComposingStateForContact:contact];
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Conversation thread id: <%@> - contact peer URI: <%@> state: %d",[conversation getConversationID], [contact getPeerURI],contactState);
    dispatch_async(dispatch_get_main_queue(), ^
    {
       NSDictionary* dict = @{@"thread":conversation, @"contact":contact, @"status":@(contactState)};
       [[NSNotificationCenter defaultCenter] postNotificationName:notificationComposingStatusChanged object:dict];
    });
}

- (void) onConversationContactComposingStateChanged:(HOPConversation*) conversation state:(HOPComposingState)state contact:(HOPContact*) contact
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Conversation thread id: <%@> - contact peer URI: <%@> state: %d",[conversation getConversationID], [contact getPeerURI],state);
    dispatch_async(dispatch_get_main_queue(), ^
   {
       NSDictionary* dict = @{@"thread":conversation, @"contact":contact, @"status":@(state)};
       [[NSNotificationCenter defaultCenter] postNotificationName:notificationComposingStatusChanged object:dict];
   });
}

- (void) onConversationMessage:(HOPConversation*) conversation messageID:(NSString*) messageID
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Handling a new message with id %@ for conversation thread.",messageID);
    dispatch_async(dispatch_get_main_queue(), ^
    {
        HOPMessageRecord* message = [conversation getMessageForID:messageID];
        if (message)
        {
            [[MessageManager sharedMessageManager] onMessageReceived:message forConversation:conversation];
        }
    });
}

- (void) onConversationMessageDeliveryStateChanged:(HOPConversation*) conversation messageID:(NSString*) messageID messageDeliveryStates:(HOPConversationThreadMessageDeliveryState) messageDeliveryStates
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Conversation thread %@ message with id %@ delivery state has changed to: %@",[conversation getConversationID],messageID, [HOPConversation stringForMessageDeliveryState:messageDeliveryStates]);
    
    [[HOPModelManager sharedModelManager] updateMessageStateForConversation:conversation lastDeliveryState:messageDeliveryStates];
}

- (void) onConversationPushMessage:(HOPConversation*) conversationThread messageID:(NSString*) messageID contact:(HOPContact*) contact
{
#ifdef APNS_ENABLED
    if (contact)
    {
        HOPMessageRecord* message = [conversationThread getMessageForID:messageID];
        
        if (message)
        {
            [[APNSManager sharedAPNSManager] sendRichPushNotificationForMessage:message conversation:conversationThread participants:@[contact]];
        }
    }
#endif
}

- (void) onConversationPushMessageRequired:(HOPConversation*) conversation message:(HOPMessageRecord*) message recipient:(HOPContact*) recipient
{
#ifdef APNS_ENABLED
    if (recipient && message)
    {
        [[APNSManager sharedAPNSManager] sendRichPushNotificationForMessage:message conversation:conversation participants:@[recipient]];
    }
#endif
}

@end

