//
//  HOPConversationRecord.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 1/15/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import "HOPConversationRecord.h"
#import "HOPConversationEvent.h"
#import "HOPConversationThreadRecord.h"
#import "HOPMessageRecord.h"
#import "HOPOpenPeerAccount.h"
#import "HOPOpenPeerContact.h"


@implementation HOPConversationRecord

@dynamic creationTime;
@dynamic lastActivity;
@dynamic name;
@dynamic sessionID;
@dynamic type;
@dynamic removed;
@dynamic selfRemoved;
@dynamic conversationThreadRecords;
@dynamic events;
@dynamic homeUser;
@dynamic messages;
@dynamic participants;

@end
