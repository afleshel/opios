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

#import "LoginManager.h"


#import "OpenPeer.h"
//Utility
#import "Utility.h"
#import "AppConsts.h"
#import "Settings.h"
#import "UIDevice+Networking.h"
//Managers
#import "ContactsManager.h"
#import "SessionManager.h"
#import "MessageManager.h"

#ifdef APNS_ENABLED
#import "APNSManager.h"
#endif
//SDK
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPAccountIdentity.h>
#import <OpenPeerSDK/HOPTypes.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
//#import <OpenpeerSDK/HOPIdentity.h>
#import <OpenpeerSDK/HOPStack.h>
#import <OpenpeerSDK/HOPBackgrounding.h>
//Delegates
#import "StackDelegate.h"
#import "IdentityDelegate.h"
#import "AccountDelegate.h"
#import "BackgroundingDelegate.h"
//View Controllers
#import "MainViewController.h"
#import "ActivityIndicatorViewController.h"
#import "WebLoginViewController.h"


#define ALERT_NO_CONNECTION_TAG 1

@interface LoginManager ()

@property (strong, nonatomic) NSMutableDictionary* associatingIdentitiesDictionary;
- (void) handleEstablishedInternetConnection;
@end


@implementation LoginManager

/**
 Retrieves singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
+ (id) sharedLoginManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

/**
 Initialize singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
- (id) init
{
    self = [super init];
    if (self)
    {
        self.isLogin  = NO;
        self.isRelogin = NO;
        self.isLoggedin = NO;
        self.isAssociation = NO;
        self.isRecovering = NO;
        self.associatingIdentitiesDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/**
 This method will show login window in case user data does not exists on device, or start relogin automatically if information are available.
 @return Singleton object of the Contacts Manager.
 */
- (void) login
{
    if (![[Settings sharedSettings] checkIfReloginInfoIsValid])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Relogin info is not valid");

        [[HOPAccount sharedAccount] resetLoggedInAccount];

    }
    
    if ([UIDevice isNetworkReachable])
    {
        //If peer file doesn't exists, show login view, otherwise start relogin
        if ([HOPAccount isReloginPossible])
        {
            [self startRelogin];
        }
        else
        {
            [self startLogin];
        }
    }
    
}

- (void)clearIdentities
{
    if ([[HOPAccount sharedAccount] isAccountReady])
    {
        NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
        for (HOPAccountIdentity* accountIdentity in associatedIdentities)
        {
            if ([accountIdentity isValid])
                [accountIdentity cancel];
        }
        
        for (id accountIdentity in self.associatingIdentitiesDictionary.allValues)
        {
            if ([[accountIdentity class] isSubclassOfClass:[HOPAccountIdentity class]])
            {
                if ([accountIdentity isValid])
                    [accountIdentity cancel];
            }
        }
    }
    [self.associatingIdentitiesDictionary removeAllObjects];
}

/**
 Logout from the current account.
 */
- (void) logout
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace,@"Logout started");
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Remove cookies");
    //Delete all cookies.
    [Utility removeCookiesAndClearCredentials];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Remove identity web view controllers");
    [[[OpenPeer sharedOpenPeer] identityDelegate] removeAllWebViewControllers];
    
    [[[[OpenPeer sharedOpenPeer] backgroundingDelegate] backgroundingSubscription] cancel];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Clear all session objects");
    [[SessionManager sharedSessionManager] clearAllSessions];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Clear all identity objects");
    [self clearIdentities];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Start account shutdown");
    //Call to the SDK in order to shutdown Open Peer engine.
    [[HOPAccount sharedAccount] shutdown];
    
    [[HOPAccount sharedAccount] resetLoggedInAccount];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Handle logout on UI level");
    [[[OpenPeer sharedOpenPeer] mainViewController] onLogout];

    
    self.isLogin = YES;

    if ([[Settings sharedSettings] isQRSettingsResetEnabled])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace,@"Removing QR settings");
        [[Settings sharedSettings] removeAppliedQRSettings];
    }
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Clear session records from the database");
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"Release all core objects");
    [[HOPStack sharedStack] doLogoutCleanup];
}

- (void) startAccount
{
    [[HOPAccount sharedAccount] loginWithAccountDelegate:(id<HOPAccountDelegate>)[[OpenPeer sharedOpenPeer] accountDelegate] conversationDelegate:(id<HOPConversationDelegate>) [[OpenPeer sharedOpenPeer] conversationDelegate]  callDelegate:(id<HOPCallDelegate>) [[OpenPeer sharedOpenPeer] callDelegate]  namespaceGrantOuterFrameURLUponReload:[[Settings sharedSettings] getOuterFrameURL] lockboxServiceDomain:[[Settings sharedSettings] getIdentityProviderDomain] forceCreateNewLockboxAccount:NO];
}

- (void) startLogin
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Login is started");
    [self startLoginUsingIdentityURI:[[Settings sharedSettings] getIdentityFederateBaseURI]];
    self.isLogin = YES;
}

/**
 Starts user login for specific identity URI. Activity indicator is displayed and identity login started.
 @param identityURI NSString identity uri (e.g. identity://facebook.com/)
 */
- (void) startLoginUsingIdentityURI:(NSString*) identityURI
{
    if (![self.associatingIdentitiesDictionary objectForKey:identityURI])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Identity login started for uri: %@",identityURI);
        [[[OpenPeer sharedOpenPeer] mainViewController] onStartLoginWithidentityURI];
        
        NSString* redirectAfterLoginCompleteURL = [Settings getRedirectURLAfterLoginComplete];

        if (![[HOPAccount sharedAccount] isAccountReady] || [[HOPAccount sharedAccount] getState].state == HOPAccountStateShutdown)
            [self startAccount];
        
        //For identity login it is required to pass identity delegate, URL that will be requested upon successful login, identity URI and identity provider domain. This is 
        HOPAccountIdentity* accountIdentity = [HOPAccountIdentity loginWithDelegate:(id<HOPAccountIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate] identityProviderDomain:[[Settings sharedSettings] getIdentityProviderDomain]  identityURIOridentityBaseURI:identityURI outerFrameURLUponReload:redirectAfterLoginCompleteURL];
        
        if (!accountIdentity)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Identity login has failed for uri: %@",identityURI);
        }
        else
        {
            [self.associatingIdentitiesDictionary setObject:accountIdentity forKey:identityURI];
        }
    }
}

/**
 Initiates relogin procedure.
 */
- (void) startRelogin
{
    BOOL reloginStarted = NO;
    self.isRelogin = YES;
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Relogin started");
    [[[OpenPeer sharedOpenPeer] mainViewController] onRelogin];

    //To start relogin procedure it is required to pass account, conversation thread and call delegates. Also, private peer file and secret, received on previous login procedure, are required.
    reloginStarted = [[HOPAccount sharedAccount] reloginWithAccountDelegate:(id<HOPAccountDelegate>) [[OpenPeer sharedOpenPeer] accountDelegate] conversationDelegate:(id<HOPConversationDelegate>)[[OpenPeer sharedOpenPeer] conversationDelegate]  callDelegate:(id<HOPCallDelegate>)[[OpenPeer sharedOpenPeer] callDelegate] lockboxOuterFrameURLUponReload:[[Settings sharedSettings] getOuterFrameURL]];
    
    if (!reloginStarted)
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Relogin has failed");
}

- (void) preloadLoginWebPage
{
    if (!self.preloadedWebLoginViewController)
    {
        self.preloadedWebLoginViewController = [[WebLoginViewController alloc] init];
        if (self.preloadedWebLoginViewController)
            self.preloadedWebLoginViewController.view.hidden = YES;
    }
    
    [self.preloadedWebLoginViewController openLoginUrl:[[Settings sharedSettings] getOuterFrameURL]];
}

/**
 Handles successful identity association. It updates list of associated identities on server side.
 @param identity HOPAccountIdentity identity used for login
 */
- (void) onIdentityAssociationFinished:(HOPAccountIdentity*) accountIdentity
{
    [[HOPAccount sharedAccount] addAccountIdentity:accountIdentity];
    [self.associatingIdentitiesDictionary removeAllObjects];
    //[self.associatingIdentitiesDictionary removeObjectForKey:[identity getIdentityURI]];
    
    [self onUserLoggedIn];
}

- (void) attachDelegateForIdentity:(HOPAccountIdentity*) accountIdentity forceAttach:(BOOL) forceAttach
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Attach delegate for identity with URI: %@", [accountIdentity getIdentityURI]);
    if (![accountIdentity isDelegateAttached] || forceAttach)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Attaching delegate for identity with URI: %@", [accountIdentity getIdentityURI]);
        //Create core data record if it is not already in the db    
        [self onIdentityAssociationFinished:accountIdentity];
        
        NSString* redirectAfterLoginCompleteURL = [NSString stringWithFormat:@"%@?reload=true",[[Settings sharedSettings] getOuterFrameURL]];
        
        [accountIdentity attachDelegate:(id<HOPAccountIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate]  redirectionURL:redirectAfterLoginCompleteURL];
    }
}

/**
 Handles SDK event after login is successful.
 */
- (void) onUserLoggedIn
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"onUserLoggedIn");

    //Wait till identity association is not completed
    if ([[HOPAccount sharedAccount] getState].state == HOPAccountStateReady && [self.associatingIdentitiesDictionary count] == 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"User is successfully logged in.");
        
        if (self.isLogin || ![[OpenPeer sharedOpenPeer] appEnteredForeground])
        {
            NSArray* associatedIdentites = [[HOPAccount sharedAccount] getAssociatedIdentities];
            for (HOPAccountIdentity* accountIdentity in associatedIdentites)
            {
                if (![accountIdentity isDelegateAttached])
                {
                    NSString* redirectAfterLoginCompleteURL = [Settings getRedirectURLAfterLoginComplete];
                    
                    [accountIdentity attachDelegate:(id<HOPAccountIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate]  redirectionURL:redirectAfterLoginCompleteURL];
                }
            }
        
            //Check if it is logged in a new user
            [[HOPAccount sharedAccount] updateLoggedInAccount];
            
            
            /*if (homeUser)
            {
                //If is previous logged in user is different update loggedIn flag
                if (![homeUser.loggedIn boolValue])
                {
                    if (previousLoggedInHomeUser)
                        previousLoggedInHomeUser.loggedIn = NO;
                    
                    homeUser.loggedIn = [NSNumber numberWithBool: YES];
                    [[HOPModelManager sharedModelManager] saveContext];
                }
            }*/
            
            //Not yet ready for association
            /*if ((self.isLogin || self.isAssociation) && ([associatedIdentites count] < 2))
            {
                self.isLogin = NO;
                
                HOPAccountIdentity* identity = [associatedIdentites objectAtIndex:0];
                
                NSString* message = @"Do you want to associate federated account?";
                
                if ([[identity getBaseIdentityURI] isEqualToString:identityFacebookBaseURI])
                    message = @"Do you want to associate federated account?";
                else
                    message = @"Do you want to associate facebook account?";
                        
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Identity association" message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
                
                [alert show];
            }
            else*/
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] onLoginFinished];
                //Start loading contacts.
                [[ContactsManager sharedContactsManager] loadContacts];
                
            }
            
            if (self.isRecovering)
            {
                [[SessionManager sharedSessionManager] recreateExistingSessions];
            }
            self.isLoggedin = YES;
#ifdef APNS_ENABLED
            //if ([[[HOPModelManager sharedModelManager] getAPNSDataForPeerURI:[[HOPAccount sharedAccount] getPeerURI]] count] == 0)
                [[APNSManager sharedAPNSManager] registerDeviceTokenWithOpenPeer];
#endif
        }
        else
        {
            [[SessionManager sharedSessionManager] recreateExistingSessions];
        }
        
        if (self.isRecovering)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Recovering application from network issue.");
            [[MessageManager sharedMessageManager] resendMessages];
            self.isRecovering = NO;
        }
        self.isRelogin = NO;
#ifdef APNS_ENABLED
        [[APNSManager sharedAPNSManager] getAllMessages];
#endif
        //Login finished. Remove activity indicator
        [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    }
    else
    {
        int o = [self.associatingIdentitiesDictionary count];
        if (o > 0)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"onUserLoggedIn - NOT Ready because of associatingIdentitiesDictionary is not empty: %d",o);
        }
        else
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"onUserLoggedIn - NOT Ready because account is not in ready state");
        }
    }
}

- (void) onUserLogOut
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace,@"Logout finished");
    [[OpenPeer sharedOpenPeer] finishPreSetup];
}

/**
 Retrieves info if an identity with specified URI is associated or not.
 @param inBaseIdentityURI NSString base identity URI
 @return YES if associated, otherwise NO
 */
- (BOOL) isAssociatedIdentity:(NSString*) inBaseIdentityURI
{
    BOOL ret = NO;

    HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:inBaseIdentityURI homeUserStableId:[[HOPAccount sharedAccount] getStableID]];
    
    if (associatedIdentity)
        ret = YES;
    
    return ret;
}

- (BOOL) isUserFullyLoggedIn
{
    BOOL ret = NO;
    
    ret = [[HOPAccount sharedAccount] getState].state == HOPAccountStateReady;
    if (ret)
    {
        NSArray* identities = [[HOPAccount sharedAccount] getAssociatedIdentities];
        for (HOPAccountIdentity* accountIdentity in identities)
        {
            if ([accountIdentity getState].state != HOPIdentityStateReady)
            {
                ret = NO;
                break;
            }
        }
    }
    return ret;
}
- (void) handleEstablishedInternetConnection
{
    if ([UIDevice isNetworkReachable])
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Network connection is established again");
        if (![[HOPAccount sharedAccount] isAccountReady] || [[HOPAccount sharedAccount] getState].state != HOPAccountStateReady)
        {
            self.isRecovering = YES;
            //If peer file doesn't exists, show login view, otherwise start relogin
            if ([HOPAccount isReloginPossible])
            {
                [self startRelogin];
            }
            else
            {
                [self startLogin];
            }
        }
        else
        {
            [[MessageManager sharedMessageManager] resendMessages];
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Network connection is lost");
    }
}

#pragma UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == ALERT_NO_CONNECTION_TAG)
    {
        //[self login];
    }
    
    //DON'T DELETE. This section is related to identity association
    /*if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSArray* associatedIdentites = [[HOPAccount sharedAccount] getAssociatedIdentities];
        HOPAccountIdentity* identity = [associatedIdentites objectAtIndex:0];
        
        if ([[identity getBaseIdentityURI] isEqualToString:identityFacebookBaseURI])
        {
            [[LoginManager sharedLoginManager] startLoginUsingIdentityURI:[[Settings sharedSettings] getIdentityFederateBaseURI]];
        }
        else
        {
            [[LoginManager sharedLoginManager] startLoginUsingIdentityURI:identityFacebookBaseURI];
        }
        
        self.isAssociation = YES;
    }
    else
    {
        [[[OpenPeer sharedOpenPeer] mainViewController] onLoginFinished];
        //Start loading contacts.
        [[ContactsManager sharedContactsManager] loadContacts];
    }*/
}
@end
