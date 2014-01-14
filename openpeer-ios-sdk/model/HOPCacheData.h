//
//  HOPCacheData.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 12/30/13.
//  Copyright (c) 2013 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HOPCacheData : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * data;
@property (nonatomic, retain) NSNumber * expire;

@end
