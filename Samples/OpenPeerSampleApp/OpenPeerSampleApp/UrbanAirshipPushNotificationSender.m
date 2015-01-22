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

#import "UrbanAirshipPushNotificationSender.h"

#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import <OpenPeerSDK/HOPConversationRecord+External.h>
#import <OpenPeerSDK/HOPRolodexContact+External.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAPNSData.h>
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "SBJsonParser.h"

@interface UrbanAirshipPushNotificationSender ()

@property (nonatomic, strong) NSURLSession *urlSession;
//@property (nonatomic, strong) NSURLSessionUploadTask *sessionDataTask;
@property (nonatomic, strong) NSURLConnection* urlConnection;

@property (nonatomic, strong) NSMutableDictionary* dictionarySessionTasks;

@property (nonatomic, strong) NSMutableDictionary* dictionaryOfPushNotificationsToSend;
@property (nonatomic, strong) NSMutableDictionary* dictionaryOfSentFiles;
@property (nonatomic, strong) NSMutableDictionary* dictionaryOfMessageIDsForSending;

@property (nonatomic, copy) NSString* tempJSON;

- (NSString*) saveRichPushForSending:(NSDictionary*) dict messageID:(NSString*) messageID;
- (void)storeForLaterSending:(HOPMessageRecord *)message missedCall:(BOOL)missedCall recipients:(NSArray *)recipients recipient:(HOPRolodexContact *)recipient;

- (void) pushData:(NSString*) filePath sendingRich:(BOOL) sendingRich messageID:(NSString*) messageID;
@end


@implementation UrbanAirshipPushNotificationSender

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dictionaryOfPushNotificationsToSend = [[NSMutableDictionary alloc] init];
        self.dictionaryOfSentFiles = [[NSMutableDictionary alloc] init];
        self.dictionaryOfMessageIDsForSending = [[NSMutableDictionary alloc] init];
        self.dictionarySessionTasks = [[NSMutableDictionary alloc] init];
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

- (void) prepare
{
    [super prepare];
    
    self.apiPushURL = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipAPIPushURL];
    
#ifdef DEBUG
    self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipDevelopmentAppKey];
    self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipMasterAppSecretDev];
#else
    self.urbanAirshipAppKey = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipProductionAppKey];
    self.urbanAirshipAppSecret = [[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyUrbanAirShipMasterAppSecret];
#endif
    
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
    
    // Set the icon badge to zero on startup (optional)
    [[UAPush shared] resetBadge];
}

- (void) registerDeviceToken:(NSData*) inDeviceToken peerURI:(NSString*) inPeerURI
{
    [super registerDeviceToken:inDeviceToken peerURI:inPeerURI];
    
    [[UAPush shared] appRegisteredForRemoteNotificationsWithDeviceToken:inDeviceToken];
}

- (void) sendPushNotificationMessage:(NSString*) message missedCall:(BOOL) missedCall recipients:(NSArray*) recipients
{
    NSDictionary *data = [self createPushMessage:message missedCall:missedCall recipients:recipients];
    
    if ([self.apiPushURL length] > 0)
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData * pushdata = [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
        NSURLSessionUploadTask* sessionDataTask = [self.urlSession uploadTaskWithRequest:request fromData:pushdata];
        if (sessionDataTask)
        {
            [self.dictionarySessionTasks setObject:sessionDataTask forKey:[NSNumber numberWithInt:sessionDataTask.taskIdentifier]];
            [sessionDataTask resume];
        }
        //[request setValue:@"application/vnd.urbanairship+json; version=3;" forHTTPHeaderField:@"Accept"];
        
//        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.apiPushURL]];
//        [request setHTTPMethod:@"POST"];
//        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//        
//        NSData * pushdata = [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
//        [request setHTTPBody:pushdata];
//        
//        [NSURLConnection connectionWithRequest:request delegate:self];
    }
}

- (void) sendRichPushNotificationMessage:(HOPMessageRecord*) message missedCall:(BOOL) missedCall recipients:(NSArray*) recipients
{
    for (HOPRolodexContact* recipient in recipients)
    {
        NSArray* deviceTokens = [self getDeviceTokensForContact:recipient];
        if ([deviceTokens count] > 0)
        {
            NSDictionary* dataToPush = [self createRichPushMessage:message recipient:recipient recipients:recipients];
            
            if (dataToPush.count > 0)
            {
                NSString* filePath = [self saveRichPushForSending:dataToPush messageID:message.messageID];
                
                if ([filePath length] > 0 && [dataToPush count] > 0)
                {
                    [self pushData:filePath sendingRich:YES messageID:message.messageID];
                }
                else
                {
                    OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Dictionary with push data is not valid. Push notification is not sent.");
                }
            }
        }
        else
        {
            NSString* peerURI = [recipient getPeerURI];
            if (peerURI.length > 0)
            {
                [self requestDeviceTokenForPeerURI:peerURI];
                @synchronized(self.dictionaryOfPushNotificationsToSend)
                {
                    [self storeForLaterSending:message missedCall:missedCall recipients:recipients recipient:recipient];
                }
            }
        }
    }
}

- (NSDictionary*) createRichPushMessage:(HOPMessageRecord*) message recipient:(HOPRolodexContact*) recipient recipients:(NSArray*) recipients
{
    NSDictionary* ret = nil;
    NSArray* deviceTokens = [self getDeviceTokensForContact:recipient];
    NSMutableArray* tempArray = [NSMutableArray arrayWithArray:recipients];
    [tempArray removeObject:recipient];
    NSString* peerURIs = [self getListOfRecipientsFromPeerURIsArray:tempArray];
    
    NSString* msg = [message.text length] > 22 ? [NSString stringWithFormat:@"%@...",[message.text substringToIndex:22]] : message.text;
    
    NSString* messageText  = [NSString stringWithFormat:@"%@  %@",[[HOPAccount sharedAccount] getFullName],msg];
    
    NSString* content = [NSString stringWithFormat:@"{\\\"peerURI\\\":\\\"%@\\\",\\\"peerURIs\\\":\\\"%@\\\",\\\"messageId\\\":\\\"%@\\\",\\\"replacesMessageId\\\":\\\"%@\\\",\\\"messageType\\\":\\\"%@\\\",\\\"message\\\":\\\"%@\\\",\\\"conversationId\\\":\\\"%@\\\",\\\"conversationType\\\":\\\"%@\\\",\\\"location\\\":\\\"%@\\\",\\\"date\\\":\\\"%.0f\\\"}",self.peerURI,peerURIs,message.messageID,message.replacedMessageID,message.type,message.text,message.session.sessionID,message.session.type,self.location,[message.date timeIntervalSince1970]];
    
    for (HOPAPNSData* pushNotificationData in deviceTokens)
    {
        NSString* stringToSend = nil;
        
        if ([pushNotificationData.type isEqualToString:notificationTypeApple])
            stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"device_token\" : \"%@\"}, \"device_types\" : [ \"ios\" ], \"notification\" : {\"ios\" : {\"sound\":\"message-received\",\"alert\": \"%@\",\"content-available\": true,\"priority\": 10}}, \"message\" : {\"title\" : \"%@\", \"body\" : \"%@\", \"content_type\" : \"text/html\"} }",pushNotificationData.deviceToken,messageText,messageText,content];
        else if ([pushNotificationData.type isEqualToString:notificationTypeAndroid])
            stringToSend = [NSString stringWithFormat:@"{\"audience\" : {\"apid\" : \"%@\"}, \"device_types\" : [ \"android\" ],  \"notification\" : {\"android\" : {\"extra\" : {\"date\": \"%.0f\",\"messageId\": \"%@\",\"location\": \"%@\",\"peerURI\": \"%@\",\"peerURIs\": \"%@\",\"messageType\": \"%@\",\"conversationId\": \"%@\", \"conversationType\": \"%@\"}}, \"alert\" : \"%@\"} }",pushNotificationData.deviceToken,[message.date timeIntervalSince1970],message.messageID,self.location,self.peerURI,peerURIs,message.type,message.session.sessionID,message.session.type,message.text];
        
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"Rich push content: %@",stringToSend);
        
        NSData *data = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
        ret = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        self.tempJSON = stringToSend;
    }
    
    return ret;
}

- (NSString*) saveRichPushForSending:(NSDictionary*) dict messageID:(NSString*) messageID
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@%@", documentsDirectory, messageID,@".json"];
    NSLog(@"filePath %@", filePath);
    
    NSError *error;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];

    
    [jsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (![[NSFileManager defaultManager] isWritableFileAtPath:filePath])
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Unable to save rich push notification in file for sendig.");
        return nil;
    }
    return filePath;
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
                NSURLSessionUploadTask* sessionDataTask = [self.urlSession uploadTaskWithRequest:request fromFile:fileURL];
                if (sessionDataTask)
                {
                    [sessionDataTask resume];
                    [self.dictionarySessionTasks setObject:sessionDataTask forKey:[NSNumber numberWithInt:sessionDataTask.taskIdentifier]];
                    [self.dictionaryOfSentFiles setObject:filePath forKey:[NSNumber numberWithInt:sessionDataTask.taskIdentifier]];
                    [self.dictionaryOfMessageIDsForSending setObject:messageID forKey:[NSNumber numberWithInt:sessionDataTask.taskIdentifier]];
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Started sending push notification");
                }
                else
                {
                    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Push notification is not sent, because session upload task is not created");
                }
                /*self.sessionDataTask = [self.urlSession uploadTaskWithRequest:request fromFile:fileURL];
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
                }*/
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

- (void)storeForLaterSending:(HOPMessageRecord *)message missedCall:(BOOL)missedCall recipients:(NSArray *)recipients recipient:(HOPRolodexContact *)recipient
{
    NSString* recipientPeerURI = [recipient getPeerURI];
    NSArray* array = [self.dictionaryOfPushNotificationsToSend objectForKey:recipientPeerURI];
    NSMutableArray* messages = array.count > 0 ? [NSMutableArray arrayWithArray:array] : [NSMutableArray new];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", recipient, @"recipient", recipients, @"recipients", [NSNumber numberWithBool:missedCall], @"missedCall", nil];
    if (dict.count > 0)
        [messages addObject:dict];
    [self.dictionaryOfPushNotificationsToSend setObject:messages forKey:recipientPeerURI];
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

#pragma  mark - NSURLSessionTaskDelegate
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
            [self.dictionaryOfSentFiles removeObjectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
            [self.dictionarySessionTasks removeObjectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
            [self.dictionaryOfMessageIDsForSending removeObjectForKey:[NSNumber numberWithInt:task.taskIdentifier]];
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Error occured while sending push notification: %@", error);
    }
    return;
}

- (void) onDeviceTokenReceivedForPeerURI:(NSString*) peerURI
{
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
        HOPMessageRecord* message = [dict objectForKey:@"message"];
        if (message)
        {
            BOOL missedCall = [dict objectForKey:@"missedCall"] != nil ? ((NSNumber*) [dict objectForKey:@"missedCall"]).boolValue : NO;
            NSArray* recipients = [dict objectForKey:@"recipients"];
            HOPRolodexContact* recipient = [dict objectForKey:@"recipient"];
            if (recipient)
            {
                if (missedCall)
                    [self sendPushNotificationMessage:message.text missedCall:YES recipients:recipients];
                else
                    [self sendRichPushNotificationMessage:message missedCall:NO recipients:recipients];
            }
        }
    }
}
@end
