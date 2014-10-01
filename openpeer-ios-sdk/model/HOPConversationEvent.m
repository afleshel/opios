//
//  HOPConversationEvent.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "HOPConversationEvent.h"
#import "HOPConversationRecord.h"
#import "HOPMessageRecord.h"
#import "HOPParticipants.h"
#import "HOPUtility.h"


@implementation HOPConversationEvent

@dynamic eventType;
@dynamic name;
@dynamic time;
@dynamic showEvent;
@dynamic messages;
@dynamic participants;
@dynamic session;

- (NSString *)sectionIdentifier
{
    return [HOPUtility getTimeSectionForDate:self.time];
}

@end
