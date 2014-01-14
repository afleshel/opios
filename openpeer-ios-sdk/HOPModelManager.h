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

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;
@class NSManagedObjectModel;
@class NSPersistentStoreCoordinator;
@class NSManagedObject;

@class HOPRolodexContact;
@class HOPAssociatedIdentity;
@class HOPIdentityContact;
@class HOPPublicPeerFile;
@class HOPHomeUser;
@class HOPAvatar;

@interface HOPModelManager : NSObject

//These properties are not marked as readonly because it is left possibility for app developer to integrate its own .xcdatamodel file with OpenPeerModel.xcdatamodel and to use one model object, one context object and one persistent storage. In this case NSManagedObjectModel objects need to be initiated and merged at the application startup and right after that, directly from application, to set managedObjectContext, managedObjectModel and persistentStoreCoordinator properties.

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id)sharedModelManager;
- (id) init __attribute__((unavailable("HOPModelManager is singleton class.")));

/**
 Retrieves the URL to the application's Documents directory.
 @return NSURL Documents directory URL
 */
- (NSURL*)applicationDocumentsDirectory;

/**
 Attempts to commit unsaved changes to registered objects to their persistent store.
 */
- (void)saveContext;

/**
 Specifies an object that should be removed from its persistent store when changes are committed.
 @param managedObjectToDelete NSManagedObject object ready for deletion
 */
- (void) deleteObject:(NSManagedObject*) managedObjectToDelete;

/**
 Creates, configures, and returns an instance of the class for the entity with a given name.
 @param entityName NSString entity name
 @return NSManagedObject instance of the class for spcified entity
 */
- (NSManagedObject*) createObjectForEntity:(NSString*) entityName;

/**
 Retrieves the rolodex contact for specified identity URI.
 @param identityURI NSString identity URI
 @return HOPRolodexContact rolodex contact object
 */
- (HOPRolodexContact*) getRolodexContactByIdentityURI:(NSString*) identityURI;

/**
 Retrieves the list of rolodex contacts for specified peer URI.
 @param peerURI NSString peer URI
 @return NSArray list of HOPRolodexContact objects
 */
- (NSArray*) getRolodexContactsByPeerURI:(NSString*) peerURI;

/**
 Retrieves the list of all rolodex contacts for home user identity URI.
 @param homeUserIdentityURI NSString home user identity URI
 @return NSArray list of HOPRolodexContact objects
 */
- (NSArray*) getAllRolodexContactForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Retrieves the list of all or just registered rolodex contacts for home user identity URI.
 @param openPeerContacts BOOL If YES is passed, only registered roldex contacts will be returned
 @param homeUserIdentityURI NSString home user identity URI
 @return NSArray list of HOPRolodexContact objects
 */
- (NSArray*) getRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI openPeerContacts:(BOOL) openPeerContacts;

/**
 Retrieves the identity contact for specified stable ID and identity URI.
 @param stableID NSString stable ID of registered contact
 @param identityURI NSString identity URI
 @return HOPRolodexContact rolodex contact object
 */
- (HOPIdentityContact*) getIdentityContactByStableID:(NSString*) stableID identityURI:(NSString*) identityURI;

/**
 Retrieves the array of identity contacts for specified stable ID.
 @param stableID NSString stable ID of registered contact
 @return NSArray Array of HOPRolodexContact objects
 */
- (NSArray*) getIdentityContactsByStableID:(NSString*) stableID;

/**
 Retrieves the public peer file object for spcified peer URI.
 @param peerURI NSString peer URI
 @return HOPPublicPeerFile public peer file object
 */
- (HOPPublicPeerFile*) getPublicPeerFileForPeerURI:(NSString*) peerURI;

/**
 Retrieves the identity provider object for spcified identity provider domain, identity name and home user identity URI.
 @param identityProviderDomain NSString identity provider domain
 @param identityName NSString identity name (e.g. foo.com)
 @param homeUserIdentityURI NSString home user identity URI
 @return HOPAssociatedIdentity identity provider object
 */
- (HOPAssociatedIdentity*) getAssociatedIdentityByDomain:(NSString*) identityProviderDomain identityName:(NSString*) identityName homeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Retrieves the identity provider object for spcified base identity uri and home user stable id.
 @param baseIdentityURI NSString base identity uri
 @param homeUserStableId NSString home user stable id
 @return HOPAssociatedIdentity identity provider object
 */
- (HOPAssociatedIdentity*) getAssociatedIdentityBaseIdentityURI:(NSString*) baseIdentityURI homeUserStableId:(NSString*) homeUserStableId;
/**
 Retrieves data about all home user associated identites.
 @param identityURI NSString home user identity URI
 @return NSArray array of HOPAssociatedIdentity objects
 */
- (NSArray*) getAllIdentitiesInfoForHomeUserIdentityURI:(NSString*) identityURI;

/**
 Retrieves the avatar object for spcified url.
 @param url NSString image url
 @return HOPAvatar avatar object
 */
- (HOPAvatar*) getAvatarByURL:(NSString*) url;

/**
 Retrieves the last logged in user.
 @return HOPHomeUser home user object
 */
- (HOPHomeUser*) getLastLoggedInHomeUser;

/**
 Retrieves home user with specified stable id.
 @param stableId NSString contact stble id
 @return HOPHomeUser home user object
 */
- (HOPHomeUser*) getHomeUserByStableID:(NSString*) stableID;

/**
 Deletes all marked rolodex contacts for home user specific identity URI.
 @param homeUserIdentityURI NSString user identity URI
 */
- (void) deleteAllMarkedRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Retrieves all rolodex contacts ready for deletion for home user specific identity URI.
 @param homeUserIdentityURI NSString user identity URI
 @return NSArray array of rolodex contacts ready for deleteion
 */
- (NSArray*) getAllRolodexContactsMarkedForDeletionForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Retrieves all rolodex contacts that should be refreshed. It refreshes all contacts that are not openpeer and contacts that are refreshed some time ago.
 @param homeUserIdentityURI NSString user identity URI
 @param lastRefreshTime NSDate all contacts that are refreshed earlier than this date should be refreshed
 @return NSArray array of rolodex contacts ready for refresh
 */
- (NSArray*) getRolodexContactsForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime;

/**
 Retrieves device tokens for specific URI.
 @param peerURI NSString contact peer URI
 @return NSArray array of device tokens associated to peer URI
 */
- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI;

/**
 Set device token for specific peer URI
 @param deviceToken NSString* device token used for sending push notification
 @param peerURI NSString* contacts peer uri
 */
- (void) setAPNSData:(NSString*) deviceToken PeerURI:(NSString*) peerURI;

- (NSString*) getCookieWithPath:(NSString*) path;
- (void) setCookie:(NSString*) data withPath:(NSString*) path expires:(NSDate*) expires;
- (void) removeExpiredCookies;
- (void) removeCookieForPath:(NSString*) path;
@end
