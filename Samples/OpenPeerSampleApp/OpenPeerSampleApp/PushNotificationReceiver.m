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

#import "PushNotificationReceiver.h"
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPIdentity+External.h>
#import <OpenPeerSDK/HOPUtility.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPSystemMessage.h>
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import "OpenPeer.h"
#import "MainViewController.h"
#import "Utility.h"
#import "SessionManager.h"

@interface PushNotificationReceiver()

@property (nonatomic, weak) HOPConversation* lastUpdatedConversation;

@end

@implementation PushNotificationReceiver

- (void) prepare
{
    
}

- (void) handleAPNS:(NSDictionary *)apnsInfo
{
    NSDictionary *apsInfo = [apnsInfo objectForKey:@"aps"];
    NSString *alert = [apsInfo objectForKey:@"alert"];
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Received Push Alert: %@", alert);
    NSString *peerURI = [apnsInfo objectForKey:@"peerURI"];
    NSString *locationID = [apnsInfo objectForKey:@"location"];
    
    [HOPIdentity hintAboutLocation:locationID peerURI:peerURI];
}

- (void)createMessageFromRichPushDict:(NSDictionary *)richPushDictionary
{
    if ([richPushDictionary count] > 0)
    {
        NSString* senderPeerURI = [richPushDictionary objectForKey:@"peerURI"];
        NSString *peerURIs = [richPushDictionary objectForKey:@"peerURIs"];
        NSString *conversationID = [richPushDictionary objectForKey:@"conversationId"];
        NSString *threadType = [richPushDictionary objectForKey:@"conversationType"];
        NSString *messageType = [richPushDictionary objectForKey:@"messageType"];
        
        
        NSArray *items = [peerURIs componentsSeparatedByString:@","];
        HOPContact* sender = nil;
        if ([senderPeerURI length] > 0)
            sender = [[HOPModelManager sharedModelManager] getContactByPeerURI:senderPeerURI];
        
        
        if (sender)
        {
            NSMutableArray* participants = [NSMutableArray arrayWithObject:sender];
            
            for (NSString* peerURI in items)
            {
                HOPContact* contact = [[HOPModelManager sharedModelManager] getContactByPeerURI:peerURI];
                if (contact)
                    [participants addObject:contact];
            }
            HOPConversation *conversation = [HOPConversation conversationForID:conversationID threadType:threadType participants:participants];
            
            if (conversation)
            {
                NSString* messageID = [richPushDictionary objectForKey:@"messageId"];
                NSString* messageText = [richPushDictionary objectForKey:@"message"];
                NSString* location = [richPushDictionary objectForKey:@"location"];
                NSNumber* timeInterval = [richPushDictionary objectForKey:@"date"];
                NSString* replacesMessageID = [richPushDictionary objectForKey:@"replacesMessageId"];
                
                if ([messageType isEqualToString:[HOPSystemMessage getMessageType]])
                {
                    NSDictionary* systemDict = [richPushDictionary objectForKey:@"system"];
                    if (systemDict)
                    {
                        NSDictionary* callDict = [systemDict objectForKey:@"callStatus"];
                        
                        if (callDict)
                        {
                            NSString* callID = [callDict objectForKey:@"id"];
                            NSMutableDictionary* mutD = [NSMutableDictionary dictionaryWithDictionary:callDict];
                            [mutD removeObjectForKey:@"id"];
                            [mutD setObject:callID forKey:@"$id"];
                            NSDictionary* callStatusDict = [NSDictionary dictionaryWithObject:mutD forKey:@"callStatus"];
                            NSDictionary* sysStatusDict = [NSDictionary dictionaryWithObject:callStatusDict forKey:@"system"];
                            messageText = [Utility jsonFromDictionary:sysStatusDict];
                        }
                    }
                }

                NSDate* date = [NSDate dateWithTimeIntervalSince1970:timeInterval.doubleValue];
                
                if ([messageID length] > 0 && ([messageText length] > 0 || [replacesMessageID length] > 0)  && date)
                {
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content \"%@\" for message %@ is ready.",messageText,messageID);
                    
                    [HOPIdentity hintAboutLocation:location peerURI:senderPeerURI];
                    
                    if ([replacesMessageID length] > 0)
                    {
                        [[HOPModelManager sharedModelManager] replaceMessageWithID:replacesMessageID newMessageID:messageID messageText:messageText];
                    }
                    else
                    {
                        HOPMessageRecord* messageObj = [HOPMessageRecord createMessage:messageText type:messageType date:date visible:YES conversation:conversation sender:sender messageId:messageID validated:NO messageIDToReplace:nil];
                        
                        if (messageObj)
                        {
                            conversation.numberOfUnreadMessages++;
                            self.lastUpdatedConversation = conversation;
                        }
                        else
                        {
                            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message is not saved - message id %@ - session id %@ - date %@",messageText,messageID,[conversation getConversationID],date);
                        }
                    }
                }
                else
                {
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content is corrupted");
                }
            }
        }
    }
}

- (void)downloadAllMessages
{
    self.lastUpdatedConversation = nil;
}
- (void) handleExistingMessages
{
    
}

- (void) setBadgeNumber:(NSInteger) numberOfUnreadMessages
{
    
}

- (void) onPushNotificationsDownloaded
{
    if (self.lastUpdatedConversation)
        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:self.lastUpdatedConversation replaceConversation:nil incomingCall:NO incomingMessage:YES];
}

- (void)downloadMessageWithID:(NSString *)messageID
{
    
}
@end
