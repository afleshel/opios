//
//  HOPConversationEvent.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationRecord, HOPMessageRecord, HOPParticipants;

@interface HOPConversationEvent : NSManagedObject

@property (nonatomic, retain) NSString * eventType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * showEvent;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) HOPParticipants *participants;
@property (nonatomic, retain) HOPConversationRecord *session;
@end

@interface HOPConversationEvent (CoreDataGeneratedAccessors)

- (NSString *)sectionIdentifier;

- (void)addMessagesObject:(HOPMessageRecord *)value;
- (void)removeMessagesObject:(HOPMessageRecord *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
