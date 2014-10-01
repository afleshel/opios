//
//  HOPParticipants.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationEvent, HOPOpenPeerContact;

@interface HOPParticipants : NSManagedObject

@property (nonatomic, retain) NSString * cbcID;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *participants;
@end

@interface HOPParticipants (CoreDataGeneratedAccessors)

- (NSString *)sectionIdentifier;
- (HOPConversationEvent*) lastEvent;
- (NSDate*) getDateOfLastEvent;

- (void)addEventsObject:(HOPConversationEvent *)value;
- (void)removeEventsObject:(HOPConversationEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addParticipantsObject:(HOPOpenPeerContact *)value;
- (void)removeParticipantsObject:(HOPOpenPeerContact *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

@end
