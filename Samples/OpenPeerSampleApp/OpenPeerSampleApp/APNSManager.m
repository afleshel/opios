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
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSessionUploadTask *sessionDataTask;

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfSentFiles;
- (id) initSingleton;

- (void) pushDataOld:(NSDictionary*) dataToPush sendingRich:(BOOL) sendingRich;
- (void) pushData:(NSString*) filePath sendingRich:(BOOL) sendingRich;
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
        
        self.dictionaryOfSentFiles = [[NSMutableDictionary alloc] init];
        
        NSString* sessionIdentifier = [NSString stringWithFormat:@"com.hookflash.backgroundSession.%@",@""];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
        //NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
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
    
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound |UIRemoteNotificationTypeAlert);
    
    //[UAPush shared].notificationTypes = (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert);
    [[UAPush shared] registerForRemoteNotifications];
    
    // Print out the application configuration for debugging (optional)
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"UrbanAirship config: %@",[config description]);

    [[UAPush shared] setAutobadgeEnabled:YES];
    
    [[APNSInboxManager sharedAPNSInboxManager]setup];
    // Set the icon badge to zero on startup (optional)
    [[UAPush shared] resetBadge];
}

- (void) pushDataOld:(NSDictionary*) dataToPush sendingRich:(BOOL) sendingRich
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
    else
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Push URL is invalid.");
    }
}

- (void) pushData:(NSString*) filePath sendingRich:(BOOL) sendingRich
{
    if ([filePath length] > 0)
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if (sendingRich)
            [request setValue:@"application/vnd.urbanairship+json; version=3;" forHTTPHeaderField:@"Accept"];
        
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        if (fileURL)
        {
            self.sessionDataTask = [self.urlSession uploadTaskWithRequest:request fromFile:fileURL];
            [self.sessionDataTask resume];
            [self.dictionaryOfSentFiles setObject:filePath forKey:[NSNumber numberWithInt:self.sessionDataTask.taskIdentifier]];
        }
    }
    
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
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Sending rich push response code %i: response: %@",res.statusCode, res);
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

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Sending rich push failed. Error: %@",error);
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
                
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Sending push notification: %@",message);
                
                if ([dataToPush count] > 0)
                {
                    [self pushDataOld:dataToPush sendingRich:NO];
                    
                    [self.apnsHisotry setObject:[NSDate date] forKey:peerURI];
                }
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
    
    NSArray* deviceTokens = [self getDeviceTokensForContact:message.contact];
    
    if ([deviceTokens count] > 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Creating rich push for message: :%@", message.messageID);
        NSString* msg = [message.text length] > 22 ? [NSString stringWithFormat:@"%@...",[message.text substringToIndex:22]] : message.text;
        
        NSString* messageText  = [NSString stringWithFormat:@"%@  %@",[[[HOPModelManager sharedModelManager] getLastLoggedInHomeUser] getFullName],msg];
        
        NSString* content = [self prepareMessageForRichPush:message peerURI:[[HOPContact getForSelf]getPeerURI] location:[[HOPAccount sharedAccount] getLocationID]];
        
        for (NSString* deviceToken in deviceTokens)
        {
            
            //NSString* stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"badge\":\"auto\",\"sound\":\"default\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",deviceToken,messageText,messageText,content];
            NSString* stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"sound\":\"message-received\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",deviceToken,messageText,messageText,content];

            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"Rich push content: %@",stringToSend);
            SBJsonParser* parser = [[SBJsonParser alloc] init];
            NSDictionary* dataToPush = [parser objectWithString: stringToSend];

            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [NSString stringWithFormat:@"%@/%@%@", documentsDirectory, message.messageID,@".json"];
            NSLog(@"filePath %@", filePath);
            
            //if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) { // if file is not exist, create it.
                                                                               // NSString *helloStr = @"hello world";
                NSError *error;
                [stringToSend writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            //}
            
            if ([[NSFileManager defaultManager] isWritableFileAtPath:filePath]) {
                NSLog(@"Writable");
            }else {
                NSLog(@"Not Writable");
            }
            
            if ([filePath length] > 0 && [dataToPush count] > 0)
                [self pushData:filePath sendingRich:YES];
            else
            {
                OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Dictionary with push data is not valid. Push notification is not sent.");
            }
        }
        [self.apnsHisotry setObject:[NSDate date] forKey:[message.contact getPeerURI]];
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Unable to send a message because lack of device token for contact with peer uri: ", [message.contact getPeerURI]);
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

#pragma  mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (challenge.previousFailureCount == 0)
    {
        NSURLCredentialPersistence persistence = NSURLCredentialPersistenceForSession;
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.urbanAirshipAppKey password:self.urbanAirshipAppSecret persistence:persistence];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else
    {
        // handle the fact that the previous attempt failed
        NSLog(@"%s: challenge.error = %@", __FUNCTION__, challenge.error);
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
}
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}

#pragma  mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    
}

/* The task has received a request specific authentication challenge.
 * If this delegate is not implemented, the session specific authentication challenge
 * will *NOT* be called and the behavior will be the same as using the default handling
 * disposition.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (challenge.previousFailureCount == 0)
    {
        NSURLCredentialPersistence persistence = NSURLCredentialPersistenceForSession;
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.urbanAirshipAppKey password:self.urbanAirshipAppSecret persistence:persistence];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else
    {
        // handle the fact that the previous attempt failed
        NSLog(@"%s: challenge.error = %@", __FUNCTION__, challenge.error);
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

/* Sent if a task requires a new, unopened body stream.  This may be
 * necessary when authentication has failed for any request that
 * involves a body stream.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    
}

/* Sent periodically to notify the delegate of upload progress.  This
 * information is also available as properties of the task.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"%@",error);
    if (!error)
    {
        NSError* fileError;
        NSString* filePath = [self.dictionaryOfSentFiles objectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
        if ([filePath length] > 0)
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&fileError];
            if (fileError)
            {
                
            }
        }
    }
    return;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
}

/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
}

/* Invoke the completion routine with a valid NSCachedURLResponse to
 * allow the resulting data to be cached, or pass nil to prevent
 * caching. Note that there is no guarantee that caching will be
 * attempted for a given resource, and you should not rely on this
 * message to receive the resource data.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    
}
@end
