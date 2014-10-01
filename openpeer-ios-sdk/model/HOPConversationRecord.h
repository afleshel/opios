//
//  HOPConversationRecord.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 9/29/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationEvent, HOPConversationThreadRecord, HOPMessageRecord, HOPOpenPeerAccount, HOPOpenPeerContact;

@interface HOPConversationRecord : NSManagedObject

@property (nonatomic, retain) NSDate * creationTime;
@property (nonatomic, retain) NSDate * lastActivity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *conversationThreadRecords;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) HOPOpenPeerAccount *homeUser;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *participants;
@end

@interface HOPConversationRecord (CoreDataGeneratedAccessors)

- (void)addConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)removeConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)addConversationThreadRecords:(NSSet *)values;
- (void)removeConversationThreadRecords:(NSSet *)values;

- (void)addEventsObject:(HOPConversationEvent *)value;
- (void)removeEventsObject:(HOPConversationEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addMessagesObject:(HOPMessageRecord *)value;
- (void)removeMessagesObject:(HOPMessageRecord *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addParticipantsObject:(HOPOpenPeerContact *)value;
- (void)removeParticipantsObject:(HOPOpenPeerContact *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

@end
