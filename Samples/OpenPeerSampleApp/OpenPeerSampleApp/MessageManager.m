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

#import "XMLWriter.h"
#import "RXMLElement.h"

#import <OpenpeerSDK/Openpeer.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import "UIDevice+Networking.h"



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

- (HOPMessageRecord*) createSystemMessageWithType:(HOPSystemMessageType) type messageType:(int) messageType reasonCode:(int)reasonCode andRecipient:(HOPRolodexContact*) contact conversation:(HOPConversation*) conversation
{
    HOPMessageRecord* ret = nil;
    
    HOPCallSystemMessage* callSystemMessage = [[HOPCallSystemMessage alloc] initWithMessageType:(HOPCallSystemMessageType)messageType callee:contact errorCode:reasonCode];
    NSString* messageBody = callSystemMessage.jsonMessage;
    if ([messageBody length] > 0)
    {
        ret = [HOPMessageRecord createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:conversation contact:contact messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:@""];
        
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
    for (HOPRolodexContact* contact in conversation.participants)
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
    for (HOPRolodexContact* contact in conversation.participants)
    {
        HOPMessageRecord* messageRecord = [self createSystemMessageWithType:HOPSystemMessageTypeCall messageType:HOPCallSystemMessageTypeCallPlaced reasonCode:0 andRecipient:contact conversation:conversation];
        if (messageRecord)
            [conversation sendMessage:messageRecord];
    }
}


- (void) parseSystemMessage:(HOPMessageRecord*) inMessage forConversation:(HOPConversation*) conversation
{
    if ([inMessage.type isEqualToString:[HOPConversationThread getSystemMessageType]])
    {
        HOPCallSystemMessage* callSystemMessage = [HOPCallSystemMessage callSystemMessageFromJSON:inMessage.text];
        
        if (callSystemMessage)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Call system messsage:%@\n",callSystemMessage.jsonMessage);
        }
    }
}


- (void) sendMessage:(NSString*) message replacesMessageID:(NSString*) replacesMessageID forConversation:(HOPConversation*) conversation
{
    //HOPRolodexContact* contact = [conversation.participants objectAtIndex:0];
    
    HOPMessageRecord* messageRecord = nil;
    
    if ([replacesMessageID length] > 0)
    {
        HOPMessageRecord* messageRecordOld = [[HOPModelManager sharedModelManager] getMessageRecordByID:replacesMessageID];
        messageRecordOld.visible = [NSNumber numberWithBool:NO];
        messageRecord.deleted = [NSNumber numberWithBool:([message length] > 0)];
        [[HOPModelManager sharedModelManager] saveContext];
    }

    messageRecord = [HOPMessageRecord createMessage:message type:messageTypeText date:[NSDate date] visible:YES conversation:conversation contact:[[HOPModelManager sharedModelManager] getRolodexContactContactForAccount] messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:replacesMessageID];

    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending message: %@ - message id: %@ - for session with id: %@",message,messageRecord.messageID,[conversation getID]);
    
    
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
            [[APNSManager sharedAPNSManager]sendRichPushNotificationForMessage:message missedCall:NO  participants:[conversation getParticipants]];
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
    BOOL isTextMessage = [message.type isEqualToString:messageTypeText];
    NSString* messageType = isTextMessage ? @"Text" : @"System";
    
    if (!conversation)
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message received with invalid conversation object", messageType);
        return;
    }
 
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Received %@ message with id: %@ for session:%@",[messageType lowercaseString],message.messageID,[conversation getID]);
    

    if (isTextMessage)
    {
        HOPMessageRecord* messageObj = nil;
        if ([message.replacedMessageID length] > 0)
        {
            [[HOPModelManager sharedModelManager] replaceMessageWithID:message.replacedMessageID newMessageID:message.messageID messageText:message.text];
        }
        else
        {
            //Message* messageObj = [[Message alloc] initWithMessageText:message.text senderContact:contact sentTime:message.date];
//            messageObj = [[HOPModelManager sharedModelManager] addMessage:message.text type:messageTypeText date:message.date conversation:conversation contact:message.contact messageId:message.messageID];
//       
//            if (messageObj)
            {
                conversation.numberOfUnreadMessages++;

                //If session view controller with message sender is not yet shown, show it
                [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation forIncomingCall:NO forIncomingMessage:YES];
            }
//            else
//            {
//                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message is not saved - message id %@ - session id %@",message.text,message.messageID,[conversation getID]);
//            }
            
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
        BOOL visible = [message.text rangeOfString:@"\"status\":\"answered\""].location == NSNotFound;
        message.visible = [NSNumber numberWithBool:visible];
        [[HOPModelManager sharedModelManager] saveContext];
        //Save System message
        //[[HOPModelManager sharedModelManager] addMessage:message.text type:[HOPSystemMessage getMessageType] date:message.date visible:visible conversation:conversation contact:message.contact messageId:message.messageID];
        [self parseSystemMessage:message forConversation:conversation];
    }
}

- (SystemMessageTypes) getTypeForSystemMessage:(HOPMessageRecord*) message
{
    SystemMessageTypes ret = SystemMessage_None;
    if ([message.type isEqualToString:messageTypeSystem])
    {
        RXMLElement *eventElement = [RXMLElement elementFromXMLString:message.text encoding:NSUTF8StringEncoding];
        if ([eventElement.tag isEqualToString:TagEvent])
        {
            ret = (SystemMessageTypes) [[eventElement child:TagId].text intValue];
        }
    }
    return ret;
}


- (void) resendMessages
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Message resending");
    NSArray* conversations = [[[SessionManager sharedSessionManager] sessionsDictionary] allValues];
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

@end
