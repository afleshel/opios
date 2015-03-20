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

#import "MessageManager.h"
#import "SessionManager.h"
#import "ContactsManager.h"
#import "ImageManager.h"
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
#import <OpenPeerSDK/HOPMessage+External.h>
#import "UIDevice+Networking.h"
#import <OpenPeerSDK/HOPContact+External.h>
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

- (HOPMessage*) createSystemMessageWithType:(HOPSystemMessageType) type messageType:(int) messageType reasonCode:(int)reasonCode andRecipient:(HOPContact*) contact conversation:(HOPConversation*) conversation
{
    HOPMessage* ret = nil;

    NSString* mediaType = [conversation.currentCall hasVideo] ? @"video" : @"audio";
    NSString* callID = [conversation.currentCall getCallID];
    if (!callID)
        callID = @"";
    
    HOPCallSystemMessage* callSystemMessage = [[HOPCallSystemMessage alloc] initWithMessageType:(HOPCallSystemMessageType)messageType mediaType:mediaType callID:callID callee:contact errorCode:reasonCode];
    
    NSString* messageBody = callSystemMessage.jsonMessage;
    if ([messageBody length] > 0)
    {
        ret = [HOPMessage createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:conversation sender:contact messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:@""];
        
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
    for (HOPContact* contact in conversation.participants)
    {
        HOPMessage* messageRecord = [self createSystemMessageWithType:HOPSystemMessageTypeCall messageType:callSystemMessage reasonCode:reasonCode andRecipient:contact conversation:conversation];
        if (messageRecord)
        {
            BOOL visible = callSystemMessage != HOPCallSystemMessageTypeCallAnswered;
            messageRecord.visible = [NSNumber numberWithBool:visible];
            
            [conversation sendMessage:messageRecord];
        }
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
                HOPMessage* messageRecord = [HOPMessage createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:toConversation sender:[HOPContact getSelf] messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:@""];
                if (messageRecord)
                {
                    [toConversation sendMessage:messageRecord];
                }
            }
        }
    }
}

//{"system":{"fileShare":{"objectId":""," ""fileType":"image","size":%d,"imageInfo":{"width":%d,"height":%d}}}"
- (HOPMessage*) createSystemMessageForFileShareWithID:(NSString*) fileShareID size:(NSUInteger) size resolution:(CGSize) resolution conversation:(HOPConversation*) conversation
{
    HOPMessage* ret = nil;
    NSDictionary* fileShareDict = [NSDictionary dictionaryWithObjectsAndKeys:fileShareID, @"objectId", @"image", @"fileType", [NSNumber numberWithInteger:size], @"size", [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat: resolution.width], @"width", [NSNumber numberWithFloat: resolution.height], @"height", nil],@"imageInfo",nil];
    
    if (fileShareDict)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:fileShareDict,@"fileShare", nil],@"system", nil];
        
        if (dict)
        {
            NSString* messageBody = [Utility jsonFromDictionary:dict];
            if (messageBody.length > 0)
            {
                ret = [HOPMessage createMessage:messageBody type:[HOPSystemMessage getMessageType] date:[NSDate date] visible:NO conversation:conversation sender:[HOPContact getSelf] messageId:fileShareID validated:NO messageIDToReplace:@""];
//                if (messageRecord)
//                {
//                    [toConversation sendMessage:messageRecord];
//                }
            }
        }
    }
    
    return ret;
}
//{"system":{"conversationSwitch":{"from":"conversationId1","to":"conversationId2"}}

- (ApplicationMessageTypes) getSystemMessageType:(HOPMessage*) inMessage
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

- (void) parseSystemMessage:(HOPMessage*) inMessage forConversation:(HOPConversation*) conversation
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
                    
                    inMessage.visible = [NSNumber numberWithBool:NO];
                    
                    if (conversation && replaceConversation)
                    {
                        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:replaceConversation incomingCall:NO incomingMessage:NO];
                        
                        [[HOPModelManager sharedModelManager] saveContext];
                    }
                }
            } //{"system":{"fileShare":{"objectId":""," ""fileType":"image","size":%d,"imageInfo":{"width":%d,"height":%d}}}"
            else if ([systemDict valueForKeyPath:@"system.fileShare"])
            {
                NSDictionary* dictFileShareSystem = [systemDict valueForKeyPath:@"system.fileShare"];
                if (dictFileShareSystem.count > 0)
                {
                    NSString* fileShareID = [dictFileShareSystem objectForKey:@"objectId"];
                    NSString* type = [dictFileShareSystem objectForKey:@"fileType"];
                    NSNumber* fileSize = [dictFileShareSystem objectForKey:@"size"];
                    NSDictionary* imageInfo = [dictFileShareSystem objectForKey:@"imageInfo"];
                    
                    [[ImageManager sharedImageManager] downloadSharedImageForMessage:inMessage];
                    
                    [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:nil incomingCall:NO incomingMessage:YES];
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
    HOPMessage* messageRecord = nil;
    NSDate* date = [NSDate date];
    
    if ([replacesMessageID length] > 0)
    {
        HOPMessage* messageRecordOld = [[HOPModelManager sharedModelManager] getMessageRecordByID:replacesMessageID];
        messageRecordOld.visible = [NSNumber numberWithBool:NO];
        if ([message length] == 0)
        {
            messageRecordOld.removed = [NSNumber numberWithBool:([message length] == 0)];
            messageRecordOld.replacedMessageID = replacesMessageID;
            //messageRecord = messageRecordOld;
            date = messageRecordOld.date;
            message = @" ";
            deleted = YES;
        }
        edited = YES;
        [[HOPModelManager sharedModelManager] saveContext];
    }

    if (!messageRecord)
        messageRecord = [HOPMessage createMessage:message type:messageTypeText date:date visible:YES conversation:conversation sender:[HOPContact getSelf] messageId:[HOPUtility getGUIDstring] validated:NO messageIDToReplace:replacesMessageID];

    messageRecord.edited = [NSNumber numberWithBool:edited];
    messageRecord.removed = [NSNumber numberWithBool:deleted];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending message: %@ - message id: %@ - for session with id: %@",message,messageRecord.messageID,[conversation getConversationID]);
    
    
    if ([UIDevice isNetworkReachable] && [[HOPAccount sharedAccount] isAccountReady] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady))
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
 @param message HOPMessage Message
 @param sessionId NSString Session id of session for which message is received.
 */
- (void) onMessageReceived:(HOPMessage*) message forConversation:(HOPConversation*) conversation
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
            //If session view controller with message sender is not yet shown, show it
            BOOL isShown = [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:nil incomingCall:NO incomingMessage:YES];
            
            if (!isShown)
                conversation.numberOfUnreadMessages++;
            
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
        for (HOPMessage* message in messages)
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

- (void) resendMessage:(HOPMessage*) message conversation:(HOPConversation*) conversation
{
    message.messageID = [HOPUtility getGUIDstring];
    message.showStatus = [NSNumber numberWithBool:NO];
    [[HOPModelManager sharedModelManager] saveContext];
    if ([UIDevice isNetworkReachable] && [[HOPAccount sharedAccount] isAccountReady] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady))
    {
        //Send message
        [conversation sendMessage:message];
    }
}

- (void)updateMessageStatus:(HOPMessage *)messageRecord
{
    messageRecord.outgoingMessageStatus = HOPConversationThreadMessageDeliveryStateSent;
    
    HOPConversation* conversation = [messageRecord.session getConversation];
    if (conversation)
    {
        [[HOPModelManager sharedModelManager] updateMessageStateForConversation:conversation lastDeliveryState:HOPConversationThreadMessageDeliveryStateSent];
        
        [[HOPModelManager sharedModelManager] saveContext];
    }
}

- (SystemMessageType) systemMessageTypeForMessage:(HOPMessage*) message
{
    SystemMessageType ret = SystemMessage_None;
    
    if (message)
    {
        BOOL isSystemMessage = [message.type isEqualToString:[HOPSystemMessage getMessageType]];
        
        if (isSystemMessage)
        {
            NSDictionary* systemDict = [Utility dictionaryFromJSON:message.text];
            if (systemDict)
            {
                if ([systemDict valueForKeyPath:@"system.callStatus"])
                {
                    ret = SystemMessage_CallStatus;
                }
                else if ([systemDict valueForKeyPath:@"system.conversationSwitch"])
                {
                    ret = SystemMessage_ConversationReplacement;
                }
                else if ([systemDict valueForKeyPath:@"system.fileShare"])
                {
                    ret = SystemMessage_FileSharing;
                }
            }
        }
    }
    
    return ret;
}

@end
