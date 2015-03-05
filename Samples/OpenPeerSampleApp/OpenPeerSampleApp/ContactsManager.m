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

#import "ContactsManager.h"
#import "SessionManager.h"
#import "MessageManager.h"
#import "LoginManager.h"

#import "MainViewController.h"
#import "ContactsViewController.h"
#import "ActivityIndicatorViewController.h"
#import "OpenPeer.h"
#import "AppConsts.h"
#import "Utility.h"
#import <OpenpeerSDK/HOPIdentityLookup.h>
#import <OpenpeerSDK/HOPIdentityLookupInfo.h>
#import <OpenpeerSDK/HOPAccountIdentity.h>
#import <OpenpeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPIdentity+External.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
#import <OpenpeerSDK/HOPIdentityProvider.h>
#import <OpenpeerSDK/HOPUtility.h>
#import <AddressBook/AddressBook.h>

@interface ContactsManager ()
{
    NSString* keyJSONContactFirstName;
    NSString* keyJSONContacLastName;
    NSString* keyJSONContactId;
    NSString* keyJSONContactProfession;
    NSString* keyJSONContactPictureURL;
    NSString* keyJSONContactFullName;
}
- (id) initSingleton;

@end
@implementation ContactsManager

/**
 Retrieves singleton object of the Contacts Manager.
 @return Singleton object of the Contacts Manager.
 */
+ (id) sharedContactsManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

/**
 Initialize singleton object of the Contacts Manager.
 @return Singleton object of the Contacts Manager.
 */
- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        self.identityLookupsArray = [[NSMutableArray alloc] init];
        self.setOfIdentitiesWhoseContactsDownloadInProgress = [[NSMutableSet alloc] init];
    }
    return self;
}

/**
 Initiates contacts loading procedure.
 */
- (void) loadContacts
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Init loading contacts");
    
    //For the first login and association it should be performed contacts download on just associated identity
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    for (HOPAccountIdentity* accountIdentity in associatedIdentities)
    {
        if (![self.setOfIdentitiesWhoseContactsDownloadInProgress containsObject:[accountIdentity getIdentityURI]])
        {
            [self.setOfIdentitiesWhoseContactsDownloadInProgress addObject:[accountIdentity getIdentityURI]];
            if (![accountIdentity isDelegateAttached])
                [[LoginManager sharedLoginManager] attachDelegateForIdentity:accountIdentity forceAttach:NO];
            
            HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[accountIdentity getBaseIdentityURI] homeUserStableId:[[HOPAccount sharedAccount] getStableID]];
        
            if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isAssociation])
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] onContactsLoadingStarted];
            }
            
            [accountIdentity startIdentitiesDownload:associatedIdentity.downloadedVersion];
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Start identities download - identity URI: - Version: %@",[accountIdentity getIdentityURI], associatedIdentity.downloadedVersion);
        }
    }
    
}

- (void) refreshExisitngContacts
{
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    for (HOPAccountIdentity* accountIdentity in associatedIdentities)
    {
        NSArray* identitiesForRefresh = [[HOPModelManager sharedModelManager] getIdentitiesForRefreshByHomeUserIdentityURI:[accountIdentity getIdentityURI] lastRefreshTime:[NSDate date]];
        
        if ([identitiesForRefresh count] > 0)
            [self identityLookupForContacts:identitiesForRefresh identityServiceDomain:[accountIdentity getIdentityProviderDomain]];
    }
}

- (void) refreshIdentities
{
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    [[HOPModelManager sharedModelManager] clearAPNSData];
    
    for (HOPAccountIdentity* accountIdentity in associatedIdentities)
    {
        if (![self.setOfIdentitiesWhoseContactsDownloadInProgress containsObject:[accountIdentity getIdentityURI]])
        {
            [self.setOfIdentitiesWhoseContactsDownloadInProgress addObject:[accountIdentity getIdentityURI]];
            [accountIdentity refreshIdentities];
        }
    }
}

/**
 Check contact identites against openpeer database.
 @param contacts NSArray List of contacts.
 */
- (void) identityLookupForContacts:(NSArray *)contacts identityServiceDomain:(NSString*) identityServiceDomain
{
    HOPIdentityLookup* identityLookup = [[HOPIdentityLookup alloc] initWithDelegate:(id<HOPIdentityLookupDelegate>)[[OpenPeer sharedOpenPeer] identityLookupDelegate] identityLookupInfos:contacts identityServiceDomain:identityServiceDomain];
    
    if (identityLookup)
        [self.identityLookupsArray addObject:identityLookup];
}

- (void) identityLookupForContacts:(NSArray *)contacts
{
    if (contacts.count > 0)
    {
        for (HOPAccountIdentity* associatedIdentity in [[HOPAccount sharedAccount] getAssociatedIdentities])
        {
            HOPIdentityLookup* identityLookup = [[HOPIdentityLookup alloc] initWithDelegate:(id<HOPIdentityLookupDelegate>)[[OpenPeer sharedOpenPeer] identityLookupDelegate] identityLookupInfos:contacts identityServiceDomain:[associatedIdentity getIdentityProviderDomain]];
            
            if (identityLookup)
                [self.identityLookupsArray addObject:identityLookup];
        }
    }
}

/**
 Handles response received from lookup server. 
 */
-(void)updateContactsWithDataFromLookup:(HOPIdentityLookup *)identityLookup
{
    BOOL refreshContacts = NO;
    NSError* error;
    if ([identityLookup isComplete:&error])
    {
        HOPIdentityLookupResult* result = [identityLookup getLookupResult];
        if ([result wasSuccessful])
        {
            NSArray* identityContacts = [identityLookup getUpdatedIdentities];
            
            refreshContacts = [identityContacts count] > 0 ? YES : NO;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if (refreshContacts)
        {
            [[[[OpenPeer sharedOpenPeer] mainViewController] contactsTableViewController] onContactsLoaded];
        }
     });
    
    [self.identityLookupsArray removeObject:identityLookup];
}

- (void) removeAllContacts
{
    
}
@end
