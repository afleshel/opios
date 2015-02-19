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

#import <openpeer/core/types.h>
#import <openpeer/core/IConversationThread.h>
#include <zsLib/Stringize.h>
#include <zsLib/XML.h>
#import <openpeer/core/IHelper.h>
#import "HOPConversationType.h"

using namespace openpeer;
using namespace openpeer::core;

@interface HOPConversationType ()
{
    ConversationThreadTypePtr conversationThreadTypePtr;
}
@end

@implementation HOPConversationType

- (id) initWithConversationThreadType:(HOPConversationThreadType) threadType
{
    self = [super init];
    if (self)
    {
        conversationThreadTypePtr = ConversationThreadTypePtr(new ConversationThreadType());
        
        conversationThreadTypePtr->mThreadType = (ConversationThreadType::ConversationThreadTypes)threadType;
        
        ElementPtr elementPtr =  Element::create();//Element::create(ConversationThreadType::Definitions::Names::conversationType());
        conversationThreadTypePtr->insert(elementPtr);
        
        String str = IHelper::convertToString(elementPtr);
        if (str.hasData())
        {
            self.jsonMessage = [NSString stringWithUTF8String:str];
            NSData *data = [self.jsonMessage dataUsingEncoding:NSUTF8StringEncoding];
            self.typeDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
    }
    return self;
}

- (id) initWithConversationType:(ConversationThreadTypePtr) inConversationThreadTypePtr
{
    self = [super init];
    
    if (self)
    {
        conversationThreadTypePtr = inConversationThreadTypePtr;
        self.conversationThreadType = (HOPConversationThreadType) conversationThreadTypePtr->mThreadType;
    }
    return self;
}

+ (id) conversationThreadTypeFromJSON:(NSString*) jsonMessage
{
    HOPConversationType* ret = nil;
    
    if ([jsonMessage length] > 0)
    {
        ConversationThreadTypePtr conversationThreadTypePtr = ConversationThreadType::extract(IHelper::createElement([jsonMessage UTF8String]));
        
        if (conversationThreadTypePtr)
        {
            ret = [[self alloc] initWithConversationType:conversationThreadTypePtr];
            //ret.jsonMessage = jsonMessage;
        }
    }
    
    return ret;
}

+ (NSString*) stringForConversationThreadType:(HOPConversationThreadType) threadType
{
    NSString* ret = nil;
    
    String str = ConversationThreadType::toString((ConversationThreadType::ConversationThreadTypes)threadType);
    
    if (str.hasData())
    {
        ret = [NSString stringWithUTF8String:str];
    }
    
    return ret;
}

+ (HOPConversationThreadType) conversationThreadTypeForString: (NSString*) conversationThreadTypeString
{
    HOPConversationThreadType ret = HOPConversationThreadTypeNone;
    
    if ([conversationThreadTypeString length] > 0)
    {
        ret = (HOPConversationThreadType)ConversationThreadType::toConversationThreadType([conversationThreadTypeString UTF8String]);
    }
    
    return ret;
}

- (BOOL) hasData
{
    BOOL ret = NO;
    
    if (conversationThreadTypePtr)
    {
        ret = conversationThreadTypePtr->hasData();
    }
    
    return ret;
}

- (NSString*)description
{
    return [NSString stringWithUTF8String: IHelper::convertToString(conversationThreadTypePtr->toDebug())];
}
@end