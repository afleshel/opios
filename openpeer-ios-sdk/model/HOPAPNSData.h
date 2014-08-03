//
//  HOPAPNSData.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 8/3/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPPublicPeerFile;

@interface HOPAPNSData : NSManagedObject

@property (nonatomic, retain) NSString * deviceToken;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) HOPPublicPeerFile *publicPeer;

@end
