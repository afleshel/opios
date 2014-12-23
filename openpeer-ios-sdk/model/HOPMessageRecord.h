//
//  HOPMessageRecord.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 12/22/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationEvent, HOPConversationRecord, HOPMessageEvent, HOPOpenPeerContact;

@interface HOPMessageRecord : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * deleted;
@property (nonatomic, retain) NSNumber * edited;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * incomingMessageStatus;
@property (nonatomic, retain) NSString * messageID;
@property (nonatomic, retain) NSString * outMessageStatus;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * showStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * validated;
@property (nonatomic, retain) NSString * replacedMessageID;
@property (nonatomic, retain) HOPConversationEvent *conversationEvent;
@property (nonatomic, retain) NSSet *messageEvent;
@property (nonatomic, retain) HOPOpenPeerContact *senderOpenPeer;
@property (nonatomic, retain) HOPConversationRecord *session;
@end

@interface HOPMessageRecord (CoreDataGeneratedAccessors)

- (void)addMessageEventObject:(HOPMessageEvent *)value;
- (void)removeMessageEventObject:(HOPMessageEvent *)value;
- (void)addMessageEvent:(NSSet *)values;
- (void)removeMessageEvent:(NSSet *)values;

@end
