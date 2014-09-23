/*
 
 Copyright (c) 2014, Hookflash Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationThreadRecord, HOPMessageRecord, HOPOpenPeerAccount, HOPOpenPeerContact;

@interface HOPConversationRecord : NSManagedObject

@property (nonatomic, retain) NSDate * creationTime;
@property (nonatomic, retain) NSDate * lastActivity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *conversationThreadRecords;
@property (nonatomic, retain) HOPOpenPeerAccount *homeUser;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *participants;
@end

@interface HOPConversationRecord (CoreDataGeneratedAccessors)

- (void)addConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)removeConversationThreadRecordsObject:(HOPConversationThreadRecord *)value;
- (void)addConversationThreadRecords:(NSSet *)values;
- (void)removeConversationThreadRecords:(NSSet *)values;

- (void)addMessagesObject:(HOPMessageRecord *)value;
- (void)removeMessagesObject:(HOPMessageRecord *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addParticipantsObject:(HOPOpenPeerContact *)value;
- (void)removeParticipantsObject:(HOPOpenPeerContact *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

@end
