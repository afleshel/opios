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

#import "OfflineManager.h"
#import "UIDevice+Networking.h"
#import "LoginManager.h"
#import "SessionManager.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "MessageManager.h"
#import "Logger.h"

#import <OpenPeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPModelManager.h>

typedef enum
{
    PRELOGIN_STATE,
    LOGIN_STATE,
    LOGGEDIN_STATE,
    LOGGEDIN_ACTIVE_SESSION,
    LOGGEDIN_ACTIVE_CALL
} AppState;

@interface OfflineManager ()

- (id) initSingleton;
- (AppState) getCurrentAppState;

- (void) handleNetworkConnectionChange;
- (void) handleNetworkConnectionNotAvailable;
- (void) handleNetworkConnectionAvailable;

- (NSString*) stringForState:(AppState) appState;
@end

@implementation OfflineManager

+ (id) sharedOfflineManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

- (id)initSingleton
{
    if ((self = [super init]))
    {
        
    }
    return self;
}

- (void) startNetworkMonitor
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkConnectionChange) name:kReachabilityChangedNotification object:nil];
    [UIDevice startNotifier];
}



- (AppState) getCurrentAppState
{
    AppState ret = PRELOGIN_STATE;
    
    if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isRelogin] || [[LoginManager sharedLoginManager] isAssociation])
    {
        ret = LOGIN_STATE;
    }
    else if ([[LoginManager sharedLoginManager] isLoggedin])
    {
        if ([[[SessionManager sharedSessionManager] sessionsDictionary] count] > 0)
        {
            if ([[SessionManager sharedSessionManager] isCallInProgress])
                ret = LOGGEDIN_ACTIVE_CALL;
            else
                ret = LOGGEDIN_ACTIVE_SESSION;
        }
        else
            ret = LOGGEDIN_STATE;
    }
    
    return ret;
}

- (void) handleNetworkConnectionChange
{
    if ([UIDevice isNetworkReachable])
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Network connection is available.");
        [Logger startAllSelectedLoggers];
        [self handleNetworkConnectionAvailable];
    }
    else
    {
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Network connection is not available.");
        [self handleNetworkConnectionNotAvailable];
    }
}

- (void) handleNetworkConnectionNotAvailable
{
    AppState appState = [self getCurrentAppState];
    
    OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Handling connection lost for state:%@",[self stringForState:appState]);
    switch (appState)
    {
        case PRELOGIN_STATE:
            [[[OpenPeer sharedOpenPeer] mainViewController] onNetworkProblem];
            break;
        case LOGIN_STATE:
            [self showInfoAboutNetworkProblem];
            break;
        case LOGGEDIN_STATE:
            
            break;
        case LOGGEDIN_ACTIVE_SESSION:
            
            break;
        case LOGGEDIN_ACTIVE_CALL:
            
            break;
            
        default:
            break;
    }
}

- (void) handleNetworkConnectionAvailable
{
    AppState appState = [self getCurrentAppState];
    
    OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Handling connection recovery for state:%@",[self stringForState:appState]);
    
    switch (appState)
    {
        case PRELOGIN_STATE:
            [[OpenPeer sharedOpenPeer] preSetup];
            break;
            
        case LOGIN_STATE:
            [[LoginManager sharedLoginManager] login];
            break;
            
        case LOGGEDIN_STATE:
            if (![[HOPAccount sharedAccount] isCoreAccountCreated] || [[HOPAccount sharedAccount] getState].state != HOPAccountStateReady)
            {
                [[LoginManager sharedLoginManager] setIsRecovering:YES];
                [[LoginManager sharedLoginManager] login];
                [[[OpenPeer sharedOpenPeer] mainViewController] onNetworkProblemResolved];
            }
            break;

        case LOGGEDIN_ACTIVE_SESSION:
        case LOGGEDIN_ACTIVE_CALL:
        {
            if (![[HOPAccount sharedAccount] isCoreAccountCreated] || [[HOPAccount sharedAccount] getState].state != HOPAccountStateReady)
            {
                [[LoginManager sharedLoginManager] setIsRecovering:YES];
                [[LoginManager sharedLoginManager] login];
                [[[OpenPeer sharedOpenPeer] mainViewController] onNetworkProblemResolved];
            }
            else
            {
                [[MessageManager sharedMessageManager] resendMessages];
            }
        }
            break;
            
        default:
            break;
    }
}
- (void) showInfoAboutNetworkProblem
{
    AppState appState = [self getCurrentAppState];
    
    if (appState == PRELOGIN_STATE)
    {
        [[[OpenPeer sharedOpenPeer] mainViewController] onNetworkProblem];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:[NSString stringWithFormat:@"Please, check your internet connection,"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}
- (NSString*) stringForState:(AppState) appState
{
    NSString* ret = nil;
    switch (appState)
    {
        case PRELOGIN_STATE:
            ret = @"PRELOGIN_STATE";
            break;
            
        case LOGIN_STATE:
            ret = @"LOGIN_STATE";
            break;
            
        case LOGGEDIN_STATE:
            ret = @"LOGGEDIN_STATE";
            break;
            
        case LOGGEDIN_ACTIVE_SESSION:
            ret = @"LOGGEDIN_ACTIVE_SESSION";
            break;
            
        case LOGGEDIN_ACTIVE_CALL:
            ret = @"LOGGEDIN_ACTIVE_CALL";
            break;
            
        default:
            break;
    }
    return ret;
}
@end
