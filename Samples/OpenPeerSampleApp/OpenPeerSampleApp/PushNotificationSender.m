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

#import "PushNotificationSender.h"
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPRolodexContact+External.h>
#import <OpenPeerSDK/HOPUtility.h>
#import "Utility.h"
#import "HTTPDownloader.h"

@interface PushNotificationSender ()

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfHTTPRequests;

- (BOOL) sendHTTPRequestForDictionary:(NSDictionary*) dict peerURI:(NSString*) peerURI;

@end

@implementation PushNotificationSender


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dictionaryOfHTTPRequests = [NSMutableDictionary new];
        self.pushesToSend = 0;
    }
    return self;
}

- (void) prepare
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Prepare PushNotificationSender");
    
    UIApplication* application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
#ifdef __IPHONE_8_0
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
#endif
    }
    else
    {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
}

- (void) registerDeviceToken:(NSData*) inDeviceToken peerURI:(NSString*) inPeerURI
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelBasic, @"Registering device token, %@, for peer URI %@",[Utility hexadecimalStringForData:inDeviceToken],inPeerURI);
    
    if (inDeviceToken.length > 0)
        self.deviceToken = inDeviceToken;
    
    if (inPeerURI.length > 0)
        self.peerURI = inPeerURI;
    
    self.location = [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady) ? [[HOPAccount sharedAccount] getLocationID] : @"";
}

- (NSDictionary*) createPushMessage:(NSString*) message incomingCall:(BOOL) incomingCall recipients:(NSArray*) recipients
{
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          (incomingCall ? @"push_incoming_call.wav" : @"message-received.wav"), @"sound",
                          self.location, @"location",
                          self.peerURI, @"peerURI",
                          nil];
    
    return data;
}

- (void) sendPushNotificationMessage:(NSString*) message outgoingCall:(BOOL) outgoingCall recipients:(NSArray*) recipients
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending push notification, \"%@\"",message);
}

- (void) sendRichPushNotificationMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipients:(NSArray*) recipients
{
    self.pushesToSend++;
}

- (NSString *)getLocation
{
    if (_location.length > 0)
        return _location;
    
    _location = [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady) ? [[HOPAccount sharedAccount] getLocationID] : @"";
    
    return _location;
}

- (NSString*) getListOfRecipientsFromPeerURIsArray:(NSArray*) array
{
    NSString* peerURIs = @"";
    NSArray* participantsPeerURIs = [array valueForKeyPath:@"openPeerContact.publicPeerFile.peerURI"];
    for (NSString* tempPeerURI in participantsPeerURIs)
    {
        if (![tempPeerURI isEqualToString:self.peerURI])
            peerURIs = [peerURIs stringByAppendingString: peerURIs.length > 0 ? [NSString stringWithFormat:@",%@",tempPeerURI] : tempPeerURI];
    }
    
    return peerURIs;
}

- (NSDictionary*) createRichPushMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipient:(HOPRolodexContact*) recipient recipients:(NSArray*) recipients
{
    return nil;
}

- (NSArray*) getDeviceTokensForContact:(HOPRolodexContact*) contact
{
    NSArray* ret = nil;
    
    NSString* peerURI = [contact getPeerURI];
    if ([peerURI length] > 0)
    {
        ret = [[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:peerURI];
    }
    return ret;
}

- (BOOL) sendHTTPRequestForDictionary:(NSDictionary*) dict peerURI:(NSString*) peerURI
{
    NSString* json = [Utility jsonFromDictionary:dict];
    
    HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:[[Settings sharedSettings] getDeviceTokenUploadURL] data:json post:YES];
    
    request.delegate = self;
    [self.dictionaryOfHTTPRequests setObject:request forKey:peerURI];
    
    return [request startDownload];
}

- (void) requestDeviceTokenForPeerURI:(NSString*) peerURI
{
    if ([peerURI length] > 0 && ![[self.dictionaryOfHTTPRequests allKeys] containsObject:peerURI])
    {
        NSMutableDictionary* dictRoot = [[NSMutableDictionary alloc] init];
        NSMutableDictionary* dictData  = [[NSMutableDictionary alloc] init];
        
        [dictData setObject:[[Settings sharedSettings] getIdentityProviderDomain]  forKey:@"$domain"];
        [dictData setObject:[[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyAppId]  forKey:@"$appid"];
        [dictData setObject:[HOPUtility getGUIDstring]  forKey:@"$id"];
        [dictData setObject:@"push-hack" forKey:@"$handler"];
        [dictData setObject:@"device-associate-get" forKey:@"$method"];
        [dictData setObject:peerURI forKey:@"uri"];
        
        [dictRoot setObject:dictData forKey:@"request"];
        
        /*NSString* json = [Utility jsonFromDictionary:dictData];
        
        HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:[[Settings sharedSettings] getDeviceTokenDownloadURL] data:json post:YES];
        
        request.delegate = self;
        [self.dictionaryOfHTTPRequests setObject:request forKey:peerURI];
        
        if (![request startDownload])*/
        if (![self sendHTTPRequestForDictionary:dictRoot peerURI:peerURI])
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Device token retrievel request is not sent.");
            [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
        }
    }
    
}

/**
 *  Register deviceToken, with OpenPeer server, for logged in user.
 */
- (void) registerDeviceTokenWithOpenPeer
{
    NSString* peerURI = [[HOPAccount sharedAccount] getPeerURI];
    
    if ([self.deviceToken length] > 0 && [peerURI length] > 0 && ![[self.dictionaryOfHTTPRequests allKeys] containsObject:peerURI])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registering device token, %@, with Open Peer system",self.deviceToken);
        
        NSMutableDictionary* dictRoot = [[NSMutableDictionary alloc] init];
        NSMutableDictionary* dictData  = [[NSMutableDictionary alloc] init];
        
        NSString* hexString = [Utility hexadecimalStringForData:self.deviceToken];
        
        if (hexString.length > 0)
        {
            [dictData setObject:[[Settings sharedSettings] getIdentityProviderDomain]  forKey:@"$domain"];
            [dictData setObject:[[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyAppId]  forKey:@"$appid"];
            [dictData setObject:[HOPUtility getGUIDstring]  forKey:@"$id"];
            [dictData setObject:@"push-hack" forKey:@"$handler"];
            [dictData setObject:@"device-associate-set" forKey:@"$method"];
            [dictData setObject:@"apns" forKey:@"type"];
            [dictData setObject:peerURI forKey:@"uri"];
            [dictData setObject:hexString forKey:@"deviceToken"];
            
            [dictRoot setObject:dictData forKey:@"request"];
            
            /*NSString* json = [Utility jsonFromDictionary:dictRoot];
            
            HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:[[Settings sharedSettings] getDeviceTokenUploadURL] data:json post:YES];
            
            request.delegate = self;
            [self.dictionaryOfHTTPRequests setObject:request forKey:peerURI];
            
            if (![request startDownload])*/
            if (![self sendHTTPRequestForDictionary:dictRoot peerURI:peerURI])
            {
                [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Device token, %@, registration request is not sent via %@.",self.deviceToken,@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-set");
            }
            else
            {
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registering device token, %@, JSON: /n is sent via %@.",self.deviceToken,[Utility jsonFromDictionary:dictRoot],@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-set");
            }
        }
    }
}

- (void)onDeviceTokenReceivedForPeerURI:(NSString *)peerURI
{
    
}

#pragma mark - HTTPDownloaderDelegate

- (void) httpDownloader:(HTTPDownloader*) downloader downloaded:(NSString*) downloaded
{
    NSString* peerURI = nil;
    
    for (NSString* key in [self.dictionaryOfHTTPRequests allKeys])
    {
        if ([self.dictionaryOfHTTPRequests objectForKey:key] == downloader)
        {
            peerURI = key;
            break;
        }
    }
    
    if ([downloaded length] > 0 && [downloaded rangeOfString:@">404<"].location == NSNotFound)
    {
        NSDictionary* responseDictionary = [Utility dictionaryFromJSON:downloaded];
        if ([responseDictionary count] > 0)
        {
            NSDictionary* result = [responseDictionary objectForKey:@"result"];
            if ([result count] > 0)
            {
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received valid response.");
                if (![peerURI isEqualToString:[[HOPAccount sharedAccount] getPeerURI]])
                {
                    NSString* type = [result objectForKey:@"type"];
                    //if ([type isEqualToString:@"apns"])
                    if ([type length] > 0)
                    {
                        NSString* deviceToken = [result objectForKey:@"deviceToken"];
                        if ([deviceToken length] > 0)
                        {
                            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received deviceToken, %@, for peer URI %@.",deviceToken,peerURI);
                            [[HOPModelManager sharedModelManager] setAPNSData:deviceToken type:type PeerURI:peerURI];
                            [self onDeviceTokenReceivedForPeerURI:peerURI];
                        }
                        
                    }
                }
                else
                {
                    [[HOPModelManager sharedModelManager] setAPNSData:[Utility hexadecimalStringForData:self.deviceToken] type:notificationTypeApple PeerURI: [[HOPAccount sharedAccount] getPeerURI]];
                }
            }
        }
    }
    else
    {
        if ([downloaded length] > 0)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Response error: 404 Not found");
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Received empty response.");
        }
    }
    
    if (peerURI.length > 0)
        [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
}

- (void) httpDownloader:(HTTPDownloader *) downloader didFailWithError:(NSError *)error
{
    
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Response error: %@", [error description]);
    NSString* peerURI = nil;
    
    for (NSString* key in [self.dictionaryOfHTTPRequests allKeys])
    {
        if ([self.dictionaryOfHTTPRequests objectForKey:key] == downloader)
        {
            peerURI = key;
            break;
        }
    }
    if (peerURI.length > 0)
        [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
}

- (void) onMessageSent:(NSString*) messageID
{
    self.pushesToSend--;
}
@end
