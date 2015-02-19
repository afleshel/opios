//
//  HOPAvatar.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/12/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPIdentity, HOPImage;

@interface HOPAvatar : NSManagedObject

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) HOPImage *avatarImage;
@property (nonatomic, retain) NSSet *identities;
@end

@interface HOPAvatar (CoreDataGeneratedAccessors)

- (void)addIdentitiesObject:(HOPIdentity *)value;
- (void)removeIdentitiesObject:(HOPIdentity *)value;
- (void)addIdentities:(NSSet *)values;
- (void)removeIdentities:(NSSet *)values;

@end
