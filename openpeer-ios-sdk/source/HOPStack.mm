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


#import <openpeer/core/IStack.h>
#import <zsLib/Log.h>

#import "HOPStack_Internal.h"
#import "OpenPeerStorageManager.h"
#import "OpenPeerUtility.h"

#import "HOPStack.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPStack

+ (id)sharedStack
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

#define WARNING_THIS_METHOD_DOES_NOT_NEED_ALL_THESE_PARAMS_ANYMORE 1
#define WARNING_THIS_METHOD_DOES_NOT_NEED_ALL_THESE_PARAMS_ANYMORE 2

- (void) setupWithStackDelegate:(id<HOPStackDelegate>) stackDelegate mediaEngineDelegate:(id<HOPMediaEngineDelegate>) mediaEngineDelegate appID:(NSString*) appID appName:(NSString*) appName appImageURL:(NSString*) appImageURL appURL:(NSString*) appURL userAgent:(NSString*) userAgent deviceID:(NSString*) deviceID deviceOs:(NSString*) deviceOs system:(NSString*) system
{
    //Check if delegates are nil
    if (!stackDelegate || !mediaEngineDelegate)
    {
        ZS_LOG_FATAL(Debug, [self log:@"Passed invalid delegate."]);
        [NSException raise:NSInvalidArgumentException format:@"Passed invalid delegate!"];
    }
    
    //Check if other parameters are valid
    if ( ([userAgent length] == 0 ) || ([deviceOs length] == 0 ) || ([system length] == 0 ) || ([deviceID length] == 0))
    {
        ZS_LOG_FATAL(Debug, [self log:@"Passed invalid system information."]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid system information!"];
    }
    
    [self createLocalDelegates:stackDelegate mediaEngineDelegate:mediaEngineDelegate];
    
    IStack::singleton()->setup(openPeerStackDelegatePtr, openPeerMediaEngineDelegatePtr);

    isReady = YES;
}

- (void) shutdown
{
    isReady = NO;
    IStack::singleton()->shutdown();
    [self deleteLocalDelegates];
}

- (BOOL) isStackReady
{
    return isReady;
}
#warning "createAuthorizedApplicationID SHOULD BE USED ONLY DURING DEVELOPMENT. AN AUTHORIZED APPLICATION ID SHOULD BE GENERATED FROM  A SERVER AND GIVEN TO THE APPLICATION."
+ (NSString*) createAuthorizedApplicationID:(NSString*) applicationID applicationIDSharedSecret:(NSString*) applicationIDSharedSecret expires:(NSDate*) expires
{
    NSString* ret = nil;
    
    NSLog(@"!!!!!!!!!!!!!!!!!!!! WARNING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!/n THIS SHOULD BE USED ONLY DURING DEVELOPMENT. AN AUTHORIZED APPLICATION ID SHOULD BE GENERATED FROM  A SERVER AND GIVEN TO THE APPLICATION");
    
    if ([applicationID length] > 0 && [applicationIDSharedSecret length] > 0)
    {
        String authorizedApplicationID = IStack::createAuthorizedApplicationID([applicationID UTF8String], [applicationIDSharedSecret UTF8String], boost::posix_time::from_time_t([expires timeIntervalSince1970]));
        if (authorizedApplicationID)
        {
            ret = [NSString stringWithUTF8String:authorizedApplicationID];
        }
    }
    
    return ret;
}

#pragma mark - Internal methods
- (void) createLocalDelegates:(id<HOPStackDelegate>) stackDelegate mediaEngineDelegate:(id<HOPMediaEngineDelegate>) mediaEngineDelegate 
{
    openPeerStackDelegatePtr = OpenPeerStackDelegate::create(stackDelegate);
    openPeerMediaEngineDelegatePtr = OpenPeerMediaEngineDelegate::create(mediaEngineDelegate);
}

- (void) deleteLocalDelegates
{
    openPeerStackDelegatePtr.reset();
    openPeerMediaEngineDelegatePtr.reset();
}


- (IStackPtr) getStackPtr
{
    return IStack::singleton();
}

- (String) log:(NSString*) message
{
    return String("HOPStack: ") + [message UTF8String];
}
@end


