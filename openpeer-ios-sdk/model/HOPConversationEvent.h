//
//  HOPConversationEvent.h
//  webrtc_ios
//
//  Created by Sergej on 12/1/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationRecord, HOPMessageRecord, HOPParticipants;

@interface HOPConversationEvent : NSManagedObject

@property (nonatomic, retain) NSString * eventType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * showEvent;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString * eventID;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) HOPParticipants *participants;
@property (nonatomic, retain) HOPConversationRecord *session;
@end

@interface HOPConversationEvent (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(HOPMessageRecord *)value;
- (void)removeMessagesObject:(HOPMessageRecord *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
