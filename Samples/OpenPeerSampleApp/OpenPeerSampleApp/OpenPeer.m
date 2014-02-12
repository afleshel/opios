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
//Managers
#import "LoginManager.h"
//Delegates
#import "StackDelegate.h"
#import "MediaEngineDelegate.h"
#import "ConversationThreadDelegate.h"
#import "CallDelegate.h"
#import "AccountDelegate.h"
#import "IdentityDelegate.h"
#import "IdentityLookupDelegate.h"
#import "CacheDelegate.h"
//View controllers
#import "MainViewController.h"


//Private methods
@interface OpenPeer ()

- (void) createDelegates;
//- (void) setLogLevels;
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
        
        _authorizedApplicationId = [HOPStack createAuthorizedApplicationID:[[Settings sharedSettings] getString: @"applicationId"] applicationIDSharedSecret:[[Settings sharedSettings] getString: @"applicationIdSharedSecret"] expires:expiry];
    }
    return _authorizedApplicationId;
}

- (NSString*) deviceId
{
    if (!_deviceId)
    {
        _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:keyOpenPeerUser];
        if ([_deviceId length] == 0)
        {
            _deviceId = [Utility getGUIDstring];
            [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:keyOpenPeerUser];
        }
    }
    return _deviceId;
}

- (void) preSetup
{
    [self createDelegates];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPathDirectory = [libraryPath stringByAppendingPathComponent:@"db"];
    [[HOPModelManager sharedModelManager] setDataPath:dataPathDirectory backupData:NO];
    NSString *cachePathDirectory = [libraryPath stringByAppendingPathComponent:@"cache"];
    [[HOPModelManager sharedModelManager] setCachePath:cachePathDirectory];
    
    [[HOPSettings sharedSettings] setupWithDelegate:[Settings sharedSettings]];
    
    [[HOPCache sharedCache] removeExpiredCookies];
    //Init cache singleton
    [[HOPCache sharedCache] setDelegate:self.cacheDelegate];
    
    if (![[HOPModelManager sharedModelManager] getLastLoggedInHomeUser])
    {
        //If not already set, set default login settings
        BOOL isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
        if (!isSetLoginSettings)
        {
            [[HOPSettings sharedSettings] applyDefaults];
            
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"];
            if ([filePath length] > 0)
            {
                [[Settings sharedSettings] storeSettingsFromPath:filePath];
            }
            
            isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
        }
        
        //If not already set, set default app data
        BOOL isSetAppData = [[Settings sharedSettings] isAppDataSet];
        if (!isSetAppData)
        {
            NSString* filePath = [[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"];
            if ([filePath length] > 0)
            {
                [[Settings sharedSettings] storeSettingsFromPath:filePath];
            }
            isSetAppData = [[Settings sharedSettings] isAppDataSet];
        }
        
        //If some of must to have data is not set, notify the user
        if (!(isSetAppData && isSetLoginSettings))
        {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Local file with local settings is corrupted!"
                                                                message:@"Please try to scan QR code or reinstall the app."
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Ok",nil];
            [alertView show];
        }
        
        //Show QR scanner if user wants to change settings by reading QR code
        [[self mainViewController] showQRScanner];
    }
    else
    {
        [self setup];
    }
    
    //Set log levels and start logging
    [Logger startAllSelectedLoggers];
}

/**
 Initializes the open peer stack. After initialization succeeds, login screen is displayed, or user relogin started.
 @param inMainViewController MainViewController Input main view controller.
 */
- (void) setup
{
    /*//Created all delegates required for openpeer stack initialization.
    [self createDelegates];
    
    [[HOPCache sharedCache] removeExpiredCookies];
    //Init cache singleton
    [[HOPCache sharedCache] setDelegate:self.cacheDelegate];
    
    //Set log levels and start logging
    [Logger startAllSelectedLoggers];*/

    //Init openpeer stack and set created delegates
    [[HOPStack sharedStack] setupWithStackDelegate:self.stackDelegate mediaEngineDelegate:self.mediaEngineDelegate appID: self.authorizedApplicationId appName:[[Settings sharedSettings] getString: @"applicationName"] appImageURL:[[Settings sharedSettings] getString: @"applicationImageURL"]  appURL:[[Settings sharedSettings] getString: @"applicationURL"] userAgent:[Utility getUserAgentName] deviceID:self.deviceId deviceOs:[Utility getDeviceOs] system:[Utility getPlatform]];

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
    self.conversationThreadDelegate = nil;
    self.callDelegate = nil;
    self.accountDelegate = nil;
    self.identityDelegate = nil;
    self.identityLookupDelegate = nil;
    self.cacheDelegate = nil;
}
/**
 Method used for all delegates creation. Delegates will catch events from the Open Peer SDK and handle them properly.
 */
- (void) createDelegates
{
    self.stackDelegate = [[StackDelegate alloc] init];
    self.mediaEngineDelegate = [[MediaEngineDelegate alloc] init];
    self.conversationThreadDelegate = [[ConversationThreadDelegate alloc] init];
    self.callDelegate = [[CallDelegate alloc] init];
    self.accountDelegate = [[AccountDelegate alloc] init];
    self.identityDelegate = [[IdentityDelegate alloc] init];
    self.identityDelegate.loginDelegate = self.mainViewController;
    self.identityLookupDelegate = [[IdentityLookupDelegate alloc] init];
    self.cacheDelegate = [[CacheDelegate alloc] init];
}
@end
