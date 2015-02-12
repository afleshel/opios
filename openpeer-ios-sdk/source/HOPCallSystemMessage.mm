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
#import <openpeer/core/IHelper.h>
#import "HOPCoreContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPIdentity_Internal.h"

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPCallSystemMessage

- (id) initWithMessageType:(HOPCallSystemMessageType) inType callee:(HOPIdentity*) inCallee errorCode:(unsigned short) inErrorCode
{
    self = [super init];
    if (self)
    {
        HOPCoreContact* coreContact = [inCallee getCoreContact];

        callSystemMessagePtr = CallSystemMessagePtr(new CallSystemMessage((CallSystemMessage::CallSystemMessageStatuses)inType, "", "", [coreContact getContactPtr], inErrorCode));
        self.type = HOPSystemMessageTypeCall;
        self.messageType = inType;
        self.callee = coreContact;
        self.errorCode = inErrorCode;
        
        callSystemMessagePtr->mCallee = [coreContact getContactPtr];
        callSystemMessagePtr->mStatus = (CallSystemMessage::CallSystemMessageStatuses)inType;
        
        ElementPtr elementPtr = ISystemMessage::createEmptySystemMessage();
        callSystemMessagePtr->insert(elementPtr);
        
        String str = IHelper::convertToString(elementPtr);
        if (str.hasData())
            self.jsonMessage = [NSString stringWithUTF8String:str];
    }
    return self;
}

- (id) initWithMessageType:(HOPCallSystemMessageType) inType mediaType:(NSString*) mediaType callID:(NSString*) callID callee:(HOPIdentity*) inCallee errorCode:(unsigned short) inErrorCode
{
    self = [super init];
    if (self)
    {
        HOPCoreContact* coreContact = [inCallee getCoreContact];
        
        callSystemMessagePtr = CallSystemMessagePtr(new CallSystemMessage((CallSystemMessage::CallSystemMessageStatuses)inType, mediaType.length > 0 ? [mediaType UTF8String] : "", callID.length > 0 ? [callID UTF8String] : "", [coreContact getContactPtr], inErrorCode));
        self.type = HOPSystemMessageTypeCall;
        self.messageType = inType;
        self.callee = coreContact;
        self.errorCode = inErrorCode;
        self.callID = callID;
        self.mediaType = mediaType;
        
        callSystemMessagePtr->mCallee = [coreContact getContactPtr];
        callSystemMessagePtr->mStatus = (CallSystemMessage::CallSystemMessageStatuses)inType;
        
        ElementPtr elementPtr = ISystemMessage::createEmptySystemMessage();
        callSystemMessagePtr->insert(elementPtr);
        
        String str = IHelper::convertToString(elementPtr);
        if (str.hasData())
            self.jsonMessage = [NSString stringWithUTF8String:str];
    }
    return self;
}

- (NSString *)getName
{
    return @"call";
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

+ (NSString*) stringForMessageType:(HOPCallSystemMessageType) messageType
{
    NSString* ret = nil;
    
    String str = CallSystemMessage::toString((CallSystemMessage::CallSystemMessageStatuses)messageType);
    
    if (str.hasData())
    {
        ret = [NSString stringWithUTF8String:str];
    }
    
    return ret;
}

+ (HOPCallSystemMessageType) messageTypeForString: (NSString*) messageTypeString
{
    HOPCallSystemMessageType ret = HOPCallSystemMessageTypeUnknown;
    
    if ([messageTypeString length] > 0)
    {
        ret = (HOPCallSystemMessageType)CallSystemMessage::toCallSystemMessageStatus([messageTypeString UTF8String]);
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
        self.messageType = (HOPCallSystemMessageType) callSystemMessagePtr->mStatus;
        self.callee = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:[NSString stringWithUTF8String:callSystemMessagePtr->mCallee->getPeerURI()]];
        self.errorCode = callSystemMessagePtr->mErrorCode;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    HOPCallSystemMessage *copy = [[HOPCallSystemMessage allocWithZone: zone] init];
    
    copy.type = self.type;
    copy.messageType = self.messageType;
    copy.callee = self.callee;
    copy.errorCode = self.errorCode;
    copy.jsonMessage = self.jsonMessage;
    
    [copy setCallSystemMessagePtr:callSystemMessagePtr];
    return copy;
}

- (CallSystemMessagePtr) getCallSystemMessagePtr
{
    return callSystemMessagePtr;
}

- (void) setCallSystemMessagePtr:(CallSystemMessagePtr) inCallSystemMessagePtr
{
    callSystemMessagePtr = inCallSystemMessagePtr;
}

- (NSString*) getSystemMessageType
{
    NSString* ret = [NSString stringWithFormat:@"%@/%@/%@",[HOPSystemMessage getMessageType], self.name, [HOPCallSystemMessage stringForMessageType:self.messageType]];
    return ret;
}
@end
