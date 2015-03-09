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

#import "HOPBackgrounding_Internal.h"
#import <zsLib/Log.h>
#import "OpenPeerStorageManager.h"

using namespace openpeer;
using namespace openpeer::core;

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPBackgrounding

+ (HOPBackgrounding*) sharedBackgrounding
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void) notifyGoingToBackground:(id<HOPBackgroundingCompletionDelegate>) inDelegate
{
    if (!openPeerBackgroundingCompletionDelegatePtr)
    {
        ZS_LOG(Trace, [self log:@"Creating backgrounding completion delegate"]);
        openPeerBackgroundingCompletionDelegatePtr = OpenPeerBackgroundingCompletionDelegate::create(inDelegate);
    }
    ZS_LOG(Trace, [self log:@"Notifying core about going to background."]);
    activeQuery = IBackgrounding::notifyGoingToBackground(openPeerBackgroundingCompletionDelegatePtr);
}

- (void) notifyGoingToBackgroundNow
{
    ZS_LOG(Trace, [self log:@"Notifying core about going to background NOW."]);
    IBackgrounding::notifyGoingToBackgroundNow();
}

- (void) notifyReturningFromBackground
{
    ZS_LOG(Trace, [self log:@"Notifying core about returning to forground."]);
    IBackgrounding::notifyReturningFromBackground();
}

- (void) subscribeDelegate:(id<HOPBackgroundingDelegate>) inDelegate phase:(unsigned long) phase
{
    if (!openPeerBackgroundingDelegatePtr)
        openPeerBackgroundingDelegatePtr = OpenPeerBackgroundingDelegate::create(inDelegate);
    backgroundingSubscriptionPtr = IBackgrounding::subscribe(openPeerBackgroundingDelegatePtr, phase);
}

- (IBackgroundingQueryPtr) getActiveQuery
{
    return activeQuery;
}

- (String) log:(NSString*) message
{
    return String("HOPBackgrounding: ") + [message UTF8String];
}
@end

@implementation HOPBackgroundingSubscription

- (id) initWithBackgroundingSubscriptionPtr:(IBackgroundingSubscriptionPtr)inBackgroundingSubscriptionPtr
{
    self = [super init];
    if (self)
    {
        backgroundingSubscriptionPtr = inBackgroundingSubscriptionPtr;
    }
    return self;
}

- (void) cancel
{
    if (backgroundingSubscriptionPtr)
    {
        backgroundingSubscriptionPtr->cancel();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid backgrounding subscription object!"]);
    }
}

- (String) log:(NSString*) message
{
    return String("HOPBackgroundingSubscription: ") + [message UTF8String];
}

@end

@implementation HOPBackgroundingNotifier : NSObject

- (id) initWithBackgroundingNotifierPtr:(IBackgroundingNotifierPtr) inBackgroundingNotifierPtr
{
    self = [super init];
    if (self)
    {
        backgroundingNotifierPtr = inBackgroundingNotifierPtr;
    }
    return self;
}

- (void) ready
{
    if (backgroundingNotifierPtr)
    {
        backgroundingNotifierPtr->ready();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid backgrounding notifier object!"]);
    }
}
- (void) destroy
{
    if (backgroundingNotifierPtr)
    {
        backgroundingNotifierPtr.reset();
        [[OpenPeerStorageManager sharedStorageManager] setBackgroundingNotifier:nil];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid backgrounding notifier object!"]);
    }
}

- (String) log:(NSString*) message
{
    return String("HOPBackgroundingNotifier: ") + [message UTF8String];
}
@end