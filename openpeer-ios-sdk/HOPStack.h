/*
 
 Copyright (c) 2012, SMB Phone Inc.
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
 Singleton class to represent the openpeer stack.
 */
@interface HOPStack : NSObject

/**
 Returns singleton object of this class.
 */
+ (id)sharedStack;
- (id) init __attribute__((unavailable("HOPStack is singleton class.")));

/**
 Initialise delegates objects required for communication between core and client.
 @param stackDelegate HOPStackDelegate delegate
 @param mediaEngineDelegate HOPMediaEngineDelegate delegate
 @param appID NSString organization assigned ID for the application (e.g. "com.xyz123.app1")
 @param appName NSString a branded human readable application name, e.g. "Hookflash"
 @param appImageURL NSString an HTTPS downloadable branded image for the application
 @param appURL NSString an HTTPS URL webpage / website that offers more information about application
 @param userAgent e.g. "App Name/App version (iOS/iPad)"
 @param deviceID device identifier
 @param deviceOs iOs version (e.g. "iOS 5.1.1")
 @param system System name (e.g. "iPhone 4S", "iPod Touch 4G")
 */
- (void) setupWithStackDelegate:(id<HOPStackDelegate>) stackDelegate mediaEngineDelegate:(id<HOPMediaEngineDelegate>) mediaEngineDelegate appID:(NSString*) appID appName:(NSString*) appName appImageURL:(NSString*) appImageURL appURL:(NSString*) appURL userAgent:(NSString*) userAgent deviceID:(NSString*) deviceID deviceOs:(NSString*) deviceOs system:(NSString*) system;

/**
 Shutdown stack.
 */
- (void) shutdown;

/** 
 Creates an authorized application ID from an application ID
 @param applicationID NSString applicationID obtained from Hookflash customer portal.
 @param applicationIDSharedSecret NSString Secret obtained from service provider
 @param expires NSDate date when authorized application ID expires
 @return NSString authorized application ID
 */
+ (NSString*) createAuthorizedApplicationID:(NSString*) applicationID applicationIDSharedSecret:(NSString*) applicationIDSharedSecret expires:(NSDate*) expires;
                                            
- (BOOL) isStackReady;
@end
