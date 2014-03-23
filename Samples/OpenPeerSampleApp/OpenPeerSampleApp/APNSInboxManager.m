//
//  APNSInboxManager.m
//  OpenPeerSampleApp
//
//  Created by Sergej on 3/19/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

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
        self.arrayRichPushMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setup
{
    [UAInbox shared].pushHandler.delegate = self;
    //[UAPush shared].pushNotificationDelegate = self;
}

- (void) handleNewMessages
{
    if ([[LoginManager sharedLoginManager] isUserFullyLoggedIn])
    {
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
    if ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady)
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
    [contact hintAboutLocation:locationID];
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
    [UAInboxPushHandler handleNotification:notification];
    completionHandler(UIBackgroundFetchResultNoData);
}

/**
 * Called when a push notification is received while the app is running in the background
 * for applications with the "remote-notification" background mode.
 *
 * @param notification The notification dictionary.
 * @param completionHandler Should be called with a UIBackgroundFetchResult as soon as possible, so the system can accurately estimate its power and data cost.
 */
//- (void)receivedBackgroundNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
//{
//    completionHandler(UIBackgroundFetchResultNoData);
//}

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
    
    [UAInboxPushHandler handleNotification:notification];
}


/**
 * Called when the app is started or resumed because a user opened a notification
 * for applications with the "remote-notification" background mode.
 *
 * @param notification The notification dictionary.
 * @param completionHandler Should be called with a UIBackgroundFetchResult as soon as possible, so the system can accurately estimate its power and data cost.
 */
//- (void)launchedFromNotification:(NSDictionary *)notification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
//{
//    completionHandler(UIBackgroundFetchResultNoData);
//}

#pragma mark - HTTPDownloaderDelegate
- (void) httpDownloader:(HTTPDownloader*) downloader downloaded:(NSString*) downloaded
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content is downloaded");
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* richPushDictionary = [parser objectWithString: downloaded];
    
    if ([richPushDictionary count] > 0)
    {
        NSString* senderPeerURI = [richPushDictionary objectForKey:@"peerURI"];
        if ([senderPeerURI length] > 0)
        {
            NSArray* rolodexContacts = [[HOPModelManager sharedModelManager]  getRolodexContactsByPeerURI:senderPeerURI];
            HOPRolodexContact* contact = nil;
            
            if ([rolodexContacts count] > 0)
                contact = [rolodexContacts objectAtIndex:0];
            
            if (contact)
            {
                Session* session = [[SessionManager sharedSessionManager] getSessionForContact:contact];
                if (!session)
                    session = [[SessionManager sharedSessionManager]createSessionForContact:contact];
                
                NSString* messageID = [richPushDictionary objectForKey:@"messageId"];
                NSString* messageText = [richPushDictionary objectForKey:@"message"];
                NSString* location = [richPushDictionary objectForKey:@"location"];
                NSNumber* timeInterval = [richPushDictionary objectForKey:@"date"];
                NSDate* date = [NSDate dateWithTimeIntervalSince1970:timeInterval.doubleValue];
                
                if ([messageID length] > 0 && [messageText length] > 0 && [location length] > 0 && date)
                {
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content for message %@ is ready.",messageID);
                    
                    HOPPublicPeerFile* publicPerFile = [[HOPModelManager sharedModelManager] getPublicPeerFileForPeerURI:senderPeerURI];
                    HOPContact* coreContact = [[HOPContact alloc] initWithPeerFile:publicPerFile.peerFile];
                    [coreContact hintAboutLocation:location];
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push hit location");

                    HOPMessageRecord* messageObj = [[HOPModelManager sharedModelManager] addMessage:messageText type:messageTypeText date:date session:[session.conversationThread getThreadId] rolodexContact:contact messageId:messageID];
                    
                    
                    if (messageObj)
                    {
                        [session.unreadMessageArray addObject:messageObj];
                        
                        //If session view controller with message sender is not yet shown, show it
                        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:YES];
                    }
                    else
                    {
                        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%@ message not saved - message id %@ - session id %@",messageID,[session.conversationThread getThreadId]);
                    }
                }
                else
                {
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content is corrupted");
                }
            }
        }
    }
    
    return;
}
- (void) httpDownloader:(HTTPDownloader *) downloader didFailWithError:(NSError *)error
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Rich push content download has failed.");
    return;
}
@end
