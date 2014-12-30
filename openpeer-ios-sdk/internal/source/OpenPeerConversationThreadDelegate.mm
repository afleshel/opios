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


#import "OpenPeerConversationThreadDelegate.h"
#import "OpenPeerStorageManager.h"
#import "HOPConversationThread_Internal.h"
#import "HOPModelManager.h"
#import "HOPMessageRecord+External.h"
#import "HOPConversation.h"
#import "HOPConversationEvent+External.h"
#import "HOPConversationRecord+External.h"
#import "HOPSettings.h"

#include <zsLib/types.h>
#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerConversationThreadDelegate::OpenPeerConversationThreadDelegate(id<HOPConversationThreadDelegate> inConversationThreadDelegate)
{
    conversationThreadDelegate = inConversationThreadDelegate;
}

OpenPeerConversationThreadDelegate::OpenPeerConversationThreadDelegate(id<HOPConversationDelegate> inConversationDelegate)
{
    conversationDelegate = inConversationDelegate;
}

OpenPeerConversationThreadDelegate::~OpenPeerConversationThreadDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerConversationThreadDelegate destructor is called"));
}

OpenPeerConversationThreadDelegatePtr OpenPeerConversationThreadDelegate::create(id<HOPConversationThreadDelegate> inConversationThreadDelegate)
{
    return OpenPeerConversationThreadDelegatePtr (new OpenPeerConversationThreadDelegate(inConversationThreadDelegate));
}

OpenPeerConversationThreadDelegatePtr OpenPeerConversationThreadDelegate::create(id<HOPConversationDelegate> inConversationDelegate)
{
    return OpenPeerConversationThreadDelegatePtr (new OpenPeerConversationThreadDelegate(inConversationDelegate));
}

HOPConversationThread* OpenPeerConversationThreadDelegate::getOpenPeerConversationThread(IConversationThreadPtr conversationThread)
{
    HOPConversationThread * hopConversationThread = nil;
    
    NSString* threadId = [[NSString alloc] initWithUTF8String:conversationThread->getThreadID()];
    if (threadId)
    {
        hopConversationThread = [[OpenPeerStorageManager sharedStorageManager] getConversationThreadForId:threadId];
    }
    return hopConversationThread;
}

HOPConversation* OpenPeerConversationThreadDelegate::getOpenPeerConversation(IConversationThreadPtr conversationThread)
{
    HOPConversation * hopConversation = nil;
    
    NSString* threadId = [[NSString alloc] initWithUTF8String:conversationThread->getThreadID()];
    if (threadId.length > 0)
    {
        hopConversation = [[OpenPeerStorageManager sharedStorageManager] getConversationForThreadID:threadId];
    }
    return hopConversation;
}



void OpenPeerConversationThreadDelegate::onConversationThreadNew(IConversationThreadPtr conversationThread)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    
    if (!hopConversationThread)
    {
        hopConversationThread = [[HOPConversationThread alloc] initWithConversationThread:conversationThread];
        
        if (conversationThreadDelegate)
        {
            [conversationThreadDelegate onConversationThreadNew:hopConversationThread];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (!hopConversation)
            {
//                hopConversation = [[OpenPeerStorageManager sharedStorageManager] getConversationForCBCID:[HOPConversation getCBCIDForContacts:[hopConversationThread getContacts]]];
                hopConversation = [[OpenPeerStorageManager sharedStorageManager] getConversationForThreadID:[hopConversationThread getThreadId]];
                if (!hopConversation)
                    hopConversation = [HOPConversation createConversationWithThread:hopConversationThread];
                else
                {
                    hopConversation.thread = hopConversationThread;
                    [[OpenPeerStorageManager sharedStorageManager] setConversation:hopConversation threadID:[hopConversationThread getThreadId]];
                }
                
                if (conversationDelegate)
                    [conversationDelegate onConversationNew:hopConversation];
            }
        }
    }
}


void OpenPeerConversationThreadDelegate::onConversationThreadContactsChanged(IConversationThreadPtr conversationThread)
{
    if (conversationThreadDelegate)
    {
        HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
        
        if (hopConversationThread)
            [conversationThreadDelegate onConversationThreadContactsChanged:hopConversationThread];
    }
    else if (conversationDelegate)
    {
        HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
        
        if (hopConversation)
        {
            int numberOfAddedParticipants = hopConversation.participants.count - [hopConversation.lastEvent getContacts].count;
            
            if (numberOfAddedParticipants != 0)
            {
                if (hopConversation.conversationType == HOPConversationThreadTypeContactBased && [[HOPSettings sharedSettings] getDefaultCovnersationType] != HOPConversationThreadTypeContactBased)
                {
                    HOPConversationThread * hopConversationThread = hopConversation.thread;
                    hopConversation.thread = nil;
                    HOPConversation* hopConversation2 = [HOPConversation createConversationWithThread:hopConversationThread];
                    hopConversation2.conversationType = [[HOPSettings sharedSettings] getDefaultCovnersationType];
                    [conversationDelegate onConversationNew:hopConversation2];
                    return;
                }
                else
                {
                    if (numberOfAddedParticipants > 0)
                        hopConversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedNewParticipant" conversationRecord:hopConversation.record partcipants:hopConversation.participants title:hopConversation.title];
                    else if (numberOfAddedParticipants < 0)
                        hopConversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"removedParticipant" conversationRecord:hopConversation.record partcipants:hopConversation.participants title:hopConversation.title];
                }

                [conversationDelegate onConversationContactsChanged:hopConversation  numberOfAddedParticipants:numberOfAddedParticipants];
            }
        }
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadMessage(IConversationThreadPtr conversationThread,const char *messageID)
{
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    if ([messageId length] > 0)
    {
        if (conversationThreadDelegate)
        {
            HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
            
            if (hopConversationThread)
                [conversationThreadDelegate onConversationThreadMessage:hopConversationThread messageID:messageId];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (hopConversation)
                [conversationDelegate onConversationMessage:hopConversation messageID:messageId];
        }
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadMessageDeliveryStateChanged(IConversationThreadPtr conversationThread,const char *messageID,MessageDeliveryStates state)
{
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    
    if ([messageId length] > 0)
    {
        HOPMessageRecord* messageRecord = [[HOPModelManager sharedModelManager] getMessageRecordByID:messageId];
        if (messageRecord)
        {
            messageRecord.outgoingMessageStatus = (HOPConversationThreadMessageDeliveryState)state;
            messageRecord.showStatus = [NSNumber numberWithBool:YES];
            [[HOPModelManager sharedModelManager] saveContext];
        }
        
        if (conversationThreadDelegate)
        {
            HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);

            if (hopConversationThread)
                [conversationThreadDelegate onConversationThreadMessageDeliveryStateChanged:hopConversationThread messageID:messageId messageDeliveryStates:(HOPConversationThreadMessageDeliveryState)state];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (hopConversation)
                [conversationDelegate onConversationMessageDeliveryStateChanged:hopConversation messageID:messageId messageDeliveryStates:(HOPConversationThreadMessageDeliveryState)state];
        }
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadPushMessage(IConversationThreadPtr conversationThread,const char *messageID,IContactPtr contact)
{
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    
    HOPRolodexContact* hopContact = [[HOPModelManager sharedModelManager] getRolodexContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
    if (conversationThreadDelegate)
    {
        HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
        if (hopConversationThread && hopContact && [messageId length] > 0)
            [conversationThreadDelegate onConversationThreadPushMessage:hopConversationThread messageID:messageId contact:hopContact];
    }
    else if (conversationDelegate)
    {
        HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
        if (hopConversation && hopContact && [messageId length] > 0)
            [conversationDelegate onConversationPushMessage:hopConversation messageID:messageId contact:hopContact];
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadContactConnectionStateChanged(IConversationThreadPtr conversationThread,IContactPtr contact,ContactConnectionStates state)
{
    HOPRolodexContact* hopContact = [[HOPModelManager sharedModelManager] getRolodexContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    if (hopContact)
    {
        if (conversationThreadDelegate)
        {
            HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
        
            if (hopConversationThread)
                [conversationThreadDelegate onConversationThreadContactConnectionStateChanged:hopConversationThread contact:hopContact contactConnectionState:(HOPConversationThreadContactConnectionState)state];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (hopConversation)
                [conversationDelegate onConversationContactConnectionStateChanged:hopConversation contact:hopContact contactConnectionState:(HOPConversationThreadContactConnectionState)state];
        }
    }
    
}

void OpenPeerConversationThreadDelegate::onConversationThreadContactStatusChanged(IConversationThreadPtr conversationThread,IContactPtr contact)
{
    HOPRolodexContact* hopContact = [[HOPModelManager sharedModelManager] getRolodexContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
    if (hopContact)
    {
        if (conversationThreadDelegate)
        {
            HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
            
            if (hopConversationThread)
                [conversationThreadDelegate onConversationThreadContactStatusChanged:hopConversationThread contact:hopContact];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (hopConversation)
                [conversationDelegate onConversationContactStatusChanged:hopConversation contact:hopContact];
        }
    }
}
