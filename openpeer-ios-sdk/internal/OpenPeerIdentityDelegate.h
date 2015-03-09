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

#include <openpeer/core/types.h>
#include <openpeer/core/IIdentity.h>

#import "HOPProtocols.h"

using namespace openpeer;
using namespace openpeer::core;

@class HOPAccountIdentity;

ZS_DECLARE_CLASS_PTR(OpenPeerIdentityDelegate)

/**
 Wrapper Class that creates delegate object used in core.
 */
class OpenPeerIdentityDelegate : public IIdentityDelegate
{
protected:
    id<HOPAccountIdentityDelegate> identityDelegate;
    
    OpenPeerIdentityDelegate(id<HOPAccountIdentityDelegate> inIdentityDelegate);

public:
    ~OpenPeerIdentityDelegate();
    /**
     Create OpenPeerIdentityDelegate object packed in boost shared pointer.
     @returns OpenPeerIdentityDelegate object boost shared object
     */
    static OpenPeerIdentityDelegatePtr create(id<HOPAccountIdentityDelegate> inIdentityDelegate);
    
    virtual void onIdentityStateChanged(IIdentityPtr identity,IdentityStates state);
    virtual void onIdentityPendingMessageForInnerBrowserWindowFrame(IIdentityPtr identity);
    virtual void onIdentityRolodexContactsDownloaded(IIdentityPtr identity);
    
private:
    HOPAccountIdentity* getHOPAccountIdentity(IIdentityPtr identity);
    HOPAccountIdentity* getHOPAccountIdentity(IIdentityPtr identity, BOOL createNewIfMissing);
    void storeDownloadedContactsForIdentity(IIdentityPtr identity);
};