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

#import "HOPMessageRecord+External.h"
#import <openpeer/core/IHelper.h>
#import <openpeer/core/types.h>
//#import <openpeer/core/IConversationThread.h>
#import "HOPConversationThread.h"
#import "HOPModelManager.h"
#import "HOPIdentity+External.h"
#import "HOPContact+External.h"
#import "HOPConversation_Internal.h"
#import "HOPConversationRecord.h"
//using namespace openpeer;
//using namespace openpeer::core;

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPMessageRecord (External)


+ (HOPMessageRecord*) createMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date  visible:(BOOL) visible  conversation:(HOPConversation*) conversation sender:(HOPContact*) sender messageId:(NSString*)messageId validated:(BOOL) validated messageIDToReplace:(NSString*) messageIDToReplace
{
    HOPMessageRecord* ret = nil;
    
    if ([messageText length] > 0 && [type length] > 0 && date != nil && conversation != nil && [messageId length] > 0)
    {
        ret = [[HOPModelManager sharedModelManager] getMessageRecordByID:messageId];
        if ( ret == nil)
        {
            ret = (HOPMessageRecord*)[[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPMessageRecord"];
            ret.text = messageText;
            ret.date = date;
            ret.visible = [NSNumber numberWithBool:visible];
            ret.type = type;
            ret.validated = [NSNumber numberWithBool:validated];
            ret.replacedMessageID = messageIDToReplace;
            ret.sender = sender;
            ret.session = conversation.record;
            ret.conversationEvent = conversation.lastEvent;
            ret.messageID = messageId;
            conversation.record.lastActivity = [NSDate date];
            
            [[HOPModelManager sharedModelManager] saveContext];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, String([([NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,[conversation getConversationID], messageId]) UTF8String]));
    }
    
    return ret;
}
- (void)setOutgoingMessageStatus:(HOPConversationThreadMessageDeliveryState)outgoingMessageStatus
{
    NSString* statusToSet = [HOPConversationThread stringForMessageDeliveryState:outgoingMessageStatus];
    if (statusToSet.length > 0)
    {
        self.outMessageStatus = statusToSet;
    
        [[HOPModelManager sharedModelManager] saveContext];
    }
}

- (HOPConversationThreadMessageDeliveryState)getOutgoingMessageStatus
{
    HOPConversationThreadMessageDeliveryState ret;
    
    ret = [HOPConversationThread toMessageDeliveryStates:self.outMessageStatus];
    
    return ret;
}

@end