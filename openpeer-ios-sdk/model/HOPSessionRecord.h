//
//  HOPSessionRecord.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 7/16/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationThreadRecord, HOPHomeUser, HOPMessageRecord, HOPPublicPeerFile;

@interface HOPSessionRecord : NSManagedObject

@property (nonatomic, retain) NSDate * creationTime;
@property (nonatomic, retain) NSDate * lastActivity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *conversationThreadRecords;
@property (nonatomic, retain) HOPHomeUser *homeUser;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *participants;
@end

@interface HOPSessionRecord (CoreDataGeneratedAccessors)

- (void)addConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)removeConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)addConversationThreadRecords:(NSSet *)values;
- (void)removeConversationThreadRecords:(NSSet *)values;

- (void)addMessagesObject:(HOPMessageRecord *)value;
- (void)removeMessagesObject:(HOPMessageRecord *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addParticipantsObject:(HOPPublicPeerFile *)value;
- (void)removeParticipantsObject:(HOPPublicPeerFile *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

@end
