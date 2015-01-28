/*
 
 Copyright (c) 2014, Hookflash Inc.
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

#import "HOPModelManager.h"
#import <openpeer/core/types.h>

using namespace openpeer;
using namespace openpeer::core;

@interface HOPModelManager()

- (HOPOpenPeerContact*) getOpenPeerContactForIdentityContact:(IdentityContact) inIdentityContact;
- (HOPOpenPeerContact*) createOpenPeerContactForIdentityContact:(IdentityContact) inIdentityContact;
- (HOPOpenPeerContact*) createOrUpdateOpenPeerContactForItentities:(NSArray*) identities coreContact:(IContactPtr) coreContact;
- (void) updateOpenPeerContact:(HOPOpenPeerContact*) contact identityContact:(IdentityContact) inIdentityContact;

/**
 Creates a peer file object for the given peer URI and peer file
 @param peerURI Peer URI
 @param peerFile Peer file
 @return HOPPublicPeerFile object
 */
- (HOPPublicPeerFile*) createPublicPeerFileForPeerURI:(NSString*) peerURI peerFile:(NSString*) peerFile;
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
 Returns HOPParticipants object for list of contacts
 @param contacts List of HOPOpenPeerContact objects
 @return HOPParticipants object
 */
- (HOPParticipants*) getParticiapantsForListOfContacts:(NSArray*) contacts;

/**
 Creates a HOPConversationThreadRecord object for conversation thread and conversation record.
 @param conversationThread Conversation thread object (Holds information about core conversation thread object that is used for message exchange)
 @param conversationRecord Conversation record object (Represent a logic unit, which can be linked to more than one conversation thread records)
 @return HOPConversationRecord Conversation record object
 */
- (HOPConversationThreadRecord*) createRecordForConversationThread:(HOPConversationThread*) conversationThread conversationRecord:(HOPConversationRecord*) conversationRecord;

/**
 Returns a list of HOPConversationRecord objects for a conversation thread ID.
 @param threadID Conversation thread ID
 @return NSArray List of conversation record objects
 */
- (NSArray*) getConversationRecordsForThreadID:(NSString*) threadID;

/**
 Returns a HOPConversationThreadRecord object for conversation thread ID.
 @param threadID Conversation thread ID
 @return HOPConversationThreadRecord Conversation thread record object
 */
- (HOPConversationThreadRecord*) getConversationThreadRecordForThreadID:(NSString*) threadID;

/**
 Returns a HOPConversationRecord object for conversation thread.
 @param conversationThread Conversation thread object
 @return HOPConversationRecord Conversation record object
 */
- (HOPConversationRecord*) getConversationRecordForConversationThread:(HOPConversationThread*) conversationThread;

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
 Returns home user with specified stable ID.
 @param stableId Contact stable ID
 @return HOPOpenPeerAccount object
 */
- (HOPOpenPeerAccount*) getAccountForStableID:(NSString*) stableID;

/**
 Returns an avatar object for the spcified url.
 @param url Image url
 @return HOPAvatar object
 */
- (HOPAvatar*) getAvatarByURL:(NSString*) url;

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
 Returns an identity contact for specified stable ID and identity URI.
 @param identityURI Identity URI
 @return HOPIdentityContact object
 */
- (HOPIdentityContact*) getIdentityContactWithIdentityURI:(NSString*) identityURI;
@end
