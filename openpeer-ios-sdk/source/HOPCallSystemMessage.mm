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

#import "HOPCallSystemMessage_Internal.h"
#import <openpeer/core/ISystemMessage.h>
#import <HOPContact_Internal.h>
#import <openpeer/core/IHelper.h>
#import "HOPContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPRolodexContact+External.h"

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPCallSystemMessage

- (id) initWithMessageTypeNew:(HOPCallSystemMessageStatus) inStatus callee:(HOPRolodexContact*) inCallee errorCode:(unsigned short) inErrorCode
{
    self = [super init];
    if (self)
    {
        HOPContact* coreContact = [inCallee getCoreContact];
        callSystemMessagePtr = CallSystemMessagePtr(new CallSystemMessage((CallSystemMessage::CallSystemMessageStatuses)inStatus, String(), String(), [coreContact getContactPtr], inErrorCode));
#define WARNING_ADD_MEDIA_TYPE_AND_CALL_ID 1
#define WARNING_ADD_MEDIA_TYPE_AND_CALL_ID 2
        self.type = HOPSystemMessageTypeCall;
        self.messageStatus = inStatus;
        self.callee = coreContact;
        self.errorCode = inErrorCode;
        
        callSystemMessagePtr->mCallee = [coreContact getContactPtr];
        callSystemMessagePtr->mStatus = (CallSystemMessage::CallSystemMessageStatuses)inStatus;

        ElementPtr elementPtr = ISystemMessage::createEmptySystemMessage();
        callSystemMessagePtr->insert(elementPtr);
        
        String str = IHelper::convertToString(elementPtr);
        if (str.hasData())
            self.jsonMessage = [NSString stringWithUTF8String:str];
    }
    return self;
}

- (id) initWithMessageType:(HOPCallSystemMessageStatus) inStatus callee:(HOPContact*) inCallee errorCode:(unsigned short) inErrorCode
{
    self = [super init];
    if (self)
    {
        callSystemMessagePtr = CallSystemMessagePtr(new CallSystemMessage((CallSystemMessage::CallSystemMessageStatuses)inStatus, String(), String(), [inCallee getContactPtr], inErrorCode));
#define WARNING_ADD_MEDIA_TYPE_AND_CALL_ID 1
#define WARNING_ADD_MEDIA_TYPE_AND_CALL_ID 2
        self.type = HOPSystemMessageTypeCall;
        self.messageStatus = inStatus;
        self.callee = inCallee;
        self.errorCode = inErrorCode;
        
        callSystemMessagePtr->mCallee = [inCallee getContactPtr];
        callSystemMessagePtr->mStatus = (CallSystemMessage::CallSystemMessageStatuses)inStatus;
        
        ElementPtr elementPtr = ISystemMessage::createEmptySystemMessage();
        callSystemMessagePtr->insert(elementPtr);
        
        String str = IHelper::convertToString(elementPtr);
        if (str.hasData())
            self.jsonMessage = [NSString stringWithUTF8String:str];
    }
    return self;
}

+ (id) callSystemMessageFromJSON:(NSString*) jsonMessage
{
    HOPCallSystemMessage* ret = nil;
    
    if ([jsonMessage length] > 0)
    {
        CallSystemMessagePtr callSystemMessagePtr = CallSystemMessage::extract(IHelper::createElement([jsonMessage UTF8String]), [[HOPAccount sharedAccount] getAccountPtr]);
        
        if (callSystemMessagePtr)
        {
            ret = [[self alloc] initWithCoreCallSystemMsssage:callSystemMessagePtr];
            ret.jsonMessage = jsonMessage;
        }
    }
    
    return ret;
}

+ (NSString*) stringForMessageStatus:(HOPCallSystemMessageStatus) messageStatus
{
    NSString* ret = nil;
    
    String str = CallSystemMessage::toString((CallSystemMessage::CallSystemMessageStatuses)messageStatus);
    
    if (str.hasData())
    {
        ret = [NSString stringWithUTF8String:str];
    }
    
    return ret;
}

+ (HOPCallSystemMessageStatus) messageTypeForString: (NSString*) messageTypeString
{
    HOPCallSystemMessageStatus ret = HOPCallSystemMessageStatusUnknown;
    
    if ([messageTypeString length] > 0)
    {
        ret = (HOPCallSystemMessageStatus)CallSystemMessage::toCallSystemMessageStatus([messageTypeString UTF8String]);
    }
    
    return ret;
}

- (BOOL) hasData
{
    BOOL ret = NO;
    
    if (callSystemMessagePtr)
    {
        ret = callSystemMessagePtr->hasData();
    }
    
    return ret;
}

- (id) initWithCoreCallSystemMsssage:(CallSystemMessagePtr) inCallSystemMessagePtr
{
    self = [super init];
    
    if (self)
    {
        callSystemMessagePtr = inCallSystemMessagePtr;
        self.type = HOPSystemMessageTypeCall;
        self.messageStatus = (HOPCallSystemMessageStatus) callSystemMessagePtr->mStatus;
        self.callee = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:callSystemMessagePtr->mCallee->getPeerURI()]];
        self.errorCode = callSystemMessagePtr->mErrorCode;
    }
    return self;
}

- (CallSystemMessagePtr) getCallSystemMessagePtr
{
    return callSystemMessagePtr;
}


@end
