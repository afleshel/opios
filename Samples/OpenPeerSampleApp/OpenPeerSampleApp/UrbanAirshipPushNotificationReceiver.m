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

#import "UrbanAirshipPushNotificationReceiver.h"
#import "UAInbox.h"
#import "UAInboxMessageList.h"
#import "UAInboxMessage.h"
#import "UAUtils.h"
#import "SBJsonParser.h"
#import "HTTPDownloader.h"
#import <OpenPeerSDK/HOPAccount.h>
#import "LoginManager.h"

@interface UrbanAirshipPushNotificationReceiver ()

@property (strong, nonatomic) NSMutableArray* arrayMessageDownloaders;
@property (strong, nonatomic) NSMutableArray* arrayRichPushMessages;
@end

@implementation UrbanAirshipPushNotificationReceiver

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.arrayMessageDownloaders = [[NSMutableArray alloc] init];
        self.arrayRichPushMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) prepare
{
    [super prepare];
    [UAInbox shared].pushHandler.delegate = self;
    [UAPush shared].pushNotificationDelegate = self;
}

- (void)downloadAllMessages
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Get all messages from the UA inbox.");

     [[UAInbox shared].messageList retrieveMessageListWithSuccessBlock:^
     {
         [self messageListLoadSucceeded];
     }
     withFailureBlock:^
     {
         OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Loading rich push inbox has failed");
     }];
}

- (void) handleExistingMessages
{
    if ([[LoginManager sharedLoginManager] isUserFullyLoggedIn])
    {
//        if ([self.localNotificationDictionary count] > 0)
//            [self createMessageFromRichPushDict:self.localNotificationDictionary];
        
        for (UAInboxMessage* message in self.arrayRichPushMessages)
            [self loadMessage:message];
    }
}

/**
 * Tells the delegate that a request for inbox messages succeeded.
 */
- (void)messageListLoadSucceeded
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push message list load succeeded.");
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    NSArray* arrayOfMessages = [UAInbox shared].messageList.messages;
    int counter = 0;
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Numbe of reach push messages is %d",[arrayOfMessages count]);
    
    for (UAInboxMessage* message in arrayOfMessages)
    {
        //[message markAsReadWithDelegate:self];
        [message markMessageReadWithCompletionHandler:^(UAInboxMessage *message) {
            [self batchMarkAsReadFinished];
        }];
        
        [set addIndex:counter];
        
        if ([message unread])
            [self loadMessage:message];
        
        counter++;
    }
    
    
    UADisposable *disposable = [[UAInbox shared].messageList markMessagesDeleted:arrayOfMessages completionHandler:^{[self batchDeleteFinished];}];
    //UADisposable *disposable = [[UAInbox shared].messageList performBatchUpdateCommand:UABatchDeleteMessages withMessageIndexSet:set withDelegate:self];
    
    if (disposable)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push inbox is cleaned");
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

#pragma mark - UAInboxMessageListDelegate
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

- (void) setBadgeNumber:(NSInteger) numberOfUnreadMessages
{
    [[UAPush shared] setBadgeNumber:numberOfUnreadMessages];
}
@end
