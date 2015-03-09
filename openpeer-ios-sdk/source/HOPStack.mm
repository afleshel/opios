/*
 
 Copyright (c) 2015, Hookflash Inc.
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
#include <zsLib/types.h>
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

- (void) setupWithStackDelegate:(id<HOPStackDelegate>) stackDelegate mediaEngineDelegate:(id<HOPMediaEngineDelegate>) mediaEngineDelegate
{
    //Check if delegates are nil
    if (!stackDelegate || !mediaEngineDelegate)
    {
        ZS_LOG_FATAL(Debug, [self log:@"Passed invalid delegate."]);
        [NSException raise:NSInvalidArgumentException format:@"Passed invalid delegate!"];
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
+ (NSString*) createAuthorizedApplicationID:(NSString*) inApplicationID applicationIDSharedSecret:(NSString*) applicationIDSharedSecret expires:(NSDate*) expires
{
    NSString* ret = nil;
    
    NSLog(@"!!!!!!!!!!!!!!!!!!!! WARNING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!/n THIS SHOULD BE USED ONLY DURING DEVELOPMENT. AN AUTHORIZED APPLICATION ID SHOULD BE GENERATED FROM  A SERVER AND GIVEN TO THE APPLICATION");
    
    if ([inApplicationID length] > 0 && [applicationIDSharedSecret length] > 0)
    {
        String authorizedApplicationID = IStack::createAuthorizedApplicationID([inApplicationID UTF8String], [applicationIDSharedSecret UTF8String], zsLib::timeSinceEpoch(zsLib::Seconds(static_cast<zsLib::Seconds::rep>([expires timeIntervalSince1970]))));
        if (authorizedApplicationID)
        {
            ret = [NSString stringWithUTF8String:authorizedApplicationID];
        }
    }
    
    return ret;
}

+ (long) getExpiryForAuthorizedApplicationID:(NSString*) inAuthorizedApplicationID
{
    long ret = 0;
    if ([inAuthorizedApplicationID length] > 0)
    {
        zsLib::Seconds duration;
        zsLib::Time time = IStack::getAuthorizedApplicationIDExpiry([inAuthorizedApplicationID UTF8String],&duration);
        ret = duration.count();
    }
    return ret;
}

+ (BOOL) isAuthorizedApplicationExpiryWindowStillValid:(NSString*) inAuthorizedApplicationID minimumValidityWindowRequired:(long) minimumValidityWindowRequired
{
    BOOL ret = YES;
    
    if ([inAuthorizedApplicationID length] > 0)
    {
        ret = IStack::isAuthorizedApplicationIDExpiryWindowStillValid([inAuthorizedApplicationID UTF8String], zsLib::Seconds(minimumValidityWindowRequired));
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

- (void) doLogoutCleanup
{
    [[OpenPeerStorageManager sharedStorageManager] totalCleanup];
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


