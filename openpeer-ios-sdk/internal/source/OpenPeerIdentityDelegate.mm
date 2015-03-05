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


#import "OpenPeerIdentityDelegate.h"
#import "HOPAccountIdentity_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPUtility.h"
#import "HOPIdentity_Internal.h"
#import "HOPModelManager.h"
#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

OpenPeerIdentityDelegate::OpenPeerIdentityDelegate(id<HOPAccountIdentityDelegate> inIdentityDelegate)
{
    identityDelegate = inIdentityDelegate;
}

OpenPeerIdentityDelegate::~OpenPeerIdentityDelegate()
{
    ZS_LOG_DEBUG(zsLib::String("SDK - OpenPeerIdentityDelegate destructor is called"));
}

boost::shared_ptr<OpenPeerIdentityDelegate>  OpenPeerIdentityDelegate::create(id<HOPAccountIdentityDelegate> inIdentityDelegate)
{
    return boost::shared_ptr<OpenPeerIdentityDelegate>  (new OpenPeerIdentityDelegate(inIdentityDelegate));
}

void OpenPeerIdentityDelegate::onIdentityStateChanged(IIdentityPtr identity,IdentityStates state)
{
    ZS_LOG_DEBUG(zsLib::String("SDK - onIdentityStateChanged for URI: ") + identity->getIdentityURI());
    //HOPAccountIdentity* accountIdentity = this->getHOPIdentity(identity);
    HOPAccountIdentity* accountIdentity = this->getHOPAccountIdentity(identity, state != HOPIdentityStateShutdown);
    
    [identityDelegate identity:accountIdentity stateChanged:(HOPAccountIdentityState) state];
    
    if (state == HOPIdentityStateReady || state == HOPIdentityStateShutdown)
    {
        accountIdentity.isLoggingIn = NO;
        accountIdentity.isAssociating = NO;
    }
}

void OpenPeerIdentityDelegate::onIdentityPendingMessageForInnerBrowserWindowFrame(IIdentityPtr identity)
{
    HOPAccountIdentity* accountIdentity = this->getHOPAccountIdentity(identity);
    
    [identityDelegate onIdentityPendingMessageForInnerBrowserWindowFrame:accountIdentity];
}

void OpenPeerIdentityDelegate::onIdentityRolodexContactsDownloaded(IIdentityPtr identity)
{
    this->storeDownloadedContactsForIdentity(identity);
    
    HOPAccountIdentity* accountIdentity = this->getHOPAccountIdentity(identity);
    
    [identityDelegate onIdentityContactsDownloaded:accountIdentity];
}

HOPAccountIdentity* OpenPeerIdentityDelegate::getHOPAccountIdentity(IIdentityPtr identity)
{
    HOPAccountIdentity* ret = this->getHOPAccountIdentity(identity, YES);
    return ret;
}

HOPAccountIdentity* OpenPeerIdentityDelegate::getHOPAccountIdentity(IIdentityPtr identity, BOOL createNewIfMissing)
{
    HOPAccountIdentity* ret = [[OpenPeerStorageManager sharedStorageManager] getIdentityForPUID:identity->getID()];
    if (!ret && createNewIfMissing)
    {
        ret = [[HOPAccountIdentity alloc] initWithIdentityPtr:identity];
        [identityDelegate onNewIdentity:ret];
        
        if (ret)
            [[OpenPeerStorageManager sharedStorageManager] setIdentity:ret forPUID:identity->getID()];
    }
    return ret;
}

void OpenPeerIdentityDelegate::storeDownloadedContactsForIdentity(IIdentityPtr identityPtr)
{
    if(identityPtr)
    {
        HOPAccountIdentity* accountIdentity = this->getHOPAccountIdentity(identityPtr);
        
        bool flushAllIdentities;
        String versionDownloadedStr;
        RolodexContactListPtr rolodexContacts;
        accountIdentity.identitiesObtained = identityPtr->getDownloadedRolodexContacts(flushAllIdentities,versionDownloadedStr, rolodexContacts);
        
        accountIdentity.flushAllIdentities = flushAllIdentities;
        if (versionDownloadedStr)
            accountIdentity.versionDownloadedStr = [NSString stringWithCString:versionDownloadedStr encoding:NSUTF8StringEncoding];
        
        if (rolodexContacts && rolodexContacts->size() > 0)
        {
            NSMutableArray* tempArray = [[NSMutableArray alloc] init];
            
            for (RolodexContactList::iterator contact = rolodexContacts->begin(); contact != rolodexContacts->end(); ++contact)
            {
                HOPIdentity* identity = nil;
                RolodexContact rolodexContact = *contact;
                NSString* contactIdentityURI = [NSString stringWithCString:rolodexContact.mIdentityURI encoding:NSUTF8StringEncoding];
                
                if ([contactIdentityURI length] > 0)
                {
                    if (rolodexContact.mDisposition == RolodexContact::Disposition_Update)
                    {
                        identity = [[HOPModelManager sharedModelManager] getIdentityByIdentityURI:contactIdentityURI];
                        if (identity)
                        {
                            //Update existing rolodex contact
                            [identity updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[accountIdentity getIdentityProviderDomain] homeUserIdentityURI:[accountIdentity getIdentityURI]];
                            [[HOPModelManager sharedModelManager] saveContext];
                        }
                        else
                        {
                            //Create a new menaged object for new rolodex contact
                            NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPIdentity"];
                            if ([managedObject isKindOfClass:[HOPIdentity class]])
                            {
                                identity = (HOPIdentity*)managedObject;
                                [identity updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[accountIdentity getIdentityProviderDomain] homeUserIdentityURI:[accountIdentity getIdentityURI]];
                                [[HOPModelManager sharedModelManager] saveContext];
                            }
                        }
                    }
                    else if (rolodexContact.mDisposition == RolodexContact::Disposition_Remove)
                    {
                        identity = [[HOPModelManager sharedModelManager] getIdentityByIdentityURI:contactIdentityURI];
                        [[HOPModelManager sharedModelManager] deleteObject:identity];
                    }
                    else if (rolodexContact.mDisposition == RolodexContact::Disposition_NA)
                    {
                        
                    }
                    else
                    {
                        
                    }
                }
                
                if (identity)
                    [tempArray addObject:identity];
            }
            
            if ([tempArray count] > 0)
            {
                accountIdentity.arrayLastDownloadedIdentities = nil;
                accountIdentity.arrayLastDownloadedIdentities = [NSArray arrayWithArray:tempArray];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, zsLib::String("Invalid identity object!"));
        [NSException raise:NSInvalidArgumentException format:@"Invalid core identity object!"];
    }
}
