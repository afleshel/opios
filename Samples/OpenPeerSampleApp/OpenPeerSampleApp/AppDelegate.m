/*
 
 Copyright (c) 2015, Hookflash Inc.
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
#import <OpenPeerSDK/HOPBackgrounding.h>
#import <OpenPeerSDK/HOPStack.h>
#import <OpenPeerSDK/HOPAccount.h>
#import "BackgroundingDelegate.h"
#import "SessionManager.h"
#import "OfflineManager.h"
#import "Logger.h"
#import "Utility.h"

#ifdef APNS_ENABLED
#import "APNSManager.h"
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
    NSDictionary *apnsInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    
    [[APNSManager sharedAPNSManager] prepare];
    
    if ([apnsInfo count] > 0)
    {
        [[APNSManager sharedAPNSManager] handleAPNS:apnsInfo];
    }
    
#endif
    return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if ([[HOPStack sharedStack] isStackReady])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Application did enter background.");
        
        [[OpenPeer sharedOpenPeer] setAppEnteredBackground:YES];
        [[OpenPeer sharedOpenPeer] setAppEnteredForeground:NO];
        
        if (![[SessionManager sharedSessionManager] isCallInProgress])
        {
            [[OpenPeer sharedOpenPeer]prepareAppForBackground];
        }
        
#ifdef APNS_ENABLED
        [[APNSManager sharedAPNSManager] setBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#endif
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if ([[HOPStack sharedStack] isStackReady])
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
        if ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady)
            [[APNSManager sharedAPNSManager] getAllMessages];
#endif
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Application did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
#ifdef APNS_ENABLED
    [[APNSManager sharedAPNSManager] setBadgeNumber:[[SessionManager sharedSessionManager] totalNumberOfUnreadMessages]];
#endif
    [[OpenPeer sharedOpenPeer] shutdownCleanup];
}

#ifdef APNS_ENABLED

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}
#endif

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (deviceToken)
    {
        [[APNSManager sharedAPNSManager] setDeviceToken:deviceToken];
        
        NSString* hexString = [Utility hexadecimalStringForData:deviceToken];
        
        if ([hexString length] > 0)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Registered push notification deviceToken:%@",hexString);

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
        [[APNSManager sharedAPNSManager] handleAPNS:apnsInfo];
    }
    else if ([userInfo count] > 0)
    {
        [[APNSManager sharedAPNSManager] handleAPNS:userInfo];
    }
    if ( [[HOPAccount sharedAccount] isAccountReady] && [[HOPAccount sharedAccount] getState].state == HOPAccountStateReady)
        [[APNSManager sharedAPNSManager] getAllMessages];
}

- (void)handleNotification:(NSDictionary *)notification applicationState:(UIApplicationState)state
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Received push notification with notification:%@", notification);
}

#endif
@end
