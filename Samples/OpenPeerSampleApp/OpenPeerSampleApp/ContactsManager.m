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
#import "SBJsonParser.h"
#import <OpenpeerSDK/HOPIdentityLookup.h>
#import <OpenpeerSDK/HOPIdentityLookupInfo.h>
#import <OpenpeerSDK/HOPIdentity.h>
#import <OpenpeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
#import <OpenpeerSDK/HOPUtility.h>
//#import <OpenpeerSDK/HOPOpenPeerContact+External.h>
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

/*- (void) loadAddressBookContacts
{
    NSMutableArray* contactsForIdentityLookup = [[NSMutableArray alloc] init];
    ABAddressBookRef addressBook = NULL;
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
        // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else
    {
        // we're on iOS 5 or older
        accessGranted = YES;
    }

    // import local contacts
    if(accessGranted)
    {
        CFErrorRef error = nil;
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
        if (error)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Unable to read the contacts from the address book.");
            if (addressBookRef)
                CFRelease(addressBookRef);
            
            return;
        }
        
        if (addressBookRef)
        {
            CFArrayRef allPeopleRef = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            if (allPeopleRef)
            {
                CFIndex nPeople = ABAddressBookGetPersonCount(addressBookRef);
                
                for (int z = 0; z < nPeople; z++)
                {
                    ABRecordRef person =  CFArrayGetValueAtIndex(allPeopleRef, z);
                    
                    NSString* firstName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                    NSString* lastName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
                    NSString* fullNameTemp = @"";
                    
                                        
                    if (firstName)
                    {
                        fullNameTemp = [firstName stringByAppendingString:@" "];
                    }
                    
                    if (lastName)
                    {
                        fullNameTemp= [fullNameTemp stringByAppendingString:lastName];
                    }
                    
                    NSString* identityURI = nil;
                    ABMultiValueRef social = ABRecordCopyValue(person, kABPersonSocialProfileProperty);
                    if (social)
                    {
                        int numberOfSocialNetworks = ABMultiValueGetCount(social);
                        for (CFIndex i = 0; i < numberOfSocialNetworks; i++)
                        {
                            NSDictionary *socialItem = (__bridge_transfer NSDictionary*)ABMultiValueCopyValueAtIndex(social, i);
                            
                            NSString* service = [socialItem objectForKey:(NSString *)kABPersonSocialProfileServiceKey];
                            if ([[service lowercaseString] isEqualToString:@"openpeer"])
                            {
                                NSString* username = [socialItem objectForKey:(NSString *)kABPersonSocialProfileUsernameKey];
                                if ([username length] > 0)
                                    identityURI = [NSString stringWithFormat:@"%@%@",[[Settings sharedSettings] getIdentityFederateBaseURI],[username lowercaseString]];
                            }
                        }
                        CFRelease(social);
                    }

                    if ([identityURI length] > 0)
                    {
                        //Execute core data manipulation on main thread to prevent app freezing. 
                        dispatch_sync(dispatch_get_main_queue(), ^
                        {
                            HOPRolodexContact* rolodexContact = [[HOPModelManager sharedModelManager] getRolodexContactByIdentityURI:identityURI];
                            if (!rolodexContact)
                            {
                                //Create a new menaged object for new rolodex contact
                                NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPRolodexContact"];
                                if ([managedObject isKindOfClass:[HOPRolodexContact class]])
                                {
                                    rolodexContact = (HOPRolodexContact*)managedObject;

                                    HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[[Settings sharedSettings] getIdentityFederateBaseURI] homeUserStableId:[[HOPAccount sharedAccount] getStableID]];

                                    rolodexContact.associatedIdentity = associatedIdentity;
                                    rolodexContact.identityURI = identityURI;
                                    if (fullNameTemp.length > 0)
                                        rolodexContact.name = fullNameTemp;
                                    [[HOPModelManager sharedModelManager] saveContext];
                                }
                            }
                        
                            if (rolodexContact)
                                [contactsForIdentityLookup addObject:rolodexContact];
                        });
                    }
                }
                CFRelease(allPeopleRef);
            }
            CFRelease(addressBookRef);
        }
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Finished loading contacts from the address book.");
    }
    
    HOPIdentityLookup* identityLookup = [[HOPIdentityLookup alloc] initWithDelegate:(id<HOPIdentityLookupDelegate>)[[OpenPeer sharedOpenPeer] identityLookupDelegate] identityLookupInfos:contactsForIdentityLookup identityServiceDomain:[[Settings sharedSettings] getIdentityProviderDomain]];
    
    if (identityLookup)
        [self.identityLookupsArray addObject:identityLookup];
}*/
/**
 Initiates contacts loading procedure.
 */
- (void) loadContacts
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Init loading contacts");
    
    //For the first login and association it should be performed contacts download on just associated identity
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    for (HOPIdentity* identity in associatedIdentities)
    {
        if (![self.setOfIdentitiesWhoseContactsDownloadInProgress containsObject:[identity getIdentityURI]])
        {
            [self.setOfIdentitiesWhoseContactsDownloadInProgress addObject:[identity getIdentityURI]];
            if (![identity isDelegateAttached])
                [[LoginManager sharedLoginManager] attachDelegateForIdentity:identity forceAttach:NO];
            
            HOPAssociatedIdentity* associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[identity getBaseIdentityURI] homeUserStableId:[[HOPAccount sharedAccount] getStableID]];
        
            if ([[LoginManager sharedLoginManager] isLogin] || [[LoginManager sharedLoginManager] isAssociation])
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] onContactsLoadingStarted];
            }
            
            [identity startRolodexDownload:associatedIdentity.downloadedVersion];
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Start rolodex contacts download - identity URI: - Version: %@",[identity getIdentityURI], associatedIdentity.downloadedVersion);
        }
    }
    
}

- (void) refreshExisitngContacts
{
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    for (HOPIdentity* identity in associatedIdentities)
    {
        NSArray* rolodexContactsForRefresh = [[HOPModelManager sharedModelManager] getRolodexContactsForRefreshByHomeUserIdentityURI:[identity getIdentityURI] lastRefreshTime:[NSDate date]];
        
        if ([rolodexContactsForRefresh count] > 0)
            [self identityLookupForContacts:rolodexContactsForRefresh identityServiceDomain:[identity getIdentityProviderDomain]];
    }
}

- (void) refreshRolodexContacts
{
    NSArray* associatedIdentities = [[HOPAccount sharedAccount] getAssociatedIdentities];
    
    [[HOPModelManager sharedModelManager] clearAPNSData];
    
    for (HOPIdentity* identity in associatedIdentities)
    {
        if (![self.setOfIdentitiesWhoseContactsDownloadInProgress containsObject:[identity getIdentityURI]])
        {
            [self.setOfIdentitiesWhoseContactsDownloadInProgress addObject:[identity getIdentityURI]];
            [identity refreshRolodexContacts];
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
