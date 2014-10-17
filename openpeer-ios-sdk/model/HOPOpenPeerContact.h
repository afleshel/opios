//
//  HOPOpenPeerContact.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 10/15/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAPNSData, HOPConversationRecord, HOPIdentityContact, HOPOpenPeerAccount, HOPParticipants, HOPPublicPeerFile;

@interface HOPOpenPeerContact : NSManagedObject

@property (nonatomic, retain) NSString * stableID;
@property (nonatomic, retain) HOPAPNSData *apnsData;
@property (nonatomic, retain) NSSet *identityContacts;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) HOPPublicPeerFile *publicPeerFile;
@property (nonatomic, retain) NSSet *sessionRecords;
@property (nonatomic, retain) HOPOpenPeerAccount *account;
@end

@interface HOPOpenPeerContact (CoreDataGeneratedAccessors)

- (void)addIdentityContactsObject:(HOPIdentityContact *)value;
- (void)removeIdentityContactsObject:(HOPIdentityContact *)value;
- (void)addIdentityContacts:(NSSet *)values;
- (void)removeIdentityContacts:(NSSet *)values;

- (void)addParticipantsObject:(HOPParticipants *)value;
- (void)removeParticipantsObject:(HOPParticipants *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

- (void)addSessionRecordsObject:(HOPConversationRecord *)value;
- (void)removeSessionRecordsObject:(HOPConversationRecord *)value;
- (void)addSessionRecords:(NSSet *)values;
- (void)removeSessionRecords:(NSSet *)values;

@end
