/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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
 Singleton class that represents the openpeer stack.
 */
@interface HOPStack : NSObject

/**
 Returns singleton object of HOPStack class.
 */
+ (id)sharedStack;

/**
 *  This init method is not available, because HOPAccount is a singleton class.
 *
 */
- (id) init __attribute__((unavailable("HOPStack is singleton class.")));

/**
 *  Setup stack and initialize delegates objects required for communication between core and client.
 *
 *  @param stackDelegate       Delegate object that implements the HOPStackDelegate protocol
 *  @param mediaEngineDelegate Delegate object that implements the HOPMediaEngineDelegate protocol
 */
- (void) setupWithStackDelegate:(id<HOPStackDelegate>) stackDelegate mediaEngineDelegate:(id<HOPMediaEngineDelegate>) mediaEngineDelegate;

/**
 Shutdowns stack.
 */
- (void) shutdown;

/**
 *  Creates an authorized application ID based on application ID and application shred secret.
 *
 *  @param inApplicationID Application ID
 *  @param applicationIDSharedSecret Application shared secret
 *  @param expires                   Date when authorized application ID expires
 *
 *  @return A generated authorized application ID
 */
+ (NSString*) createAuthorizedApplicationID:(NSString*) inApplicationID applicationIDSharedSecret:(NSString*) applicationIDSharedSecret expires:(NSDate*) expires;


/**
 *  Returns expiry time in seconds for authrized application ID.
 *
 *  @param inAuthorizedApplicationID Authorized application ID
 *
 *  @return Time in seconds till expiry
 */
+ (long) getExpiryForAuthorizedApplicationID:(NSString*) inAuthorizedApplicationID;

/**
 *  Checks if authorized application id will be valid in some time frame.
 *
 *  @param inAuthorizedApplicationID     Authorized application ID
 *  @param minimumValidityWindowRequired Tiem frame in seconds for which check will be performed
 *
 *  @return YES if authorized application id will be valid in specified time frame, otherwise NO
 */
+ (BOOL) isAuthorizedApplicationExpiryWindowStillValid:(NSString*) inAuthorizedApplicationID minimumValidityWindowRequired:(long) minimumValidityWindowRequired;

/**
 *  Checks if stack is ready.
 *
 *  @return YES if it is ready, NO if it is not ready or shutdown precuderu is started
 */
- (BOOL) isStackReady;


/**
 *  Cleans all core objects, except stack, on logout.
 */
- (void) doLogoutCleanup;
@end
