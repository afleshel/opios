//
//  HOPContact.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/12/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAPNSData, HOPConversationRecord, HOPIdentity, HOPOpenPeerAccount, HOPParticipants, HOPPublicPeerFile;

@interface HOPContact : NSManagedObject

@property (nonatomic, retain) NSString * stableID;
@property (nonatomic, retain) HOPOpenPeerAccount *account;
@property (nonatomic, retain) HOPAPNSData *apnsData;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) HOPPublicPeerFile *publicPeerFile;
@property (nonatomic, retain) NSSet *identities;
@property (nonatomic, retain) NSSet *sessionRecords;
@end

@interface HOPContact (CoreDataGeneratedAccessors)

- (void)addParticipantsObject:(HOPParticipants *)value;
- (void)removeParticipantsObject:(HOPParticipants *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

- (void)addIdentitiesObject:(HOPIdentity *)value;
- (void)removeIdentitiesObject:(HOPIdentity *)value;
- (void)addIdentities:(NSSet *)values;
- (void)removeIdentities:(NSSet *)values;

- (void)addSessionRecordsObject:(HOPConversationRecord *)value;
- (void)removeSessionRecordsObject:(HOPConversationRecord *)value;
- (void)addSessionRecords:(NSSet *)values;
- (void)removeSessionRecords:(NSSet *)values;

@end
