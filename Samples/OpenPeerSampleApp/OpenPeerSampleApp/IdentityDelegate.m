/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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

#import "IdentityDelegate.h"
#import <OpenpeerSDK/HOPAccountIdentity.h>
#import <OpenpeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPIdentityLookup.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>

#import <pthread.h>

#import "LoginManager.h"
#import "ContactsManager.h"
#import "AppConsts.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "ContactsViewController.h"
#import "ActivityIndicatorViewController.h"
#import "Settings.h"

#ifdef APNS_ENABLED
#import "APNSManager.h"
#endif

@interface IdentityDelegate()
{
    pthread_mutex_t mutexVisibleWebView;
}
@property (nonatomic,strong) NSMutableDictionary* loginWebViewsDictionary;
@property (nonatomic, weak) HOPAccountIdentity* identityMutexOwner;

- (WebLoginViewController*) getLoginWebViewForIdentity:(HOPAccountIdentity*) accountIdentity create:(BOOL) create;
- (void) removeLoginWebViewForIdentity:(HOPAccountIdentity*) accountIdentity;
@end

@implementation IdentityDelegate

- (id)init
{
    self = [super init];
    if (self)
    {
        self.loginWebViewsDictionary = [[NSMutableDictionary alloc] init];
        pthread_mutex_init(&mutexVisibleWebView, NULL);
    }
    return self;
}

/**
 Retrieves web login view for specific identity. If web login view doesn't exist it will be created.
 @param identity HOPAccountIdentity Login user identity.
 @returns WebLoginViewController web login view
 */
- (WebLoginViewController*) getLoginWebViewForIdentity:(HOPAccountIdentity*) accountIdentity create:(BOOL)create
{
    WebLoginViewController* ret = nil;
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Get login web view for identity objectId:%d", accountIdentity, [[accountIdentity getObjectId] intValue]);
    
    ret = [self.loginWebViewsDictionary objectForKey:[accountIdentity getObjectId]];
 
    if (create && !ret)
    {
        //ret = [[LoginManager sharedLoginManager] preloadedWebLoginViewController];
        //if (!ret)
        {
            ret= [[WebLoginViewController alloc] initWithCoreObject:accountIdentity];
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Created web view: %p \nidentity uri: %@ \nidentity object id:%d",accountIdentity, ret,[accountIdentity getIdentityURI],[[accountIdentity getObjectId] intValue]);
        }
        ret.view.hidden = YES;
        ret.coreObject = accountIdentity;
        [self.loginWebViewsDictionary setObject:ret forKey:[accountIdentity getObjectId]];
        //[[LoginManager sharedLoginManager] setPreloadedWebLoginViewController:nil];
    }
    else
    {
        if (ret)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Retrieved exisitng web view:%p for identity objectId:%d", accountIdentity, ret, [[accountIdentity getObjectId] intValue]);
        }
        else
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"<%p> Identity - getLoginWebViewForIdentity - NO VALID WEB VIEW:%p - %d", accountIdentity, ret, [[accountIdentity getObjectId] intValue]);
    }
    return ret;
}

- (void) removeLoginWebViewForIdentity:(HOPAccountIdentity*) accountIdentity
{
    [self.loginWebViewsDictionary removeObjectForKey:[accountIdentity getObjectId]];
}

- (void)identity:(HOPAccountIdentity *)accountIdentity stateChanged:(HOPAccountIdentityState)state
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity login state has changed to: %@ - identityURI: %@",accountIdentity, [HOPAccountIdentity stringForIdentityState:state], [accountIdentity getIdentityURI]);
    
    //Prevent to have two web views visible at the time
    if (state == HOPIdentityStateWaitingForBrowserWindowToBeMadeVisible)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity tries to obtain web view visibility mutex. identityURI: %@ identityObjectId: %d",accountIdentity,[accountIdentity getIdentityURI], [[accountIdentity getObjectId] integerValue]);
        pthread_mutex_lock(&mutexVisibleWebView);
        self.identityMutexOwner = accountIdentity;
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity owns web view visibility mutex. identityURI: %@ identityObjectId: %d",accountIdentity,[accountIdentity getIdentityURI],[[accountIdentity getObjectId] integerValue]);
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^
//    {
        WebLoginViewController* webLoginViewController = nil;
        
        switch (state)
        {
            case HOPIdentityStatePending:
                
                break;
            
            case HOPIdentityStatePendingAssociation:
                
                break;
                
            case HOPIdentityStateWaitingAttachmentOfDelegate:
            {
                [[LoginManager sharedLoginManager] attachDelegateForIdentity:accountIdentity forceAttach:NO];
            }
                break;
                
            case HOPIdentityStateWaitingForBrowserWindowToBeLoaded:
            {
                webLoginViewController = [self getLoginWebViewForIdentity:accountIdentity create:YES];
                if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isAssociation])
                {
                    [self.loginDelegate onOpeningLoginPage];
                }

                if ([[LoginManager sharedLoginManager] preloadedWebLoginViewController] != webLoginViewController)
                {
                    //Open identity login web page
                    [webLoginViewController openLoginUrl:[[Settings sharedSettings] getOuterFrameURL]];
                }
            }
                break;
                
            case HOPIdentityStateWaitingForBrowserWindowToBeMadeVisible:
            {
                webLoginViewController = [self getLoginWebViewForIdentity:accountIdentity create:NO];
                [self.loginDelegate onLoginWebViewVisible:webLoginViewController];

                //Notify core that identity login web view is visible now
                [accountIdentity notifyBrowserWindowVisible];
            }
                break;
                
            case HOPIdentityStateWaitingForBrowserWindowToClose:
            {
                webLoginViewController = [self getLoginWebViewForIdentity:accountIdentity create:NO];
                [self.loginDelegate onIdentityLoginWebViewClose:webLoginViewController forIdentityURI:[accountIdentity getIdentityURI]];
                
                //Notify core that identity login web view is closed
                [accountIdentity notifyBrowserWindowClosed];
                
                if ([[self.identityMutexOwner getObjectId] intValue] == [[accountIdentity getObjectId] intValue])
                {
                    self.identityMutexOwner = nil;
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity releases web view visibility mutex. identityURI: %@",accountIdentity,[accountIdentity getIdentityURI]);
                    pthread_mutex_unlock(&mutexVisibleWebView);
                }
                
                [self removeLoginWebViewForIdentity:accountIdentity];
            }
                break;
                
            case HOPIdentityStateReady:
                [self.loginDelegate onIdentityLoginFinished];
#ifdef APNS_ENABLED
                [[APNSManager sharedAPNSManager] handleExistingMessages];
#endif
                if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isAssociation])
                    [[LoginManager sharedLoginManager] onIdentityAssociationFinished:accountIdentity];
                break;
                
            case HOPIdentityStateShutdown:
            {
                HOPIdnState* identityState = [accountIdentity getState];
                if (identityState.lastErrorCode)
                    [self.loginDelegate onIdentityLoginError:identityState.lastErrorReason];
                [accountIdentity destroyCoreObject];
                [self.loginDelegate onIdentityLoginShutdown];
            }
                break;
                
            default:
                break;
        }
    //});
}

- (void)onIdentityPendingMessageForInnerBrowserWindowFrame:(HOPAccountIdentity *)accountIdentity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity: pending message for inner browser window frame.",accountIdentity);
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        //Get login web view for specified identity
        WebLoginViewController* webLoginViewController = [self getLoginWebViewForIdentity:accountIdentity create:NO];
        if (webLoginViewController)
        {
            NSString* jsMethod = [NSString stringWithFormat:@"sendBundleToJS(\'%@\')", [accountIdentity getNextMessageForInnerBrowerWindowFrame]];

            //Pass JSON message to java script
            [webLoginViewController passMessageToJS:jsMethod];
        }
    });
}

- (void)onIdentityContactsDownloaded:(HOPAccountIdentity *)accountIdentity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identities are downloaded.",accountIdentity);
    //Remove activity indicator
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    
    if (accountIdentity)
    {
        HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[accountIdentity getBaseIdentityURI] homeUserStableId:[[HOPAccount sharedAccount] getStableID]];
        
        BOOL outFlushAllIdentities;
        NSString* downloadedVersion;
        NSArray* identities;
        
        //Get downloaded identities
        BOOL identitiesObtained = [accountIdentity getDownloadedIdentities:&outFlushAllIdentities outVersionDownloaded:&downloadedVersion outIdentities:&identities];
        
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Identity URI: %@ - Total number of identities: %d",[accountIdentity getIdentityURI], [identities count]);
        
        if ([downloadedVersion length] > 0)
            associatedIdentity.downloadedVersion = downloadedVersion;
        
        //Stop timer that is started when outFlushAllIdentities is received
        [accountIdentity stopTimerForContactsDeletion];
        
        if (identitiesObtained)
        {
            //Unmark all received contacts, that were earlier set for deletion 
            [identities setValue:[NSNumber numberWithBool:NO] forKey:@"readyForDeletion"];
            
            [[ContactsManager sharedContactsManager] identityLookupForContacts:identities identityServiceDomain:[accountIdentity getIdentityProviderDomain]];
            
            //Check if there are more contacts marked for deletion
            NSArray* contactsToDelete = [[HOPModelManager sharedModelManager] getAllIdentitiesMarkedForDeletionForHomeUserIdentityURI:[accountIdentity getIdentityURI]];
            
            //If there is more contacts for deletion start timer again. If update for marked contacts is not received before timer expire, delete all marked contacts
            if ([contactsToDelete count] > 0)
                [accountIdentity startTimerForContactsDeletion];
            
            [[[[OpenPeer sharedOpenPeer] mainViewController] contactsTableViewController] onContactsLoaded];
        }
        else if (outFlushAllIdentities)
        {
            //Get all identities that are alredy in the database
            NSArray* allUserIdentitiesContacts = [[HOPModelManager sharedModelManager]getIdentitiesForAccountIdentityURI:[accountIdentity getIdentityURI] openPeerContacts:NO];
            
            [accountIdentity startTimerForContactsDeletion];
            [allUserIdentitiesContacts setValue:[NSNumber numberWithBool:YES] forKey:@"readyForDeletion"];
            //[[HOPModelManager sharedModelManager] saveContext];
        }
        [[HOPModelManager sharedModelManager] saveContext];
        [[[ContactsManager sharedContactsManager] setOfIdentitiesWhoseContactsDownloadInProgress] removeObject:[accountIdentity getIdentityURI]];
    }
}

- (void) onNewIdentity:(HOPAccountIdentity*) accountIdentity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity: Handling a new identity with the uri:%@", accountIdentity,[accountIdentity getIdentityURI]);
    [[LoginManager sharedLoginManager] attachDelegateForIdentity:accountIdentity forceAttach:YES];
}

- (void) removeAllWebViewControllers
{
    [self.loginWebViewsDictionary removeAllObjects];
}
@end

