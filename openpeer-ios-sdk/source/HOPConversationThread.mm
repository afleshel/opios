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
#import <openpeer/core/IConversationThreadComposingStatus.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IHelper.h>

#import "HOPConversationThread_Internal.h"
#import "HOPContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "HOPMessage.h"
#import "HOPModelManager.h"
#import "HOPIdentityContact_Internal.h"

#import "OpenPeerStorageManager.h"
#import "OpenPeerUtility.h"
#import "HOPIdentity_Internal.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPConversationThread

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

+ (NSString*) deliveryStateToString: (HOPConversationThreadMessageDeliveryState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::MessageDeliveryStates) state)];
}
+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::MessageDeliveryStates) state)];
}

+ (NSString*) stateToString: (HOPConversationThreadContactConnectionState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::ContactConnectionStates) state)];
}
+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state
{
    return [NSString stringWithUTF8String: IConversationThread::toString((IConversationThread::ContactConnectionStates) state)];
}

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
                HOPContact* tempContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                if (!tempContact)
                {
                    IPeerFilePublicPtr publicPtr =  contactPtr->getPeerFilePublic();
                    if (publicPtr)
                    {
                        ElementPtr element = IHelper::convertToElement(publicPtr);
                        if (element)
                        {
                            NSString* pulbicPeer = [NSString stringWithUTF8String:IHelper::convertToString(element)];
                            if ([pulbicPeer length] > 0)
                                tempContact = [[HOPContact alloc] initWithPeerFile:pulbicPeer];
                        }
                    }
                }
                
                if (tempContact)
                    [contactArray addObject:tempContact];
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
            for (HOPContact* contact in contacts)
            {
                ContactProfileInfo contactInfo;
                contactInfo.mContact = [contact getContactPtr];
                
                contactList.push_back(contactInfo);
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
            for (HOPContact* contact in contacts)
            {
                contactList.push_back([contact getContactPtr]);
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

- (NSArray*) getIdentityContactListForContact:(HOPContact*) contact
{
    NSMutableArray* ret = nil;
    if(conversationThreadPtr)
    {
        IdentityContactListPtr identityContactListPtr = conversationThreadPtr->getIdentityContactList([contact getContactPtr]);
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
                    HOPIdentityContact* hopIdentityContact = [[HOPModelManager sharedModelManager] getIdentityContactByStableID:sId identityURI:identityURI];
                    
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

- (NSString*) getContactStatus:(HOPContact*) contact
{
    NSString* ret = nil;
    if(conversationThreadPtr)
    {
        IContactPtr contactPtr = [contact getContactPtr];
        if (contactPtr)
        {
            ElementPtr contactStatusJSONPtr = conversationThreadPtr->getContactStatus(contactPtr);
            String str = IHelper::convertToString(contactStatusJSONPtr);
            ret = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return ret;
}

- (void) setStatusInThread:(HOPConversationThreadContactStatus) status aditioanlData:(NSString*) additionalData
{
    if(conversationThreadPtr)
    {
        ElementPtr statusElement;
        IConversationThreadComposingStatus::updateComposingStatus(statusElement, (openpeer::core::IConversationThreadComposingStatus::ComposingStates) status);
        conversationThreadPtr->setStatusInThread(statusElement);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
}

- (void) sendMessage: (NSString*) messageID replacesMessageID:(NSString*) replacesMessageID messageType:(NSString*) messageType validated:(BOOL) validated message:(NSString*) message
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
}

- (void) sendMessage: (HOPMessage*) message
{
    if(conversationThreadPtr)
    {
        conversationThreadPtr->sendMessage([message.messageID UTF8String], [message.replacesMessageID UTF8String], [message.type UTF8String], [message.text UTF8String], message.validated ? true : false);
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
            hopMessage = [[HOPMessage alloc] init];
            
            hopMessage.contact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:fromContact->getPeerURI()]];
            hopMessage.type = [NSString stringWithUTF8String:messageType];
            hopMessage.text = [NSString stringWithUTF8String:message];
            hopMessage.date = [OpenPeerUtility convertPosixTimeToDate:messageTime];
            hopMessage.messageID = messageID;
            hopMessage.replacesMessageID = [NSString stringWithUTF8String:replacesMessageID];
            hopMessage.validated = (validated ? YES : NO);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }

    return hopMessage;
}
- (BOOL) getMessage: (NSString*) messageID outReplacesMessageID:(NSString**) outReplacesMessageID outFrom:(HOPContact**) outFrom outMessageType:(NSString**) outMessageType outMessage:(NSString**) outMessage outTime:(NSDate**) outTime outValidated:(BOOL*) outValidated
{
    BOOL ret = NO;
    if(conversationThreadPtr)
    {
        zsLib::String replacesMessageID;
        IContactPtr fromContact;
        zsLib::String messageType;
        zsLib::String message;
        zsLib::Time messageTime;
        bool validated = false;
    
        conversationThreadPtr->getMessage([messageID UTF8String], replacesMessageID, fromContact, messageType, message, messageTime, validated);
        
        if (fromContact && messageType && message)
        {
            *outReplacesMessageID = [NSString stringWithUTF8String:replacesMessageID];
            *outFrom = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:fromContact->getPeerURI()]];
            *outMessageType = [NSString stringWithUTF8String:messageType];
            *outMessage = [NSString stringWithUTF8String:message];
            *outTime = [OpenPeerUtility convertPosixTimeToDate:messageTime];
            *outValidated = (validated ? YES : NO);
            ret = YES;
        }
        
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
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
@end
