//
//  HOPCacheData.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 2/10/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HOPCacheData : NSManagedObject

@property (nonatomic, retain) NSString * data;
@property (nonatomic, retain) NSNumber * expire;
@property (nonatomic, retain) NSString * path;

@end
