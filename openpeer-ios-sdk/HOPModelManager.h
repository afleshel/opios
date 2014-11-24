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
#import "HOPTypes.h"

@class NSManagedObjectContext;
@class NSManagedObjectModel;
@class NSPersistentStoreCoordinator;
@class NSManagedObject;
@class NSFetchRequest;


@class HOPRolodexContact;
@class HOPAssociatedIdentity;
@class HOPIdentityContact;
@class HOPPublicPeerFile;
@class HOPOpenPeerAccount;
@class HOPAvatar;
@class HOPConversationRecord;
@class HOPMessageRecord;
@class HOPConversationThreadRecord;
@class HOPConversationThread;
@class HOPOpenPeerContact;
@class HOPConversationEvent;
@class HOPParticipants;
/**
 *  This is the singleton class and it is used for manipulation with core data.
 */
@interface HOPModelManager : NSObject

//These properties are not marked as readonly because it is left possibility for app developer to integrate its own .xcdatamodel file with OpenPeerModel.xcdatamodel and to use one model object, one context object and one persistent storage. In this case NSManagedObjectModel objects need to be initiated and merged at the application startup and right after that, directly from application, to set managedObjectContext, managedObjectModel and persistentStoreCoordinator properties.

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 Returns singleton object of HOPModelManager class.
 */
+ (id)sharedModelManager;

/**
 *  This init method is not available, because HOPModelManager is a singleton class.
 *
 */
- (id) init __attribute__((unavailable("HOPModelManager is singleton class.")));

/**
 *  Sets path for cache persistent storage. If not set it will be used default path.
 *
 *  @param path File path
 */
- (void) setCachePath:(NSString*) path;

/**
 *  Sets path for data persistent storage. If not set it will be used default path.
 *
 *  @param path File path
 */
- (void) setDataPath:(NSString*) path backupData:(BOOL) inBackupData;

/**
 *  Returns application's Documents directory URL
 *
 *  @return Documents directory URL
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
 @param entityName Entity name
 @return NSManagedObject instance of the class for a spcified entity
 */
- (NSManagedObject*) createObjectForEntity:(NSString*) entityName;

/**
 Returns a rolodex contact for a specified identity URI.
 @param identityURI Identity URI
 @return HOPRolodexContact HOPRolodexContact object
 */
- (HOPRolodexContact*) getRolodexContactByIdentityURI:(NSString*) identityURI;

/**
 Returns a rolodex contact with highest priority for a specified peer URI.
 @param peerURI Peer URI
 @return HOPRolodexContact HOPRolodexContact object
 */
- (HOPRolodexContact *) getRolodexContactByPeerURI:(NSString*) peerURI;

/**
 Returns an array of rolodex contacts for a specified peer URI.
 @param peerURI Contact peer URI
 @return An array of HOPRolodexContact objects
 */
- (NSArray*) getRolodexContactsByPeerURI:(NSString*) peerURI;

/**
 Returns an array of all rolodex contacts for home user identity URI.
 @param homeUserIdentityURI Home user identity URI
 @return An array of HOPRolodexContact objects
 */
- (NSArray*) getAllRolodexContactForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns an array of all or just registered rolodex contacts for home user identity URI.
 @param homeUserIdentityURI Home user identity URI
 @param openPeerContacts If YES is passed, only registered rolodex contacts will be returned
 @return An array of HOPRolodexContact objects
 */
- (NSArray*) getRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI openPeerContacts:(BOOL) openPeerContacts;

/**
 Returns an identity contact for specified stable ID and identity URI.
 @param identityURI Identity URI
 @return HOPIdentityContact object
 */
- (HOPIdentityContact*) getIdentityContactWithIdentityURI:(NSString*) identityURI;

/**
 Returns a public peer file object for the spcified peer URI.
 @param peerURI Peer URI
 @return HOPPublicPeerFile object
 */
- (HOPPublicPeerFile*) getPublicPeerFileForPeerURI:(NSString*) peerURI;

/**
 Finalise identity association. Information about associated identity for active account is store in permanent storage
 @param baseIdentityURI Base identity URI
 @param domain Identity provider domain
 @param name Identity name
 @param account Open Peer account
 @param rolodexContact Rolodex contact of associated identity
 @return HOPAssociatedIdentity object
 */
- (HOPAssociatedIdentity*) addAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI domain:(NSString*) domain name:(NSString*) name selfRolodexProfileProfile:(HOPRolodexContact*) rolodexContact;

 /**
 Returns an identity provider object for spcified identity provider domain, identity name and home user identity URI.
 @param identityProviderDomain Identity provider domain
 @param identityName Identity name (e.g. foo.com)
 @param homeUserIdentityURI Home user identity URI
 @return HOPAssociatedIdentity object
 */
- (HOPAssociatedIdentity*) getAssociatedIdentityByDomain:(NSString*) identityProviderDomain identityName:(NSString*) identityName homeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns an associated identity object for spcified base identity uri and home user stable ID.
 @param baseIdentityURI Base identity uri
 @param homeUserStableId Home user stable ID
 @return HOPAssociatedIdentity object
 */
- (HOPAssociatedIdentity*) getAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI homeUserStableId:(NSString*) homeUserStableId;


/**
 Returns an avatar object for the spcified url.
 @param url Image url
 @return HOPAvatar object
 */
- (HOPAvatar*) getAvatarByURL:(NSString*) url;

/**
 Returns last logged in user.
 @return HOPOpenPeerAccount object
 */
- (HOPOpenPeerAccount*) getLastLoggedInUser;

/**
 Returns home user with specified stable ID.
 @param stableId Contact stable ID
 @return HOPOpenPeerAccount object
 */
- (HOPOpenPeerAccount*) getAccountForStableID:(NSString*) stableID;

/**
 Deletes all marked rolodex contacts for home user specific identity URI.
 @param homeUserIdentityURI Home user identity URI
 */
- (void) deleteAllMarkedRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns all rolodex contacts ready for deletion for home user specific identity URI.
 @param homeUserIdentityURI Home user identity URI
 @return An array of rolodex contacts ready for deleteion
 */
- (NSArray*) getAllRolodexContactsMarkedForDeletionForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns all rolodex contacts that should be refreshed. It refreshes all contacts that are not openpeer and contacts that are refreshed some time ago.
 @param homeUserIdentityURI Home user identity URI
 @param lastRefreshTime All contacts that are refreshed earlier than this date should be refreshed
 @return Array of rolodex contacts ready for refresh
 */
- (NSArray*) getRolodexContactsForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime;

/**
 Returns device tokens for specific URI.
 @param peerURI Contact peer URI
 @return An array of device tokens associated to peer URI
 */
- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI;

- (NSArray*) getPushNotificationDataForPeerURI:(NSString*) peerURI;
/**
 Sets device token for specific peer URI.
 @param deviceToken Device token used for sending push notification
 @param type Type of push
 @param peerURI Contacts peer uri
 */
- (void) setAPNSData:(NSString*) deviceToken type:(NSString*) type PeerURI:(NSString*) peerURI;

/**
 *  Delete push notification data for all contacts
 */
- (void) clearAPNSData;

/**
 Gets cookie for path.
 @param path NSString* cookie path
 @return Cookie value
 */
- (NSString*) getCookieWithPath:(NSString*) path;

/**
 Sets cookie data.
 @param data Cookie's data
 @param path Cookie's path
 @param expires Cookie's expire date
 */
- (void) setCookie:(NSString*) data withPath:(NSString*) path expires:(NSDate*) expires;

/**
 Removes all expired cookies.
 */
- (void) removeExpiredCookies;

/**
 Removes cookie with path.
 @param path Cookie's path
 */
- (void) removeCookieForPath:(NSString*) path;


/**
 Creates a HOPMessageRecord object.
 @param messageText Message text
 @param type Message type
 @param date Time of creation
 @param conversationThreadID Conversation Thread ID
 @param openPeerContact Sender - HOPOpenPeerContact object
 @param messageId Message ID
 @param conversationEvent Conversation event during which message has been received or sent
 @return HOPMessageRecord* message record object
 */
- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date conversationThreadID:(NSString*) conversationThreadID contact:(HOPRolodexContact*) contact messageId:(NSString*)messageId conversationEvent:(HOPConversationEvent*) conversationEvent;

/**
 Creates a HOPMessageRecord object.
 @param messageText Message text
 @param type Message type
 @param date Time of creation
 @param visible True if message should be visible in chat
 @param conversationThreadID Conversation Thread ID
 @param openPeerContact Sender - HOPOpenPeerContact object
 @param messageId Message ID
 @param conversationEvent Conversation event during which message has been received or sent
 @return HOPMessageRecord* message record object
 */
- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date  visible:(BOOL) visible  conversationThreadID:(NSString*) conversationThreadID contact:(HOPRolodexContact*) contact messageId:(NSString*)messageId conversationEvent:(HOPConversationEvent*) conversationEvent;

/**
 Returns peer URI for logged in user.
 @return peer URI
 */
- (NSString*) getPeerURIForHomeUser;

/**
 Returns a HOPConversationRecord object for conversation ID.
 @param conversationID Conversation ID
 @return HOPConversationRecord Conversation record object
 */
- (HOPConversationRecord *) getConversationRecordByID:(NSString*) conversationID;

/**
 Returns a HOPMessageRecord object for message ID.
 @param messageID Message ID
 @return HOPMessageRecord Message record object
 */
- (HOPMessageRecord *) getMessageRecordByID:(NSString*) messageID;

/**
 Returns a HOPConversationRecord object for conversation thread.
 @param conversationThread Conversation thread object
 @return HOPConversationRecord Conversation record object
 */
- (HOPConversationRecord*) getConversationRecordForConversationThread:(HOPConversationThread*) conversationThread;

/**
 Returns a HOPConversationThreadRecord object for conversation thread ID.
 @param threadID Conversation thread ID
 @return HOPConversationThreadRecord Conversation thread record object
 */
- (HOPConversationThreadRecord*) getConversationThreadRecordForThreadID:(NSString*) threadID;

/**
 Returns a list of HOPConversationRecord objects for a conversation thread ID.
 @param threadID Conversation thread ID
 @return NSArray List of conversation record objects
 */
- (NSArray*) getConversationRecordsForThreadID:(NSString*) threadID;

/**
 Creates a HOPConversationThreadRecord object for conversation thread and conversation record.
 @param conversationThread Conversation thread object (Holds information about core conversation thread object that is used for message exchange)
 @param conversationRecord Conversation record object (Represent a logic unit, which can be linked to more than one conversation thread records)
 @return HOPConversationRecord Conversation record object
 */
- (HOPConversationThreadRecord*) createRecordForConversationThread:(HOPConversationThread*) conversationThread conversationRecord:(HOPConversationRecord*) conversationRecord;

/**
 Creates a HOPConversationRecord object.
 @param conversationThread Conversation thread object
 @param type Conversation type
 @param date Time of creation
 @param name Conversation name
 @param participants List of HOPRolodexContact objects
 @return HOPConversationRecord  object
 */
- (HOPConversationRecord*) createConversationRecordForConversationThread:(HOPConversationThread*) conversationThread type:(NSString*) type date:(NSDate*) date name:(NSString*) name participants:(NSArray*) participants;

/**
 Creates a NSFetchRequest object.
 @param conversationID Conversation ID
 @param sortAscending Sort messages in ascending order
 @return NSFetchRequest  object
 */
- (NSFetchRequest*) getMessagesFetchRequestForConversationID:(NSString*) conversationID sortAscending:(BOOL) ascending;

/**
 Replaces old message text with a new one.
 @param replacesMessageID Message ID of the message that will be replaced
 @param newMessageID New message ID
 @param messageText  New text of the message
 */
- (void) replaceMessageWithID:(NSString*) replacesMessageID newMessageID:(NSString*) newMessageID messageText:(NSString*) messageText;

/**
 Update message delivary state (sent, delivered, read) for conversation.
 @param conversationRecord Conversation thread record
 @param messageDeliveryState MEssage delivery state
 */
- (void) updateMessageStateForConversation:(HOPConversationRecord*) conversationRecord lastDeliveryState:(HOPConversationThreadMessageDeliveryState) messageDeliveryState;

/**
 Returns open peer contact for peer URI.
 @param peerURI Peer URI
 @return HOPOpenPeerContact object
 */
- (HOPOpenPeerContact*) getOpenPeerContactForPeerURI:(NSString*) peerURI;

/**
 Returns open peer contact for stable ID.
 @param stableID Stable ID
 @return HOPOpenPeerContact object
 */
- (HOPOpenPeerContact*) getOpenPeerContactForStableID:(NSString*) stableID;

/**
 Returns open peer contact for identity URI.
 @param identityURI Identity URI
 @return HOPOpenPeerContact object
 */
- (HOPOpenPeerContact*) getOpenPeerContactForIdentityURI:(NSString*) identityURI;

/**
 Returns list of open peer contacts for list of peer URIs.
 @param peerURIs List of peer URIs
 @return List of HOPOpenPeerContact objects
 */
- (NSArray *) getOpenPeerContactsByPeerURIs:(NSArray*) peerURIs;

/**
 Creates a conversation event.
 @param eventType Event type
 @param conversationRecord Conversation record for which event is being added
 @param participants List of participants that are affected with conversation event
 @param title Event title, that would be used for display in application
 @return HOPConversationEvent object
 */
- (HOPConversationEvent*) addConversationEvent:(NSString*) eventType conversationRecord:(HOPConversationRecord*) conversationRecord partcipants:(NSArray*) participants title:(NSString*) title;

/**
 Returns HOPParticipants object for list of contacts
 @param contacts List of HOPOpenPeerContact objects
 @return HOPParticipants object
 */
- (HOPParticipants*) getParticiapantsForListOfContacts:(NSArray*) contacts;

/**
 Returns fetch request for the list of messages exchanged within group of participants
 @param participants HOPParticipants object
 @param ascending Sort ascending
 @return NSFetchRequest object
 */
- (NSFetchRequest*) getMessagesFetchRequestForParticipants:(HOPParticipants*) participants sortAscending:(BOOL) ascending;

/**
 Returns HOPOpenPeerContact object for logged in user.
 @return HOPOpenPeerContact object
 */
- (HOPOpenPeerContact*) getOpenPeerContactForAccount;

- (HOPRolodexContact*) getRolodexContactContactForAccount;
/**
 Creates a peer file object for the given peer URI and peer file
 @param peerURI Peer URI
 @param peerFile Peer file
 @return HOPPublicPeerFile object
 */
- (HOPPublicPeerFile*) createPublicPeerFileForPeerURI:(NSString*) peerURI peerFile:(NSString*) peerFile;
@end
