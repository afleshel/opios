
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


#import "HOPIdentityLookup_Internal.h"
#import "HOPIdentityLookupInfo_Internal.h"
#import <openpeer/core/IIdentityLookup.h>
#import <openpeer/core/IHelper.h>
#import "OpenPeerStorageManager.h"
#import "HOPAccount_Internal.h"
#import "HOPRolodexContact.h"
#import "HOPIdentityContact_Internal.h"
#import "HOPModelManager.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPIdentityLookupResult

@end

@implementation HOPIdentityLookup

- (id) initWithDelegate:(id<HOPIdentityLookupDelegate>) inDelegate identityLookupInfos:(NSArray*) identityLookupInfos identityServiceDomain:(NSString*) identityServiceDomain
{
    if ([identityServiceDomain length] > 0 && [identityLookupInfos count] > 0)
    {
        if (self = [super init])
        {
            IIdentityLookup::IdentityLookupInfoList identityLookupInfoList;
            for (HOPRolodexContact* contact in identityLookupInfos)
            {
                IIdentityLookup::IdentityLookupInfo lookupInfo;
                lookupInfo.mIdentityURI = [contact.identityURI UTF8String];
                lookupInfo.mLastUpdated = [contact isKindOfClass:[HOPIdentityContact class]] ? boost::posix_time::from_time_t([[(HOPIdentityContact*)contact lastUpdated] timeIntervalSince1970]) : Time();
                
                identityLookupInfoList.push_back(lookupInfo);
            }
            [self setLocalDelegates:inDelegate];
            
            identityLookupPtr = IIdentityLookup::create([[HOPAccount sharedAccount] getAccountPtr], openPeerIdentityLookupDelegatePtr, identityLookupInfoList, [identityServiceDomain UTF8String]);
            if (identityLookupPtr)
                [[OpenPeerStorageManager sharedStorageManager] setIdentityLookup:self forPUID:identityLookupPtr->getID()];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, "Invalid input parameters!");
    }
                     
    return self;
}

- (BOOL) isComplete:(NSError**) error
{
    BOOL ret = NO;
    
    if(identityLookupPtr)
    {
        ret = identityLookupPtr->isComplete();
        if (ret)
        {
            WORD errorCode = 0;
            String errorReason;
            if (!identityLookupPtr->wasSuccessful(&errorCode, &errorReason))
            {
                NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
                [errorDetails setValue:[NSString stringWithUTF8String: errorReason] forKey:NSLocalizedDescriptionKey];
                // populate the error object with the details
                if (error != NULL)
                    *error = [NSError errorWithDomain:@"identityLookup" code:errorCode userInfo:errorDetails];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity lookup object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
    
    return ret;
}

- (HOPIdentityLookupResult*) getLookupResult
{
    HOPIdentityLookupResult* ret = nil;
    
    if(identityLookupPtr)
    {
        ret = [[HOPIdentityLookupResult alloc] init];
        WORD errorCode;
        String errorReason;
        ret.wasSuccessful  = identityLookupPtr->wasSuccessful(&errorCode, &errorReason);
        ret.errorCode = errorCode;
        ret.errorReason = [NSString stringWithUTF8String:errorReason];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity lookup object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
    
    return ret;
}

- (void) cancel
{
    if(identityLookupPtr)
    {
        identityLookupPtr->cancel();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity lookup object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
}

- (NSArray*) getUpdatedIdentities
{
    NSMutableArray* ret = nil;
    if(identityLookupPtr)
    {
        IdentityContactListPtr identityContactListPtr = identityLookupPtr->getUpdatedIdentities();
        if (identityContactListPtr)
        {
            ret = [[NSMutableArray alloc] init];
            for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
            {
                IdentityContact identityContact = *identityContactInfo;
                if (identityContact.hasData())
                {
                    NSString* sId = [NSString stringWithUTF8String:identityContact.mStableID];
                    NSString* identityURI = [NSString stringWithUTF8String:identityContact.mIdentityURI];
                    HOPIdentityContact* hopIdentityContact = [[HOPModelManager sharedModelManager] getIdentityContactByStableID:sId identityURI:identityURI];
                    
                    if (!hopIdentityContact)
                    {
                        NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPIdentityContact"];
                        if (managedObject && [managedObject isKindOfClass:[HOPIdentityContact class]])
                        {
                            hopIdentityContact = (HOPIdentityContact*) managedObject;
                        }
                    }
                    
                    if (hopIdentityContact)
                    {
                        [hopIdentityContact updateWithIdentityContact:identityContact];
                    
                        [ret addObject:hopIdentityContact];
                    }
                }
            }
            [[HOPModelManager sharedModelManager] saveContext];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity lookup object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
    return ret;
}

- (NSArray*) getUnchangedIdentities
{
    NSMutableArray* ret = nil;
    if(identityLookupPtr)
    {
        IIdentityLookup::IdentityLookupInfoListPtr identityLookupInfoListPtr = identityLookupPtr->getUnchangedIdentities();
        if (identityLookupInfoListPtr)
        {
            ret = [[NSMutableArray alloc] init];
            for (IIdentityLookup::IdentityLookupInfoList::iterator identityLookupInfo = identityLookupInfoListPtr->begin(); identityLookupInfo != identityLookupInfoListPtr->end(); ++identityLookupInfo)
            {
                IIdentityLookup::IdentityLookupInfo identityInfo = *identityLookupInfo;
                HOPIdentityLookupInfo* hopIdentityLookupInfo = [[HOPIdentityLookupInfo alloc] initWithCoreIdentityLookupInfo:identityInfo];
                [ret addObject:hopIdentityLookupInfo];
            }
        }
    }
    else
    {
            
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
    return ret;
}

- (NSArray*) getInvalidIdentities
{
    NSMutableArray* ret = nil;
    if(identityLookupPtr)
    {
        IIdentityLookup::IdentityLookupInfoListPtr identityLookupInfoListPtr = identityLookupPtr->getInvalidIdentities();
        if (identityLookupInfoListPtr)
        {
            ret = [[NSMutableArray alloc] init];
            for (IIdentityLookup::IdentityLookupInfoList::iterator identityLookupInfo = identityLookupInfoListPtr->begin(); identityLookupInfo != identityLookupInfoListPtr->end(); ++identityLookupInfo)
            {
                IIdentityLookup::IdentityLookupInfo identityInfo = *identityLookupInfo;
                HOPIdentityLookupInfo* hopIdentityLookupInfo = [[HOPIdentityLookupInfo alloc] initWithCoreIdentityLookupInfo:identityInfo];
                [ret addObject:hopIdentityLookupInfo];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity lookup object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity lookup object!"];
    }
    return ret;
}

- (void) destroyCoreObject
{
    if(identityLookupPtr)
        identityLookupPtr.reset();
}

- (NSString *)description
{
    NSString* ret = nil;
    
    if (identityLookupPtr)
        ret = [NSString stringWithUTF8String: IHelper::convertToString(IIdentityLookup::toDebug(identityLookupPtr))];
    else
        ret = NSLocalizedString(@"Identity lookup object is not created.", @"Identity lookup  object is not created.");
    
    return ret;
}

#pragma mark - Internal
- (void) setLocalDelegates:(id<HOPIdentityLookupDelegate>) inIdentityLookupDelegate
{
    openPeerIdentityLookupDelegatePtr = OpenPeerIdentityLookupDelegate::create(inIdentityLookupDelegate);
}

- (IIdentityLookupPtr) getIdentityLookupPtr
{
    return identityLookupPtr;
}

- (String) log:(NSString*) message
{
    if (identityLookupPtr)
        return String("HOPIdentityLookup [") + string(identityLookupPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPIdentityLookup: ") + [message UTF8String];
}

@end