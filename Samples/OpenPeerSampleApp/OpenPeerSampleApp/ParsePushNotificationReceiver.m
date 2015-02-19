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

#import "ParsePushNotificationReceiver.h"
#import <Parse/Parse.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPSystemMessage.h>

@implementation ParsePushNotificationReceiver

- (void)downloadAllMessages
{
    [super downloadAllMessages];
    PFQuery* parseQuery = [PFQuery queryWithClassName:@"OPPushMessage"];    [parseQuery whereKey:@"to" equalTo:[[HOPAccount sharedAccount] getPeerURI]];
    [parseQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error)
         {
             OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, [error description]);
         }
         else
         {
             for (PFObject* object in objects)
             {

    //             NSString* jsonMessage = object[@"extras"];
                 NSString* jsonMessageText = object[@"alert"];
                  NSDictionary* dictSystem = object[@"system"];

    //             NSData *data = [jsonMessage dataUsingEncoding:NSUTF8StringEncoding];
    //             NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:object[@"conversationId"], @"conversationId", object[@"conversationType"], @"conversationType", object[@"date"], @"date", object[@"location"], @"location", object[@"messageId"], @"messageId", object[@"peerURI"], @"peerURI", object[@"peerURIs"], @"peerURIs", object[@"senderName"], @"senderName", object[@"to"], @"to", object[@"messageType"], @"messageType",  nil];
                 if (dict.count > 0)
                 {
                     NSMutableDictionary* dictMessage = [NSMutableDictionary dictionaryWithDictionary:dict];
                     if (jsonMessageText.length > 0)
                         [dictMessage setObject:jsonMessageText forKey:@"message"];
                     if (dictSystem)
                     {
                         [dictMessage setObject:dictSystem forKey:@"system"];
                     }
                     [self createMessageFromRichPushDict:dictMessage];
                 }
             }
         }
         if (objects.count > 0)
             [PFObject deleteAllInBackground:objects];
         if (![PFInstallation currentInstallation].badge != 0)
         {
             [PFInstallation currentInstallation].badge = 0;
             [[PFInstallation currentInstallation] saveEventually];
         }
         [self onPushNotificationsDownloaded];
     }];

}

- (void) setBadgeNumber:(NSInteger) numberOfUnreadMessages
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = numberOfUnreadMessages;
}

@end
