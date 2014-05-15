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
#import "HOPUtility.h"
#import "HOPRolodexContact_Internal.h"
#import "HOPModelManager.h"
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
    //HOPIdentity* hopIdentity = this->getHOPIdentity(identity);
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity, state != HOPIdentityStateShutdown);
    
    [identityDelegate identity:hopIdentity stateChanged:(HOPIdentityStates) state];
}

void OpenPeerIdentityDelegate::onIdentityPendingMessageForInnerBrowserWindowFrame(IIdentityPtr identity)
{
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity);
    
    [identityDelegate onIdentityPendingMessageForInnerBrowserWindowFrame:hopIdentity];
}

void OpenPeerIdentityDelegate::onIdentityRolodexContactsDownloaded(IIdentityPtr identity)
{
    this->storeDownloadedContactsForIdentity(identity);
    
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity);
    
    [identityDelegate onIdentityRolodexContactsDownloaded:hopIdentity];
}

HOPIdentity* OpenPeerIdentityDelegate::getHOPIdentity(IIdentityPtr identity)
{
    HOPIdentity* hopIdentity = this->getHOPIdentity(identity, YES);//[[OpenPeerStorageManager sharedStorageManager] getIdentityForPUID:identity->getID()];
    
    /*if (!hopIdentity)
    {
        hopIdentity = [[HOPIdentity alloc] initWithIdentityPtr:identity];
        [identityDelegate onNewIdentity:hopIdentity];
        
        if (hopIdentity)
            [[OpenPeerStorageManager sharedStorageManager] setIdentity:hopIdentity forPUID:identity->getID()];
    }*/
    return hopIdentity;
}

HOPIdentity* OpenPeerIdentityDelegate::getHOPIdentity(IIdentityPtr identity, BOOL createNewIfMissing)
{
    HOPIdentity* hopIdentity = [[OpenPeerStorageManager sharedStorageManager] getIdentityForPUID:identity->getID()];
    if (!hopIdentity && createNewIfMissing)
    {
        hopIdentity = [[HOPIdentity alloc] initWithIdentityPtr:identity];
        [identityDelegate onNewIdentity:hopIdentity];
        
        if (hopIdentity)
            [[OpenPeerStorageManager sharedStorageManager] setIdentity:hopIdentity forPUID:identity->getID()];
    }
    return hopIdentity;
}

void OpenPeerIdentityDelegate::storeDownloadedContactsForIdentity(IIdentityPtr identityPtr)
{
    if(identityPtr)
    {
        HOPIdentity* hopIdentity = this->getHOPIdentity(identityPtr);
        
        bool flushAllRolodexContacts;
        String versionDownloadedStr;
        RolodexContactListPtr rolodexContacts;
        hopIdentity.rolodexContactsObtained = identityPtr->getDownloadedRolodexContacts(flushAllRolodexContacts,versionDownloadedStr, rolodexContacts);
        
        hopIdentity.flushAllRolodexContacts = flushAllRolodexContacts;
        if (versionDownloadedStr)
            hopIdentity.versionDownloadedStr = [NSString stringWithCString:versionDownloadedStr encoding:NSUTF8StringEncoding];
        
        if (rolodexContacts && rolodexContacts->size() > 0)
        {
            NSMutableArray* tempArray = [[NSMutableArray alloc] init];
            
            for (RolodexContactList::iterator contact = rolodexContacts->begin(); contact != rolodexContacts->end(); ++contact)
            {
                HOPRolodexContact* hopRolodexContact = nil;
                RolodexContact rolodexContact = *contact;
                NSString* contactIdentityURI = [NSString stringWithCString:rolodexContact.mIdentityURI encoding:NSUTF8StringEncoding];
                
                if ([contactIdentityURI length] > 0)
                {
                    if (rolodexContact.mDisposition == RolodexContact::Disposition_Update)
                    {
                        hopRolodexContact = [[HOPModelManager sharedModelManager] getRolodexContactByIdentityURI:contactIdentityURI];
                        if (hopRolodexContact)
                        {
                            //Update existing rolodex contact
                            [hopRolodexContact updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[hopIdentity getIdentityProviderDomain] homeUserIdentityURI:[hopIdentity getIdentityURI]];
                            [[HOPModelManager sharedModelManager] saveContext];
                        }
                        else
                        {
                            //Create a new menaged object for new rolodex contact
                            NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPRolodexContact"];
                            if ([managedObject isKindOfClass:[HOPRolodexContact class]])
                            {
                                hopRolodexContact = (HOPRolodexContact*)managedObject;
                                [hopRolodexContact updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[hopIdentity getIdentityProviderDomain] homeUserIdentityURI:[hopIdentity getIdentityURI]];
                                [[HOPModelManager sharedModelManager] saveContext];
                            }
                        }
                    }
                    else if (rolodexContact.mDisposition == RolodexContact::Disposition_Remove)
                    {
                        hopRolodexContact = [[HOPModelManager sharedModelManager] getRolodexContactByIdentityURI:contactIdentityURI];
                        [[HOPModelManager sharedModelManager] deleteObject:hopRolodexContact];
                    }
                    else if (rolodexContact.mDisposition == RolodexContact::Disposition_NA)
                    {
                        
                    }
                    else
                    {
                        
                    }
                }
                
                if (hopRolodexContact)
                    [tempArray addObject:hopRolodexContact];
            }
            
            if ([tempArray count] > 0)
            {
                hopIdentity.arrayLastDownloadedRolodexContacts = nil;
                hopIdentity.arrayLastDownloadedRolodexContacts = [NSArray arrayWithArray:tempArray];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, zsLib::String("Invalid identity object!"));
        [NSException raise:NSInvalidArgumentException format:@"Invalid core identity object!"];
    }
}
