//
//  HOPConversationEvent+External.m
//  openpeer-ios-sdk
//
//  Created by Sergej on 11/20/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "HOPConversationEvent+External.h"
#import "HOPParticipants.h"
#import "HOPOpenPeerContact+External.h"

@implementation HOPConversationEvent (External)


-(NSArray*) getContacts
{
    NSMutableArray* ret = nil;
    if (self.participants && self.participants.participants.count > 0)
    {
        ret = [[NSMutableArray alloc] init];
        for (HOPOpenPeerContact* contact in self.participants.participants)
        {
            HOPRolodexContact* rolodexContact = [contact getDefaultRolodexContact];
            if (rolodexContact)
                [ret addObject:rolodexContact];
        }
    }
    return ret;
}
@end
