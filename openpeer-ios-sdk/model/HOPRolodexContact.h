//
//  HOPRolodexContact.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/11/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAssociatedIdentity, HOPAvatar, HOPOpenPeerContact;

@interface HOPRolodexContact : NSManagedObject

@property (nonatomic, retain) NSString * identityURI;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * profileURL;
@property (nonatomic, retain) NSNumber * readyForDeletion;
@property (nonatomic, retain) NSString * vProfileURL;
@property (nonatomic, retain) NSDate * expires;
@property (nonatomic, retain) NSString * identityProofBundle;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) HOPAssociatedIdentity *associatedIdentity;
@property (nonatomic, retain) HOPAssociatedIdentity *associatedIdentityForHomeUser;
@property (nonatomic, retain) NSSet *avatars;
@property (nonatomic, retain) HOPOpenPeerContact *openPeerContact;
@end

@interface HOPRolodexContact (CoreDataGeneratedAccessors)

- (void)addAvatarsObject:(HOPAvatar *)value;
- (void)removeAvatarsObject:(HOPAvatar *)value;
- (void)addAvatars:(NSSet *)values;
- (void)removeAvatars:(NSSet *)values;

@end
