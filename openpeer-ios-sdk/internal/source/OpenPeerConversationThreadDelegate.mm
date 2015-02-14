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
#import "HOPModelManager_Internal.h"
#import "HOPMessageRecord+External.h"
#import "HOPConversation_Internal.h"
#import "HOPConversationEvent+External.h"
#import "HOPConversationRecord+External.h"
#import "HOPIdentity+External.h"
#import "HOPSettings.h"
#import "HOPUtility.h"
#import "HOPSystemMessage.h"

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
        NSArray* updatedContacts = [[HOPModelManager sharedModelManager] addUnkownContactsFromConversationThread:hopConversationThread];
        [hopConversationThread refreshParticipants];
        
        if (conversationThreadDelegate)
        {
            [conversationThreadDelegate onConversationThreadNew:hopConversationThread];
        }
        else if (conversationDelegate)
        {
            HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
            
            if (!hopConversation)
            {
                hopConversation.updatedContacts = nil;
                if (updatedContacts.count > 0)
                    hopConversation.updatedContacts = [NSArray arrayWithArray:updatedContacts];
                
                hopConversation = [[OpenPeerStorageManager sharedStorageManager] getConversationForThreadID:[hopConversationThread getThreadId]];
                if (!hopConversation)
                    hopConversation = [HOPConversation conversationWithThread:hopConversationThread];
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

void OpenPeerConversationThreadDelegate::addTimerForConversation(HOPConversation* conversation, NSSet* participants)
{
    conversation.removalTimer = [NSTimer timerWithTimeInterval:3.0 target:conversation selector:@selector(onRemovalTimerExpired:) userInfo:nil repeats:NO];
}



void OpenPeerConversationThreadDelegate::onConversationThreadContactsChanged(IConversationThreadPtr conversationThread)
{
    if (conversationThreadDelegate)
    {
        HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
        
        if (hopConversationThread)
        {
            NSArray* updatedContacts = [[HOPModelManager sharedModelManager] addUnkownContactsFromConversationThread:hopConversationThread];
            [hopConversationThread refreshParticipants];
            [conversationThreadDelegate onConversationThreadContactsChanged:hopConversationThread];
        }
    }
    else if (conversationDelegate)
    {
        HOPConversation * hopConversation = this->getOpenPeerConversation(conversationThread);
        
        if (hopConversation)
        {
             NSArray* updatedContacts = [[HOPModelManager sharedModelManager] addUnkownContactsFromConversationThread:hopConversation.thread];
            [hopConversation.thread refreshParticipants];
            hopConversation.updatedContacts = nil;
            
            NSArray* difference = [HOPUtility differenceBetweenArray:hopConversation.participants array:[hopConversation.lastEvent getContacts]];
            int numberOfAddedParticipants = hopConversation.participants.count - [hopConversation.lastEvent getContacts].count;
            
            if (updatedContacts.count > 0)
                hopConversation.updatedContacts = [NSArray arrayWithArray:updatedContacts];
            else
                hopConversation.updatedContacts = [NSArray arrayWithArray:difference];
            
            if (numberOfAddedParticipants != 0)
            {
                if (hopConversation.conversationType == HOPConversationThreadTypeContactBased && [[HOPSettings sharedSettings] getDefaultCovnersationType] != HOPConversationThreadTypeContactBased)
                {
                    HOPConversationThread * hopConversationThread = hopConversation.thread;
                    hopConversation.thread = nil;
                    HOPConversation* hopConversation2 = [HOPConversation conversationWithThread:hopConversationThread];
                    hopConversation2.conversationType = [[HOPSettings sharedSettings] getDefaultCovnersationType];
                    [conversationDelegate onConversationNew:hopConversation2];
                    return;
                }
                else
                {
                    if (numberOfAddedParticipants > 0)
                    {
                        for (HOPContact* contact in difference)
                        {
                            [hopConversation.record addParticipantsObject:contact];
                        }
                        
                        hopConversation.record.name = [HOPConversation getDefaultTitleForParticipants:hopConversation.participants];
                        hopConversation.topic = hopConversation.record.name;
                        
                        hopConversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedNewParticipant" conversationRecord:hopConversation.record partcipants:hopConversation.participants title:hopConversation.topic];
                    }
                    else if (numberOfAddedParticipants < 0)
                    {
                        @synchronized(hopConversation)
                        {
                            if (hopConversation.removalTimer)
                            {
                                if ([hopConversation.record.participants isEqualToSet:hopConversation.previousParticipants])
                                    return;
                            }
                            else
                            {
                                hopConversation.previousParticipants = [NSSet setWithSet:hopConversation.record.participants];
                                this->addTimerForConversation(hopConversation, hopConversation.record.participants);
                            }
                        }
                        
                        for (HOPContact* contact in difference)
                        {
                            [hopConversation.record removeParticipantsObject:contact];
                        }
                        
                        hopConversation.record.name = [HOPConversation getDefaultTitleForParticipants:hopConversation.participants];
                        hopConversation.topic = hopConversation.record.name;
                        
                        hopConversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"removedParticipant" conversationRecord:hopConversation.record partcipants:hopConversation.participants title:hopConversation.topic];
                    }
                }

                [conversationDelegate onConversationContactsChanged:hopConversation];
            }
        }
        
        [[HOPModelManager sharedModelManager] saveContext];
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
            {
                [conversationDelegate onConversationMessage:hopConversation messageID:messageId];
            }
        }
    }
}
void OpenPeerConversationThreadDelegate::callProperConversationDelegate(HOPConversation * conversation, NSString* messageID)
{
    HOPMessageRecord* message = [conversation getMessageForID:messageID];
    BOOL isSystemMessage = [message.type isEqualToString:[HOPSystemMessage getMessageType]];
    
    if (!isSystemMessage)
    {
        [conversationDelegate onConversationNewMessage:conversation message:message];
    }
    else
    {
        
    }
}
//- (void) onConversationNewMessage:(HOPConversation*) conversation messageID:(NSString*) messageID;
//- (void) onConversationCallSystemMessageReceived:(HOPConversation*) conversation jsonMessage:(NSString*) jsonMessage;
//- (void) onConversationSwitch:(HOPConversation*) conversation fromConversationId:(NSString*)fromConversationId toConversationId:(NSString*)toConversationId;



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
    
    HOPContact* hopContact = [[HOPModelManager sharedModelManager] getContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
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
            [conversationDelegate onConversationPushMessageRequired:hopConversation message:[hopConversation getMessageForID:messageId] recipient:hopContact];
            
        //[conversationDelegate onConversationPushMessage:hopConversation messageID:messageId contact:hopContact];
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadContactConnectionStateChanged(IConversationThreadPtr conversationThread,IContactPtr contact,ContactConnectionStates state)
{
    HOPContact* hopContact = [[HOPModelManager sharedModelManager] getContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
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
    HOPContact* hopContact = [[HOPModelManager sharedModelManager] getContactByPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
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
           {
               HOPComposingState state = [hopConversation getComposingStateForContact:hopContact];
               [conversationDelegate onConversationContactComposingStateChanged:hopConversation state:state contact:hopContact];
           }
                //[conversationDelegate onConversationContactStatusChanged:hopConversation contact:hopContact];
        }
    }
}
