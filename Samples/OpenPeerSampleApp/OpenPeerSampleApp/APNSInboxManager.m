/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "APNSInboxManager.h"
#import "UAInbox.h"
#import "UAInboxMessageList.h"
#import "UAInboxMessage.h"
#import "HTTPDownloader.h"
#import "UAUtils.h"
#import "SBJsonParser.h"
#import "SessionManager.h"
#import "LoginManager.h"
#import "Session.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "Utility.h"
#import <OpenpeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPContact.h>
#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPConversationThread.h>
#import <OpenpeerSDK/HOPPublicPeerFile.h>
#import <OpenpeerSDK/HOPOpenPeerContact.h>

@interface APNSInboxManager ()

@property (strong, nonatomic) NSMutableArray* arrayMessageDownloaders;
@property (strong, nonatomic) NSMutableArray* arrayRichPushMessages;
@end

@implementation APNSInboxManager

+ (id) sharedAPNSInboxManager
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
        self.arrayMessageDownloaders = [[NSMutableArray alloc] init];
        //self.arrayRichPushMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setup
{
    [UAInbox shared].pushHandler.delegate = self;
    [UAPush shared].pushNotificationDelegate = self;
}

- (void) handleNewMessages
{
    if ([[LoginManager sharedLoginManager] isUserFullyLoggedIn])
    {
        if ([self.localNotificationDictionary count] > 0)
            [self createMessageFromRichPushDict:self.localNotificationDictionary];
        
        for (UAInboxMessage* message in self.arrayRichPushMessages)
            [self loadMessage:message];
    }
}

- (void)loadMessage:(UAInboxMessage*) inboxMessage
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Start downloading content for rich push message %@",inboxMessage.messageID);
    HTTPDownloader* downloader = [[HTTPDownloader alloc] initSettingsDownloadFromURL:inboxMessage.messageBodyURL.absoluteString postDate:nil auth:[UAUtils userAuthHeaderString]];
    downloader.delegate = self;
    [downloader startDownload];
    [self.arrayMessageDownloaders addObject:downloader];
}

#pragma mark - UAInboxPushHandlerDelegate
- (void)richPushNotificationArrived:(NSDictionary *)notification
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received rich push notification id:%@",[notification objectForKey:@"_uamaid"]);
}

- (void)applicationLaunchedWithRichPushNotification:(NSDictionary *)notification
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Apllication launched with rich push notification id:%@",[notification objectForKey:@"_uamaid"]);
}


- (void)richPushMessageAvailable:(UAInboxMessage *)richPushMessage
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push message is available id:%@",richPushMessage.messageID);
    if ([[HOPAccount sharedAccount] isCoreAccountCreated] && [[HOPAccount sharedAccount] getState].state == HOPAccountStateReady)
        [self loadMessage:richPushMessage];
    else
        [self.arrayRichPushMessages addObject:richPushMessage];
}


- (void)launchRichPushMessageAvailable:(UAInboxMessage *)richPushMessage
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Launch rich push message is available id:%@",richPushMessage.messageID);
    if ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady)
        [self loadMessage:richPushMessage];
    else
        [self.arrayRichPushMessages addObject:richPushMessage];
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
    
    if ([locationID length] > 0)
        [contact hintAboutLocation:locationID];
}


- (void)createMessageFromRichPushDict:(NSDictionary *)richPushDictionary
{
    if ([richPushDictionary count] > 0)
    {
        NSString* senderPeerURI = [richPushDictionary objectForKey:@"peerURI"];
        if ([senderPeerURI length] > 0)
        {
            HOPOpenPeerContact* contact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:senderPeerURI];
            if (contact)
            {
                Session* session = [[SessionManager sharedSessionManager] getSessionForContacts:@[contact]];
                if (!session)
                    session = [[SessionManager sharedSessionManager]createSessionForContacts:@[contact]];
                
                NSString* messageID = [richPushDictionary objectForKey:@"messageId"];
                NSString* messageText = [richPushDictionary objectForKey:@"message"];
                NSString* location = [richPushDictionary objectForKey:@"location"];
                NSNumber* timeInterval = [richPushDictionary objectForKey:@"date"];
                NSString* replacesMessageID = [richPushDictionary objectForKey:@"replacesMessageId"];
                
                NSDate* date = [NSDate dateWithTimeIntervalSince1970:timeInterval.doubleValue];
                
                if ([messageID length] > 0 && ([messageText length] > 0 || [replacesMessageID length] > 0)  && date)
                {
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content \"%@\" for message %@ is ready.",messageText,messageID);
                    
                    HOPPublicPeerFile* publicPerFile = [[HOPModelManager sharedModelManager] getPublicPeerFileForPeerURI:senderPeerURI];
                    HOPContact* coreContact = [[HOPContact alloc] initWithPeerFile:publicPerFile.peerFile];
                    if ([location length] > 0)
                    {
                        [coreContact hintAboutLocation:location];
                        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push hit location");
                    }
                    else
                    {
                        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Local notification withut location is hit");
                    }
                    
                    
                    if ([replacesMessageID length] > 0)
                    {
                        [[HOPModelManager sharedModelManager] replaceMessageWithID:replacesMessageID newMessageID:messageID messageText:messageText];
                    }
                    else
                    {
                        HOPMessageRecord* messageObj = [[HOPModelManager sharedModelManager] addMessage:messageText type:messageTypeText date:date session:[session.conversationThread getThreadId] openPeerContact:contact messageId:messageID conversationEvent:session.lastConversationEvent];
                        
                        
                        if (messageObj)
                        {
                            [session.unreadMessageArray addObject:messageObj];
                            
                            //If session view controller with message sender is not yet shown, show it
                            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:YES];
                        }
                        else
                        {
                            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message is not saved - message id %@ - session id %@ - date %@",messageText,messageID,[session.conversationThread getThreadId],date);
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

#pragma mark - UAPushNotificationDelegate
/**
 * Called when an alert notification is received in the foreground.
 * @param alertMessage a simple string to be displayed as an alert
 */
- (void)displayNotificationAlert:(NSString *)alertMessage
{
    
}

/**
 * Called when an alert notification is received in the foreground with additional localization info.
 * @param alertDict a dictionary containing the alert and localization info
 */
- (void)displayLocalizedNotificationAlert:(NSDictionary *)alertDict
{
    
}

/**
 * Called when a push notification is received in the foreground with a sound associated
 * @param soundFilename The sound file to play or `default` for the standard notification sound.
 *        This file must be included in the application bundle.
 */
- (void)playNotificationSound:(NSString *)soundFilename
{
    
}


/**
 * Called when a push notification is received in the foreground with a badge number.
 * @param badgeNumber The badge number to display
 */
- (void)handleBadgeUpdate:(NSInteger)badgeNumber
{
    
}

/**
 * Called when a push notification is received while the app is running in the foreground.
 *
 * @param notification The notification dictionary.
 */
- (void)receivedForegroundNotification:(NSDictionary *)notification
{
    
}


/**
 * Called when a push notification is received while the app is running in the foreground
 * for applications with the "remote-notification" background mode.
 *
 * @param notification The notification dictionary.
 * @param completionHandler Should be called with a UIBackgroundFetchResult as soon as possible, so the system can accurately estimate its power and data cost.
 */
- (void)receivedForegroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{

}


/**
 * Called when a push notification is received while the app is running in the background.
 *
 * @param notification The notification dictionary.
 */
- (void)receivedBackgroundNotification:(NSDictionary *)notification
{

}


/**
 * Called when the app is started or resumed because a user opened a notification.
 *
 * @param notification The notification dictionary.
 */
- (void)launchedFromNotification:(NSDictionary *)notification
{
    
}


#pragma mark - HTTPDownloaderDelegate
- (void) httpDownloader:(HTTPDownloader*) downloader downloaded:(NSString*) downloaded
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content is downloaded");
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* richPushDictionary = [parser objectWithString: downloaded];
    
    [self createMessageFromRichPushDict:richPushDictionary];
    
    return;
}
- (void) httpDownloader:(HTTPDownloader *) downloader didFailWithError:(NSError *)error
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content download has failed.");
    return;
}

- (void)getAllMessages
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Get all messages from the UA inbox.");
    [[UAInbox shared].messageList retrieveMessageListWithDelegate:self];
}

/**
 * Tells the delegate that a request for inbox messages succeeded.
 */
- (void)messageListLoadSucceeded
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push message list load succeeded.");
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    NSMutableArray* arrayOfMessages = [UAInbox shared].messageList.messages;
    int counter = 0;
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Numbe of reach push messages is %d",[arrayOfMessages count]);
    
    for (UAInboxMessage* message in arrayOfMessages)
    {
        [message markAsReadWithDelegate:self];
        [set addIndex:counter];
        
        if ([message unread])
            [self loadMessage:message];
        else
        {
            
        }
        //[self launchRichPushMessageAvailable:message];
        counter++;
    }
    
    UADisposable *disposable = [[UAInbox shared].messageList performBatchUpdateCommand:UABatchDeleteMessages withMessageIndexSet:set withDelegate:self];
    
    if (disposable)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push inbox is cleaned");
    }
}
/**
 * Tells the delegate that a request for inbox messages failed.
 */
- (void)messageListLoadFailed
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Loading rich push inbox has failed");
}

/**
 * Tells the delegate that a message has been marked as read.
 *
 * @param message The message marked as read
 */
- (void)singleMessageMarkAsReadFinished:(UAInboxMessage *)message
{
    
}

/**
 * Tells the delegate that a mark-as-read request failed.
 *
 * @param message The message that failed to update
 */
- (void)singleMessageMarkAsReadFailed:(UAInboxMessage *)message
{
    
}

/**
 * Tells the delegate that a batch of messages has been marked as read.
 */
- (void)batchMarkAsReadFinished
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Reading rich push messages has successfully finished");
    int numberOfMessages = [[UAInbox shared].messageList unreadCount];
    if ( numberOfMessages > 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"There is %d unread rich push %@",numberOfMessages, (numberOfMessages == 1 ? @"message" : @"messages"));
    }
}

/**
 * Tells the delegate that a batch mark-as-read request failed.
 */
- (void)batchMarkAsReadFailed
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Reading rich push messages has failed");
    int numberOfMessages = [[UAInbox shared].messageList unreadCount];
    if ( numberOfMessages > 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"There is %d unread rich push %@",numberOfMessages, (numberOfMessages == 1 ? @"message" : @"messages"));
    }
}

/**
 * Tells the delegate that a batch of messages has been deleted.
 */
- (void)batchDeleteFinished
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Deleting rich push messages has successfully finished");
    int numberOfMessages = [[UAInbox shared].messageList messageCount];
    if ( numberOfMessages > 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"After delete there is %d rich push %@",numberOfMessages, (numberOfMessages == 1 ? @"message" : @"messages"));
    }
    
}

/**
 * Tells the delegate that a batch update of messages has failed.
 */
- (void)batchDeleteFailed
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Deleting rich push messages has failed");
}

- (void)handleNotification:(NSDictionary *)notification applicationState:(UIApplicationState)state
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received push notification with notification:%@", notification);
}


@end
