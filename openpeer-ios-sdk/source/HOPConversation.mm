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
#import "OpenPeerStorageManager.h"

#import "HOPConversation_Internal.h"
#import "HOPAccount.h"
#import "HOPContact+External.h"
#import "HOPCall.h"

#import "HOPConversationThread_Internal.h"
#import "HOPConversationRecord.h"
#import "HOPConversationEvent+External.h"
#import "HOPConversationType.h"

#import "HOPIdentity+External.h"
#import "HOPMessageRecord+External.h"
#import "HOPModelManager_Internal.h"
#import "HOPUtility.h"
#import "HOPAccount.h"
#import "HOPsettings.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@interface HOPConversation()


@property (nonatomic, strong) NSDictionary* participantsDict;



@end

@implementation HOPConversation


- (id) init
{
    self = [super init];
    if (self)
    {
        self.conversationID = [HOPUtility getGUIDstring];
        self.setOfNotSentMessages = [NSMutableSet new];
        self.numberOfUnreadMessages = 0;
        self.redialCall = NO;
        self.conversationType = [[HOPSettings sharedSettings] getDefaultCovnersationType];
    }
    return self;
}


+ (HOPConversation*) conversationWithParticipants:(NSArray*) participants title:(NSString*) inTitle type:(HOPConversationThreadType) type
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        ret.conversationType = type;
        
        ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities] participants:participants conversationThreadID: @"" threadType:type];
        
        if (ret.thread)
        {
            ret.topic = inTitle.length > 0 ? inTitle : [ret getDefaultTitle];
            
            if (type == HOPConversationThreadTypeContactBased)
                ret.record = [[HOPModelManager sharedModelManager] getConversationRecordForParticipants:participants];
            
            if (!ret.record)
                ret.record = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:ret.thread type:[HOPConversationType stringForConversationThreadType:type] date:[NSDate date] name:ret.topic participants:participants];
            
            ret.conversationID = ret.record.sessionID;
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:participants title:ret.topic];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.topic];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:participants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPUtility getCBCIDForContacts:participants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (HOPConversation *) conversationForID:(NSString *)conversationID threadType:(NSString *)threadType participants:(NSArray *)participants
{
    HOPConversation* conversation = nil;
    if (conversationID.length > 0)
        conversation = [[OpenPeerStorageManager sharedStorageManager] getConversationForID:conversationID];
    
    if (!conversation)
    {
        HOPConversationRecord* record = [[HOPModelManager sharedModelManager] getConversationRecordByID:conversationID];
        if (record)
            conversation = [HOPConversation conversationForRecord:record];
    }
    
    if (!conversation)
    {
        if (threadType.length > 0)
        {
            if ([threadType isEqualToString:[HOPConversation stringForConversationThreadType:HOPConversationThreadTypeContactBased]])
            {
                conversation = [HOPConversation getConversationForCBCID:[HOPUtility getCBCIDForContacts:participants]];
                if (!conversation)
                    conversation = [HOPConversation conversationWithParticipants:participants title:nil type:[HOPConversation conversationThreadTypeForString:threadType]];
            }
            else
            {
                conversation = [HOPConversation conversationWithParticipants:participants title:nil type:[HOPConversation conversationThreadTypeForString:threadType]];
            }
        }
        else
        {
            if (participants.count == 1)
                conversation = [HOPConversation conversationWithParticipants:participants title:nil type:HOPConversationThreadTypeContactBased];
            else
                conversation = [HOPConversation conversationWithParticipants:participants title:nil type:[[HOPSettings sharedSettings] getDefaultCovnersationType]];
        }
    }
    return conversation;
}

+ (HOPConversation*) conversationWithThread:(HOPConversationThread*) inConversationThread
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        ret.thread = inConversationThread;
        ret.conversationType = inConversationThread.conversationType;
        if (ret.thread)
        {
            ret.topic = [ret getDefaultTitle];
            
            NSArray* participants = [ret getParticipants];
            
            ret.record = [[HOPModelManager sharedModelManager] getConversationRecordForConversationThread:inConversationThread];
            
            if (!ret.record)
                ret.record = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:ret.thread type:[HOPConversationType stringForConversationThreadType: ret.thread.conversationType] date:[NSDate date] name:ret.topic participants:participants];

            ret.conversationID = ret.record.sessionID;
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:participants title:ret.topic];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.topic];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:participants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPUtility getCBCIDForContacts:participants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (HOPConversation*) conversationForRecord:(HOPConversationRecord*) inConversationRecord
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        ret.record = inConversationRecord;
        if (ret.record)
        {
            ret.conversationID = ret.record.sessionID;
            ret.topic = ret.record.name;
            ret.conversationType = [HOPConversationType conversationThreadTypeForString: ret.record.type];
            
            NSMutableArray* tempParticipants = [NSMutableArray new];
            for (HOPContact* contact in ret.record.participants)
            {
                [tempParticipants addObject:[contact getDefaultIdentity]];
            }

            ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities] participants:tempParticipants conversationThreadID: inConversationRecord.sessionID threadType:[HOPConversationType conversationThreadTypeForString:inConversationRecord.type]];
            
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:tempParticipants title:ret.topic];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.topic];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:tempParticipants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPUtility getCBCIDForContacts:tempParticipants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (NSArray*) getConversations
{
    return [[OpenPeerStorageManager sharedStorageManager] getConversations];
}

- (void) setComposingState:(HOPComposingState) composingState
{
    [self.thread setComposingStatusInThread:composingState];
}
- (NSArray*) getParticipants
{
    NSArray* ret = self.thread ? self.thread.participants : nil;
    //NSArray* ret = [self.thread getContacts];
    return ret;
}

- (void) refresh
{
    NSArray* tempParticipants = nil;
    if (self.thread.participants.count > 0)
        tempParticipants = [NSArray arrayWithArray:self.thread.participants];
    self.thread = nil;
    self.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
    [self.thread addContacts:tempParticipants];
}


- (void) clear
{
    if (self.thread)
        [self.thread destroyCoreObject];
    
    [[OpenPeerStorageManager sharedStorageManager] removeConversation:self];
}

- (HOPComposingState) getComposingStateForContact:(HOPIdentity*) identity
{
    HOPComposingState ret = HOPComposingStateInactive;
    
    if (self.thread)
    {
        ret = [self.thread getComposingStateForContact:identity];
    }
    
    return ret;
}

- (HOPMessageRecord*) getMessageForID: (NSString*) messageID
{
    HOPMessageRecord* ret = nil;
    
    if (self.thread && messageID.length > 0)
        ret = [self.thread getMessageForID:messageID];
    
    return ret;
}

- (void) sendMessage: (HOPMessageRecord*) message
{
    if (self.thread && message)
        [self.thread sendMessage:message];
}

- (HOPCall*) placeCallForParticipants:(NSArray*) participants includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo
{
    self.currentCall = [HOPCall placeCallForConversation:self partcipants:participants includeAudio:includeAudio includeVideo:includeVideo];
    return self.currentCall;
}

- (void) markAllMessagesRead;
{
    if (self.thread)
        [self.thread markAllMessagesRead];
}
- (NSString*) getConversationID
{
    return _conversationID;
}

- (void)setConversationID:(NSString *)conversationID
{
    if (conversationID.length > 0)
    {
        _conversationID = [NSString stringWithString:conversationID];
        if (self.record)
        {
            self.record.sessionID = conversationID;
            [[HOPModelManager sharedModelManager] saveContext];
        }
    }
}

- (NSString*) getDefaultTitle
{
    NSString* ret = @"";
    
    ret = [HOPConversation getDefaultTitleForParticipants:self.thread.participants];
    return ret;
}

+(NSString*) getDefaultTitleForParticipants:(NSArray*) inParticipants
{
    NSString* ret = @"";
    
    for (HOPIdentity* identity in inParticipants)
    {
        if (identity)
        {
            if (ret.length == 0)
                ret = identity.name;
            else
            {
                ret = [ret stringByAppendingString:@", "];
                ret = [ret stringByAppendingString:identity.name];
            }
        }
    }
    return ret;
}

+ (NSString*) stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState) state
{
    return [HOPConversationThread stringForMessageDeliveryState:state];
}

+ (NSString*) stringForContactConnectionState:(HOPConversationThreadContactConnectionState) state
{
    return [HOPConversationThread stringForContactConnectionState:state];
}

+ (NSString*) stringForConversationThreadType:(HOPConversationThreadType) type
{
    return [HOPConversationType stringForConversationThreadType:type];
}

+ (HOPConversationThreadType) conversationThreadTypeForString:(NSString*) type
{
    return [HOPConversationType conversationThreadTypeForString:type];
}
- (String) log:(NSString*) message
{
    return String("HOPConversation: ") + [message UTF8String];
}

+ (HOPConversation*) conversationOnParticipantsChanged:(NSArray*) newParticipantsList conversation:(HOPConversation*) conversation
{
    HOPConversation* ret = nil;
    NSString* topic = [HOPConversation getDefaultTitleForParticipants:newParticipantsList];
    
    NSMutableArray* arrayOfAddedParticipants = [NSMutableArray arrayWithArray:newParticipantsList];
    [arrayOfAddedParticipants removeObjectsInArray:conversation.participants];
    NSMutableArray* arrayOfRemovedParticipants = [NSMutableArray arrayWithArray:conversation.participants];
    [arrayOfRemovedParticipants removeObjectsInArray:newParticipantsList];
    
    if (conversation.conversationType == HOPConversationThreadTypeContactBased)
    {
        if(newParticipantsList.count > 0)
        {
            if ([[HOPSettings sharedSettings] getDefaultCovnersationType] == HOPConversationThreadTypeContactBased)
                ret = [[OpenPeerStorageManager sharedStorageManager] getConversationForCBCID:[HOPUtility getCBCIDForContacts:newParticipantsList]];
            
            if (!ret)
                ret = [HOPConversation conversationWithParticipants:newParticipantsList title:[HOPConversation getDefaultTitleForParticipants:newParticipantsList] type:[[HOPSettings sharedSettings] getDefaultCovnersationType]];
        }
    }
    else if (conversation.conversationType == HOPConversationThreadTypeThreadBased)
    {
        if (conversation.thread && arrayOfAddedParticipants.count > 0)
        {
            [conversation.thread addContacts:arrayOfAddedParticipants];
            for (HOPIdentity* identity in arrayOfAddedParticipants)
            {
                HOPContact* participant = identity.contact;
                if (participant)
                    [conversation.record addParticipantsObject:participant];
            }
            
            conversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedParticipant" conversationRecord:conversation.record partcipants:conversation.participants title:topic];
        }
        
        if (conversation.thread && arrayOfRemovedParticipants.count > 0)
        {
            [conversation.thread removeContacts:arrayOfRemovedParticipants];
            
            for (HOPIdentity* identity in arrayOfRemovedParticipants)
            {
                HOPContact* participant = identity.contact;
                if (participant)
                    [conversation.record removeParticipantsObject:participant];
            }
            
            conversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"removedParticipant" conversationRecord:conversation.record partcipants:conversation.participants title:topic];
        }
        
        ret = conversation;
    }
    
    if (ret)
    {
        ret.record.name = topic;
        ret.topic = conversation.record.name;
        [[HOPModelManager sharedModelManager] saveContext];
    }
    return ret;
}
+ (HOPConversation*) conversationOnParticipantsAdded:(NSArray*) addedParticipants conversation:(HOPConversation*) conversation
{
    HOPConversation* ret = nil;
    
    if (conversation.conversationType == HOPConversationThreadTypeContactBased)
    {
        if(addedParticipants.count > 0)
        {
            NSMutableArray* allParticipants = [NSMutableArray arrayWithArray:conversation.participants];
            [allParticipants addObjectsFromArray:addedParticipants];
            
            if ([[HOPSettings sharedSettings] getDefaultCovnersationType] == HOPConversationThreadTypeContactBased)
                ret = [[OpenPeerStorageManager sharedStorageManager] getConversationForCBCID:[HOPUtility getCBCIDForContacts:allParticipants]];
            
            if (!ret)
                ret = [HOPConversation conversationWithParticipants:allParticipants title:[HOPConversation getDefaultTitleForParticipants:allParticipants] type:[[HOPSettings sharedSettings] getDefaultCovnersationType]];
        }
    }
    else if (conversation.conversationType == HOPConversationThreadTypeThreadBased)
    {
        if (conversation.thread && addedParticipants.count > 0)
        {
            [conversation.thread addContacts:addedParticipants];
            for (HOPIdentity* identity in addedParticipants)
            {
                HOPContact* participant = identity.contact;
                if (participant)
                    [conversation.record addParticipantsObject:participant];
            }
        }
        
        ret = conversation;
    }
    
    if (ret)
    {
        conversation.record.name = [HOPConversation getDefaultTitleForParticipants:conversation.participants];
        conversation.topic = conversation.record.name;
        
        conversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedParticipant" conversationRecord:conversation.record partcipants:conversation.participants title:conversation.topic];
        
        [[HOPModelManager sharedModelManager] saveContext];
    }
    
    return ret;
}

+ (HOPConversation*) conversationOnParticipantsRemoved:(NSArray*) removedParticipants conversation:(HOPConversation*) conversation
{
    HOPConversation* ret = nil;
    
    if (conversation.participants.count >= removedParticipants.count)
    {
        if (conversation.conversationType == HOPConversationThreadTypeContactBased)
        {
            if(removedParticipants.count > 0)
            {
                NSMutableArray* allParticipants = [NSMutableArray arrayWithArray:conversation.participants];
                [allParticipants removeObjectsInArray:removedParticipants];
                
                if ([[HOPSettings sharedSettings] getDefaultCovnersationType] == HOPConversationThreadTypeContactBased)
                    ret = [[OpenPeerStorageManager sharedStorageManager] getConversationForCBCID:[HOPUtility getCBCIDForContacts:allParticipants]];
                
                if (!ret)
                    ret = [HOPConversation conversationWithParticipants:allParticipants title:[HOPConversation getDefaultTitleForParticipants:allParticipants] type:[[HOPSettings sharedSettings] getDefaultCovnersationType]];
            }
        }
        else if (conversation.conversationType == HOPConversationThreadTypeThreadBased)
        {
            if (conversation.thread && removedParticipants.count > 0)
            {
                [conversation.thread removeContacts:removedParticipants];
            }
            
            for (HOPIdentity* identity in removedParticipants)
            {
                HOPContact* participant = identity.contact;
                if (participant)
                    [conversation.record removeParticipantsObject:participant];
            }
            
            ret = conversation;
        }
    }
    else
    {
        ret = conversation; //If number of removed participants is equal or greater than number of active partcipants, do nothing.
    }
    
    
    if (ret)
    {
        conversation.record.name = [HOPConversation getDefaultTitleForParticipants:conversation.participants];
        conversation.topic = conversation.record.name;
        
        conversation.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"removedParticipant" conversationRecord:conversation.record partcipants:conversation.participants title:conversation.topic];
        
        [[HOPModelManager sharedModelManager] saveContext];
    }
    return ret;
}

+ (HOPConversation*) getConversationForID:(NSString*) inConversationID
{
    return [[OpenPeerStorageManager sharedStorageManager] getConversationForID:inConversationID];
}

+ (HOPConversation*) getConversationForCBCID:(NSString*) cbcID
{
    return [[OpenPeerStorageManager sharedStorageManager] getConversationForCBCID:cbcID];
}

- (BOOL) quit
{
    BOOL ret = NO;
    if (self.participants.count > 1)
    {
        self.record.selfRemoved = [NSNumber numberWithBool:YES];
        [self.thread removeContacts:@[[HOPIdentity getSelf]]];
        [self.thread destroyCoreObject];
        ret = YES;
        [[HOPModelManager sharedModelManager] saveContext];

    }
    
    return ret;
}

- (BOOL) isQuit
{
    BOOL ret = YES;
    
    if (self.record)
        ret = self.record.selfRemoved.boolValue;
    
    return ret;
}
- (void) onRemovalTimerExpired:(id) object
{
    @synchronized(self)
    {
        [self.removalTimer invalidate];
        self.removalTimer = nil;
        self.previousParticipants = nil;
    }
}

- (void) addParticipants:(NSArray*) inParticipants
{
    if (self.conversationType == HOPConversationThreadTypeThreadBased)
    {
        if (self.thread && inParticipants.count > 0)
        {
            [self.thread addContacts:inParticipants];
        }
    }
}

- (void) removeParticipants:(NSArray*) inParticipants
{
    if (self.conversationType == HOPConversationThreadTypeThreadBased)
    {
        if (self.thread && inParticipants.count > 0)
        {
            [self.thread removeContacts:inParticipants];
        }
    }
}
@end