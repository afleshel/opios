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

/**
 *  Singleton class for work with cache.
 */
@interface HOPCache : NSObject

/**
 *  Returns singleton object of HOPCache class.
 */
+ (HOPCache*) sharedCache;

/**
 *  This init method is not available, because HOPCache is a singleton class.
 *
 */
- (id) init __attribute__((unavailable("HOPCache is singleton class.")));

/**
 *  Set default cache delegate. In this case there is no need to implement delegate in application
 */
- (void) setup;

/**
 Set cache delegate implemented in client application.
 @param cacheDelegate Delegate object that implements the HOPCacheDelegate protocol
 */
- (void) setDelegate:(id<HOPCacheDelegate>) cacheDelegate;

/**
 Returns cookie for the path.
 @param cookieNamePath Cookie path
 @return A string that represents a cookie.
 */
- (NSString*) fetchForCookieNamePath:(NSString*) cookieNamePath;

/**
 Stores cookie to cache for specified path.
 @param stringToStore Cookie value
 @param expireDate Expiry date
 @param cookieNamePath Cookie path
 */
- (void) store:(NSString*) stringToStore expireDate:(NSDate*) expireDate cookieNamePath:(NSString*) cookieNamePath;

/**
 Removes cookies from the cache for specified path
 @param cookieNamePath Cookie path
 */
- (void) removeCookieWithNamePath:(NSString*) cookieNamePath;

/**
 Removes all expired cookies.
 */
- (void) removeExpiredCookies;
@end