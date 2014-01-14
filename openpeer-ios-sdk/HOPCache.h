/*
 
 Copyright (c) 2013, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */


#import <Foundation/Foundation.h>
#import "HOPProtocols.h"

@interface HOPCache : NSObject

/**
 Returns singleton object of this class.
 */
+ (HOPCache*) sharedCache;
- (id) init __attribute__((unavailable("HOPCache is singleton class.")));

/**
 Set cache delegate implemented in client app
 @param cacheDelegate id<HOPCacheDelegate> cache delegate
 */
- (void) setDelegate:(id<HOPCacheDelegate>) cacheDelegate;

/**
 Fetches data for specified path
 @param cookieNamePath NSString path
 @return NSString fetched data
 */
- (NSString*) fetchForCookieNamePath:(NSString*) cookieNamePath;

/**
 Stored data to cache for specified path
 @param stringToStore NSString data to store
 @param expireDate NSDate data expire date
 @param cookieNamePath NSString path
 */
- (void) store:(NSString*) stringToStore expireDate:(NSDate*) expireDate cookieNamePath:(NSString*) cookieNamePath;

/**
 Removes data from cache for specified path
 @param cookieNamePath NSString path
 */
- (void) clearForCookieNamePath:(NSString*) cookieNamePath;

- (void) clearExpiredCookies;
@end