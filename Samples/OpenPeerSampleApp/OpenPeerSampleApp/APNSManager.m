/*
 
 Copyright (c) 2013, SMB Phone Inc.
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
#import "APNSInboxManager.h"
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "Settings.h"
#import "AppConsts.h"
#import "SBJsonParser.h"
#import "Utility.h"
#import "OpenPeer.h"
#import "BackgroundingDelegate.h"

#import <OpenPeerSDK/HOPRolodexContact.h>
#import <OpenPeerSDK/HOPContact.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPPublicPeerFile.h>
#import <OpenPeerSDK/HOPHomeUser+External.h>
#import <OpenPeerSDK/HOPMessage.h>
#import <OpenPeerSDK/HOPBackgrounding.h>

#define  timeBetweenPushNotificationsInSeconds 1

@interface APNSManager ()

@property (nonatomic, strong) NSString* apiPushURL;

@property (nonatomic, strong) NSString* urbanAirshipAppKey;
@property (nonatomic, strong) NSString* urbanAirshipAppSecret;

@property (nonatomic, strong) NSMutableDictionary* apnsHisotry;

- (id) initSingleton;

- (void) pushData:(NSDictionary*) dataToPush sendingRich:(BOOL) sendingRich;
- (BOOL) canSendPushNotificationForPeerURI:(NSString*) peerURI;
- (NSArray*) getDeviceTokensForContact:(HOPContact*) contact;
- (NSString*) prepareMessageForRichPush:(HOPMessage*) message peerURI:(NSString*) peerURI location:(NSString*) location;
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
        self.goingToBackground = NO;
#ifdef DEBUG
        self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipDevelopmentAppKey];
        self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipMasterAppSecretDev];
#else
        self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipProductionAppKey];
        self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipMasterAppSecret];
#endif
        self.apiPushURL = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipAPIPushURL];
        self.apnsHisotry = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void) prepareUrbanAirShip
{
    [UAirship setLogging:NO];
    
    UAConfig *config = [UAConfig defaultConfig];
    
    config.developmentAppKey = self.urbanAirshipAppKey;
    config.developmentAppSecret = self.urbanAirshipAppSecret;
    
    config.productionAppKey = self.urbanAirshipAppKey;
    config.productionAppSecret = self.urbanAirshipAppSecret;
    
    [UAirship takeOff:config];
    
    //[UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound |UIRemoteNotificationTypeAlert);
    
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert);
    [[UAPush shared] registerForRemoteNotifications];
    
    // Print out the application configuration for debugging (optional)
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"UrbanAirship config: %@",[config description]);

    [[APNSInboxManager sharedAPNSInboxManager]setup];
    // Set the icon badge to zero on startup (optional)
    [[UAPush shared] resetBadge];
}

- (void) pushData:(NSDictionary*) dataToPush sendingRich:(BOOL) sendingRich
{
    if ([self.apiPushURL length] > 0)
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if (sendingRich)
            [request setValue:@"application/vnd.urbanairship+json; version=3;" forHTTPHeaderField:@"Accept"];
        
        NSData * pushdata = [NSJSONSerialization dataWithJSONObject:dataToPush options:0 error:NULL];
        [request setHTTPBody:pushdata];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push is sent");
        @synchronized (self)
        {
            self.pushesToSend++;
        }
    }
}

/*- (void) sendPushNotificationForDeviceToken:(NSString*) deviceToken message:(NSString*) message
{
    NSDictionary * dataToPush = @{@"device_tokens":@[deviceToken], @"aps":@{@"alert":message, @"sound":@"calling"}};
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Sending push notification: %@",message);
    
    [self pushData:dataToPush sendingRich:NO];
}*/

- (void) registerDeviceToken:(NSData*) devToken
{
    [[UAPush shared] registerDeviceToken:devToken];
}

- (void) handleRemoteNotification:(NSDictionary*) launchOptions application:(UIApplication *)application
{
    [[UAPush shared] handleNotification:[launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]
                       applicationState:application.applicationState];
}
- (void) connection:(NSURLConnection *) connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge
{
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])
    {
        //if ([self.developmentAppKey length] > 0 || [self.masterAppSecret length] > 0)
        if ([self.urbanAirshipAppSecret length] > 0 || [self.urbanAirshipAppKey length] > 0)
        {
//            NSURLCredential * credential = [[NSURLCredential alloc] initWithUser:self.developmentAppKey password:self.masterAppSecret persistence:NSURLCredentialPersistenceForSession];
            NSURLCredential * credential = [[NSURLCredential alloc] initWithUser:self.urbanAirshipAppKey password:self.urbanAirshipAppSecret persistence:NSURLCredentialPersistenceForSession];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
    }
}

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response
{
    NSHTTPURLResponse * res = (NSHTTPURLResponse *) response;
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Response code %i: response: %@",res.statusCode, res);
    @synchronized (self)
    {
        self.pushesToSend--;
        if (self.goingToBackground)
        {
            [[[[OpenPeer sharedOpenPeer] backgroundingDelegate] backgroundingNotifier] destroy];
            [[[OpenPeer sharedOpenPeer] backgroundingDelegate] setBackgroundingNotifier:nil];
        }
    }
}

- (void) sendPushNotificationForContact:(HOPContact*) contact message:(NSString*) message missedCall:(BOOL) missedCall
{
    NSString* peerURI = [contact getPeerURI];
    if ([peerURI length] > 0)
    {
        if ([self canSendPushNotificationForPeerURI:peerURI])
        {
            NSArray* deviceTokens = [[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:peerURI];
            
            if ([deviceTokens count] > 0)
            {
                NSString* myPeerURI = [[HOPContact getForSelf]getPeerURI];
                NSString* locationId = [[HOPAccount sharedAccount] getLocationID];
                NSMutableDictionary* messageDictionary = [[NSMutableDictionary alloc] init];
                
                [messageDictionary setObject:message forKey:@"alert"];
                [messageDictionary setObject:locationId forKey:@"location"];
                [messageDictionary setObject:myPeerURI forKey:@"peerURI"];
                
                if (missedCall)
                    [messageDictionary setObject:@"ringing.caf" forKey:@"sound"];
                else
                    [messageDictionary setObject:@"message-received.wav" forKey:@"sound"];

                NSDictionary * dataToPush = @{@"device_tokens":deviceTokens, @"aps":messageDictionary};
                
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Sending push notification: %@",message);
                
                [self pushData:dataToPush sendingRich:NO];
                
                [self.apnsHisotry setObject:[NSDate date] forKey:peerURI];
            }
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Cannot send push notification because it passes less than %d seconds since last push",[[NSUserDefaults standardUserDefaults] integerForKey:settingsKeyAPNSTimeOut]);
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Cannot send push notification because of invalid peerURI");
    }
}

- (void) sendRichPushNotificationForMessage:(HOPMessage*) message missedCall:(BOOL) missedCall
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Creating rich push for message: :%@", message.messageID);
    NSArray* deviceTokens = [self getDeviceTokensForContact:message.contact];
    
    if ([deviceTokens count] > 0)
    {
        NSString* msg = [message.text length] > 22 ? [NSString stringWithFormat:@"%@...",[message.text substringToIndex:22]] : message.text;
        
        NSString* messageText  = [NSString stringWithFormat:@"%@  %@",[[[HOPModelManager sharedModelManager] getLastLoggedInHomeUser] getFullName],msg];
        
        NSString* content = [self prepareMessageForRichPush:message peerURI:[[HOPContact getForSelf]getPeerURI] location:[[HOPAccount sharedAccount] getLocationID]];
        
        for (NSString* deviceToken in deviceTokens)
        {
            
            //NSString* stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"badge\":\"+1\",\"sound\":\"default\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",deviceToken,messageText,messageText,content];
            NSString* stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"sound\":\"message-received\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",deviceToken,messageText,messageText,content];

            
            SBJsonParser* parser = [[SBJsonParser alloc] init];
            NSDictionary* dataToPush = [parser objectWithString: stringToSend];

            [self pushData:dataToPush sendingRich:YES];
        }
        [self.apnsHisotry setObject:[NSDate date] forKey:[message.contact getPeerURI]];
    }
}

- (NSString*) prepareMessageForRichPush:(HOPMessage*) message peerURI:(NSString*) peerURI location:(NSString*) location
{
    NSString* ret = [NSString stringWithFormat:@"{\\\"peerURI\\\":\\\"%@\\\",\\\"messageId\\\":\\\"%@\\\",\\\"message\\\":\\\"%@\\\",\\\"location\\\":\\\"%@\\\",\\\"date\\\":\\\"%.0f\\\"}",peerURI,message.messageID,message.text,location,[message.date timeIntervalSince1970]];

    return ret;
}

- (NSArray*) getDeviceTokensForContact:(HOPContact*) contact
{
    NSArray* ret = nil;
    
    NSString* peerURI = [contact getPeerURI];
    if ([peerURI length] > 0)
    {
        if ([self canSendPushNotificationForPeerURI:peerURI])
        {
            ret = [[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:peerURI];
        }
    }
    return ret;
}

- (BOOL) canSendPushNotificationForPeerURI:(NSString*) peerURI
{
    BOOL ret = YES;

    NSDate* lastPushDate = [self.apnsHisotry objectForKey:peerURI];
    if (lastPushDate)
        ret = [[NSDate date] timeIntervalSinceDate:lastPushDate] > [[NSUserDefaults standardUserDefaults] integerForKey:settingsKeyAPNSTimeOut] ? YES : NO;
    
    return ret;
}
- (BOOL) areTherePushesForSending
{
    BOOL ret = NO;
    @synchronized(self)
    {
        ret = self.pushesToSend > 0;
    }
    return ret;
}

@end
