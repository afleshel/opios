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


#import <Foundation/Foundation.h>
#import <openpeer/core/types.h>
#import <zsLib/types.h>

@class HOPCall;
@class HOPConversationThread;
@class HOPCoreContact;
@class HOPAccountIdentity;
@class HOPIdentityLookup;
@class HOPBackgroundingNotifier;
@class HOPBackgroundingSubscription;
@class HOPConversation;

using namespace zsLib;

@interface OpenPeerStorageManager : NSObject
{
    NSMutableDictionary* _dictionaryCalls;
    NSMutableDictionary* _dictionaryConversationThreads;
    NSMutableDictionary* _dictionaryConversations;
    NSMutableDictionary* _dictionaryConversationsWithThreadID;
    NSMutableDictionary* _dictionaryConversationsWithCBCID;
    
    NSMutableDictionary* _dictionaryContacts;
//    NSMutableDictionary* _dictionaryContactsWithUserId;
//NSMutableDictionary* _dictionaryProvisioningAccount;
    NSMutableDictionary* _dictionaryIdentities;
    NSMutableDictionary* _dictionaryIdentityLookups;
//    NSMutableDictionary* _dictionaryContactPeerFilePublicLookup;
}

@property (strong, nonatomic) HOPBackgroundingNotifier* backgroundingNotifier;
@property (strong, nonatomic) HOPBackgroundingSubscription* backgroundingSubscription;

+ (id)sharedStorageManager;

- (HOPCall*) getCallForId:(NSString*) callId;
- (void) setCall:(HOPCall*) call forId:(NSString*) callId;

- (HOPConversationThread*) getConversationThreadForId:(NSString*) threadId;
- (NSArray*) getConversationThreads;
- (void) setConversationThread:(HOPConversationThread*) conversationThread forId:(NSString*) threadId;

- (HOPConversation*) getConversationForID:(NSString*) conversationID;
- (HOPConversation*) getConversationForThreadID:(NSString*) threadID;
- (HOPConversation*) getConversationForCBCID:(NSString*) cbcID;
- (NSArray*) getConversations;
- (void) setConversation:(HOPConversation*) conversation conversationID:(NSString*) conversationID;
- (void) setConversation:(HOPConversation*) conversation threadID:(NSString*) threadID;
- (void) setConversation:(HOPConversation*) conversation cbcID:(NSString*) cbcID;
- (void) removeConversation:(HOPConversation*) conversation;
- (HOPCoreContact*) getCoreContactForPeerURI:(NSString*) peerURI;
- (void) setContact:(HOPCoreContact*) contact forPeerURI:(NSString*) contactId;

//- (HOPProvisioningAccount*) getProvisioningAccountForUserId:(NSString*) userId;
//- (void) setCProvisioningAccount:(HOPProvisioningAccount*) account forUserId:(NSString*) userId;

- (HOPAccountIdentity*) getIdentityForId:(NSString*) identityId;
- (void) setIdentity:(HOPAccountIdentity*) accountIdentity forId:(NSString*) identityId;
- (void) removeIdentityWithPUID:(PUID) puid;
- (HOPAccountIdentity*) getIdentityForPUID:(PUID) puid;
- (void) setIdentity:(HOPAccountIdentity*) accountIdentity forPUID:(PUID) puid;
- (NSArray*) getIdentities;

- (HOPIdentityLookup*) getIdentityLookupForPUID:(PUID) puid;
- (void) setIdentityLookup:(HOPIdentityLookup*) lookup forPUID:(PUID) puid;

- (void) totalCleanup;
@end
