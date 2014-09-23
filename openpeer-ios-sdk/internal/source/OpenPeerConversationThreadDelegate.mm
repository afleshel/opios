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
#import "HOPMessageRecord.h"

#include <zsLib/types.h>
#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerConversationThreadDelegate::OpenPeerConversationThreadDelegate(id<HOPConversationThreadDelegate> inConversationThreadDelegate)
{
    conversationThreadDelegate = inConversationThreadDelegate;
}

OpenPeerConversationThreadDelegate::~OpenPeerConversationThreadDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerConversationThreadDelegate destructor is called"));
}

OpenPeerConversationThreadDelegatePtr OpenPeerConversationThreadDelegate::create(id<HOPConversationThreadDelegate> inConversationThreadDelegate)
{
    return OpenPeerConversationThreadDelegatePtr (new OpenPeerConversationThreadDelegate(inConversationThreadDelegate));
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

void OpenPeerConversationThreadDelegate::onConversationThreadNew(IConversationThreadPtr conversationThread)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    
    if (!hopConversationThread)
    {
        hopConversationThread = [[HOPConversationThread alloc] initWithConversationThread:conversationThread];
        [conversationThreadDelegate onConversationThreadNew:hopConversationThread];
    }
}


void OpenPeerConversationThreadDelegate::onConversationThreadContactsChanged(IConversationThreadPtr conversationThread)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    
    if (hopConversationThread)
        [conversationThreadDelegate onConversationThreadContactsChanged:hopConversationThread];
}

void OpenPeerConversationThreadDelegate::onConversationThreadMessage(IConversationThreadPtr conversationThread,const char *messageID)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    
    if (hopConversationThread && [messageId length] > 0)
        [conversationThreadDelegate onConversationThreadMessage:hopConversationThread messageID:messageId];
}

void OpenPeerConversationThreadDelegate::onConversationThreadMessageDeliveryStateChanged(IConversationThreadPtr conversationThread,const char *messageID,MessageDeliveryStates state)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    
    
    if (hopConversationThread && [messageId length] > 0)
    {
        HOPMessageRecord* messageRecord = [[HOPModelManager sharedModelManager] getMessageRecordByID:messageId];
        messageRecord.outgoingMessageStatus = [NSNumber numberWithInt:state];
        messageRecord.showStatus = [NSNumber numberWithBool:YES];
        [[HOPModelManager sharedModelManager] saveContext];
        
        [conversationThreadDelegate onConversationThreadMessageDeliveryStateChanged:hopConversationThread messageID:messageId messageDeliveryStates:(HOPConversationThreadMessageDeliveryState)state];
    }
}

void OpenPeerConversationThreadDelegate::onConversationThreadPushMessage(IConversationThreadPtr conversationThread,const char *messageID,IContactPtr contact)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    NSString* messageId = [NSString stringWithUTF8String:messageID];
    HOPContact* hopContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
    if (hopConversationThread && hopContact && [messageId length] > 0)
        [conversationThreadDelegate onConversationThreadPushMessage:hopConversationThread messageID:messageId contact:hopContact];
}

void OpenPeerConversationThreadDelegate::onConversationThreadContactConnectionStateChanged(IConversationThreadPtr conversationThread,IContactPtr contact,ContactConnectionStates state)
{
    HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
    HOPContact* hopContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];
    
    if (hopConversationThread && hopContact)
        [conversationThreadDelegate onConversationThreadContactConnectionStateChanged:hopConversationThread contact:hopContact contactConnectionState:(HOPConversationThreadContactConnectionState)state];
}

void OpenPeerConversationThreadDelegate::onConversationThreadContactStatusChanged(IConversationThreadPtr conversationThread,IContactPtr contact)
{
  HOPConversationThread * hopConversationThread = this->getOpenPeerConversationThread(conversationThread);
  HOPContact* hopContact = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:contact->getPeerURI()]];

  if (hopConversationThread && hopContact)
    [conversationThreadDelegate onConversationThreadContactStatusChanged:hopConversationThread contact:hopContact];
}
