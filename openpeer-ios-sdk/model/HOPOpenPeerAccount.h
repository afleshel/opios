//
//  HOPOpenPeerAccount.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 10/15/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAssociatedIdentity, HOPConversationRecord, HOPOpenPeerContact;

@interface HOPOpenPeerAccount : NSManagedObject

@property (nonatomic, retain) NSNumber * loggedIn;
@property (nonatomic, retain) NSString * reloginInfo;
@property (nonatomic, retain) NSString * stableId;
@property (nonatomic, retain) NSSet *associatedIdentities;
@property (nonatomic, retain) NSSet *sessionRecords;
@property (nonatomic, retain) HOPOpenPeerContact *contact;
@end

@interface HOPOpenPeerAccount (CoreDataGeneratedAccessors)

- (void)addAssociatedIdentitiesObject:(HOPAssociatedIdentity *)value;
- (void)removeAssociatedIdentitiesObject:(HOPAssociatedIdentity *)value;
- (void)addAssociatedIdentities:(NSSet *)values;
- (void)removeAssociatedIdentities:(NSSet *)values;

- (void)addSessionRecordsObject:(HOPConversationRecord *)value;
- (void)removeSessionRecordsObject:(HOPConversationRecord *)value;
- (void)addSessionRecords:(NSSet *)values;
- (void)removeSessionRecords:(NSSet *)values;

@end
