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

#import "ParsePushNotificationSender.h"
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import <OpenPeerSDK/HOPConversationRecord+External.h>
#import <OpenPeerSDK/HOPRolodexContact+External.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPSystemMessage.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPCall.h>
#import <Parse/Parse.h>
#import "MessageManager.h"
#import "Utility.h"

@implementation ParsePushNotificationSender

- (void) prepare
{
    [super prepare];
    
#ifdef DEBUG
    self.applicationID = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyParseDevelopmentAppID];
    self.clientKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyParseDevelopmentClientKey];
#else
    self.applicationID = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyParseProductionAppID];
    self.clientKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyParseProductionClientKey];
#endif
}


- (void) registerDeviceToken:(NSData*) inDeviceToken peerURI:(NSString*) inPeerURI
{
    [super registerDeviceToken:inDeviceToken peerURI:inPeerURI];
    
    if (self.applicationID.length > 0 && self.clientKey.length > 0)
        [Parse setApplicationId:self.applicationID clientKey:self.clientKey];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:inDeviceToken];
    currentInstallation[@"peerUri"] = inPeerURI;
    [currentInstallation saveInBackground];
}

- (void) sendPushNotificationMessage:(NSString*) message outgoingCall:(BOOL) outgoingCall recipients:(NSArray*) recipients
{
    [super sendPushNotificationMessage:message outgoingCall:outgoingCall recipients:recipients];
    
    NSDictionary *data = [self createPushMessage:message missedCall:outgoingCall recipients:recipients];
    
    for (HOPRolodexContact* recipient in recipients)
    {
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"peerUri" equalTo:[recipient getPeerURI]];
        
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:pushQuery]; // Set our Installation query
        [push setData:data];
        [push sendPushInBackground];
    }
}

- (void) sendRichPushNotificationMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipients:(NSArray*) recipients
{
    [super sendRichPushNotificationMessage:message conversation:conversation recipients:recipients];
    
    for (HOPRolodexContact* recipient in recipients)
    {
        NSDictionary* parameters = [self createRichPushMessage:message conversation:conversation recipient:recipient recipients:recipients];
        
        if (parameters.count > 0)
        {
            [PFCloud callFunctionInBackground:@"sendPushToUser" withParameters:parameters block:^(NSString *result, NSError *error)
             {
                 if (error)
                 {
                     OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, [error description]);
                 }
                 else
                 {
                     [self onMessageSent:message.messageID];
                     [[MessageManager sharedMessageManager] updateMessageStatus:message];
                     OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Parse push sent");
                 }
             }];
        }
    }
}


- (NSDictionary*) createRichPushMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipient:(HOPRolodexContact*) recipient recipients:(NSArray*) recipients
{
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    NSMutableArray* tempArray = [NSMutableArray arrayWithArray:recipients];
    [tempArray removeObject:recipient];
    NSString* peerURIs = [self getListOfRecipientsFromPeerURIsArray:tempArray];
    
    [dict setObject:message.session.sessionID forKey:@"conversationId"];
    [dict setObject:message.session.type forKey:@"conversationType"];
    [dict setObject:[NSNumber numberWithDouble:[message.date timeIntervalSince1970]] forKey:@"date"];
    [dict setObject:self.location forKey:@"location"];
    [dict setObject:message.messageID forKey:@"messageId"];
    [dict setObject:message.type forKey:@"messageType"];
    [dict setObject:self.peerURI forKey:@"peerURI"];
    [dict setObject:peerURIs forKey:@"peerURIs"];
    [dict setObject:[[HOPAccount sharedAccount] getFullName] forKey:@"senderName"];
    [dict setObject:[recipient getPeerURI] forKey:@"to"];
    
    if ([message.type isEqualToString:[HOPSystemMessage getMessageType]])
    {
        //TODO: Go through all keys, find these which starts with $ and replace them.
        if ([message.text rangeOfString:@"$id"].length != 0)
        {
            message.text = [message.text stringByReplacingOccurrencesOfString:@"$id" withString:@"id"];
        }
        
        NSDictionary* jsonDict = [Utility dictionaryFromJSON:message.text];
        if (jsonDict)
        {
            [dict addEntriesFromDictionary:jsonDict];
            
            NSString* callStatus = [dict valueForKeyPath:@"system.callStatus.status"];
            if (callStatus.length > 0)
            {
                if ([callStatus isEqualToString:@"placed"])
                    [dict setObject:@"Incoming call" forKey:@"alert"];
                else if ([callStatus isEqualToString:@"hungup"])
                    [dict setObject:@"Missed call" forKey:@"alert"];
            } 
        }
    }
    else
    {
        [dict setObject:message.text forKey:@"alert"];
    }
    
    return dict;
}
@end
