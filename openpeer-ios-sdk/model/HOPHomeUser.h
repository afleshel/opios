//
//  HOPHomeUser.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 7/16/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAssociatedIdentity, HOPSessionRecord;

@interface HOPHomeUser : NSManagedObject

@property (nonatomic, retain) NSNumber * loggedIn;
@property (nonatomic, retain) NSString * reloginInfo;
@property (nonatomic, retain) NSString * stableId;
@property (nonatomic, retain) NSSet *associatedIdentities;
@property (nonatomic, retain) NSSet *sessionRecords;
@end

@interface HOPHomeUser (CoreDataGeneratedAccessors)

- (void)addAssociatedIdentitiesObject:(HOPAssociatedIdentity *)value;
- (void)removeAssociatedIdentitiesObject:(HOPAssociatedIdentity *)value;
- (void)addAssociatedIdentities:(NSSet *)values;
- (void)removeAssociatedIdentities:(NSSet *)values;

- (void)addSessionRecordsObject:(HOPSessionRecord *)value;
- (void)removeSessionRecordsObject:(HOPSessionRecord *)value;
- (void)addSessionRecords:(NSSet *)values;
- (void)removeSessionRecords:(NSSet *)values;

@end
