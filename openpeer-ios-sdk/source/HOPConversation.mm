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

#import "HOPConversation.h"
#import "HOPAccount.h"
#import "HOPOpenPeerContact+External.h"

#import "HOPConversationThread.h"
#import "HOPConversationRecord.h"
#import "HOPConversationEvent+External.h"
#import "HOPConversationType.h"

#import "HOPRolodexContact+External.h"
#import "HOPMessageRecord+External.h"
#import "HOPModelManager.h"
#import "HOPUtility.h"
#import "HOPAccount.h"
#import "HOPsettings.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@interface HOPConversation()



@property (nonatomic, strong) NSDictionary* participantsDict;

@property (nonatomic, copy) NSString* identifier;

//- (String) log:(NSString*) message;

@end

@implementation HOPConversation


- (id) init
{
    self = [super init];
    if (self)
    {
        self.identifier = [HOPUtility getGUIDstring];
        self.setOfNotSentMessages = [NSMutableSet new];
        self.numberOfUnreadMessages = 0;
        self.redialCall = NO;
//        self.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
//        if (!self.thread)
//        {
//            self = nil;
//        }
    }
    return self;
}

/*- (id) initWithParticipants:(NSArray*) participants title:(NSString*) inTitle
{
    self = [self init];
    if (self && self.thread)
    {
        [self.thread addContacts:participants];
        
        self.title = inTitle.length > 0 ? inTitle : [self getDefaultTitle];
        
        self.record = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:self.thread type:nil date:[NSDate date] name:self.title participants:participants];
        
        self.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:self.record partcipants:participants title:self.title];
    }
    else
    {
        self = nil;
    }
    return self;
}*/

+ (NSDictionary*) createMetadataDictionary:(HOPConversationThreadType) threadType
{
    HOPConversationType* conversationType = [[HOPConversationType alloc] initWithConversationThreadType:threadType];
    
    NSDictionary* conversationTypeDict = [NSDictionary dictionaryWithObject:[[HOPSettings sharedSettings] getDefaultCovnersationType] forKey:[NSString stringWithUTF8String:ConversationThreadType::Definitions::Names::conversationType()]];
    NSDictionary* dict = [NSDictionary dictionaryWithObject:conversationTypeDict forKey:[NSString stringWithUTF8String:IConversationThread::Definitions::Names::metaDataName()]];
    
    return dict;
}

+ (HOPConversation*) createConversation
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        //+ (id) conversationThreadWithIdentities:(NSArray*) identities participants:(NSArray*) participants conversationThreadID:(NSString*) conversationThreadID metaData:(NSDictionary*) metaData
        NSDictionary* metadata = [HOPConversation createMetadataDictionary:[HOPConversationType conversationThreadTypeForString:[[HOPSettings sharedSettings] getDefaultCovnersationType]]];
        ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities] participants:@[] conversationThreadID: @"" metaData: metadata];
        if (!ret.thread)
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
        else
        {
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
        }
    }
    return ret;
}

+ (HOPConversation*) createConversationWithParticipants:(NSArray*) participants title:(NSString*) inTitle
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        NSDictionary* metadata = [HOPConversation createMetadataDictionary:[HOPConversationType conversationThreadTypeForString:[[HOPSettings sharedSettings] getDefaultCovnersationType]]];
        ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities] participants:participants conversationThreadID: @"" metaData: metadata];
        
        //ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
        if (ret.thread)
        {
            //[ret.thread addContacts:participants];
            
            ret.title = inTitle.length > 0 ? inTitle : [ret getDefaultTitle];
            
            if ([[[HOPSettings sharedSettings] getDefaultCovnersationType] isEqualToString:[NSString stringWithUTF8String: ConversationThreadType::Definitions::ValueKeywords::contactBased()]])
                ret.record = [[HOPModelManager sharedModelManager] getConversationRecordForParticipants:participants];
            
            if (!ret.record)
                ret.record = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:ret.thread type:nil date:[NSDate date] name:ret.title participants:participants];
            ret.identifier = ret.record.sessionID;
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:participants title:ret.title];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.title];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:participants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPConversation getCBCIDForContacts:participants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (HOPConversation*) createConversationWithThread:(HOPConversationThread*) inConversationThread
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        ret.thread = inConversationThread;
        if (ret.thread)
        {
            ret.title = [ret getDefaultTitle];
            
            NSArray* participants = [ret getParticipants];
            
            ret.record = [[HOPModelManager sharedModelManager] getConversationRecordForConversationThread:inConversationThread];
            
            if (!ret.record)
                ret.record = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:ret.thread type:nil date:[NSDate date] name:ret.title participants:participants];
            ret.identifier = ret.record.sessionID;
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:participants title:ret.title];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.title];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:participants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPConversation getCBCIDForContacts:participants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (HOPConversation*) createConversationForRecord:(HOPConversationRecord*) inConversationRecord
{
    HOPConversation* ret = [HOPConversation new];
    
    if (ret)
    {
        ret.record = inConversationRecord;
        if (ret.record)
        {
            ret.identifier = ret.record.sessionID;
            ret.title = ret.record.name;
            
            //NSArray* participants = [ret getParticipants];
            
            NSMutableArray* tempParticipants = [NSMutableArray new];
            for (HOPOpenPeerContact* contact in ret.record.participants)
            {
                [tempParticipants addObject:[contact getDefaultRolodexContact]];
            }
            ret.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
            [ret.thread addContacts:tempParticipants];
            
            ret.lastEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.record partcipants:tempParticipants title:ret.title];
            
            NSString* str = [NSString stringWithFormat:@"Conversation object with title %@", ret.title];
            ZS_LOG(Debug, [ret log:str]);
            
            ret.participantsDict = [NSDictionary dictionaryWithObject:tempParticipants forKey:ret.lastEvent.eventID];
            
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret threadID:[ret.thread getThreadId]];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret conversationID:ret.record.sessionID];
            [[OpenPeerStorageManager sharedStorageManager] setConversation:ret cbcID:[HOPConversation getCBCIDForContacts:tempParticipants]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [ret log:@"Invalid conversation thread object!"]);
            ret = nil;
        }
    }
    return ret;
}

+ (NSString*) getCBCIDForContacts:(NSArray*) contacts
{
    NSString* ret = @"";
    
    for (HOPRolodexContact* contact in contacts)
    {
        if (ret.length == 0)
            ret = [contact getStableID];
        else
            ret = [ret stringByAppendingString:[NSString stringWithFormat:@"_%@",[contact getStableID]]];
    }
    
    return ret;
}

- (void) addParticipants:(NSArray*) inParticipants
{
    if (self.thread && inParticipants.count > 0)
    {
        [self.thread addContacts:inParticipants];
    }
}

- (void) removeParticipants:(NSArray*) inParticipants
{
    if (self.thread && inParticipants.count > 0)
    {
        [self.thread removeContacts:inParticipants];
    }
}

- (void) setComposingStatus:(HOPConversationThreadContactStatus) composingStatus
{
    [self.thread setStatusInThread:composingStatus];
}
- (NSArray*) getParticipants
{
    NSArray* ret = [self.thread getContacts];
    return ret;
    
    /*if (self.lastEvent && self.lastEvent.eventID.length > 0)
    {
        ret = [self.participantsDict objectForKey:self.lastEvent.eventID];
    }
    
    if (!ret)
    {
        self.participantsDict = nil;
        ret = [self.thread getContacts];
        if (self.lastEvent && self.lastEvent.eventID.length > 0)
        {
            [self.participantsDict setValue:ret forKey:self.lastEvent.eventID];
        }
    }
    
    return ret;*/
}

- (void) refresh
{
    self.thread = nil;
    self.thread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
    [self.thread addContacts:self.participants];
}


- (void) clear
{
    if (self.thread)
        [self.thread destroyCoreObject];
}

- (HOPConversationThreadContactStatus) getContactStatus:(HOPRolodexContact*) rolodexContact
{
    HOPConversationThreadContactStatus ret = HOPComposingStateInactive;
    
    if (self.thread)
    {
        ret = [self.thread getContactStatus:rolodexContact];
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

- (void) markAllMessagesRead;
{
    if (self.thread)
        [self.thread markAllMessagesRead];
}
- (NSString*) getID
{
    return self.identifier;
}

- (NSString*) getDefaultTitle
{
    NSString* ret = @"";
    
    NSArray* participants = [self.thread getContacts];
    for (HOPRolodexContact* rolodexContact in participants)
    {
        if (rolodexContact)
        {
            if (ret.length == 0)
                ret = rolodexContact.name;
            else
            {
                ret = [ret stringByAppendingString:@", "];
                ret = [ret stringByAppendingString:rolodexContact.name];
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

- (String) log:(NSString*) message
{
    return String("HOPConversation: ") + [message UTF8String];
}
@end