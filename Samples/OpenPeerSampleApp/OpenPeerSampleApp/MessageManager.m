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
#import "Session.h"
#import "Utility.h"
#import "Message.h"
#import "OpenPeer.h"
#import "MainViewController.h"

#import "XMLWriter.h"
#import "RXMLElement.h"

#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPIdentityContact.h>
#import <OpenpeerSDK/HOPPublicPeerFile.h>
#import <OpenpeerSDK/HOPMessage.h>
#import <OpenpeerSDK/HOPConversationThread.h>
#import <OpenpeerSDK/HOPContact.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPMessageRecord.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPUtility.h>

#import "UIDevice+Networking.h"



@interface MessageManager ()

@property (nonatomic, strong) NSComparator comparator;

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
        _comparator = ^NSComparisonResult(Message* message1, Message* message2)
        {
            return [message1.date compare:message2.date];
        };
    }
    return self;
}

- (HOPMessage*) createSystemMessageWithType:(SystemMessageTypes) type andText:(NSString*) text andRecipient:(HOPRolodexContact*) contact
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating system message with type %d, text:%@ recipient:%@",type,text,contact.name);
    
    HOPMessage* hopMessage = nil;
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    //<Event>
    [xmlWriter writeStartElement:TagEvent];
    
    //<id>
    [xmlWriter writeStartElement:TagId];
    [xmlWriter writeCharacters:[NSString stringWithFormat:@"%d",type]];
    [xmlWriter writeEndElement];
    //</id>
    
    //<text>
    [xmlWriter writeStartElement:TagText];
    [xmlWriter writeCharacters:text];
    [xmlWriter writeEndElement];
    //</text>
    
    [xmlWriter writeEndElement];
    //</event>
    
    NSString* messageBody = [xmlWriter toString];
    
    if (messageBody)
    {
        hopMessage = [[HOPMessage alloc] initWithMessageId:[HOPUtility getGUIDstring] andMessage:messageBody andContact:[contact getCoreContact] andMessageType:messageTypeSystem andMessageDate:[NSDate date]];
        
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Created system messsage with id:%@ %@\n",hopMessage.messageID,messageBody);
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Failed creating a system messsage");
    }
    
    return hopMessage;
}

- (void) sendSystemMessageToInitSessionBetweenPeers:(NSArray*) peers forSession:(Session*) inSession
{
    NSString *messageText = @"";
    int counter = 0;
    for (HOPRolodexContact* contact in peers)
    {
        if (counter == 0 || counter == ([peers count] - 1) )
            messageText = [messageText stringByAppendingString:contact.identityContact.peerFile.peerURI];
        else
            messageText = [messageText stringByAppendingFormat:@"%@,",contact.identityContact.peerFile.peerURI];
        
    }
    
    HOPMessage* hopMessage = [self createSystemMessageWithType:SystemMessage_EstablishSessionBetweenTwoPeers andText:messageText andRecipient:[[inSession participantsArray] objectAtIndex:0]];
    [inSession.conversationThread sendMessage:hopMessage];
}

- (void) sendSystemMessageToCallAgainForSession:(Session*) inSession
{
    HOPMessage* hopMessage = [self createSystemMessageWithType:SystemMessage_CallAgain andText:systemMessageRequest andRecipient:[[inSession participantsArray] objectAtIndex:0]];
    [inSession.conversationThread sendMessage:hopMessage];
}

- (void) sendSystemMessageToCheckAvailability:(Session*) inSession
{
    HOPMessage* hopMessage = [self createSystemMessageWithType:SystemMessage_CheckAvailability andText:systemMessageRequest andRecipient:[[inSession participantsArray] objectAtIndex:0]];
    [inSession.conversationThread sendMessage:hopMessage];
}
- (void) parseSystemMessage:(HOPMessage*) inMessage forSession:(Session*) inSession
{
    if ([inMessage.type isEqualToString:messageTypeSystem])
    {
        RXMLElement *eventElement = [RXMLElement elementFromXMLString:inMessage.text encoding:NSUTF8StringEncoding];
        if ([eventElement.tag isEqualToString:TagEvent])
        {
            SystemMessageTypes type = (SystemMessageTypes) [[eventElement child:TagId].text intValue];
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Parsing system message with type %d",type);
            
            NSString* messageText =  [eventElement child:TagText].text;
            switch (type)
            {
                case SystemMessage_EstablishSessionBetweenTwoPeers:
                {
                    if ([messageText length] > 0)
                    [[SessionManager sharedSessionManager] createSessionInitiatedFromSession:inSession forContactPeerURIs:messageText];
                }
                break;
                    
                case SystemMessage_IsContactAvailable:
                {
                    
                }
                break;
                    
                case SystemMessage_IsContactAvailable_Response:
                {
                    
                }
                break;
                    
                case SystemMessage_CallAgain:
                {
                    [[SessionManager sharedSessionManager] redialCallForSession:inSession];
                }
                break;
#ifdef APNS_ENABLED
                case SystemMessage_APNS_Request:
                {
                    if ([messageText length] > 0 && [[inMessage.contact getPeerURI] length] > 0)
                        [[HOPModelManager sharedModelManager] setAPNSData:messageText PeerURI: [inMessage.contact getPeerURI]];
                    
                    HOPMessage* message = [self createSystemMessageWithType:SystemMessage_APNS_Response andText:[[OpenPeer sharedOpenPeer] deviceToken] andRecipient:[[inSession participantsArray] objectAtIndex:0]];
                    if (message)
                        [inSession.conversationThread sendMessage:message];
                }
                break;
                    
                case SystemMessage_APNS_Response:
                {
                    if ([messageText length] > 0 && [[inMessage.contact getPeerURI] length] > 0)
                        [[HOPModelManager sharedModelManager] setAPNSData:messageText PeerURI: [inMessage.contact getPeerURI]];
                }
                break;
#endif
                default:
                    break;
            }
        }
    }
}


- (void) sendMessage:(NSString*) message forSession:(Session*) inSession
{
    
    //Currently it is not available group chat, so we can have only one message recipients
    HOPRolodexContact* contact = [[inSession participantsArray] objectAtIndex:0];
    //Create a message object
    HOPMessage* hopMessage = [[HOPMessage alloc] initWithMessageId:[HOPUtility getGUIDstring] andMessage:message andContact:[contact getCoreContact] andMessageType:messageTypeText andMessageDate:[NSDate date]];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending message: %@ - message id: %@ - for session with id: %@",message,hopMessage.messageID,[inSession.conversationThread getThreadId]);
    
    [[HOPModelManager sharedModelManager] addMessage:message type:messageTypeText date:hopMessage.date session:[inSession.conversationThread getThreadId] rolodexContact:nil messageId:hopMessage.messageID];
    
    if ([UIDevice isNetworkReachable] && [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady))
    {
        //Send message
        [inSession.conversationThread sendMessage:hopMessage];
    }
    else
    {
        if (![UIDevice isNetworkReachable])
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Message %@ cannot be sent because of a network problem.",hopMessage.messageID);
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Message %@ cannot be sent because account is not in the ready state.",hopMessage.messageID);
        #ifdef APNS_ENABLED
            [[APNSManager sharedAPNSManager]sendRichPushNotificationForMessage:hopMessage missedCall:NO];
        #endif
        }
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resendMessages) name:kReachabilityChangedNotification object:nil];
        [inSession.setOfNotSentMessages addObject:hopMessage];
    }
}

/**
 Handles received message. For text message just display alert view, and for the system message perform appropriate action.
 @param message HOPMessage Message
 @param sessionId NSString Session id of session for which message is received.
 */
- (void) onMessageReceived:(HOPMessage*) message forSessionId:(NSString*) sessionId
{
    BOOL isTextMessage = [message.type isEqualToString:messageTypeText];
    NSString* messageType = isTextMessage ? @"Text" : @"System";
    
    if ([sessionId length] == 0)
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message received with invalid session id", messageType);
        return;
    }
 
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Received %@ message with id: %@ for session:%@",[messageType lowercaseString],message.messageID,sessionId);
    
    Session* session = [[SessionManager sharedSessionManager] getSessionForSessionId:sessionId];
    
    if (session == nil)
    {
        HOPRolodexContact* contact  = [[[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[message.contact getPeerURI]] objectAtIndex:0];
        session = [[SessionManager sharedSessionManager] getSessionForContact:contact];
        if (session == nil)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message received - unable to get session for provided session id %@.",messageType,sessionId);
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"%@ message received - further message handling is canceled.",messageType);
            return;
        }
        else
        {
            //[[SessionManager sharedSessionManager] setValidSession:session newSessionId:[session.conversationThread getThreadId]oldSessionId:sessionId];
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%Session for id %@ not found, but it is found other with id %@",sessionId,[session.conversationThread getThreadId]);
        }
    }
    
    if (isTextMessage)
    {
        
        HOPRolodexContact* contact  = [[[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[message.contact getPeerURI]] objectAtIndex:0];
        //Message* messageObj = [[Message alloc] initWithMessageText:message.text senderContact:contact sentTime:message.date];
        HOPMessageRecord* messageObj = [[HOPModelManager sharedModelManager] addMessage:message.text type:messageTypeText date:message.date session:[session.conversationThread getThreadId] rolodexContact:contact messageId:message.messageID];
   
        if (messageObj)
        {
            [session.unreadMessageArray addObject:messageObj];
            /*NSUInteger addedIndex = [session.messageArray indexOfObject:messageObj inSortedRange:NSMakeRange(0, session.messageArray.count) options:NSBinarySearchingInsertionIndex usingComparator:self.comparator];
                [session.messageArray insertObject:messageObj atIndex:addedIndex];

            //[session.messageArray addObject:messageObj];
            [session.unreadMessageArray addObject:messageObj];*/

            //If session view controller with message sender is not yet shown, show it
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:YES];
        }
        else
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message is not saved - message id %@ - session id %@",message.text,message.messageID,sessionId);
        }
        
        if ([[OpenPeer sharedOpenPeer] appEnteredBackground])
        {
            NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
            [dict setObject:contact.identityContact.peerFile.peerURI forKey:@"peerURI"];
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
    else
    {
        [self parseSystemMessage:message forSession:session];
    }
}

- (SystemMessageTypes) getTypeForSystemMessage:(HOPMessage*) message
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

- (HOPMessage*) createMessageFromRichPush:(NSDictionary*) richPush
{
    //HOPMessage* hopMessage = [[HOPMessage alloc] initWithMessageId:[HOPUtility getGUIDstring] andMessage:message andContact:[contact getCoreContact] andMessageType:messageTypeText andMessageDate:[NSDate date]];
    
//    NSString* senderPeerURI = [richPush objectForKey:@"peerURI"];
//    NSString* messageId = [richPush objectForKey:@"messageId"];
//    NSString* messageText = [richPush objectForKey:@"message"];
//    NSString* location = [richPush objectForKey:@"location"];
    
    return nil;
}

- (void) resendMessages
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Message resending");
    NSArray* sessions = [[[SessionManager sharedSessionManager] sessionsDictionary] allValues];
    for (Session* session in sessions)
    {
        NSArray* messages = [session.setOfNotSentMessages allObjects];
        for (HOPMessage* message in messages)
        {
            if ([UIDevice isNetworkReachable])
            {
                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Message %@ is being resent",message.messageID);
                [session.conversationThread sendMessage:message];
                [session.setOfNotSentMessages removeObject:message];
            }
        }
    }
}
@end
