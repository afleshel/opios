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

#import "HOPConversationThread_Internal.h"
#import "HOPContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "HOPMessage.h"
#import "HOPModelManager_Internal.h"
#import "HOPIdentityContact_Internal.h"
#import "HOPOpenPeerContact+External.h"
#import "HOPRolodexContact+External.h"
#import "HOPAssociatedIdentity.h"
#import "HOPIdentityProvider.h"
#import "OpenPeerStorageManager.h"
#import "OpenPeerUtility.h"
#import "HOPIdentity_Internal.h"
#import "HOPPublicPeerFile.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

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
        conversationThreadPtr = inConversationThreadPtr;
        [[OpenPeerStorageManager sharedStorageManager] setConversationThread:self forId:[NSString stringWithUTF8String:inConversationThreadPtr->getThreadID()]];
    }
    return self;
}

+ (id) conversationThreadWithIdentities:(NSArray*) identities
{
    HOPConversationThread* ret = nil;
    core::IdentityContactList identityContactsList;
    
    for (HOPIdentity* identity in identities)
    {
        IdentityContact identityContact;
        [identity getIdentityPtr]->getSelfIdentityContact(identityContact);
        
        identityContactsList.push_back(identityContact);
    }
    
    IConversationThreadPtr tempConversationThreadPtr = IConversationThread::create([[HOPAccount sharedAccount] getAccountPtr], identityContactsList);
    
    if (tempConversationThreadPtr)
    {
        ret = [[self alloc] initWithConversationThread:tempConversationThreadPtr];
    }
    
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
        ret =[[OpenPeerStorageManager sharedStorageManager] getConversationThreadForId:threadID];
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

- (NSArray*) getRolodexContacts
{
    NSMutableArray* contactArray = nil;
    if (conversationThreadPtr)
    {
        contactArray = [[NSMutableArray alloc] init];
        ContactListPtr contactList = conversationThreadPtr->getContacts();
        
        for (ContactList::iterator contact = contactList->begin(); contact != contactList->end(); ++contact)
        {
            IContactPtr contactPtr = *contact;
            if (!contactPtr->isSelf())
            {
                HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                
                if (!openPeerContact)
                {
                    openPeerContact = [HOPConversationThread createOpenPeerContacFromCoreContact:contactPtr conversationThread:conversationThreadPtr];
                }
                
                //TODO_S: Remove once HOPMEssage is switched to HOPOpenPeerContact
                //                HOPContact* tempContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                //                if (!tempContact)
                //                {
                //                    IPeerFilePublicPtr publicPtr =  contactPtr->getPeerFilePublic();
                //                    if (publicPtr)
                //                    {
                //                        ElementPtr element = IHelper::convertToElement(publicPtr);
                //                        if (element)
                //                        {
                //                            NSString* pulbicPeer = [NSString stringWithUTF8String:IHelper::convertToString(element)];
                //                            if ([pulbicPeer length] > 0)
                //                                tempContact = [[HOPContact alloc] initWithPeerFile:pulbicPeer];
                //                        }
                //                    }
                //                }
                
                if (openPeerContact)
                    [contactArray addObject:[openPeerContact getDefaultRolodexContact]];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return contactArray;
}

- (NSArray*) getContacts
{
    NSMutableArray* contactArray = nil;
    if (conversationThreadPtr)
    {
        contactArray = [[NSMutableArray alloc] init];
        ContactListPtr contactList = conversationThreadPtr->getContacts();
        
        for (ContactList::iterator contact = contactList->begin(); contact != contactList->end(); ++contact)
        {
            IContactPtr contactPtr = *contact;
            if (!contactPtr->isSelf())
            {
                HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                
                if (!openPeerContact)
                {
                    openPeerContact = [HOPConversationThread createOpenPeerContacFromCoreContact:contactPtr conversationThread:conversationThreadPtr];
                }
                
                //TODO_S: Remove once HOPMEssage is switched to HOPOpenPeerContact
//                HOPContact* tempContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
//                if (!tempContact)
//                {
//                    IPeerFilePublicPtr publicPtr =  contactPtr->getPeerFilePublic();
//                    if (publicPtr)
//                    {
//                        ElementPtr element = IHelper::convertToElement(publicPtr);
//                        if (element)
//                        {
//                            NSString* pulbicPeer = [NSString stringWithUTF8String:IHelper::convertToString(element)];
//                            if ([pulbicPeer length] > 0)
//                                tempContact = [[HOPContact alloc] initWithPeerFile:pulbicPeer];
//                        }
//                    }
//                }
                
                if (openPeerContact)
                    [contactArray addObject:openPeerContact];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return contactArray;
}

- (void) addContacts: (NSArray*) contacts
{
    if(conversationThreadPtr)
    {
        if ([contacts count] > 0)
        {
            ContactProfileInfoList contactList;
            for (id tempContact in contacts)
            {
                HOPContact* contact = nil;
                if ([[tempContact class] isSubclassOfClass:[HOPContact class]])
                    contact = tempContact;
                else
                {
                    HOPRolodexContact* rolodexContact = [[tempContact class] isSubclassOfClass:[HOPRolodexContact class]] ? tempContact : [((HOPOpenPeerContact*)tempContact) getDefaultRolodexContact];
                    contact = [rolodexContact getCoreContact];
                }
                
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

                            //coreIdentityContact.mPeerFilePublic = IHelper::createPeerFilePublic(IHelper::createElement([openPeerContact.publicPeerFile.peerFile UTF8String]));
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
                    contactList.push_back(contactInfo);
                }
            }
            
            conversationThreadPtr->addContacts(contactList);
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
                HOPContact* coreContact = [contact getCoreContact];
                contactList.push_back([coreContact getContactPtr]);
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
                NSString* sId = [NSString stringWithUTF8String:identityContact.mStableID];
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
- (NSArray*) getIdentityContactListForContact:(HOPContact*) contact
{
    NSMutableArray* ret = nil;
    if(conversationThreadPtr)
    {
        ret = [self getIdentityContactListForCoreContact:[contact getContactPtr]];
    }
    
    return ret;
}

- (HOPConversationThreadContactConnectionState) getContactConnectionState: (HOPContact*) contact
{
    HOPConversationThreadContactConnectionState ret = HOPConversationThreadContactConnectionStateNotApplicable;
    if(conversationThreadPtr)
    {
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

- (HOPConversationThreadContactStatus) getContactStatusNew:(HOPRolodexContact*) rolodexCoontact
{
    HOPConversationThreadContactStatus ret = HOPComposingStateInactive;
    if(conversationThreadPtr)
    {
        HOPContact* contact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[rolodexCoontact getPeerURI]];
        IContactPtr contactPtr = [contact getContactPtr];
        if (contactPtr)
        {
            ElementPtr contactStatusJSONPtr = conversationThreadPtr->getContactStatus(contactPtr);
            if (contactStatusJSONPtr)
            {
                ComposingStatusPtr composingStatusPtr = ComposingStatus::extract(contactStatusJSONPtr);
                if (composingStatusPtr)
                {
                    ret = (HOPConversationThreadContactStatus) composingStatusPtr->mComposingStatus;
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

- (HOPConversationThreadContactStatus) getContactStatus:(HOPContact*) contact
{
    HOPConversationThreadContactStatus ret = HOPComposingStateInactive;
    if(conversationThreadPtr)
    {
        IContactPtr contactPtr = [contact getContactPtr];
        if (contactPtr)
        {
            ElementPtr contactStatusJSONPtr = conversationThreadPtr->getContactStatus(contactPtr);
            if (contactStatusJSONPtr)
            {
                ComposingStatusPtr composingStatusPtr = ComposingStatus::extract(contactStatusJSONPtr);
                if (composingStatusPtr)
                {
                    ret = (HOPConversationThreadContactStatus) composingStatusPtr->mComposingStatus;
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

- (void) setStatusInThread:(HOPConversationThreadContactStatus) status
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

/*- (void) sendMessage: (NSString*) messageID replacesMessageID:(NSString*) replacesMessageID messageType:(NSString*) messageType validated:(BOOL) validated message:(NSString*) message
{
    if(conversationThreadPtr)
    {
        conversationThreadPtr->sendMessage([messageID UTF8String], [replacesMessageID UTF8String], [messageType UTF8String], [message UTF8String], validated ? true : false);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}*/

- (void) sendMessage: (HOPMessage*) message
{
    if(conversationThreadPtr)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            conversationThreadPtr->sendMessage([message.messageID UTF8String], [message.replacesMessageID UTF8String], [message.type UTF8String], [message.text UTF8String], message.validated ? true : false);
        });
        
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

- (HOPMessage*) getMessageForID: (NSString*) messageID
{
    HOPMessage* hopMessage = nil;
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
                hopMessage = [[HOPMessage alloc] init];
                
                hopMessage.contact = [[HOPModelManager sharedModelManager] getRolodexContactByPeerURI:peerURI];
                
                
                /*if (!hopMessage.contact)
                {
                    HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:peerURI];
                    if (!openPeerContact)
                    {
                        openPeerContact = [[HOPModelManager sharedModelManager] createOrUpdateOpenPeerContactForItentities:[self getIdentityContactListForCoreContact:fromContact] coreContact:fromContact];
                        if (openPeerContact)
                            hopMessage.contact = [openPeerContact getCoreContact];
                    }
                    else
                    {
                        hopMessage.contact = [openPeerContact getCoreContact];
                    }
                }*/
                hopMessage.type = [NSString stringWithUTF8String:messageType];
                hopMessage.text = [NSString stringWithUTF8String:message];
                hopMessage.date = [OpenPeerUtility convertPosixTimeToDate:messageTime];
                hopMessage.messageID = messageID;
                hopMessage.replacesMessageID = [NSString stringWithUTF8String:replacesMessageID];
                hopMessage.validated = (validated ? YES : NO);
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }

    return hopMessage;
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

+ (NSString*) createSystemMessage:(HOPSystemMessageType) systemMessageType messageType:(int) messageType contact:(HOPContact*) contact
{
    NSString* ret = nil;

    if (contact)
    {
        ElementPtr systemMessage = ISystemMessage::createEmptySystemMessage();
        
        switch (systemMessageType)
        {
            case HOPSystemMessageTypeCall:
            {
#define WARNING_FILL_IN_MEDIA_TYPE_AND_CALL_ID 1
#define WARNING_FILL_IN_MEDIA_TYPE_AND_CALL_ID 2
                CallSystemMessagePtr callSystemPtr = CallSystemMessagePtr(new CallSystemMessage((CallSystemMessage::CallSystemMessageStatuses) messageType, String(), String(), [contact getContactPtr]));
                callSystemPtr->insert(systemMessage);
            }
                break;
                
            default:
                break;
        }
        
        String str = IHelper::convertToString(systemMessage);
        ret = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    }
    
    return ret;
}

+ (NSString*) getSystemMessageType
{
    NSString* ret = nil;
    
    ret = [NSString stringWithUTF8String:ISystemMessage::getMessageType()];
    
    return ret;
}

- (NSString *)description
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

+ (id) createOpenPeerContacFromCoreContact:(IContactPtr) contactPtr conversationThread:(IConversationThreadPtr) conversationThreadPtr
{
    HOPOpenPeerContact* ret = nil;
    
    IdentityContactListPtr identityContactListPtr = conversationThreadPtr->getIdentityContactList(contactPtr);
    
    for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
    {
        IdentityContact identityContact = *identityContactInfo;
        if (identityContact.hasData())
        {
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
                
                ret = [[HOPModelManager sharedModelManager]  getOpenPeerContactForIdentityContact:identityContact];
                if (ret)
                    [ret addIdentityContactsObject:hopIdentityContact];
                else
                    ret = [[HOPModelManager sharedModelManager] createOpenPeerContactForIdentityContact:identityContact];
            }
            
        }
    }
    
    return ret;
}
@end
