//
//  HOPOpenPeerContact.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 1/29/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAPNSData, HOPConversationRecord, HOPIdentityContact, HOPOpenPeerAccount, HOPParticipants, HOPPublicPeerFile, HOPRolodexContact;

@interface HOPOpenPeerContact : NSManagedObject

@property (nonatomic, retain) NSString * stableID;
@property (nonatomic, retain) HOPOpenPeerAccount *account;
@property (nonatomic, retain) HOPAPNSData *apnsData;
@property (nonatomic, retain) NSSet *identityContacts;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) HOPPublicPeerFile *publicPeerFile;
@property (nonatomic, retain) NSSet *rolodexContacts;
@property (nonatomic, retain) NSSet *sessionRecords;
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

- (void)addRolodexContactsObject:(HOPRolodexContact *)value;
- (void)removeRolodexContactsObject:(HOPRolodexContact *)value;
- (void)addRolodexContacts:(NSSet *)values;
- (void)removeRolodexContacts:(NSSet *)values;

- (void)addSessionRecordsObject:(HOPConversationRecord *)value;
- (void)removeSessionRecordsObject:(HOPConversationRecord *)value;
- (void)addSessionRecords:(NSSet *)values;
- (void)removeSessionRecords:(NSSet *)values;

@end
