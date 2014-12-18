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
#import "HTTPDownloader.h"

#import <OpenPeerSDK/HOPRolodexContact+External.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPMessage.h>
#import <OpenPeerSDK/HOPBackgrounding.h>
#import <OpenPeerSDK/HOPUtility.h>
#import <OpenPeerSDK/HOPAPNSData.h>
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import <OpenPeerSDK/HOPConversationRecord+External.h>
#import <OpenPeerSDK/HOPTypes.h>

#define  timeBetweenPushNotificationsInSeconds 1

@interface APNSManager ()

@property (nonatomic, strong) NSString* apiPushURL;

@property (nonatomic, strong) NSString* urbanAirshipAppKey;
@property (nonatomic, strong) NSString* urbanAirshipAppSecret;

@property (nonatomic, strong) NSMutableDictionary* apnsHisotry;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSessionUploadTask *sessionDataTask;
@property (nonatomic, strong) NSURLConnection* urlConnection;

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfSentFiles;

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfHTTPRequests;
@property (nonatomic, strong) NSMutableDictionary* dictionaryOfPushNotificationsToSend;

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfMessageIDsForSending;

- (id) initSingleton;

- (void) pushDataOld:(NSDictionary*) dataToPush sendingRich:(BOOL) sendingRich;
- (void) pushData:(NSString*) filePath sendingRich:(BOOL) sendingRich messageID:(NSString*) messageID;
- (BOOL) canSendPushNotificationForPeerURI:(NSString*) peerURI;
- (NSString*) prepareMessageForRichPush:(HOPMessage*) message peerURI:(NSString*) peerURI location:(NSString*) location participantPeerURIs:(NSArray*) participantPeerURIs;
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
        self.dictionaryOfHTTPRequests = [[NSMutableDictionary alloc] init];
        self.dictionaryOfPushNotificationsToSend = [[NSMutableDictionary alloc] init];
        self.dictionaryOfMessageIDsForSending = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSURLSession*) urlSession
{
    if (_urlSession != nil)
        return _urlSession;
    
    NSString* sessionIdentifier = [NSString stringWithFormat:@"com.hookflash.backgroundSession.%@",@""];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
    
    _urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    return _urlSession;
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
    
    [UAPush shared].userNotificationTypes = (UIUserNotificationTypeBadge |UIUserNotificationTypeSound |UIUserNotificationTypeAlert);
    
    [[UAPush shared] updateRegistration];
    
    // Print out the application configuration for debugging (optional)
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"UrbanAirship config: %@",[config description]);

    [[UAPush shared] setUserPushNotificationsEnabled:YES];
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
        //if (sendingRich)
            [request setValue:@"application/vnd.urbanairship+json; version=3;" forHTTPHeaderField:@"Accept"];
        
        NSData * pushdata = [NSJSONSerialization dataWithJSONObject:dataToPush options:0 error:NULL];
        [request setHTTPBody:pushdata];
        
        self.urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];
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

- (void) pushData:(NSString*) filePath sendingRich:(BOOL) sendingRich messageID:(NSString*) messageID
{
    if ([filePath length] > 0)
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //if (sendingRich)
            [request setValue:@"application/vnd.urbanairship+json; version=3;" forHTTPHeaderField:@"Accept"];
        
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        if (fileURL)
        {
            if (self.urlSession)
            {
                self.sessionDataTask = [self.urlSession uploadTaskWithRequest:request fromFile:fileURL];
                if (self.sessionDataTask)
                {
                    [self.sessionDataTask resume];
                    [self.dictionaryOfSentFiles setObject:filePath forKey:[NSNumber numberWithInt:self.sessionDataTask.taskIdentifier]];
                    [self.dictionaryOfMessageIDsForSending setObject:messageID forKey:[NSNumber numberWithInt:self.sessionDataTask.taskIdentifier]];
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Started sending push notification");
                }
                else
                {
                    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Push notification is not sent, because session upload task is not created");
                }
            }
            else
            {
                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Push notification is not sent, because url session is invalid");
            }
        }
        else
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Invalid file url for sending push notification");
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Invalid path for sending push notification");
    }
    
}

- (void) registerDeviceToken:(NSData*) devToken
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registering device token, %@, with Urban Airship",devToken);
    [[UAPush shared] appRegisteredForRemoteNotificationsWithDeviceToken:devToken];
}

- (void) handleRemoteNotification:(NSDictionary*) launchOptions application:(UIApplication *)application
{
    [[UAPush shared] appReceivedRemoteNotification:[launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]
                       applicationState:application.applicationState];
}
- (void) connection:(NSURLConnection *) connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge
{
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])
    {
        if ([self.urbanAirshipAppSecret length] > 0 || [self.urbanAirshipAppKey length] > 0)
        {
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

- (void) sendPushNotificationForContact:(HOPRolodexContact*) contact message:(NSString*) message missedCall:(BOOL) missedCall
{
    NSString* peerURI = [contact getPeerURI];
    if ([peerURI length] > 0)
    {
        if ([self canSendPushNotificationForPeerURI:peerURI])
        {
            NSArray* deviceTokens = [[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:peerURI];
            
            if ([deviceTokens count] > 0)
            {
                NSString* myPeerURI = [[HOPRolodexContact getSelf] getPeerURI];
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

- (void)sendRichPush:(HOPMessage *)message deviceTokens:(NSArray *)deviceTokens participantPeerURIs:(NSArray*) participantPeerURIs
{
    NSString* msg = [message.text length] > 22 ? [NSString stringWithFormat:@"%@...",[message.text substringToIndex:22]] : message.text;
    
    NSString* messageText  = [NSString stringWithFormat:@"%@  %@",[[HOPAccount sharedAccount] getFullName],msg];
    
    NSString* location = [[HOPAccount sharedAccount] isCoreAccountCreated] && ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady) ? [[HOPAccount sharedAccount] getLocationID] : @"";
    NSString* content = [self prepareMessageForRichPush:message peerURI:[[HOPModelManager sharedModelManager]getPeerURIForHomeUser] location:location participantPeerURIs:participantPeerURIs];
    
    for (HOPAPNSData* pushNotificationData in deviceTokens)
    {
        NSString* stringToSend = nil;
        
        if ([pushNotificationData.type isEqualToString:notificationTypeApple])
            stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"sound\":\"message-received\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",pushNotificationData.deviceToken,messageText,messageText,content];
        else if ([pushNotificationData.type isEqualToString:notificationTypeAndroid])
            stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"apid\" : \"%@\"}, \"device_types\" : [ \"android\" ],  \"notification\" : {\"android\" : {\"extra\" : {\"date\": \"%.0f\",\"messageId\": \"%@\",\"location\": \"%@\",\"peerURI\": \"%@\",\"peerURIs\": \"%@\"}}, \"alert\" : \"%@\"} }",pushNotificationData.deviceToken,[message.date timeIntervalSince1970],message.messageID,location,[[HOPModelManager sharedModelManager]getPeerURIForHomeUser],@"",message.text];

        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"Rich push content: %@",stringToSend);
        SBJsonParser* parser = [[SBJsonParser alloc] init];
        NSDictionary* dataToPush = [parser objectWithString: stringToSend];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@%@", documentsDirectory, message.messageID,@".json"];
        NSLog(@"filePath %@", filePath);
        
        NSError *error;
        [stringToSend writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (![[NSFileManager defaultManager] isWritableFileAtPath:filePath])
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Unable to save rich push notification in file for sendig.");
        }
        
        if ([filePath length] > 0 && [dataToPush count] > 0)
            [self pushData:filePath sendingRich:YES messageID:message.messageID];
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Dictionary with push data is not valid. Push notification is not sent.");
        }
    }
    [self.apnsHisotry setObject:[NSDate date] forKey:[message.contact getPeerURI]];
}

- (void) sendRichPushNotificationForMessage:(HOPMessage*) message missedCall:(BOOL) missedCall participantsPeerURIs:(NSArray*) participantsPeerURIs
{
    NSArray* deviceTokens = [self getDeviceTokensForContact2:message.contact];
    
    if ([deviceTokens count] > 0)
    {
        [self sendRichPush:message deviceTokens:deviceTokens participantPeerURIs:participantsPeerURIs];
    }
    else
    {
        [self requestDeviceTokenForPeerURI:[message.contact getPeerURI]];
        @synchronized(self.dictionaryOfPushNotificationsToSend)
        {
            NSArray* array = [self.dictionaryOfPushNotificationsToSend objectForKey:[message.contact getPeerURI]];
            NSMutableArray* messages = array.count > 0 ? [NSMutableArray arrayWithArray:array] : [NSMutableArray new];
            NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", participantsPeerURIs, @"participantsPeerURIs", nil];
            if (dict.count > 0)
                [messages addObject:dict];
            [self.dictionaryOfPushNotificationsToSend setObject:messages forKey:[message.contact getPeerURI]];
        }
    }
}

- (NSString*) prepareMessageForRichPush:(HOPMessage*) message peerURI:(NSString*) peerURI location:(NSString*) location  participantPeerURIs:(NSArray*) participantPeerURIs
{
    NSString*  peerURIs = @"";
    NSMutableArray* array  = [NSMutableArray arrayWithArray:participantPeerURIs];
    [array addObject:[[HOPModelManager sharedModelManager]getPeerURIForHomeUser]];
    [array removeObject:[message.contact getPeerURI]];
    for (NSString* tempPeerURI in array)
    {
        if (![tempPeerURI isEqualToString:peerURI])
            peerURIs = [peerURIs stringByAppendingString: peerURIs.length > 0 ? [NSString stringWithFormat:@",%@",tempPeerURI] : tempPeerURI];
            //peerURIs = [peerURIs stringByAppendingString: peerURIs.length > 0 ? [NSString stringWithFormat:@",%@",peerURI] : peerURI];
    }
    
    NSString* ret = [NSString stringWithFormat:@"{\\\"peerURI\\\":\\\"%@\\\",\\\"peerURIs\\\":\\\"%@\\\",\\\"messageId\\\":\\\"%@\\\",\\\"replacesMessageId\\\":\\\"%@\\\",\\\"message\\\":\\\"%@\\\",\\\"location\\\":\\\"%@\\\",\\\"date\\\":\\\"%.0f\\\"}",peerURI,peerURIs,message.messageID,message.replacesMessageID,message.text,location,[message.date timeIntervalSince1970]];

    return ret;
}


- (NSArray*) getDeviceTokensForContact2:(HOPRolodexContact*) contact
{
    NSArray* ret = nil;
    
    NSString* peerURI = [contact getPeerURI];
    if ([peerURI length] > 0)
    {
        if ([self canSendPushNotificationForPeerURI:peerURI])
        {
            ret = [[HOPModelManager sharedModelManager] getPushNotificationDataForPeerURI:peerURI];
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
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"URL session %@ has received auth challenge", session);
    
    if (challenge.previousFailureCount == 0)
    {
        NSURLCredentialPersistence persistence = NSURLCredentialPersistenceForSession;
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.urbanAirshipAppKey password:self.urbanAirshipAppSecret persistence:persistence];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else
    {
        // handle the fact that the previous attempt failed
        //NSLog(@"%s: challenge.error = %@", __FUNCTION__, challenge.error);
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
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"URL session %@ has received auth challenge for task %@", session, [task originalRequest]);
    
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
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Push notification response: %@", [task response]);
    
    if (!error)
    {
        NSString* messageID = [self.dictionaryOfMessageIDsForSending objectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
        if ([messageID length] > 0)
        {
            HOPMessageRecord* messageRecord = [[HOPModelManager sharedModelManager] getMessageRecordByID:messageID];
            if (messageRecord)
            {
                messageRecord.outgoingMessageStatus = HOPConversationThreadMessageDeliveryStateSent;
                
                HOPConversation* conversation = [messageRecord.session getConversation];
                if (conversation)
                {
                    [[HOPModelManager sharedModelManager] updateMessageStateForConversation:conversation lastDeliveryState:HOPConversationThreadMessageDeliveryStateSent];
                    
                    [[HOPModelManager sharedModelManager] saveContext];
                }
            }
        }
        NSError* fileError;
        NSString* filePath = [self.dictionaryOfSentFiles objectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
        if ([filePath length] > 0)
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&fileError];
            if (fileError)
            {
                OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Error occured while deleting sent file: %@", fileError);
            }
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Error occured while sending push notification: %@", error);
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
        
        NSString* json = nil;
        NSError* error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictRoot
                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (!jsonData)
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"JSON data serialization has failed with an error: %@", error);
        } else
        {
            json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        //HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-get" data:json post:YES];
        HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:[[Settings sharedSettings] getDeviceTokenDownloadURL] data:json post:YES];
        
        request.delegate = self;
        [self.dictionaryOfHTTPRequests setObject:request forKey:peerURI];
        
        if (![request startDownload])
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Device token retrievel request is not sent.");
            [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
        }
    }

}

- (void) registerDeviceToken
{
    NSString* peerURI = [[HOPModelManager sharedModelManager] getPeerURIForHomeUser];
    
    if ([self.deviceToken length] > 0 && [peerURI length] > 0 && ![[self.dictionaryOfHTTPRequests allKeys] containsObject:peerURI])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registering device token, %@, with Open Peer system",self.deviceToken);
        
        NSMutableDictionary* dictRoot = [[NSMutableDictionary alloc] init];
        NSMutableDictionary* dictData  = [[NSMutableDictionary alloc] init];
        
        [dictData setObject:[[Settings sharedSettings] getIdentityProviderDomain]  forKey:@"$domain"];
        [dictData setObject:[[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyAppId]  forKey:@"$appid"];
        [dictData setObject:[HOPUtility getGUIDstring]  forKey:@"$id"];
        [dictData setObject:@"push-hack" forKey:@"$handler"];
        [dictData setObject:@"device-associate-set" forKey:@"$method"];
        [dictData setObject:@"apns" forKey:@"type"];
        [dictData setObject:peerURI forKey:@"uri"];
        [dictData setObject:self.deviceToken forKey:@"deviceToken"];

        [dictRoot setObject:dictData forKey:@"request"];
        
        NSString* json = nil;
        NSError* error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictRoot
                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (!jsonData)
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"JSON data serialization has failed with an error: %@", error);
        } else
        {
            json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        //HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-set" data:json post:YES];
        HTTPDownloader* request = [[HTTPDownloader alloc] initDownloadFromURL:[[Settings sharedSettings] getDeviceTokenUploadURL] data:json post:YES];
        
        request.delegate = self;
        [self.dictionaryOfHTTPRequests setObject:request forKey:peerURI];
        
        if (![request startDownload])
        {
            [self.dictionaryOfHTTPRequests removeObjectForKey:peerURI];
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Device token, %@, registration request is not sent via %@.",self.deviceToken,@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-set");
        }
        else
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registering device token, %@, JSON: /n is sent via %@.",self.deviceToken,json,@"http://push-hack.hcs-stack-v2-i7957106-7.hcs.io/device-associate-set");
        }
    }
}

#pragma mark - HTTPDownloaderDelegate

- (void) httpDownloader:(HTTPDownloader*) downloader downloaded:(NSString*) downloaded
{
    NSDictionary* responseDictionary = nil;

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
        SBJsonParser* parser = [[SBJsonParser alloc] init];
        responseDictionary = [parser objectWithString: downloaded];
        if ([responseDictionary count] > 0)
        {
            NSDictionary* result = [responseDictionary objectForKey:@"result"];
            if ([result count] > 0)
            {
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received valid response.");
                if (![peerURI isEqualToString:[[HOPModelManager sharedModelManager] getPeerURIForHomeUser]])
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
                            NSArray* messages = nil;
                            @synchronized(self.dictionaryOfPushNotificationsToSend)
                            {
                                if (peerURI.length > 0)
                                {
                                    if ([self.dictionaryOfPushNotificationsToSend objectForKey:peerURI])
                                        messages = [NSMutableArray arrayWithArray:[self.dictionaryOfPushNotificationsToSend objectForKey:peerURI]];
                                    [self.dictionaryOfPushNotificationsToSend removeObjectForKey:peerURI];
                                }
                            }

                            for (NSDictionary * dict in messages)
                            {
                                HOPMessage* msg = [dict objectForKey:@"message"];
                                NSArray* peerURIs = [dict objectForKey:@"participantsPeerURIs"];
                                if (msg)
                                {
                                    NSArray* deviceTokens = [self getDeviceTokensForContact2:msg.contact];
                                    [self sendRichPush:msg deviceTokens:deviceTokens participantPeerURIs:peerURIs];
                                }
                            }

                            //NSDictionary* dict = [self.dictionaryOfPushNotificationsToSend objectForKey:peerURI];
//                            HOPMessage* msg = [dict objectForKey:@"message"];//[self.dictionaryOfPushNotificationsToSend objectForKey:peerURI];
//                            NSArray* peerURIs = [dict objectForKey:@"participantsPeerURIs"];
//                            if (msg)
//                            {
//                                NSArray* deviceTokens = [self getDeviceTokensForContact2:msg.contact];
//                                [self sendRichPush:msg deviceTokens:deviceTokens participantPeerURIs:peerURIs];
//                            }
//                            [self.dictionaryOfPushNotificationsToSend removeObjectForKey:peerURI];
                        }
                        
                    }
                }
                else
                {
                    [[HOPModelManager sharedModelManager] setAPNSData:self.deviceToken type:notificationTypeApple PeerURI: [[HOPModelManager sharedModelManager] getPeerURIForHomeUser]];
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
@end
