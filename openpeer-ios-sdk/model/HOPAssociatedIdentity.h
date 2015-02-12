//
//  HOPAssociatedIdentity.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/12/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPIdentity, HOPIdentityProvider, HOPOpenPeerAccount;

@interface HOPAssociatedIdentity : NSManagedObject

@property (nonatomic, retain) NSString * downloadedVersion;
@property (nonatomic, retain) HOPOpenPeerAccount *account;
@property (nonatomic, retain) HOPIdentityProvider *identityProvider;
@property (nonatomic, retain) NSSet *identities;
@property (nonatomic, retain) HOPIdentity *selfIdentity;
@end

@interface HOPAssociatedIdentity (CoreDataGeneratedAccessors)

- (void)addIdentitiesObject:(HOPIdentity *)value;
- (void)removeIdentitiesObject:(HOPIdentity *)value;
- (void)addIdentities:(NSSet *)values;
- (void)removeIdentities:(NSSet *)values;

@end
