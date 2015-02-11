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


#import <openpeer/core/IConversationThread.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IHelper.h>
#import <openpeer/core/ComposingStatus.h>
#import <openpeer/core/ISystemMessage.h>
#include <zsLib/Stringize.h>
#include <zsLib/XML.h>

#import "HOPConversationThread_Internal.h"
#import "HOPCoreContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "HOPMessageRecord+External.h"
#import "HOPModelManager_Internal.h"
#import "HOPIdentityContact_Internal.h"
#import "HOPOpenPeerContact.h"
#import "HOPRolodexContact_Internal.h"
#import "HOPAssociatedIdentity.h"
#import "HOPIdentityProvider.h"
#import "HOPOpenPeerContact_Internal.h"
#import "OpenPeerStorageManager.h"
#import "OpenPeerUtility.h"
#import "HOPAccountIdentity_Internal.h"
#import "HOPPublicPeerFile.h"
#import "HOPConversationType.h"
#import "HOPSettings.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@interface HOPConversationThread ()
+ (ContactProfileInfoListPtr) getContactProfileListForContacts:(NSArray*) contacts;
@end

@implementation HOPConversationThread

- (id)init
{
    [NSException raise:NSInvalidArgumentException format:@"Don't use init for object creation. Use class method conversationThreadWithProfileBundle."];
    return nil;
}

- (id) initWithConversationThread:(IConversationThreadPtr) inConversationThreadPtr
{
    self = [super init];
    if (self)
    {
        self.participants = [NSMutableArray new];
        conversationThreadPtr = inConversationThreadPtr;
        [[OpenPeerStorageManager sharedStorageManager] setConversationThread:self forId:[NSString stringWithUTF8String:inConversationThreadPtr->getThreadID()]];
        
        self.conversationType = HOPConversationThreadTypeNone;
        
        ElementPtr elementPtr = inConversationThreadPtr->getMetaData();
        String str = IHelper::convertToString(elementPtr);
        if (str)
        {
            NSString* jsonString = [NSString stringWithUTF8String:str];
            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            id dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (dict)
            {
                NSDictionary* dictConversationType = [dict objectForKey:@"metaData"];
                if (dictConversationType)
                {
                    NSString* type = [dictConversationType objectForKey:@"conversationType"];
                    if (type.length > 0)
                        self.conversationType = [HOPConversationType conversationThreadTypeForString: type];
                }
            }
        }
        else
        {
            if (conversationThreadPtr->getContacts()->size() > 1 && [[HOPSettings sharedSettings] getDefaultCovnersationType] == HOPConversationThreadTypeThreadBased)
            {
                self.conversationType = HOPConversationThreadTypeThreadBased;
            }
            else
            {
                self.conversationType = HOPConversationThreadTypeContactBased;
            }
        }
#warning TODO_S: Read conversation type from core conversation thred object
        //TODO_S: Read conversation type from core conversation thred object
    }
    return self;
}


+ (NSDictionary*) createMetadataDictionary:(HOPConversationThreadType) threadType
{
    HOPConversationType* conversationType = [[HOPConversationType alloc] initWithConversationThreadType:threadType];

    NSDictionary* conversationTypeDict = [NSDictionary dictionaryWithObject:[HOPConversationType stringForConversationThreadType:threadType] forKey:[NSString stringWithUTF8String:ConversationThreadType::Definitions::Names::conversationType()]];
    NSDictionary* dict = [NSDictionary dictionaryWithObject:conversationTypeDict forKey:[NSString stringWithUTF8String:IConversationThread::Definitions::Names::metaDataName()]];
    
    return dict;
}

//{"metaData" : { "conversationType" : "contact" } }
+ (id) conversationThreadWithIdentities:(NSArray*) identities participants:(NSArray*) participants conversationThreadID:(NSString*) conversationThreadID threadType:(HOPConversationThreadType) threadType
{
    HOPConversationThread* ret = nil;
    core::IdentityContactList identityContactsList;
    
    for (HOPAccountIdentity* accountIdentity in identities)
    {
        IdentityContact identityContact;
        [accountIdentity getIdentityPtr]->getSelfIdentityContact(identityContact);
        
        identityContactsList.push_back(identityContact);
    }
    
    ContactProfileInfoListPtr contactListPtr = [HOPConversationThread getContactProfileListForContacts:participants];
    
    NSDictionary* metaData = [HOPConversationThread createMetadataDictionary:threadType];
    
    NSError* err;
    NSData *jsonData =[NSJSONSerialization dataWithJSONObject:metaData options:0 error:&err];
    
    NSString *metaDatastr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];//[NSString stringWithUTF8String:[jsonData bytes]];
    
    ElementPtr elementPtr = IHelper::createElement([metaDatastr UTF8String]);
    
    IConversationThreadPtr tempConversationThreadPtr = IConversationThread::create([[HOPAccount sharedAccount] getAccountPtr], identityContactsList, *contactListPtr,conversationThreadID.length > 0 ? [conversationThreadID UTF8String] : "",elementPtr);
    
    if (tempConversationThreadPtr)
    {
        ret = [[self alloc] initWithConversationThread:tempConversationThreadPtr];
        [ret.participants addObjectsFromArray:participants];
        if (ret.conversationType == HOPConversationThreadTypeNone)
            ret.conversationType = threadType;
    }
    
    [ret refreshParticipants];
    
    return ret;
}

+ (id) conversationThreadWithIdentities:(NSArray*) identities
{
    HOPConversationThread* ret = nil;
    core::IdentityContactList identityContactsList;
    
    for (HOPAccountIdentity* accountIdentity in identities)
    {
        IdentityContact identityContact;
        [accountIdentity getIdentityPtr]->getSelfIdentityContact(identityContact);
        
        identityContactsList.push_back(identityContact);
    }
    
    IConversationThreadPtr tempConversationThreadPtr = IConversationThread::create([[HOPAccount sharedAccount] getAccountPtr], identityContactsList);
    
    if (tempConversationThreadPtr)
    {
        ret = [[self alloc] initWithConversationThread:tempConversationThreadPtr];
        ret.conversationType = [[HOPSettings sharedSettings] getDefaultCovnersationType];
    }
    
    [ret refreshParticipants];
    
    return ret;
}

+ (NSArray*) getActiveConversationThreads
{
    return [[OpenPeerStorageManager sharedStorageManager] getConversationThreads];
}

+ (HOPConversationThread*) getConversationThreadForID:(NSString*) threadID
{
    HOPConversationThread* ret = nil;
    if (threadID)
    {
        ret =[[OpenPeerStorageManager sharedStorageManager] getConversationThreadForId:threadID];
        if (!ret)
        {
            IConversationThreadPtr tempConversationThreadPtr = IConversationThread::getConversationThreadByID([[HOPAccount sharedAccount] getAccountPtr], [threadID UTF8String]);
            if (tempConversationThreadPtr)
            {
                ret = [[HOPConversationThread alloc] initWithConversationThread:tempConversationThreadPtr];
                [ret refreshParticipants];
                if (ret.conversationType == HOPConversationThreadTypeNone)
                    ret.conversationType = [[HOPSettings sharedSettings] getDefaultCovnersationType];
            }
        }
    }
    return ret;
}

- (NSString*) getConversationThreadID
{
    NSString* ret = nil;
    
    String threadID = conversationThreadPtr->getThreadID();
    
    if (threadID)
        ret = [NSString stringWithUTF8String:threadID];
    
    return ret;
}

+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::MessageDeliveryStates) state)];
}

+ (HOPConversationThreadMessageDeliveryState) toMessageDeliveryStates:(NSString*) messageDeliveryStateString
{
    if ([messageDeliveryStateString isEqualToString:(@"Discovering")])
        return HOPConversationThreadMessageDeliveryStateDiscovering;
    else if ([messageDeliveryStateString isEqualToString:(@"User not available")])
        return HOPConversationThreadMessageDeliveryStateUserNotAvailable;
    else if ([messageDeliveryStateString isEqualToString:(@"Sent")])
        return HOPConversationThreadMessageDeliveryStateSent;
    else if ([messageDeliveryStateString isEqualToString:(@"Delivered")])
        return HOPConversationThreadMessageDeliveryStateDelivered;
    else
        return HOPConversationThreadMessageDeliveryStateRead;
}


+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::ContactConnectionStates) state)];
}


- (NSString*) getThreadId
{
    NSString* threadId = nil;
    
    if(conversationThreadPtr)
    {
        threadId = [NSString stringWithUTF8String: conversationThreadPtr->getThreadID()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    return threadId;
}

- (BOOL) amIHost
{
    BOOL ret = NO;
    if (conversationThreadPtr)
    {
        ret = conversationThreadPtr->amIHost();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    return ret;
}

- (HOPAccount*) getAssociatedAccount
{
    return [HOPAccount sharedAccount];
}

//- (NSArray*) getContacts
//{
//
//    return self.participants;
//}

- (void) refreshParticipants
{
    [self.participants removeAllObjects];
    
    if (conversationThreadPtr)
    {
        ContactListPtr contactList = conversationThreadPtr->getContacts();
        
        for (ContactList::iterator contact = contactList->begin(); contact != contactList->end(); ++contact)
        {
            IContactPtr contactPtr = *contact;
            if (!contactPtr->isSelf())
            {
                //It is not obtained rolodex contact, because we need to be sure that open peer contact exists. If doesn't exists create a new one.
                HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                
                /*if (!openPeerContact)
                {
                    openPeerContact = [[HOPModelManager sharedModelManager] createOpenPeerContacFromCoreContact:contactPtr conversationThread:conversationThreadPtr];
                }*/
                
                if (openPeerContact)
                    [self.participants addObject:[openPeerContact getDefaultRolodexContact]];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}
+ (ContactProfileInfoListPtr) getContactProfileListForContacts:(NSArray*) contacts
{
    ContactProfileInfoListPtr contactListPtr(new ContactProfileInfoList);
    
    for (HOPRolodexContact* rolodexContact in contacts)
    {
        HOPCoreContact* contact = [rolodexContact getCoreContact];
        if (contact)
        {
            ContactProfileInfo contactInfo;
            IdentityContactList identityContactList;
            contactInfo.mContact = [contact getContactPtr];
            
            HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:[contact getPeerURI]];
            if (openPeerContact)
            {
                for (HOPIdentityContact* identityContact in openPeerContact.identityContacts)
                {
                    IdentityContact coreIdentityContact;
                    
                    coreIdentityContact.mIdentityProofBundleEl = IHelper::createElement([identityContact.identityProofBundle UTF8String]);
                    coreIdentityContact.mStableID = [openPeerContact.stableID UTF8String];
                    coreIdentityContact.mPriority = identityContact.priority.intValue;
                    coreIdentityContact.mWeight = identityContact.weight.intValue;
                    
                    if (identityContact.rolodexContact)
                    {
                        if (identityContact.rolodexContact.identityURI.length > 0)
                            coreIdentityContact.mIdentityURI = [identityContact.rolodexContact.identityURI UTF8String];
                        if (identityContact.rolodexContact.name.length > 0)
                            coreIdentityContact.mName = [identityContact.rolodexContact.name UTF8String];
                        if (identityContact.rolodexContact.profileURL.length > 0)
                            coreIdentityContact.mProfileURL = [identityContact.rolodexContact.profileURL UTF8String];
                    }
                    if (identityContact.rolodexContact.associatedIdentity && identityContact.rolodexContact.associatedIdentity.identityProvider)
                        coreIdentityContact.mIdentityProvider = [identityContact.rolodexContact.associatedIdentity.identityProvider.domain UTF8String];
                    
                    identityContactList.push_back(coreIdentityContact);
                }
            }
            contactInfo.mIdentityContacts = identityContactList;
            contactListPtr->push_back(contactInfo);
//            [self.participants addObject:rolodexContact];
        }
    }
    
    return contactListPtr;
}

- (void) addContacts: (NSArray*) contacts
{
    if(conversationThreadPtr)
    {
        if ([contacts count] > 0)
        {
            ContactProfileInfoListPtr contactListPtr = [HOPConversationThread getContactProfileListForContacts:contacts];
            for (HOPRolodexContact* rolodexContact in contacts)
            {
                if ([rolodexContact getCoreContact])
                    [self.participants addObject:rolodexContact];
            }
            
            conversationThreadPtr->addContacts(*contactListPtr);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

- (void) removeContacts: (NSArray*) contacts
{
    if(conversationThreadPtr)
    {
        if ([contacts count] > 0)
        {
            ContactList contactList;
            for (HOPRolodexContact* contact in contacts)
            {
                HOPCoreContact* coreContact = [contact getCoreContact];
                if (coreContact)
                {
                    contactList.push_back([coreContact getContactPtr]);
                    [self.participants removeObject:contact];
                }
            }
            conversationThreadPtr->removeContacts(contactList);
            
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

- (NSArray*) getIdentityContactListForCoreContact:(IContactPtr) contact
{
    NSMutableArray* ret = nil;
    IdentityContactListPtr identityContactListPtr = conversationThreadPtr->getIdentityContactList(contact);
    if (identityContactListPtr)
    {
        ret = [[NSMutableArray alloc] init];
        for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
        {
            IdentityContact identityContact = *identityContactInfo;
            if (identityContact.hasData())
            {
                //NSString* sId = [NSString stringWithUTF8String:identityContact.mStableID];
                NSString* identityURI = [NSString stringWithUTF8String:identityContact.mIdentityURI];
                HOPIdentityContact* hopIdentityContact = [[HOPModelManager sharedModelManager] getIdentityContactWithIdentityURI:identityURI];
                
                if (!hopIdentityContact)
                {
                    NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPIdentityContact"];
                    if (managedObject && [managedObject isKindOfClass:[HOPIdentityContact class]])
                    {
                        hopIdentityContact = (HOPIdentityContact*) managedObject;
                    }
                }
                
                if (hopIdentityContact)
                {
                    [hopIdentityContact updateWithIdentityContact:identityContact];
                    
                    [ret addObject:hopIdentityContact];
                }
            }
        }
        [[HOPModelManager sharedModelManager] saveContext];
    }
    return ret;
}
- (NSArray*) getIdentityContactListForContact:(HOPCoreContact*) rolodexCoontact
{
    NSArray* ret = nil;
    if(conversationThreadPtr)
    {
        HOPCoreContact* contact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[rolodexCoontact getPeerURI]];
        if (contact)
            ret = [self getIdentityContactListForCoreContact:[contact getContactPtr]];
    }
    
    return ret;
}

- (HOPConversationThreadContactConnectionState) getContactConnectionState: (HOPRolodexContact*) rolodexCoontact
{
    HOPConversationThreadContactConnectionState ret = HOPConversationThreadContactConnectionStateNotApplicable;
    if(conversationThreadPtr)
    {
        HOPCoreContact* contact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[rolodexCoontact getPeerURI]];
        if (contact)
            ret = (HOPConversationThreadContactConnectionState) conversationThreadPtr->getContactConnectionState([contact getContactPtr]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return ret;
}

- (NSString*) createEmptyStatus
{
    NSString* ret = nil;
    
    if(conversationThreadPtr)
    {
        ElementPtr emptyStatusJSONPtr = conversationThreadPtr->createEmptyStatus();
        String str = IHelper::convertToString(emptyStatusJSONPtr);
        ret = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return ret;
}

- (HOPComposingState) getComposingStateForContact:(HOPRolodexContact*) rolodexCoontact
{
    HOPComposingState ret = HOPComposingStateInactive;
    if(conversationThreadPtr)
    {
        HOPCoreContact* contact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[rolodexCoontact getPeerURI]];
        IContactPtr contactPtr = [contact getContactPtr];
        if (contactPtr)
        {
            ElementPtr contactStatusJSONPtr = conversationThreadPtr->getContactStatus(contactPtr);
            if (contactStatusJSONPtr)
            {
                ComposingStatusPtr composingStatusPtr = ComposingStatus::extract(contactStatusJSONPtr);
                if (composingStatusPtr)
                {
                    ret = (HOPComposingState) composingStatusPtr->mComposingStatus;
//                    String str = ComposingStatus::toString(composingStatusPtr->mComposingStatus); //IHelper::convertToString(contactStatusJSONPtr);
//                    if (str.hasData())
//                        ret = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
                }
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return ret;
}


- (void) setComposingStatusInThread:(HOPComposingState) status
{
    if(conversationThreadPtr)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ElementPtr statusJSONPtr = conversationThreadPtr->createEmptyStatus();
            
            ComposingStatusPtr composingStatusPtr = ComposingStatusPtr(new ComposingStatus((ComposingStatus::ComposingStates) status));
            composingStatusPtr->insert(statusJSONPtr);
            conversationThreadPtr->setStatusInThread(statusJSONPtr);
        });
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}


- (void) sendMessage: (HOPMessageRecord*) message
{
    if(conversationThreadPtr)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            conversationThreadPtr->sendMessage([message.messageID UTF8String], [message.replacedMessageID UTF8String], [message.type UTF8String], message.removed.boolValue ? " " : [message.text UTF8String], message.validated ? true : false);
        });
        
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

- (HOPMessageRecord*) getMessageForID: (NSString*) messageID
{
    HOPMessageRecord* ret = [[HOPModelManager sharedModelManager] getMessageRecordByID:messageID];

    if (!ret)
    {
        if(conversationThreadPtr)
        {
            IContactPtr fromContact;
            zsLib::String messageType;
            zsLib::String message;
            zsLib::String replacesMessageID;
            zsLib::Time messageTime;
            bool validated = false;
            
            conversationThreadPtr->getMessage([messageID UTF8String], replacesMessageID, fromContact, messageType, message, messageTime, validated);
            
            if (fromContact && messageType && message)
            {
                NSString* peerURI = [NSString stringWithUTF8String:fromContact->getPeerURI()];
                if (peerURI.length > 0)
                {
                    ret = [HOPMessageRecord createMessage:[NSString stringWithUTF8String:message] type:[NSString stringWithUTF8String:messageType] date:[OpenPeerUtility convertPosixTimeToDate:messageTime] visible:YES conversation:[[OpenPeerStorageManager sharedStorageManager] getConversationForThreadID:[self getThreadId]] contact:[[HOPModelManager sharedModelManager] getRolodexContactByPeerURI:peerURI] messageId:messageID validated:validated messageIDToReplace:[NSString stringWithUTF8String:replacesMessageID]];
                }
            }
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
            [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
        }
    }
    
    return ret;
}

- (BOOL) getMessageDeliveryState: (NSString*) messageID outDeliveryState:(HOPConversationThreadMessageDeliveryState*) outDeliveryState
{
    BOOL ret = NO;
    IConversationThread::MessageDeliveryStates tmpState;

    if(conversationThreadPtr)
    {
        if ([messageID length] > 0)
        {
            ret = conversationThreadPtr->getMessageDeliveryState([messageID UTF8String], tmpState);
            *outDeliveryState = (HOPConversationThreadMessageDeliveryState) tmpState;
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    return ret;
}

- (void) setMessageDeliveryState: (NSString*) messageID deliveryState:(HOPConversationThreadMessageDeliveryState) deliveryState
{
    if(conversationThreadPtr && messageID.length > 0)
    {
        conversationThreadPtr->setMessageDeliveryState([messageID UTF8String], (IConversationThread::MessageDeliveryStates) deliveryState);
    }
}

- (void) markAllMessagesRead
{
    if(conversationThreadPtr)
    {
        conversationThreadPtr->markAllMessagesRead();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

+ (NSString*) getSystemMessageType
{
    NSString* ret = nil;
    
    ret = [NSString stringWithUTF8String:ISystemMessage::getMessageType()];
    
    return ret;
}

- (NSString*) getMetaData
{
    NSString* ret = nil;
    
    if(conversationThreadPtr)
    {
        ret = [NSString stringWithUTF8String: IHelper::convertToString(conversationThreadPtr->getMetaData())];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    return ret;
}

- (NSString*)description
{
    return [NSString stringWithUTF8String: IHelper::convertToString(IConversationThread::toDebug([self getConversationThreadPtr]))];
}


- (void) destroyCoreObject
{
    if(conversationThreadPtr)
    {
        conversationThreadPtr.reset();
    }
}
#pragma mark - Internal methods
- (IConversationThreadPtr) getConversationThreadPtr
{
    return conversationThreadPtr;
}

- (String) log:(NSString*) message
{
    if (conversationThreadPtr)
        return String("HOPConversationThread [") + string(conversationThreadPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPConversationThread: ") + [message UTF8String];
}
@end
