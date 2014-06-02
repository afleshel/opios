/*
 
 Copyright (c) 2012, SMB Phone Inc.
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

#import "AppDelegate.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "LoginManager.h"
#import "Utility.h"
#import <OpenPeerSDK/HOPBackgrounding.h>
#import "BackgroundingDelegate.h"
#import "SessionManager.h"
#import "OfflineManager.h"
#import "Logger.h"
#ifdef APNS_ENABLED
#import "APNSManager.h"
#import "APNSInboxManager.h"
#import "UAInboxPushHandler.h"
#import "UAPush.h"
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //Create root view controller. This view controller will manage displaying all other view controllers.
    MainViewController* mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window setRootViewController:mainViewController];
    
    [self.window makeKeyAndVisible];

    [[OfflineManager sharedOfflineManager]  startNetworkMonitor];
    
    [[OpenPeer sharedOpenPeer] setMainViewController:mainViewController];
    [[OpenPeer sharedOpenPeer] preSetup];
    

#ifdef APNS_ENABLED
    [[APNSManager sharedAPNSManager] prepareUrbanAirShip];
    NSDictionary *apnsInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    
    if ([apnsInfo count] > 0)
    {
        [[APNSInboxManager sharedAPNSInboxManager] handleAPNS:apnsInfo];
    }
    else
    {
        NSDictionary *localInfo = [launchOptions valueForKey:localNotificationKey];
        if ([localInfo count] > 0)
            [[APNSInboxManager sharedAPNSInboxManager] setLocalNotificationDictionary:localInfo];
    }
#endif
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Application did enter background.");
    
    [[OpenPeer sharedOpenPeer] setAppEnteredBackground:YES];
    [[OpenPeer sharedOpenPeer] setAppEnteredForeground:NO];
    
    if (![[SessionManager sharedSessionManager] isCallInProgress])
    {
        [[OpenPeer sharedOpenPeer]prepareAppForBackground];
    }
    
    //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#ifdef APNS_ENABLED
    [[UAPush shared] setBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Application will enter foreground.");
    [Logger startAllSelectedLoggers];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ( [[OpenPeer sharedOpenPeer] appEnteredBackground])
    {
        [[OpenPeer sharedOpenPeer] setAppEnteredForeground:YES];
        [[OpenPeer sharedOpenPeer] setAppEnteredBackground:NO];
        
        [[HOPBackgrounding sharedBackgrounding]notifyReturningFromBackground];
    }
#ifdef APNS_ENABLED
    [[APNSInboxManager sharedAPNSInboxManager] getAllMessages];
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#ifdef APNS_ENABLED
    [[UAPush shared] setBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#endif
    [[OpenPeer sharedOpenPeer] shutdownCleanup];
}

#ifdef APNS_ENABLED
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (deviceToken)
    {
        NSString* hexString = [Utility hexadecimalStringForData:deviceToken];
        
        if ([hexString length] > 0)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Push notification deviceToken:%@",hexString);

            [[APNSManager sharedAPNSManager] registerDeviceToken:deviceToken];
            [[APNSManager sharedAPNSManager] setDeviceToken:hexString];
            [[OpenPeer sharedOpenPeer] setDeviceToken:hexString];
        }
        else
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Failed device token conversion to hexadecimal string");
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Device token is invalid.");
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Error in registration. Error: %@", err.description);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received push notification with userInfo:%@", userInfo);
    NSDictionary *apnsInfo = [userInfo valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    
    if ([apnsInfo count] > 0)
    {
        [[APNSInboxManager sharedAPNSInboxManager] handleAPNS:apnsInfo];
    }
}

/*- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Notify UAInbox to fetch any new messages if the notification contains a rich application page id.
    if (application.applicationState != UIApplicationStateBackground)
    {
        [UAInboxPushHandler handleNotification:userInfo];
    }
    
    // Notify UAPush that a push came in with the completion handler
//    [[UAPush shared] handleNotification:userInfo applicationState:application.applicationState fetchCompletionHandler:completionHandler];
}*/

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    
}

- (void)handleNotification:(NSDictionary *)notification applicationState:(UIApplicationState)state
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received push notification with notification:%@", notification);
}

#endif
@end
