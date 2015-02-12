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


@class HOPIdentity;
@class HOPAssociatedIdentity;
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
@class HOPConversation;
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
 Returns a identity for a specified identity URI.
 @param identityURI Identity URI
 @return HOPIdentity HOPIdentity object
 */
- (HOPIdentity*) getIdentityByIdentityURI:(NSString*) identityURI;

/**
 Returns a identity with highest priority for a specified peer URI.
 @param peerURI Peer URI
 @return HOPIdentity HOPIdentity object
 */
- (HOPIdentity *) getIdentityByPeerURI:(NSString*) peerURI;

/**
 Returns an array of identities for a specified peer URI.
 @param peerURI Contact peer URI
 @return An array of HOPIdentity objects
 */
- (NSArray*) getIdentitiesByPeerURI:(NSString*) peerURI;

/**
 Returns an array of all identities for home user identity URI.
 @param homeUserIdentityURI Home user identity URI
 @return An array of HOPIdentity objects
 */
- (NSArray*) getAllIdentitiesForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns an array of all or just registered identities for home user identity URI.
 @param homeUserIdentityURI Home user identity URI
 @param openPeerContacts If YES is passed, only registered identities will be returned
 @return An array of HOPIdentity objects
 */
- (NSArray*) getIdentitiesForAccountIdentityURI:(NSString*) homeUserIdentityURI openPeerContacts:(BOOL) openPeerContacts;


/**
 Returns an associated identity object for spcified base identity uri and home user stable ID.
 @param baseIdentityURI Base identity uri
 @param homeUserStableId Home user stable ID
 @return HOPAssociatedIdentity object
 */
- (HOPAssociatedIdentity*) getAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI homeUserStableId:(NSString*) homeUserStableId;


/**
 Returns last logged in user.
 @return HOPOpenPeerAccount object
 */
- (HOPOpenPeerAccount*) getLastLoggedInUser;



/**
 Deletes all marked identities for home user specific identity URI.
 @param homeUserIdentityURI Home user identity URI
 */
- (void) deleteAllMarkedIdentitiesForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns all identities ready for deletion for home user specific identity URI.
 @param homeUserIdentityURI Home user identity URI
 @return An array of identities ready for deleteion
 */
- (NSArray*) getAllIdentitiesMarkedForDeletionForHomeUserIdentityURI:(NSString*) homeUserIdentityURI;

/**
 Returns all identities that should be refreshed. It refreshes all contacts that are not openpeer and contacts that are refreshed some time ago.
 @param homeUserIdentityURI Home user identity URI
 @param lastRefreshTime All contacts that are refreshed earlier than this date should be refreshed
 @return Array of identities ready for refresh
 */
- (NSArray*) getIdentitiesForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime;

/**
 Returns device tokens for specific URI.
 @param peerURI Contact peer URI
 @return An array of device tokens associated to peer URI
 */
- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI;

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
//- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date conversation:(HOPConversation*) conversation contact:(HOPIdentity*) contact messageId:(NSString*)messageId;

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
//- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date  visible:(BOOL) visible  conversation:(HOPConversation*) conversation contact:(HOPIdentity*) contact messageId:(NSString*)messageId;

//- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date  visible:(BOOL) visible  conversation:(HOPConversation*) conversation contact:(HOPIdentity*) contact messageId:(NSString*)messageId validated:(BOOL) validated messageIDToReplace:(NSString*) messageIDToReplace;



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


- (HOPConversationRecord*) getConversationRecordForParticipants:(NSArray*) participants;



/**
 Creates a HOPConversationRecord object.
 @param conversationThread Conversation thread object
 @param type Conversation type
 @param date Time of creation
 @param name Conversation name
 @param participants List of HOPIdentity objects
 @return HOPConversationRecord  object
 */
- (HOPConversationRecord*) createConversationRecordForConversationThread:(HOPConversationThread*) conversationThread type:(NSString*) type date:(NSDate*) date name:(NSString*) name participants:(NSArray*) participants;

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
- (void) updateMessageStateForConversation:(HOPConversation*) conversation lastDeliveryState:(HOPConversationThreadMessageDeliveryState) messageDeliveryState;


/**
 Creates a conversation event.
 @param eventType Event type
 @param conversationRecord Conversation record for which event is being added
 @param participants List of participants that are affected with conversation event
 @param title Event title, that would be used for display in application
 @return HOPConversationEvent object
 */
- (HOPConversationEvent*) addConversationEvent:(NSString*) eventType conversationRecord:(HOPConversationRecord*) conversationRecord partcipants:(NSArray*) participants title:(NSString*) title;




- (NSFetchRequest*) getMessagesFetchRequestForConversation:(HOPConversation*) conversation sortAscending:(BOOL) ascending;


/**
 Returns HOPIdentity object for logged in user.
 @return HOPIdentity object
 */
- (HOPIdentity*) getIdentityForAccount;


@end
