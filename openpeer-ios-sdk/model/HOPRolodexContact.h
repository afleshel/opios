//
//  HOPRolodexContact.h
//  hfstack_ios
//
//  Created by Sergej on 11/18/14.
//  Copyright (c) 2014 SMB Phone Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPAssociatedIdentity, HOPAvatar, HOPIdentityContact, HOPOpenPeerContact;

@interface HOPRolodexContact : NSManagedObject

@property (nonatomic, retain) NSString * identityURI;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * profileURL;
@property (nonatomic, retain) NSNumber * readyForDeletion;
@property (nonatomic, retain) NSString * vProfileURL;
@property (nonatomic, retain) HOPAssociatedIdentity *associatedIdentity;
@property (nonatomic, retain) HOPAssociatedIdentity *associatedIdentityForHomeUser;
@property (nonatomic, retain) NSSet *avatars;
@property (nonatomic, retain) HOPIdentityContact *identityContact;
@property (nonatomic, retain) HOPOpenPeerContact *openPeerContact;
@end

@interface HOPRolodexContact (CoreDataGeneratedAccessors)

- (void)addAvatarsObject:(HOPAvatar *)value;
- (void)removeAvatarsObject:(HOPAvatar *)value;
- (void)addAvatars:(NSSet *)values;
- (void)removeAvatars:(NSSet *)values;

@end
