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


#import "OpenPeerIdentityLookupDelegate.h"
#import "HOPIdentityLookup_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPModelManager_Internal.h"
#import "HOPContact.h"
#import "HOPIdentity.h"

#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerIdentityLookupDelegate::OpenPeerIdentityLookupDelegate(id<HOPIdentityLookupDelegate> inIdentityLookupDelegate)
{
    identityLookupDelegate = inIdentityLookupDelegate;
}

OpenPeerIdentityLookupDelegate::~OpenPeerIdentityLookupDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerIdentityLookupDelegate destructor is called"));
}

boost::shared_ptr<OpenPeerIdentityLookupDelegate> OpenPeerIdentityLookupDelegate::create(id<HOPIdentityLookupDelegate> inIdentityLookupDelegate)
{
    return boost::shared_ptr<OpenPeerIdentityLookupDelegate> (new OpenPeerIdentityLookupDelegate(inIdentityLookupDelegate));
}

void OpenPeerIdentityLookupDelegate::onIdentityLookupCompleted(IIdentityLookupPtr lookup)
{
    this->updateContactsReceivedOnIdentityLookup(lookup);
    
    HOPIdentityLookup* identityLookup = [[OpenPeerStorageManager sharedStorageManager] getIdentityLookupForPUID:lookup->getID()];
    [identityLookupDelegate onIdentityLookupCompleted:identityLookup];
}

void OpenPeerIdentityLookupDelegate::updateContactsReceivedOnIdentityLookup(IIdentityLookupPtr identityLookupPtr)
{
    if(identityLookupPtr)
    {
        HOPIdentityLookup* identityLookup = [[OpenPeerStorageManager sharedStorageManager] getIdentityLookupForPUID:identityLookupPtr->getID()];
        
        IdentityContactListPtr identityContactListPtr = identityLookupPtr->getUpdatedIdentities();
        if (identityContactListPtr)
        {
            if (identityLookup.arrayLastUpdatedContacts)
                [identityLookup.arrayLastUpdatedContacts removeAllObjects];
            else
                identityLookup.arrayLastUpdatedContacts = [[NSMutableArray alloc] init];
            
            for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
            {
                IdentityContact identityContact = *identityContactInfo;
                if (identityContact.hasData())
                {
                    HOPIdentity* identity = [[HOPModelManager sharedModelManager] createIdentityForCoreIdentity:identityContact];
                    if (identity)
                    {
                        [identityLookup.arrayLastUpdatedContacts addObject:identity];
                    }
                }
            }
            [[HOPModelManager sharedModelManager] saveContext];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, zsLib::String("Invalid identity lookup object!"));
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
}