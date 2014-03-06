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
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "Settings.h"

#import <OpenPeerSDK/HOPRolodexContact.h>
#import <OpenPeerSDK/HOPContact.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPPublicPeerFile.h>

#define  timeBetweenPushNotificationsInSeconds 1

@interface APNSManager ()

@property (nonatomic, strong) NSString* apiPushURL;

@property (nonatomic, strong) NSString* urbanAirshipAppKey;
@property (nonatomic, strong) NSString* urbanAirshipAppSecret;

@property (nonatomic, strong) NSMutableDictionary* apnsHisotry;

- (id) initSingleton;

- (void) pushData:(NSDictionary*) dataToPush;
- (BOOL) canSendPushNotificationForPeerURI:(NSString*) peerURI;
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
        
#ifdef DEBUG
        self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipDevelopmentAppKey];
        self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipMasterAppSecretDev;
#else
        self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipProductionAppKey];
        self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirMasterAppSecret];
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
    [UAirship takeOff:config];
    
    // Print out the application configuration for debugging (optional)
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"UrbanAirship config: %@",[config description]);

    
    // Set the icon badge to zero on startup (optional)
    [[UAPush shared] resetBadge];
}

- (void) pushData:(NSDictionary*) dataToPush
{
    if ([self.apiPushURL length] > 0)
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSData * pushdata = [NSJSONSerialization dataWithJSONObject:dataToPush options:0 error:NULL];
        [request setHTTPBody:pushdata];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
}

- (void) sendPushNotificationForDeviceToken:(NSString*) deviceToken message:(NSString*) message
{
    NSDictionary * dataToPush = @{@"device_tokens":@[deviceToken], @"aps":@{@"alert":message, @"sound":@"calling"}};
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Sending push notification: %@",message);
    
    [self pushData:dataToPush];
}

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
                
                [self pushData:dataToPush];
                
                [self.apnsHisotry setObject:[NSDate date] forKey:peerURI];
            }
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Cannot send push notification because it passes less than %d seconds since last push",timeBetweenPushNotificationsInSeconds);
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Cannot send push notification because of invalid peerURI");
    }
}

- (BOOL) canSendPushNotificationForPeerURI:(NSString*) peerURI
{
    BOOL ret = YES;

    NSDate* lastPushDate = [self.apnsHisotry objectForKey:peerURI];
    if (lastPushDate)
        ret = [[NSDate date] timeIntervalSinceDate:lastPushDate] > timeBetweenPushNotificationsInSeconds ? YES : NO;
    
    return ret;
}

- (void) handleAPNS:(NSDictionary *)apnsInfo
{
    NSDictionary *apsInfo = [apnsInfo objectForKey:@"aps"];
    NSString *alert = [apsInfo objectForKey:@"alert"];
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Received Push Alert: %@", alert);
    NSString *peerURI = [apnsInfo objectForKey:@"peerURI"];
    NSString *locationID = [apnsInfo objectForKey:@"location"];
    
    HOPPublicPeerFile* publicPerFile = [[HOPModelManager sharedModelManager] getPublicPeerFileForPeerURI:peerURI];
    HOPContact* contact = [[HOPContact alloc] initWithPeerFile:publicPerFile.peerFile];
    [contact hintAboutLocation:locationID];
}
@end
