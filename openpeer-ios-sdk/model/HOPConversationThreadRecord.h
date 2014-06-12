//
//  HOPConversationThreadRecord.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 6/12/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPSessionRecord;

@interface HOPConversationThreadRecord : NSManagedObject

@property (nonatomic, retain) NSDate * creationTime;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * threadID;
@property (nonatomic, retain) NSSet *sessionReords;
@end

@interface HOPConversationThreadRecord (CoreDataGeneratedAccessors)

- (void)addSessionReordsObject:(HOPSessionRecord *)value;
- (void)removeSessionReordsObject:(HOPSessionRecord *)value;
- (void)addSessionReords:(NSSet *)values;
- (void)removeSessionReords:(NSSet *)values;

@end
