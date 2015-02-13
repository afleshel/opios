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

#import "MessageManager.h"
#import "SessionManager.h"
#import "ContactsManager.h"
#ifdef APNS_ENABLED
    #import "APNSManager.h"
#endif

#import "AppConsts.h"
//#import "Session.h"
#import "Utility.h"
#import "OpenPeer.h"
#import "MainViewController.h"

#import <OpenpeerSDK/Openpeer.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import "UIDevice+Networking.h"

typedef enum
{
    ApplicationSystemMessageTypeNone,
    ApplicationSystemMessageTypeCall,
    ApplicationSystemMessageTypeConversation,
}ApplicationMessageTypes;

@interface MessageManager ()

- (id) initSingleton;

@end

@implementation MessageManager

/**
 Retrieves singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
+ (id) sharedMessageManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

- (id)initSingleton
{
    self = [super init];
    if (self)
    {

    }
    return self;
}

- (HOPMessageRecord*) createSystemMessageWithType:(HOPSystemMessageType) type messageType:(int) messageType reasonCode:(int)reasonCode andRecipient:(HOPIdentity*) contact conversation:(HOPConversation*) conversation
{
    HOPMessageRecord* ret = nil;
    
    //HOPCallSystemMessage* callSystemMessage = [[HOPCallSystemMessage alloc] initWithMessageType:(HOPCallSystemMessageType)messageType callee:contact errorCode:reasonCode];
    
    NSString* mediaType = [conversation.currentCall hasVideo] ? @"video" : @"audio";
    NSString* callID = [conversation.currentCall getCallID];
    if (!callID)
        callID = @"";
    
    HOPCallSystemMessage* callSystemMessage = [[HOPCallSystemMessage alloc] initWithMessageType:(HOPCallSystemMessageType)messageType mediaType:mediaType callID:callID callee:contact errorCode:reasonCode];
    
    NSString* messageBody = callSystemMessage.jsonMessage;
    if ([messageBody length] > 0)
    {
        ret = [HOPMessageRecord createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:conversation sender:contact messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:@""];
        
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Created system messsage with id:%@ %@\n",ret.messageID,messageBody);
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Failed creating a system messsage");
    }
    
    return ret;
}

- (void) sendCallSystemMessage:(HOPCallSystemMessageType) callSystemMessage reasonCode:(int) reasonCode forConversation:(HOPConversation*) conversation
{
    for (HOPIdentity* contact in conversation.participants)
    {
        HOPMessageRecord* messageRecord = [self createSystemMessageWithType:HOPSystemMessageTypeCall messageType:callSystemMessage reasonCode:reasonCode andRecipient:contact conversation:conversation];
        if (messageRecord)
        {
            BOOL visible = callSystemMessage != HOPCallSystemMessageTypeCallAnswered;
            messageRecord.visible = [NSNumber numberWithBool:visible];
            
            [conversation sendMessage:messageRecord];
        }
    }
}


- (void) sendSystemMessageToCheckAvailability:(HOPConversation*) conversation
{
    for (HOPIdentity* contact in conversation.participants)
    {
        HOPMessageRecord* messageRecord = [self createSystemMessageWithType:HOPSystemMessageTypeCall messageType:HOPCallSystemMessageTypeCallPlaced reasonCode:0 andRecipient:contact conversation:conversation];
        if (messageRecord)
            [conversation sendMessage:messageRecord];
    }
}

//{"system":{"conversationSwitch":{"from":"conversationId1","to":"conversationId2"}}
- (void) sendSystemForSwitchFromConversation:(HOPConversation*) conversation toConversation:(HOPConversation*) toConversation
{
    NSDictionary* conversationSwitchDict = [NSDictionary dictionaryWithObjectsAndKeys:conversation.conversationID, @"from", toConversation.conversationID, @"to", nil];
    if (conversationSwitchDict)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:conversationSwitchDict,@"conversationSwitch", nil],@"system", nil];
        
        if (dict)
        {
            NSString* messageBody = [Utility jsonFromDictionary:dict];
            if (messageBody.length > 0)
            {
                HOPMessageRecord* messageRecord = [HOPMessageRecord createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:conversation sender:[HOPIdentity getSelf] messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:@""];
                if (messageRecord)
                {
                    [toConversation sendMessage:messageRecord];
                }
            }
        }
    }
}

//{"system":{"conversationSwitch":{"from":"conversationId1","to":"conversationId2"}}

- (ApplicationMessageTypes) getSystemMessageType:(HOPMessageRecord*) inMessage
{
    ApplicationMessageTypes ret = ApplicationSystemMessageTypeNone;
    
    NSDictionary* systemDict = [Utility dictionaryFromJSON:inMessage.text];
    if (systemDict)
    {
        if ([systemDict valueForKeyPath:@"system.callStatus"])
            ret = ApplicationSystemMessageTypeCall;
        else if ([systemDict valueForKeyPath:@"system.conversationSwitch"])
            ret = ApplicationSystemMessageTypeConversation;
    }
    return ret;
}

- (void) parseSystemMessage:(HOPMessageRecord*) inMessage forConversation:(HOPConversation*) conversation
{
    if ([inMessage.type isEqualToString:[HOPSystemMessage getMessageType]])
    {
        NSDictionary* systemDict = [Utility dictionaryFromJSON:inMessage.text];
        if (systemDict)
        {
            if ([systemDict valueForKeyPath:@"system.callStatus"])
            {
                HOPCallSystemMessage* callSystemMessage = [HOPCallSystemMessage callSystemMessageFromJSON:inMessage.text];
                
                if (callSystemMessage)
                {
                    if (callSystemMessage.messageType == HOPCallSystemMessageTypeCallAnswered)
                    {
                        inMessage.visible = [NSNumber numberWithBool:NO];
                        [[HOPModelManager sharedModelManager]saveContext];
                    }
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Call system messsage:%@\n",callSystemMessage.jsonMessage);
                }
            }
            else if ([systemDict valueForKeyPath:@"system.conversationSwitch"])
            {
                NSDictionary* dictConversationSystem = [systemDict valueForKeyPath:@"system.conversationSwitch"];
                if (dictConversationSystem.count > 0)
                {
                    NSString* replaceConversationID = [dictConversationSystem objectForKey:@"from"];
                    NSString* conversationID = [dictConversationSystem objectForKey:@"to"];
                    
                    HOPConversation* replaceConversation = replaceConversationID.length > 0 ? [HOPConversation getConversationForID:replaceConversationID] : nil;
                    HOPConversation* conversation = conversationID.length > 0 ? [HOPConversation getConversationForID:conversationID] : nil;
                    
                    if (conversation)
                    {
                        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:replaceConversation incomingCall:NO incomingMessage:NO];
                        
                        inMessage.visible = [NSNumber numberWithBool:NO];
                        [[HOPModelManager sharedModelManager] saveContext];
                    }
                }
            }
        }
    }
}


- (void) replaceConversationWithID:(NSString*) conversationID toConversationWithID:(NSString*) toConversationID
{
    
}

- (void) sendMessage:(NSString*) message replacesMessageID:(NSString*) replacesMessageID forConversation:(HOPConversation*) conversation
{
    //HOPIdentity* contact = [conversation.participants objectAtIndex:0];
    BOOL edited = NO;
    BOOL deleted = NO;
    HOPMessageRecord* messageRecord = nil;
    
    if ([replacesMessageID length] > 0)
    {
        HOPMessageRecord* messageRecordOld = [[HOPModelManager sharedModelManager] getMessageRecordByID:replacesMessageID];
        messageRecordOld.visible = [NSNumber numberWithBool:NO];
        if ([message length] == 0)
        {
            messageRecordOld.removed = [NSNumber numberWithBool:([message length] == 0)];
            messageRecordOld.replacedMessageID = replacesMessageID;
            //messageRecord = messageRecordOld;
            message = @" ";
            deleted = YES;
        }
        edited = YES;
        [[HOPModelManager sharedModelManager] saveContext];
    }

    if (!messageRecord)
        messageRecord = [HOPMessageRecord createMessage:message type:messageTypeText date:[NSDate date] visible:YES conversation:conversation sender:[[HOPModelManager sharedModelManager] getIdentityForAccount] messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:replacesMessageID];

    messageRecord.edited = [NSNumber numberWithBool:edited];
    messageRecord.removed = [NSNumber numberWithBool:deleted];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending message: %@ - message id: %@ - for session with id: %@",message,messageRecord.messageID,[conversation getConversationID]);
    
    
    if ([UIDevice isNetworkReachable] && [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady))
    {
        //Send message
        [conversation sendMessage:messageRecord];
    }
    else
    {
        if (![UIDevice isNetworkReachable])
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Message %@ cannot be sent because of a network problem.",messageRecord.messageID);
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Message %@ cannot be sent because account is not in the ready state.",messageRecord.messageID);
        #ifdef APNS_ENABLED
            [[APNSManager sharedAPNSManager]sendRichPushNotificationForMessage:messageRecord conversation:conversation  participants:[conversation getParticipants]];
            //[[APNSManager sharedAPNSManager]sendRichPushNotificationForMessage:messageRecord missedCall:NO participantsPeerURIs:@[]];
        #endif
        }
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resendMessages) name:kReachabilityChangedNotification object:nil];
        [conversation.setOfNotSentMessages addObject:messageRecord];
    }
}

/**
 Handles received message. For text message just display alert view, and for the system message perform appropriate action.
 @param message HOPMessageRecord Message
 @param sessionId NSString Session id of session for which message is received.
 */
- (void) onMessageReceived:(HOPMessageRecord*) message forConversation:(HOPConversation*) conversation
{
    //BOOL isTextMessage = [message.type isEqualToString:messageTypeText];
    BOOL isSystemMessage = [message.type isEqualToString:[HOPSystemMessage getMessageType]];
    //NSString* messageType = isTextMessage ? @"Text" : @"System";
    
    if (!conversation)
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message received with invalid conversation object", message.type);
        return;
    }
 
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Received %@ message with id: %@ for session:%@",[message.type lowercaseString],message.messageID,[conversation getConversationID]);
    

    if (!isSystemMessage)
    {

        if ([message.replacedMessageID length] > 0)
        {
            [[HOPModelManager sharedModelManager] replaceMessageWithID:message.replacedMessageID newMessageID:message.messageID messageText:message.text];
        }
        else
        {
            conversation.numberOfUnreadMessages++;

            //If session view controller with message sender is not yet shown, show it
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:nil incomingCall:NO incomingMessage:YES];

            if ([[OpenPeer sharedOpenPeer] appEnteredBackground])
            {
                NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
                [dict setObject:[message.sender getPeerURI] forKey:@"peerURI"];
                [dict setObject:message.messageID forKey:@"messageId"];
                [dict setObject:message.text forKey:@"message"];
                [dict setObject:message.date forKey:@"date"];
                if ([dict count] > 0)
                {
                    NSDictionary* packedDict = @{localNotificationKey: dict};
                    [Utility showLocalNotification:message.text additionalData:packedDict];
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Local notification for message: \" %@ \" with id %@ is shown.",message.text,message.messageID);
                }
                else
                {
                    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Local notification for message: \" %@ \" with id %@ is NOT shown.",message.text,message.messageID);
                }
            }
        }
    }
    else
    {
        [self parseSystemMessage:message forConversation:conversation];
    }
}


- (void) resendMessages
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Message resending");
    NSArray* conversations = [HOPConversation getConversations];
    for (HOPConversation* conversation in conversations)
    {
        NSArray* messages = [conversation.setOfNotSentMessages allObjects];
        for (HOPMessageRecord* message in messages)
        {
            if ([UIDevice isNetworkReachable])
            {
                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Message %@ is being resent",message.messageID);
                [conversation sendMessage:message];
                [conversation.setOfNotSentMessages removeObject:message];
            }
        }
    }
}

- (void) resendMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation
{
    message.messageID = [HOPUtility getGUIDstring];
    message.showStatus = [NSNumber numberWithBool:NO];
    [[HOPModelManager sharedModelManager] saveContext];
    if ([UIDevice isNetworkReachable] && [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady))
    {
        //Send message
        [conversation sendMessage:message];
    }
}

- (void)updateMessageStatus:(HOPMessageRecord *)messageRecord
{
    messageRecord.outgoingMessageStatus = HOPConversationThreadMessageDeliveryStateSent;
    
    HOPConversation* conversation = [messageRecord.session getConversation];
    if (conversation)
    {
        [[HOPModelManager sharedModelManager] updateMessageStateForConversation:conversation lastDeliveryState:HOPConversationThreadMessageDeliveryStateSent];
        
        [[HOPModelManager sharedModelManager] saveContext];
    }
}


@end
