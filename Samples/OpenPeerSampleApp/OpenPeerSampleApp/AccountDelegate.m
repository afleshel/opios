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

#import "UIKit/UIKit.h"
#import "AccountDelegate.h"
#import "OpenpeerSDK/HOPAccount.h"
#import "LoginManager.h"
#import "OpenPeer.h"
#import "AppConsts.h"
#import "MainViewController.h"
#import "WebLoginViewController.h"
#import "OpenpeerSDK/HOPLogger.h"
#import "OpenpeerSDK/HOPCache.h"

#ifdef APNS_ENABLED
#import "APNSInboxManager.h"
#endif
@interface AccountDelegate()
@property (nonatomic, strong) WebLoginViewController* webLoginViewController;
@end

@implementation AccountDelegate

/**
 Custom getter for webLoginViewController
 */
- (WebLoginViewController *)webLoginViewController
{
    if (!_webLoginViewController)
    {
        _webLoginViewController = [[WebLoginViewController alloc] initWithCoreObject:[HOPAccount sharedAccount]];
        if (_webLoginViewController)
            _webLoginViewController.view.hidden = YES;
    }
    
    return _webLoginViewController;
}

//This method handles account state changes from SDK.
- (void) account:(HOPAccount*) account stateChanged:(HOPAccountStates) accountState
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Account login state: %@", [HOPAccount stringForAccountState:accountState]);
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        switch (accountState)
        {
            case HOPAccountStatePending:
                break;
                
            case HOPAccountPendingPeerFilesGeneration:
                break;
                
            case HOPAccountWaitingForAssociationToIdentity: //after creation
                break;
                
            case HOPAccountWaitingForBrowserWindowToBeLoaded:
                [self.webLoginViewController openLoginUrl:[[Settings sharedSettings] getNamespaceGrantServiceURL]];
                break;
                
            case HOPAccountWaitingForBrowserWindowToBeMadeVisible:
            {
                //Add login web view like main view subview
                if (!self.webLoginViewController.view.superview)
                {
                    [self.webLoginViewController.view setFrame:[[OpenPeer sharedOpenPeer] mainViewController].view.bounds];
                    [[[OpenPeer sharedOpenPeer] mainViewController] showWebLoginView:self.webLoginViewController];
                }
                
                self.webLoginViewController.view.alpha = 0;
                self.webLoginViewController.view.hidden = NO;
                
                [UIView animateWithDuration:0.7 animations:^{
                    self.webLoginViewController.view.alpha = 1;
                }];

                //Notify core that login web view is visible now
                [account notifyBrowserWindowVisible];
            }
                break;
                
            case HOPAccountWaitingForBrowserWindowToClose:
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] closeWebLoginView:self.webLoginViewController];
                
                //Notify core that login web view is closed
                [account notifyBrowserWindowClosed];
            }
                break;
                
            case HOPAccountStateReady:
                [[LoginManager sharedLoginManager] onUserLoggedIn];
#ifdef APNS_ENABLED
                [[APNSInboxManager sharedAPNSInboxManager] handleNewMessages];
#endif
                break;
                
            case HOPAccountStateShuttingDown:
                break;
                
            case HOPAccountStateShutdown:
            {
                HOPAccountState* accountState = [account getState];
                if (accountState.errorCode && ![[OpenPeer sharedOpenPeer] appEnteredForeground])
                {
                    [[[OpenPeer sharedOpenPeer] mainViewController]  onAccountLoginError:accountState.errorReason];
                    [[HOPCache sharedCache] removeCookieWithNamePath:settingsKeySettingsDownloadURL];
                }
                else
                {
                    [[LoginManager sharedLoginManager] onUserLogOut];
                }
                self.webLoginViewController = nil;
            }
                break;
                
            default:
                break;
        }
    });
}

- (void)onAccountAssociatedIdentitiesChanged:(HOPAccount *)account
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Account associated identities has changed.");
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSArray* associatedIdentities = [account getAssociatedIdentities];
        for (HOPIdentity* identity in associatedIdentities)
        {
            [[LoginManager sharedLoginManager] attachDelegateForIdentity:identity forceAttach:NO];
        }
    });
}

- (void)onAccountPendingMessageForInnerBrowserWindowFrame:(HOPAccount*) account
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Account: pending message for inner browser window frame.");
  
    dispatch_async(dispatch_get_main_queue(), ^
    {
        WebLoginViewController* webLoginViewController = [self webLoginViewController];
            if (webLoginViewController)
            {
                NSString* jsMethod = [NSString stringWithFormat:@"sendBundleToJS(\'%@\')", [account getNextMessageForInnerBrowerWindowFrame]];
                
                [webLoginViewController passMessageToJS:jsMethod];
            }
    });
}


@end
