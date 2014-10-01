//
//  HOPParticipants.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "HOPParticipants.h"
#import "HOPConversationEvent.h"
#import "HOPOpenPeerContact.h"
#import "HOPUtility.h"

@implementation HOPParticipants

@dynamic cbcID;
@dynamic events;
@dynamic participants;

- (NSString *)sectionIdentifier
{
    NSString* ret = nil;
    NSArray* sorted = [self.events.allObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    if (sorted.count > 0)
        ret = [HOPUtility getTimeSectionForDate:((HOPConversationEvent*) sorted[0]).time];
    return ret;
}

- (HOPConversationEvent*) lastEvent
{
    NSArray* sorted = [self.events.allObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    return sorted[0];
}

- (NSDate*) getDateOfLastEvent
{
    NSDate* ret = nil;
    NSArray* sorted = [self.events.allObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    if (sorted.count > 0)
        ret = ((HOPConversationEvent*) sorted[0]).time;
    
    return ret;
}
@end
