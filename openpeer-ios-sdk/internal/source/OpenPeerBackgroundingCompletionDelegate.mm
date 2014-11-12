/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "OpenPeerBackgroundingCompletionDelegate.h"
#import <openpeer/core/ILogger.h>
#import "HOPBackgrounding_Internal.h"
#import "OpenPeerStorageManager.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerBackgroundingCompletionDelegate::OpenPeerBackgroundingCompletionDelegate(id<HOPBackgroundingCompletionDelegate> inBackgroundingCompletionDelegate)
{
    backgroundingCompletionDelegate = inBackgroundingCompletionDelegate;
}

OpenPeerBackgroundingCompletionDelegatePtr OpenPeerBackgroundingCompletionDelegate::create(id<HOPBackgroundingCompletionDelegate> inBackgroundingCompletionDelegate)
{
    return OpenPeerBackgroundingCompletionDelegatePtr(new OpenPeerBackgroundingCompletionDelegate(inBackgroundingCompletionDelegate));
}

OpenPeerBackgroundingCompletionDelegate::~OpenPeerBackgroundingCompletionDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerBackgroundingCompletionDelegate destructor is called"));
}

void OpenPeerBackgroundingCompletionDelegate::onBackgroundingReady(IBackgroundingQueryPtr query)
{
    BOOL isActiveQuery = NO;
    IBackgroundingQueryPtr active = [[HOPBackgrounding sharedBackgrounding] getActiveQuery];
    if (active)
      isActiveQuery = active->getID() <= query->getID();
    
    if (isActiveQuery)
    {
        [backgroundingCompletionDelegate onBackgroundingReady];
    }
}

#pragma mark - OpenPeerBackgroundingDelegate
OpenPeerBackgroundingDelegate::OpenPeerBackgroundingDelegate(id<HOPBackgroundingDelegate> inBackgroundingDelegate)
{
    backgroundingDelegate = inBackgroundingDelegate;
}

OpenPeerBackgroundingDelegatePtr OpenPeerBackgroundingDelegate::create(id<HOPBackgroundingDelegate> inBackgroundingDelegate)
{
    return OpenPeerBackgroundingDelegatePtr(new OpenPeerBackgroundingDelegate(inBackgroundingDelegate));
}

OpenPeerBackgroundingDelegate::~OpenPeerBackgroundingDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerBackgroundingDelegate destructor is called"));
}

void OpenPeerBackgroundingDelegate::onBackgroundingGoingToBackground(IBackgroundingSubscriptionPtr subscription,IBackgroundingNotifierPtr notifier)
{
    if (![[OpenPeerStorageManager sharedStorageManager] backgroundingNotifier])
    {
        [[OpenPeerStorageManager sharedStorageManager] setBackgroundingNotifier:[[HOPBackgroundingNotifier alloc] initWithBackgroundingNotifierPtr:notifier]];
    }
    
    if (![[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription])
    {
        [[OpenPeerStorageManager sharedStorageManager] setBackgroundingSubscription:[[HOPBackgroundingSubscription alloc] initWithBackgroundingSubscriptionPtr:subscription]];
    }
    
    [backgroundingDelegate onBackgroundingGoingToBackground:[[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription] notifier:[[OpenPeerStorageManager sharedStorageManager] backgroundingNotifier]];
}
void OpenPeerBackgroundingDelegate::onBackgroundingGoingToBackgroundNow(IBackgroundingSubscriptionPtr subscription)
{
    if (![[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription])
    {
        [[OpenPeerStorageManager sharedStorageManager] setBackgroundingSubscription:[[HOPBackgroundingSubscription alloc] initWithBackgroundingSubscriptionPtr:subscription]];
    }
    [backgroundingDelegate onBackgroundingGoingToBackgroundNow:[[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription]];
}

void OpenPeerBackgroundingDelegate::onBackgroundingReturningFromBackground(IBackgroundingSubscriptionPtr subscription)
{
    if (![[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription])
    {
        [[OpenPeerStorageManager sharedStorageManager] setBackgroundingSubscription:[[HOPBackgroundingSubscription alloc] initWithBackgroundingSubscriptionPtr:subscription]];
    }
    [backgroundingDelegate onBackgroundingReturningFromBackground:[[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription]];
}

void OpenPeerBackgroundingDelegate::onBackgroundingApplicationWillQuit(IBackgroundingSubscriptionPtr subscription)
{
  if (![[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription])
  {
    [[OpenPeerStorageManager sharedStorageManager] setBackgroundingSubscription:[[HOPBackgroundingSubscription alloc] initWithBackgroundingSubscriptionPtr:subscription]];
  }
  [backgroundingDelegate onBackgroundingApplicationWillQuit:[[OpenPeerStorageManager sharedStorageManager] backgroundingSubscription]];
}


