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


#import "OpenPeerStorageManager.h"
#import "HOPCall.h"
#import "HOPCoreContact.h"
#import "HOPConversationThread.h"
#import "HOPAccountIdentity.h"
#import "HOPIdentityLookup.h"
#import "HOPConversation_Internal.h"
#import "HOPUtility.h"

@interface OpenPeerStorageManager()

- (void) initSingleton;
@end

@implementation OpenPeerStorageManager

+ (id)sharedStorageManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
        if (_sharedObject)
            [_sharedObject initSingleton];
    });
    return _sharedObject;
}

- (void) initSingleton
{
    _dictionaryCalls = [[NSMutableDictionary alloc] init];
    _dictionaryContacts = [[NSMutableDictionary alloc] init];
//    _dictionaryContactsWithUserId = [[NSMutableDictionary alloc] init];
    _dictionaryConversationThreads = [[NSMutableDictionary alloc] init];
    _dictionaryConversations = [[NSMutableDictionary alloc] init];
    _dictionaryConversationsWithThreadID = [[NSMutableDictionary alloc] init];
    _dictionaryConversationsWithCBCID = [[NSMutableDictionary alloc] init];
    _dictionaryIdentities = [[NSMutableDictionary alloc] init];
    _dictionaryIdentityLookups = [[NSMutableDictionary alloc] init];
//    _dictionaryContactPeerFilePublicLookup = [[NSMutableDictionary alloc] init];
}


- (HOPCall*) getCallForId:(NSString*) callId
{
    HOPCall* call = nil;
    
    call = [_dictionaryCalls objectForKey:callId];
    
    return call;
}

- (void) setCall:(HOPCall*) call forId:(NSString*) callId
{
    [_dictionaryCalls setObject:call forKey:callId];
}

- (HOPConversationThread*) getConversationThreadForId:(NSString*) threadId
{
    HOPConversationThread* conversationThread = nil;
    
    conversationThread = [_dictionaryConversationThreads objectForKey:threadId];
    
    return conversationThread;
}

- (NSArray*) getConversationThreads
{
    return [_dictionaryConversationThreads allValues];
}
- (void) setConversationThread:(HOPConversationThread*) conversationThread forId:(NSString*) threadId
{
    [_dictionaryConversationThreads setObject:conversationThread forKey:threadId];
}

- (HOPConversation*) getConversationForID:(NSString*) conversationID
{
    if (conversationID.length > 0)
        return [_dictionaryConversations objectForKey:conversationID];
    else
        return nil;
}
- (HOPConversation*) getConversationForThreadID:(NSString*) threadID
{
    if (threadID.length > 0)
        return [_dictionaryConversationsWithThreadID objectForKey:threadID];
    else
        return nil;
}
- (HOPConversation*) getConversationForCBCID:(NSString*) cbcID
{
    if (cbcID.length > 0)
        return [_dictionaryConversationsWithCBCID objectForKey:cbcID];
    else
        return nil;
}
- (NSArray*) getConversations
{
    return _dictionaryConversations.allValues;
}

- (void) setConversation:(HOPConversation*) conversation conversationID:(NSString*) conversationID
{
    if (conversation && conversationID.length > 0)
        [_dictionaryConversations setObject:conversation forKey:conversationID];
}
- (void) setConversation:(HOPConversation*) conversation threadID:(NSString*) threadID
{
    if (conversation && threadID.length > 0)
        [_dictionaryConversationsWithThreadID setObject:conversation forKey:threadID];
}
- (void) setConversation:(HOPConversation*) conversation cbcID:(NSString*) cbcID
{
    if (conversation && cbcID.length > 0)
        [_dictionaryConversationsWithCBCID setObject:conversation forKey:cbcID];
}

- (void) removeConversation:(HOPConversation*) conversation
{
    [_dictionaryConversations removeObjectForKey:conversation.conversationID];
    [_dictionaryConversationsWithThreadID removeObjectForKey:[conversation.thread getThreadId]];
    if (conversation.conversationType == HOPConversationThreadTypeContactBased)
        [_dictionaryConversationsWithCBCID removeObjectForKey:[HOPUtility getCBCIDForContacts:conversation.participants]];
}


- (HOPCoreContact*) getCoreContactForPeerURI:(NSString*) peerURI
{
    HOPCoreContact* contact = nil;
    
    contact = [_dictionaryContacts objectForKey:peerURI];
    
    return contact;
}
- (void) setContact:(HOPCoreContact*) contact forPeerURI:(NSString*) peerURI
{
    [_dictionaryContacts setObject:contact forKey:peerURI];
}


/*- (HOPProvisioningAccount*) getProvisioningAccountForUserId:(NSString*) userId
{
    HOPProvisioningAccount* provisioningAccount = nil;
    
    provisioningAccount = [_dictionaryProvisioningAccount objectForKey:userId];
    
    return provisioningAccount;
}

- (void) setCProvisioningAccount:(HOPProvisioningAccount*) account forUserId:(NSString*) userId
{
    [_dictionaryProvisioningAccount setObject:account forKey:userId];
}*/

- (HOPAccountIdentity*) getIdentityForId:(NSString*) identityId
{
    HOPAccountIdentity* ret = nil;
    
    ret = [_dictionaryIdentities objectForKey:identityId];
    
    return ret;
}
- (NSArray*) getIdentities
{
    return [_dictionaryIdentities allValues];
}

- (void) setIdentity:(HOPAccountIdentity*) accountIdentity forId:(NSString*) identityId
{
    [_dictionaryIdentities setObject:accountIdentity forKey:identityId];
}

- (void) setIdentity:(HOPAccountIdentity*) accountIdentity forPUID:(PUID) puid
{
    [_dictionaryIdentities setObject:accountIdentity forKey:[NSNumber numberWithInt:puid]];
}
- (void) removeIdentityWithPUID:(PUID) puid
{
    [_dictionaryIdentities removeObjectForKey:[NSNumber numberWithInt:puid]];
}
- (HOPAccountIdentity*) getIdentityForPUID:(PUID) puid
{
    return [_dictionaryIdentities objectForKey:[NSNumber numberWithInt:puid]];
}


- (HOPIdentityLookup*) getIdentityLookupForPUID:(PUID) puid
{
    return [_dictionaryIdentityLookups objectForKey:[NSNumber numberWithInt:puid]];
}
- (void) setIdentityLookup:(HOPIdentityLookup*) lookup forPUID:(PUID) puid
{
    [_dictionaryIdentityLookups setObject:lookup forKey:[NSNumber numberWithInt:puid]];
}

- (void) totalCleanup
{
    for (HOPCall* object in [_dictionaryCalls allValues])
    {
        [object destroyCoreObject];
    }
    [_dictionaryCalls removeAllObjects];
    
    for (HOPConversationThread* object in [_dictionaryConversationThreads allValues])
    {
        [object destroyCoreObject];
    }
    [_dictionaryConversationThreads removeAllObjects];
    
//    for (HOPAccountIdentity* object in [_dictionaryIdentities allValues])
//    {
//        [object destroyCoreObject];
//    }
//    [_dictionaryIdentities removeAllObjects];
    
    for (HOPCoreContact* object in [_dictionaryContacts allValues])
    {
        [object destroyCoreObject];
    }
    [_dictionaryContacts removeAllObjects];
    
    for (HOPIdentityLookup* object in [_dictionaryIdentityLookups allValues])
    {
        [object destroyCoreObject];
    }
    [_dictionaryIdentityLookups removeAllObjects];
}
@end
