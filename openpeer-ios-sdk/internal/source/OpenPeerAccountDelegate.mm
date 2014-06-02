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


#import "OpenPeerAccountDelegate.h"
#import "HOPAccount.h"
#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerAccountDelegate::OpenPeerAccountDelegate(id<HOPAccountDelegate> inAccountDelegate)
{
    accountDelegate = inAccountDelegate;
}

OpenPeerAccountDelegate::~OpenPeerAccountDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerAccountDelegate destructor is called"));
}

boost::shared_ptr<OpenPeerAccountDelegate>  OpenPeerAccountDelegate::create(id<HOPAccountDelegate> inAccountDelegate)
{
    return boost::shared_ptr<OpenPeerAccountDelegate>  (new OpenPeerAccountDelegate(inAccountDelegate));
}

void OpenPeerAccountDelegate::onAccountStateChanged(IAccountPtr account,AccountStates state)
{
    [accountDelegate account:[HOPAccount sharedAccount] stateChanged:(HOPAccountState)state];
}

void OpenPeerAccountDelegate::onAccountAssociatedIdentitiesChanged(IAccountPtr account)
{
    [accountDelegate onAccountAssociatedIdentitiesChanged:[HOPAccount sharedAccount]];
}

void OpenPeerAccountDelegate::onAccountPendingMessageForInnerBrowserWindowFrame(IAccountPtr account)
{
    [accountDelegate onAccountPendingMessageForInnerBrowserWindowFrame:[HOPAccount sharedAccount]];
}