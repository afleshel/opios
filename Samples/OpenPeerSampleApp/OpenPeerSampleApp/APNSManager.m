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


#import "APNSManager.h"
#import "Settings.h"
#import "AppConsts.h"
#import "Utility.h"
#import "OpenPeer.h"
#import "BackgroundingDelegate.h"
#import "HTTPDownloader.h"
#import "PushNotificationSender.h"
#import "ParsePushNotificationSender.h"
#import "UrbanAirshipPushNotificationSender.h"
#import "ParsePushNotificationReceiver.h"
#import "UrbanAirshipPushNotificationReceiver.h"

#import <OpenPeerSDK/Openpeer.h>
#import <Parse/Parse.h>

#define  timeBetweenPushNotificationsInSeconds 1

@interface APNSManager ()

@property (nonatomic, strong) PushNotificationSender* pushNotificationSender;
@property (nonatomic, strong) PushNotificationReceiver* pushNotificationReceiver;

- (id) initSingleton;
@end

@implementation APNSManager

+ (id) sharedAPNSManager
{
    static dispatch_once_t pred = 0;
    __strong static id sharedInstance = nil;
    dispatch_once(&pred, ^
    {
        sharedInstance = [[self alloc] initSingleton];
    });
    
    return sharedInstance;
}

- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        self.pushesToSend = 0;
        
        //Get default push provider
        self.pushProvider = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyDefaultAPNSProvider];
        
        if (self.pushProvider.length > 0)
        {
            if ([self.pushProvider localizedCaseInsensitiveCompare:@"UrbanAirship"] == NSOrderedSame)
            {
                self.pushNotificationSender = [UrbanAirshipPushNotificationSender new];
                self.pushNotificationReceiver = [UrbanAirshipPushNotificationReceiver new];
            }
            else if ([self.pushProvider localizedCaseInsensitiveCompare:@"Parse"] == NSOrderedSame)
            {
                self.pushNotificationSender = [ParsePushNotificationSender new];
                self.pushNotificationReceiver = [ParsePushNotificationReceiver new];
            }
        }
    }
    return self;
}


- (void)prepare
{
    //Apply settings for push sending
    [self.pushNotificationSender prepare];
    
    //Apply settings for push receiving
    [self.pushNotificationReceiver prepare];
}

- (void) registerDeviceToken:(NSData*) devToken
{
    // Register device token and user peer URI with choosen push provider
    [self.pushNotificationSender registerDeviceToken:devToken peerURI:[[HOPAccount sharedAccount] getPeerURI]];
}

- (void) registerDeviceTokenWithOpenPeer
{
    [self registerDeviceToken:self.deviceToken];
    //Register device token with Open Peer server
    if ([[[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:[[HOPModelManager sharedModelManager] getPeerURIForHomeUser]] count] == 0)
        [self.pushNotificationSender registerDeviceTokenWithOpenPeer];
}

/**
 *  Direct sending push message over default push provider
 *
 *  @param message      message to send
 *  @param outgoingCall outgoingCall description
 *  @param recipients   list of push notification recipients
 */
- (void) sendPushNotificationMessage:(NSString*) message outgoingCall:(BOOL) outgoingCall recipients:(NSArray*) recipients
{
    [self.pushNotificationSender sendPushNotificationMessage:message outgoingCall:outgoingCall recipients:recipients];
}

- (void) sendRichPushNotificationForMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation participants:(NSArray*) participants
{
    [self.pushNotificationSender sendRichPushNotificationMessage:message conversation:conversation recipients:participants];
}

- (BOOL) areTherePushesForSending
{
    BOOL ret = NO;
    @synchronized(self)
    {
        ret = self.pushNotificationSender.pushesToSend > 0;
    }
    return ret;
}

- (void) getAllMessages
{
    [self.pushNotificationReceiver downloadAllMessages];
}

- (void) handleExistingMessages
{
    [self.pushNotificationReceiver handleExistingMessages];
}

- (void) handleAPNS:(NSDictionary *)apnsInfo
{
    [self.pushNotificationReceiver handleAPNS:apnsInfo];
}

- (void) setBadgeNumber:(NSInteger) numberOfUnreadMessages
{
    [self.pushNotificationReceiver setBadgeNumber:numberOfUnreadMessages];
}

- (NSString*) getSelfDeviceToken
{
    NSString* ret = nil;
    
    if (self.deviceToken)
    {
        ret = [Utility hexadecimalStringForData:self.deviceToken];
    }
    else
    {
        ret = @"";
    }
    
    return ret;
}
@end
