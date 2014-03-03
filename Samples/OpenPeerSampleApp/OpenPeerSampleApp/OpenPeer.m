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
#import "BackgroundingDelegate.h"
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
        
        _authorizedApplicationId = [HOPStack createAuthorizedApplicationID:[[NSUserDefaults standardUserDefaults] stringForKey: @"applicationId"] applicationIDSharedSecret:[[NSUserDefaults standardUserDefaults] stringForKey: @"applicationIdSharedSecret"] expires:expiry];
        [[NSUserDefaults standardUserDefaults] synchronize];
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
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return _deviceId;
}
- (void) refreshAuthorizedApplicationId
{
    self.authorizedApplicationId = nil;
    [[HOPSettings sharedSettings] storeAuthorizedApplicationId:[self authorizedApplicationId]];
}

- (void) preSetup
{
    //Create all delegates required for communication with core
    [self createDelegates];
    
    //Set persistent stores
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPathDirectory = [libraryPath stringByAppendingPathComponent:@"db"];
    [[HOPModelManager sharedModelManager] setDataPath:dataPathDirectory backupData:NO];
    NSString *cachePathDirectory = [libraryPath stringByAppendingPathComponent:@"cache"];
    [[HOPModelManager sharedModelManager] setCachePath:cachePathDirectory];
    
    //Set settigns delegate
    [[HOPSettings sharedSettings] setup];//WithDelegate:[Settings sharedSettings]];
    
    //Cleare expired cookies and set delegate
    [[HOPCache sharedCache] removeExpiredCookies];
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
                NSDictionary* filteredDictionary = [[Settings sharedSettings] dictionaryWithRemovedAllInvalidEntriesForPath:filePath];
                if ([filteredDictionary count] > 0)
                    [[HOPSettings sharedSettings] storeSettingsFromDictionary:filteredDictionary];
                //[[HOPSettings sharedSettings] storeSettingsFromPath:filePath];
            }
            
            isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
        }
        
        //If not already set, set default app data
        BOOL isSetAppData = NO;//[[Settings sharedSettings] isAppDataSet];
        if (!isSetAppData)
        {
            NSString* filePath = [[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"];
            if ([filePath length] > 0)
            {
                NSMutableDictionary* filteredDictionary = [[Settings sharedSettings] dictionaryWithRemovedAllInvalidEntriesForPath:filePath];
                [[Settings sharedSettings] createUserAgentFromDictionary:filteredDictionary];
                if ([filteredDictionary count] > 0)
                    [[HOPSettings sharedSettings] storeSettingsFromDictionary:filteredDictionary];
            }
            isSetAppData = [[Settings sharedSettings] isAppDataSet];
        }
        
         [[Settings sharedSettings] updateDeviceInfo];
        
#ifdef DEBUG
        //Show QR scanner if user wants to change settings by reading QR code
        [[self mainViewController] showQRScanner];
#else
        [[self mainViewController] waitForUserGesture];
#endif
    }
    else
    {
        [[Settings sharedSettings] updateDeviceInfo];
        
        [self setup];
        //Set log levels and start logging
        [Logger startAllSelectedLoggers];
    }
}

/**
 Initializes the open peer stack. After initialization succeeds, login screen is displayed, or user relogin started.
 @param inMainViewController MainViewController Input main view controller.
 */
- (void) setup
{
    //If authorized application id is missing, generate it 
    if ([[[HOPSettings sharedSettings] getAuthorizedApplicationId] length] == 0)
        [[HOPSettings sharedSettings] storeAuthorizedApplicationId:[[OpenPeer sharedOpenPeer] authorizedApplicationId]];
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
    //Set log levels and start logging
    [Logger startAllSelectedLoggers];

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
    self.conversationThreadDelegate = nil;
    self.callDelegate = nil;
    self.accountDelegate = nil;
    self.identityDelegate = nil;
    self.identityLookupDelegate = nil;
    self.cacheDelegate = nil;
    self.backgroundingDelegate = nil;
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
    self.backgroundingDelegate = [[BackgroundingDelegate alloc] init];
    //self.cacheDelegate = [[CacheDelegate alloc] init];
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
@end
