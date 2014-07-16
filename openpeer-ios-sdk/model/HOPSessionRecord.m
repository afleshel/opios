//
//  HOPSessionRecord.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 7/16/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "HOPSessionRecord.h"
#import "HOPConversationThreadRecord.h"
#import "HOPHomeUser.h"
#import "HOPMessageRecord.h"
#import "HOPPublicPeerFile.h"


@implementation HOPSessionRecord

@dynamic creationTime;
@dynamic lastActivity;
@dynamic name;
@dynamic sessionID;
@dynamic type;
@dynamic conversationThreadRecords;
@dynamic homeUser;
@dynamic messages;
@dynamic participants;

@end
