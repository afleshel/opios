/*
 
 Copyright (c) 2013, SMB Phone Inc.
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
#import <OpenpeerSDK/HOPIdentity.h>
#import <OpenpeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPRolodexContact.h>
#import <OpenpeerSDK/HOPIdentityContact.h>
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
#import "APNSInboxManager.h"
#endif

@interface IdentityDelegate()
{
    pthread_mutex_t mutexVisibleWebView;
}
@property (nonatomic,strong) NSMutableDictionary* loginWebViewsDictionary;
@property (nonatomic, weak) HOPIdentity* identityMutexOwner;

- (WebLoginViewController*) getLoginWebViewForIdentity:(HOPIdentity*) identity create:(BOOL) create;
- (void) removeLoginWebViewForIdentity:(HOPIdentity*) identity;
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
 @param identity HOPIdentity Login user identity.
 @returns WebLoginViewController web login view
 */
- (WebLoginViewController*) getLoginWebViewForIdentity:(HOPIdentity*) identity create:(BOOL)create
{
    WebLoginViewController* ret = nil;
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Get login web view for identity objectId:%d", identity, [[identity getObjectId] intValue]);
    
    ret = [self.loginWebViewsDictionary objectForKey:[identity getObjectId]];
 
    if (create && !ret)
    {
        //ret = [[LoginManager sharedLoginManager] preloadedWebLoginViewController];
        //if (!ret)
        {
            ret= [[WebLoginViewController alloc] initWithCoreObject:identity];
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Created web view: %p \nidentity uri: %@ \nidentity object id:%d",identity, ret,[identity getIdentityURI],[[identity getObjectId] intValue]);
        }
        ret.view.hidden = YES;
        ret.coreObject = identity;
        [self.loginWebViewsDictionary setObject:ret forKey:[identity getObjectId]];
        //[[LoginManager sharedLoginManager] setPreloadedWebLoginViewController:nil];
    }
    else
    {
        if (ret)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity - Retrieved exisitng web view:%p for identity objectId:%d", identity, ret, [[identity getObjectId] intValue]);
        }
        else
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"<%p> Identity - getLoginWebViewForIdentity - NO VALID WEB VIEW:%p - %d", identity, ret, [[identity getObjectId] intValue]);
    }
    return ret;
}

- (void) removeLoginWebViewForIdentity:(HOPIdentity*) identity
{
    [self.loginWebViewsDictionary removeObjectForKey:[identity getObjectId]];
}

- (void)identity:(HOPIdentity *)identity stateChanged:(HOPIdentityState)state
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity login state has changed to: %@ - identityURI: %@",identity, [HOPIdentity stringForIdentityState:state], [identity getIdentityURI]);
    
    //Prevent to have two web views visible at the time
    if (state == HOPIdentityStateWaitingForBrowserWindowToBeMadeVisible)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity tries to obtain web view visibility mutex. identityURI: %@ identityObjectId: %d",identity,[identity getIdentityURI], [[identity getObjectId] integerValue]);
        pthread_mutex_lock(&mutexVisibleWebView);
        self.identityMutexOwner = identity;
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity owns web view visibility mutex. identityURI: %@ identityObjectId: %d",identity,[identity getIdentityURI],[[identity getObjectId] integerValue]);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        WebLoginViewController* webLoginViewController = nil;
        
        switch (state)
        {
            case HOPIdentityStatePending:
                
                break;
            
            case HOPIdentityStatePendingAssociation:
                
                break;
                
            case HOPIdentityStateWaitingAttachmentOfDelegate:
            {
                [[LoginManager sharedLoginManager] attachDelegateForIdentity:identity forceAttach:NO];
            }
                break;
                
            case HOPIdentityStateWaitingForBrowserWindowToBeLoaded:
            {
                webLoginViewController = [self getLoginWebViewForIdentity:identity create:YES];
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
                webLoginViewController = [self getLoginWebViewForIdentity:identity create:NO];
                [self.loginDelegate onLoginWebViewVisible:webLoginViewController];

                //Notify core that identity login web view is visible now
                [identity notifyBrowserWindowVisible];
            }
                break;
                
            case HOPIdentityStateWaitingForBrowserWindowToClose:
            {
                webLoginViewController = [self getLoginWebViewForIdentity:identity create:NO];
                [self.loginDelegate onIdentityLoginWebViewClose:webLoginViewController forIdentityURI:[identity getIdentityURI]];
                
                //Notify core that identity login web view is closed
                [identity notifyBrowserWindowClosed];
                
                if ([[self.identityMutexOwner getObjectId] intValue] == [[identity getObjectId] intValue])
                {
                    self.identityMutexOwner = nil;
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity releases web view visibility mutex. identityURI: %@",identity,[identity getIdentityURI]);
                    pthread_mutex_unlock(&mutexVisibleWebView);
                }
                
                [self removeLoginWebViewForIdentity:identity];
            }
                break;
                
            case HOPIdentityStateReady:
                [self.loginDelegate onIdentityLoginFinished];
#ifdef APNS_ENABLED
                [[APNSInboxManager sharedAPNSInboxManager] handleNewMessages];
#endif
                if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isAssociation])
                    [[LoginManager sharedLoginManager] onIdentityAssociationFinished:identity];
                break;
                
            case HOPIdentityStateShutdown:
            {
                HOPIdnState* identityState = [identity getState];
                if (identityState.lastErrorCode)
                    [self.loginDelegate onIdentityLoginError:identityState.lastErrorReason];
                [identity destroyCoreObject];
                [self.loginDelegate onIdentityLoginShutdown];
            }
                break;
                
            default:
                break;
        }
    });
}

- (void)onIdentityPendingMessageForInnerBrowserWindowFrame:(HOPIdentity *)identity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity: pending message for inner browser window frame.",identity);
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        //Get login web view for specified identity
        WebLoginViewController* webLoginViewController = [self getLoginWebViewForIdentity:identity create:NO];
        if (webLoginViewController)
        {
            NSString* jsMethod = [NSString stringWithFormat:@"sendBundleToJS(\'%@\')", [identity getNextMessageForInnerBrowerWindowFrame]];

            //Pass JSON message to java script
            [webLoginViewController passMessageToJS:jsMethod];
        }
    });
}

- (void)onIdentityRolodexContactsDownloaded:(HOPIdentity *)identity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity rolodex contacts are downloaded.",identity);
    //Remove activity indicator
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    if (identity)
    {
        HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[identity getBaseIdentityURI] homeUserStableId:[[HOPAccount sharedAccount] getStableID]];
        
        BOOL flushAllRolodexContacts;
        NSString* downloadedVersion;
        NSArray* rolodexContacts;
        
        //Get downloaded rolodex contacts
        BOOL rolodexContactsObtained = [identity getDownloadedRolodexContacts:&flushAllRolodexContacts outVersionDownloaded:&downloadedVersion outRolodexContacts:&rolodexContacts];
        
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Identity URI: %@ - Total number of rolodex contacts: %d",[identity getIdentityURI], [rolodexContacts count]);
        
        if ([downloadedVersion length] > 0)
            associatedIdentity.downloadedVersion = downloadedVersion;
        
        //Stop timer that is started when flushAllRolodexContacts is received
        [identity stopTimerForContactsDeletion];
        
        if (rolodexContactsObtained)
        {
            //Unmark all received contacts, that were earlier set for deletion 
            [rolodexContacts setValue:[NSNumber numberWithBool:NO] forKey:@"readyForDeletion"];
            
            [[ContactsManager sharedContactsManager] identityLookupForContacts:rolodexContacts identityServiceDomain:[identity getIdentityProviderDomain]];
            
            //Check if there are more contacts marked for deletion
            NSArray* contactsToDelete = [[HOPModelManager sharedModelManager] getAllRolodexContactsMarkedForDeletionForHomeUserIdentityURI:[identity getIdentityURI]];
            
            //If there is more contacts for deletion start timer again. If update for marked contacts is not received before timer expire, delete all marked contacts
            if ([contactsToDelete count] > 0)
                [identity startTimerForContactsDeletion];
            
            [[[[OpenPeer sharedOpenPeer] mainViewController] contactsTableViewController] onContactsLoaded];
        }
        else if (flushAllRolodexContacts)
        {
            //Get all rolodex contacts that are alredy in the database
            NSArray* allUserRolodexContacts = [[HOPModelManager sharedModelManager]getRolodexContactsForHomeUserIdentityURI:[identity getIdentityURI] openPeerContacts:NO];
            
            [identity startTimerForContactsDeletion];
            [allUserRolodexContacts setValue:[NSNumber numberWithBool:YES] forKey:@"readyForDeletion"];
            //[[HOPModelManager sharedModelManager] saveContext];
        }
        [[HOPModelManager sharedModelManager] saveContext];
        [[[ContactsManager sharedContactsManager] setOfIdentitiesWhoseContactsDownloadInProgress] removeObject:[identity getIdentityURI]];
    }
}

- (void) onNewIdentity:(HOPIdentity*) identity
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"<%p> Identity: Handling a new identity with the uri:%@", identity,[identity getIdentityURI]);
    [[LoginManager sharedLoginManager] attachDelegateForIdentity:identity forceAttach:YES];
}

- (void) removeAllWebViewControllers
{
    [self.loginWebViewsDictionary removeAllObjects];
}
@end

