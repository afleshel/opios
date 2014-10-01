//
//  HOPConversationRecord.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
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
@dynamic conversationThreadRecords;
@dynamic events;
@dynamic homeUser;
@dynamic messages;
@dynamic participants;

@end
