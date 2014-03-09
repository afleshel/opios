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


#import "OpenPeerIdentityDelegate.h"
#import "HOPIdentity_Internal.h"

#import "OpenPeerStorageManager.h"
//#import "OpenPeerUtility.h"
#import "HOPUtility.h"

#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerIdentityDelegate::OpenPeerIdentityDelegate(id<HOPIdentityDelegate> inIdentityDelegate)
{
    identityDelegate = inIdentityDelegate;
}

OpenPeerIdentityDelegate::~OpenPeerIdentityDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerIdentityDelegate destructor is called"));
}

boost::shared_ptr<OpenPeerIdentityDelegate>  OpenPeerIdentityDelegate::create(id<HOPIdentityDelegate> inIdentityDelegate)
{
    return boost::shared_ptr<OpenPeerIdentityDelegate>  (new OpenPeerIdentityDelegate(inIdentityDelegate));
}

void OpenPeerIdentityDelegate::onIdentityStateChanged(IIdentityPtr identity,IdentityStates state)
{
    ZS_LOG_DEBUG(zsLib::String("SDK - onIdentityStateChanged for URI: ") + identity->getIdentityURI());
    // NSString* identityId = [NSString stringWithCString:identity->getIdentityURI() encoding:NSUTF8StringEncoding];
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity);//[[OpenPeerStorageManager sharedStorageManager] getIdentityForId:identityId];
    
    [identityDelegate identity:hopIdentity stateChanged:(HOPIdentityStates) state];
}

void OpenPeerIdentityDelegate::onIdentityPendingMessageForInnerBrowserWindowFrame(IIdentityPtr identity)
{
    //NSString* identityId = [NSString stringWithCString:identity->getIdentityURI() encoding:NSUTF8StringEncoding];
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity);//[[OpenPeerStorageManager sharedStorageManager] getIdentityForId:identityId];
    
    [identityDelegate onIdentityPendingMessageForInnerBrowserWindowFrame:hopIdentity];
}

void OpenPeerIdentityDelegate::onIdentityRolodexContactsDownloaded(IIdentityPtr identity)
{
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity);//[[OpenPeerStorageManager sharedStorageManager] getIdentityForId:identityId];
    
    [identityDelegate onIdentityRolodexContactsDownloaded:hopIdentity];
}
HOPIdentity* OpenPeerIdentityDelegate::getHOPIdentity(IIdentityPtr identity)
{
    NSString* identityURI = [NSString stringWithCString:identity->getIdentityURI() encoding:NSUTF8StringEncoding];
    NSNumber* identityObjectId = [NSNumber numberWithInt:identity->getID()];
    //TODO: Use identityObjectId for key
    HOPIdentity* hopIdentity = [[OpenPeerStorageManager sharedStorageManager] getIdentityForId:identityURI];
     
    if (!hopIdentity && ![HOPUtility isBaseIdentityURI:identityURI])
    {
        NSString* uri = [HOPUtility getBaseIdentityURIFromURI:identityURI];
        if (uri)
        {
            hopIdentity = [[OpenPeerStorageManager sharedStorageManager] getIdentityForId:uri];
            
            if (!hopIdentity)
            {
                hopIdentity = [[HOPIdentity alloc] initWithIdentityPtr:identity];
                [identityDelegate onNewIdentity:hopIdentity];
            }
            
            if (hopIdentity)
                [[OpenPeerStorageManager sharedStorageManager] setIdentity:hopIdentity forId:identityURI];
        }
    }
    return hopIdentity;
}