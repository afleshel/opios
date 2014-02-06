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
//Managers
#import "ContactsManager.h"
#import "SessionManager.h"
//SDK
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPIdentity.h>
#import <OpenPeerSDK/HOPTypes.h>
#import <OpenpeerSDK/HOPHomeUser.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
#import <OpenpeerSDK/HOPIdentityContact.h>
#import <OpenpeerSDK/HOPRolodexContact.h>

//Delegates
#import "StackDelegate.h"
//View Controllers
#import "MainViewController.h"
#import "ActivityIndicatorViewController.h"
#import "WebLoginViewController.h"

@interface LoginManager ()




@property (strong, nonatomic) NSMutableDictionary* associatingIdentitiesDictionary;
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
        self.isAssociation = NO;
        
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
    //If peer file doesn't exists, show login view, otherwise start relogin
    if (![[HOPModelManager sharedModelManager] getLastLoggedInHomeUser])
    {
        [self startLogin];
        //[[[OpenPeer sharedOpenPeer] mainViewController] showQRScanner];
    }
    else
    {
        [self startRelogin];
    }
}

/**
 Logout from the current account.
 */
- (void) logout
{    
    //Delete all cookies.
    [Utility removeCookiesAndClearCredentials];
    
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    for (HOPIdentity* identity in associatedIdentities)
    {
        [identity cancel];
    }
    
    for (HOPIdentity* identity in self.associatingIdentitiesDictionary)
    {
        [identity cancel];
    }
    [self.associatingIdentitiesDictionary removeAllObjects];
    
    //Call to the SDK in order to shutdown Open Peer engine.
    [[HOPAccount sharedAccount] shutdown];
    
    [[[OpenPeer sharedOpenPeer] mainViewController] onLogout];
    
    HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getLastLoggedInHomeUser];
    homeUser.loggedIn = [NSNumber numberWithBool:NO];
    [[HOPModelManager sharedModelManager] saveContext];
    
    self.isLogin = YES;

}

- (void) startAccount
{
    [[HOPAccount sharedAccount] loginWithAccountDelegate:(id<HOPAccountDelegate>)[[OpenPeer sharedOpenPeer] accountDelegate] conversationThreadDelegate:(id<HOPConversationThreadDelegate>) [[OpenPeer sharedOpenPeer] conversationThreadDelegate]  callDelegate:(id<HOPCallDelegate>) [[OpenPeer sharedOpenPeer] callDelegate]  namespaceGrantOuterFrameURLUponReload:[[Settings sharedSettings] getOuterFrameURL] grantID:[[OpenPeer sharedOpenPeer] deviceId] lockboxServiceDomain:[[Settings sharedSettings] getIdentityProviderDomain] forceCreateNewLockboxAccount:NO];
}

- (void) startLogin
{
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
        
        NSString* redirectAfterLoginCompleteURL = [NSString stringWithFormat:@"%@?reload=true",[[Settings sharedSettings] getOuterFrameURL]];

        if (![[HOPAccount sharedAccount] isCoreAccountCreated] || [[HOPAccount sharedAccount] getState].state == HOPAccountStateShutdown)
            [self startAccount];
        
        //For identity login it is required to pass identity delegate, URL that will be requested upon successful login, identity URI and identity provider domain. This is 
        HOPIdentity* hopIdentity = [HOPIdentity loginWithDelegate:(id<HOPIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate] identityProviderDomain:[[Settings sharedSettings] getIdentityProviderDomain]  identityURIOridentityBaseURI:identityURI outerFrameURLUponReload:redirectAfterLoginCompleteURL];
        
        if (!hopIdentity)
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Identity login has failed for uri: %@",identityURI);
        else
            [self.associatingIdentitiesDictionary setObject:hopIdentity forKey:identityURI];
    }
}

/**
 Initiates relogin procedure.
 */
- (void) startRelogin
{
    BOOL reloginStarted = NO;
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Relogin started");
    [[[OpenPeer sharedOpenPeer] mainViewController] onRelogin];
    
    HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getLastLoggedInHomeUser];
    
    if (homeUser && [homeUser.reloginInfo length] > 0)
    {
        //To start relogin procedure it is required to pass account, conversation thread and call delegates. Also, private peer file and secret, received on previous login procedure, are required.
        reloginStarted = [[HOPAccount sharedAccount] reloginWithAccountDelegate:(id<HOPAccountDelegate>) [[OpenPeer sharedOpenPeer] accountDelegate] conversationThreadDelegate:(id<HOPConversationThreadDelegate>)[[OpenPeer sharedOpenPeer] conversationThreadDelegate]  callDelegate:(id<HOPCallDelegate>)[[OpenPeer sharedOpenPeer] callDelegate] lockboxOuterFrameURLUponReload:[[Settings sharedSettings] getOuterFrameURL] reloginInformation:homeUser.reloginInfo];
    }
    
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
 @param identity HOPIdentity identity used for login
 */
- (void) onIdentityAssociationFinished:(HOPIdentity*) identity
{
    NSString* relogininfo = [[HOPAccount sharedAccount] getReloginInformation];
    
    if ([relogininfo length] > 0)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Identity association finished - identityURI: %@  - accountStableId: %@", [identity getIdentityURI], [[HOPAccount sharedAccount] getStableID]);
        HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getHomeUserByStableID:[[HOPAccount sharedAccount] getStableID]];
        
        if (!homeUser)
        {
            homeUser = (HOPHomeUser*)[[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPHomeUser"];
            homeUser.stableId = [[HOPAccount sharedAccount] getStableID];
            homeUser.reloginInfo = [[HOPAccount sharedAccount] getReloginInformation];
            homeUser.loggedIn = [NSNumber numberWithBool: YES];
        }
        
        HOPAssociatedIdentity*  associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityBaseIdentityURI:[identity getBaseIdentityURI] homeUserStableId:homeUser.stableId];
        
        if (!associatedIdentity)
            associatedIdentity = (HOPAssociatedIdentity*)[[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPAssociatedIdentity"];
            
        HOPIdentityContact* homeIdentityContact = [identity getSelfIdentityContact];
        associatedIdentity.domain = [identity getIdentityProviderDomain];
        //associatedIdentity.downloadedVersion = @"";
        associatedIdentity.name = [identity getBaseIdentityURI];
        associatedIdentity.baseIdentityURI = [identity getBaseIdentityURI];
        associatedIdentity.homeUserProfile = homeIdentityContact.rolodexContact;
        associatedIdentity.homeUser = homeUser;
        homeIdentityContact.rolodexContact.associatedIdentityForHomeUser = associatedIdentity;
        
        [[HOPModelManager sharedModelManager] saveContext];
        
        //[self.associatingIdentitiesDictionary removeObjectForKey:[identity getBaseIdentityURI]];
        [self.associatingIdentitiesDictionary removeAllObjects];
    }
    
    [self onUserLoggedIn];
}

- (void) attachDelegateForIdentity:(HOPIdentity*) identity forceAttach:(BOOL) forceAttach
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Attach delegate for identity with URI: %@", [identity getIdentityURI]);
    if (![identity isDelegateAttached] || forceAttach)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Attaching delegate for identity with URI: %@", [identity getIdentityURI]);
        //Create core data record if it is not already in the db    
        [self onIdentityAssociationFinished:identity];
        
        NSString* redirectAfterLoginCompleteURL = [NSString stringWithFormat:@"%@?reload=true",[[Settings sharedSettings] getOuterFrameURL]];
        
        [identity attachDelegate:(id<HOPIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate]  redirectionURL:redirectAfterLoginCompleteURL];
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
        
        if (![[OpenPeer sharedOpenPeer] appEnteredForeground])
        {
            NSArray* associatedIdentites = [[HOPAccount sharedAccount] getAssociatedIdentities];
            for (HOPIdentity* identity in associatedIdentites)
            {
                if (![identity isDelegateAttached])
                {
                    NSString* redirectAfterLoginCompleteURL = [NSString stringWithFormat:@"%@?reload=true",[[Settings sharedSettings] getOuterFrameURL]];
                    
                    [identity attachDelegate:(id<HOPIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate]  redirectionURL:redirectAfterLoginCompleteURL];
                }
            }
        
            //Check if it is logged in a new user
            HOPHomeUser* previousLoggedInHomeUser = [[HOPModelManager sharedModelManager] getLastLoggedInHomeUser];
            HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getHomeUserByStableID:[[HOPAccount sharedAccount] getStableID]];
        
            if (homeUser)
            {
                //If is previous logged in user is different update loggedIn flag
                if (![homeUser.loggedIn boolValue])
                {
                    if (previousLoggedInHomeUser)
                        previousLoggedInHomeUser.loggedIn = NO;
                    
                    homeUser.loggedIn = [NSNumber numberWithBool: YES];
                    [[HOPModelManager sharedModelManager] saveContext];
                }
            }
            
            //Not yet ready for association
            if ((self.isLogin || self.isAssociation) && ([associatedIdentites count] < 2))
            {
                self.isLogin = NO;
                
                HOPIdentity* identity = [associatedIdentites objectAtIndex:0];
                
                NSString* message = @"Do you want to associate federated account?";
                
                if ([[identity getBaseIdentityURI] isEqualToString:identityFacebookBaseURI])
                    message = @"Do you want to associate federated account?";
                else
                    message = @"Do you want to associate facebook account?";
                        
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Identity association" message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
                
                [alert show];
            }
            else
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] onLoginFinished];
                //Start loading contacts.
                [[ContactsManager sharedContactsManager] loadContacts];
            }
        }
        else
        {
            [[SessionManager sharedSessionManager] recreateExistingSessions];
        }
        
        //Login finished. Remove activity indicator
        [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    }
    else
    {
        int o = [self.associatingIdentitiesDictionary count];
        if (o > 0)
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"onUserLoggedIn - NOT Ready because of associatingIdentitiesDictionary is not empty: %d",o);
        else
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"onUserLoggedIn - NOT Ready because account is not in ready state");
    }
}


/**
 Retrieves info if an identity with specified URI is associated or not.
 @param inBaseIdentityURI NSString base identity URI
 @return YES if associated, otherwise NO
 */
- (BOOL) isAssociatedIdentity:(NSString*) inBaseIdentityURI
{
    BOOL ret = NO;
    
    HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getLastLoggedInHomeUser];
    if (homeUser)
    {
        HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityBaseIdentityURI:inBaseIdentityURI homeUserStableId:homeUser.stableId];
        
        if (associatedIdentity)
            ret = YES;
    }
    
    return ret;
}

#pragma UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSArray* associatedIdentites = [[HOPAccount sharedAccount] getAssociatedIdentities];
        HOPIdentity* identity = [associatedIdentites objectAtIndex:0];
        
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
    }
}
@end
