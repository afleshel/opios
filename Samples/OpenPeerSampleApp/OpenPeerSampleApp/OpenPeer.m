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

#import "OpenPeer.h"
#import "Utility.h"
#import "AppConsts.h"
#import "Logger.h"
#import "Settings.h"
//SDK
#import "OpenpeerSDK/HOPStack.h"
#import "OpenpeerSDK/HOPLogger.h"
#import "OpenpeerSDK/HOPMediaEngine.h"
#import "OpenpeerSDK/HOPCache.h"
#import "OpenpeerSDK/HOPModelManager.h"
#import "OpenpeerSDK/HOPSettings.h"
#import "OpenpeerSDK/HOPAccount.h"
#import "OpenpeerSDK/HOPBackgrounding.h"
//Managers
#import "LoginManager.h"
#import "SessionManager.h"
#import "OfflineManager.h"
//Delegates
#import "StackDelegate.h"
#import "MediaEngineDelegate.h"
#import "ConversationDelegate.h"
#import "CallDelegate.h"
#import "AccountDelegate.h"
#import "IdentityDelegate.h"
#import "IdentityLookupDelegate.h"
#import "CacheDelegate.h"
#import "BackgroundingDelegate.h"
//View controllers
#import "MainViewController.h"
//#import "HTTPDownloader.h"

#import "UIDevice+Networking.h"

//Private methods
@interface OpenPeer ()

@property (nonatomic, strong) HTTPDownloader* settingsDownloadeer;
- (void) createDelegates;
@end


@implementation OpenPeer

/**
 Retrieves singleton object of the Open Peer.
 @return Singleton object of the Open Peer.
 */
+ (id) sharedOpenPeer
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (NSString*) authorizedApplicationId
{
    if (!_authorizedApplicationId)
    {
        NSDate* expiry = [[NSDate date] dateByAddingTimeInterval:(30 * 24 * 60 * 60)];
        
        _authorizedApplicationId = [HOPStack createAuthorizedApplicationID:[[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyAppId] applicationIDSharedSecret:[[NSUserDefaults standardUserDefaults] stringForKey: settingsKeyAppIdSharedSecret] expires:expiry];
    }
    return _authorizedApplicationId;
}


- (void) refreshAuthorizedApplicationId
{
    self.authorizedApplicationId = nil;
    [[HOPSettings sharedSettings] storeAuthorizedApplicationId:[self authorizedApplicationId]];
}


- (void) preSetup
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Pre setup");
    
    //Create all delegates required for communication with core
    [self createDelegates];
    
    //Set log levels and start logging
    [Logger startAllSelectedLoggers];
    
    //Cleare expired cookies and set delegate
    [[HOPCache sharedCache] removeExpiredCookies];
    [[HOPCache sharedCache] setup];
    
    if ([UIDevice isNetworkReachable])
    {
        //Set persistent stores
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        NSString *dataPathDirectory = [libraryPath stringByAppendingPathComponent:@"db"];
        
        [[HOPModelManager sharedModelManager] setDataPath:dataPathDirectory backupData:NO];
     
        //Set settigns delegate
        [[HOPSettings sharedSettings] setup];
        
        if ([Utility isRuningForTheFirstTime])
            [[HOPSettings sharedSettings] applyDefaults];
        
        BOOL startedDownloadingSettings = [[Settings sharedSettings] updateAppSettings];
        
        if (![HOPAccount isReloginPossible])
        {
            //Start settings download. If download is not started finish presetup
            if (!startedDownloadingSettings)
                [self finishPreSetup];
        }
        else
        {
            //Start settings download. If download is not started finish setup
            if (!startedDownloadingSettings)
                [self setup];
        }
    }
    else
        [[OfflineManager sharedOfflineManager]showInfoAboutNetworkProblem];
}

- (void) finishPreSetup
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Pre setup finished");
    
    if (![HOPAccount isReloginPossible])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"There is no logged in user");
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey: settingsKeyQRScannerShownAtStart])
            [[self mainViewController] showQRScanner]; //Show QR scanner if user wants to change settings by reading QR code
        else if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeySplashScreenAllowsQRScannerGesture])
            [[self mainViewController] waitForUserGesture];
        else
            [self setup];
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Starting setup for logged in user");
        [self setup];
    }
}

/**
 Initializes the open peer stack. After initialization succeeds, login screen is displayed, or user relogin started.
 @param inMainViewController MainViewController Input main view controller.
 */
- (void) setup
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Started setup");

    [self refreshAuthorizedApplicationId];
    
    long secondsTillExpire = [HOPStack getExpiryForAuthorizedApplicationID:[[HOPSettings sharedSettings] getAuthorizedApplicationId]];
    [NSTimer scheduledTimerWithTimeInterval:secondsTillExpire target:self selector:@selector(refreshAuthorizedApplicationId) userInfo:nil repeats:NO];
#ifdef DEBUG
    NSArray* missingFields = [[Settings sharedSettings] getMissingAppSettings];
    
    if ([missingFields count] > 0)
    {
        NSString* strMissingFields = @"";
        for (NSString* str in missingFields)
        {
            if ([strMissingFields length] == 0)
                strMissingFields = str;
            else
                strMissingFields = [strMissingFields stringByAppendingFormat:@", %@",str];
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Application settings are missing!" message:[NSString stringWithFormat:@"Please set following fields in CustomerSpecific.plist file: %@",strMissingFields] delegate:self cancelButtonTitle:@"I swear, I will enter valid data" otherButtonTitles: nil];
        
        [alert show];
        NSLog(@"Application settings are not set. Please set all required fileds in CustomerSpecific.plist file!");
        return;
    }
#endif
    //Run logger again if some of logger settings are changed during settings initialization
    [Logger startAllSelectedLoggers];

    [[HOPBackgrounding sharedBackgrounding] subscribeDelegate:self.backgroundingDelegate phase:((NSNumber*)[[NSUserDefaults standardUserDefaults]objectForKey:settingsKeyBackgroundingPhaseRichPush]).unsignedLongValue];
    if (![[HOPStack sharedStack] isStackReady])
    {
        //Init openpeer stack and set created delegates
        [[HOPStack sharedStack] setupWithStackDelegate:self.stackDelegate mediaEngineDelegate:self.mediaEngineDelegate];
    }
    
    //Start with login procedure and display login view
    [[LoginManager sharedLoginManager] login];
    
    [[HOPMediaEngine sharedInstance] setEcEnabled:[[Settings sharedSettings] isMediaAECOn]];
    [[HOPMediaEngine sharedInstance] setAgcEnabled:[[Settings sharedSettings] isMediaAGCOn]];
    [[HOPMediaEngine sharedInstance] setNsEnabled:[[Settings sharedSettings] isMediaNSOn]];
}

- (void) shutdown
{
    [[HOPStack sharedStack] shutdown];
    
    self.stackDelegate = nil;
    self.mediaEngineDelegate = nil;
    self.conversationDelegate = nil;
    self.callDelegate = nil;
    self.accountDelegate = nil;
    self.identityDelegate = nil;
    self.identityLookupDelegate = nil;
    self.backgroundingDelegate = nil;
}
/**
 Method used for all delegates creation. Delegates will catch events from the Open Peer SDK and handle them properly.
 */
- (void) createDelegates
{
    self.stackDelegate = [[StackDelegate alloc] init];
    self.mediaEngineDelegate = [[MediaEngineDelegate alloc] init];
    self.conversationDelegate = [[ConversationDelegate alloc] init];
    self.callDelegate = [[CallDelegate alloc] init];
    self.accountDelegate = [[AccountDelegate alloc] init];
    self.identityDelegate = [[IdentityDelegate alloc] init];
    self.identityDelegate.loginDelegate = self.mainViewController;
    self.identityLookupDelegate = [[IdentityLookupDelegate alloc] init];
    self.backgroundingDelegate = [[BackgroundingDelegate alloc] init];
}

- (void) closeTheApp
{
    exit(-1);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Closing Application" message:@"Application will be closed in 2 seconds" delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    
    [alert show];
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(closeTheApp) userInfo:nil repeats:NO];
}


- (void) shutdownCleanup
{
    [[SessionManager sharedSessionManager] stopAnyActiveCall];
    [[LoginManager sharedLoginManager] clearIdentities];
    [[HOPAccount sharedAccount] shutdown];
    [self shutdown];
    
}

- (void) prepareAppForBackground
{
    if ([[HOPStack sharedStack] isStackReady])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Preparing app for the background");
        UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
        
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                  {
                      [[HOPBackgrounding sharedBackgrounding]notifyGoingToBackgroundNow];
                      
                      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                  }];
        
        [[OpenPeer sharedOpenPeer] setBackgroundingTaskId:bgTask];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           [[HOPBackgrounding sharedBackgrounding] notifyGoingToBackground:[[OpenPeer sharedOpenPeer] backgroundingDelegate]];
                       });
    }
}

@end

