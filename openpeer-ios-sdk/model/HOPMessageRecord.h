//
//  HOPMessageRecord.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/10/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPPublicPeerFile, HOPSessionRecord;

@interface HOPMessageRecord : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * message;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * delivered;
@property (nonatomic, retain) HOPSessionRecord *session;
@property (nonatomic, retain) HOPPublicPeerFile *fromPeer;

@end
