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


#import "HOPIdentity_Internal.h"
#import <openpeer/core/IIdentity.h>
#import <openpeer/core/IHelper.h>

#import "HOPAccount_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPModelManager.h"
#import "OpenPeerIdentityDelegate.h"
#import "OpenPeerUtility.h"
#import "HOPUtility.h"
#import "HOPRolodexContact_Internal.h"
#import "HOPIdentityContact_Internal.h"
#import "OpenPeerConstants.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPIdnState


@end

@interface HOPIdentity()

- (void) deleteMarkedRolodexContacts;

@end



@implementation HOPIdentity

+ (id) loginWithDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain  identityURIOridentityBaseURI:(NSString*) identityURIOridentityBaseURI outerFrameURLUponReload:(NSString*) outerFrameURLUponReload
{
    HOPIdentity* ret = nil;
    
    if (!inIdentityDelegate || [outerFrameURLUponReload length] == 0 || [identityURIOridentityBaseURI length] == 0 || [identityProviderDomain length] == 0)
    {
        ZS_LOG_ERROR(Debug, "Invalid input parameters!");
        return ret;
    }
    
    boost::shared_ptr<OpenPeerIdentityDelegate> identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
    
    IIdentityPtr identity = IIdentity::login([[HOPAccount sharedAccount]getAccountPtr],identityDelegatePtr, [identityProviderDomain UTF8String], [identityURIOridentityBaseURI UTF8String], [outerFrameURLUponReload UTF8String]);
    
    if (identity)
    {
        ret = [[self alloc] initWithIdentityPtr:identity openPeerIdentityDelegate:identityDelegatePtr];
        [[OpenPeerStorageManager sharedStorageManager] setIdentity:ret forPUID:identity->getID()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, "Identity login is not started successfully!");
    }
    
    return ret;
}

+ (id) loginWithDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain identityPreauthorizedURI:(NSString*) identityURI identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires
{
    HOPIdentity* ret = nil;
    
    if (!inIdentityDelegate || [identityURI length] == 0 || [identityAccessToken length] == 0 || [identityAccessSecret length] == 0)
    {
        ZS_LOG_ERROR(Debug, "Invalid input parameters!");
        return ret;
    }
    
    boost::shared_ptr<OpenPeerIdentityDelegate> identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
    
    IIdentityPtr identity = IIdentity::loginWithIdentityPreauthorized([[HOPAccount sharedAccount]getAccountPtr], identityDelegatePtr, [identityProviderDomain UTF8String], [identityURI UTF8String],[identityAccessToken UTF8String], [identityAccessSecret UTF8String], boost::posix_time::from_time_t([identityAccessSecretExpires timeIntervalSince1970]));
    
    if (identity)
    {
        ret = [[self alloc] initWithIdentityPtr:identity openPeerIdentityDelegate:identityDelegatePtr];
        //[[OpenPeerStorageManager sharedStorageManager] setIdentity:ret forId:identityURI];
        [[OpenPeerStorageManager sharedStorageManager] setIdentity:ret forPUID:identity->getID()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, "Identity login is not started successfully!");
    }
    
    return ret;
}

- (NSNumber*) getObjectId
{
    if (objectId == nil)
    {
        if(identityPtr)
        {
            ULONG objId = identityPtr->getID();
            objectId = [NSNumber numberWithUnsignedLong:objId];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
            [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
        }
    }
    return objectId;
}

- (HOPIdnState*) getState
{
    WORD lastErrorCode;
    zsLib::String lastErrorReason;
    HOPIdentityState state = (HOPIdentityState)identityPtr->getState(&lastErrorCode, &lastErrorReason);
    HOPIdnState* ret = [[HOPIdnState alloc] init];
    ret.state = state;
    ret.lastErrorCode = lastErrorCode;
    ret.lastErrorReason = [NSString stringWithCString:lastErrorReason encoding:NSUTF8StringEncoding];
    return ret;
}

- (BOOL) isDelegateAttached
{
    BOOL ret = NO;
    
    if(identityPtr)
    {
        ret = identityPtr->isDelegateAttached();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (void) attachDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate redirectionURL:(NSString*) redirectionURL
{
    if(identityPtr)
    {
        boost::shared_ptr<OpenPeerIdentityDelegate> identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
        openPeerIdentityDelegatePtr = identityDelegatePtr;
        identityPtr->attachDelegate(identityDelegatePtr,[redirectionURL UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}


- (void) attachDelegateAndPreauthorizedLogin:(id<HOPIdentityDelegate>) inIdentityDelegate identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires
{
    if(identityPtr)
    {
        if (inIdentityDelegate && [identityAccessToken length] > 0 && [identityAccessSecret length] > 0 )
        {
            boost::shared_ptr<OpenPeerIdentityDelegate> identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
            identityPtr->attachDelegateAndPreauthorizedLogin(identityDelegatePtr, [identityAccessToken UTF8String], [identityAccessSecret UTF8String], boost::posix_time::from_time_t([identityAccessSecretExpires timeIntervalSince1970]));
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid input parameters!"]);
            [NSException raise:NSInvalidArgumentException format:@"Invalid input parameters!"];
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

- (NSString*) getIdentityURI
{
    NSString* ret = nil;
    
    if(identityPtr)
    {
        ret = [NSString stringWithCString:identityPtr->getIdentityURI() encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (NSString*) getBaseIdentityURI
{
    NSString* ret = nil;
    
    if(identityPtr)
    {
        NSString* uri = [NSString stringWithCString:identityPtr->getIdentityURI() encoding:NSUTF8StringEncoding];
        if (uri)
            ret = [HOPUtility getBaseIdentityURIFromURI:uri];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (NSString*) getIdentityProviderDomain
{
    NSString* ret = nil;
    
    if(identityPtr)
    {
        ret = [NSString stringWithCString:identityPtr->getIdentityProviderDomain() encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (HOPIdentityContact*) getSelfIdentityContact
{
    HOPIdentityContact* ret = nil;
    
    if(identityPtr)
    {
        IdentityContact identityContact;
        identityPtr->getSelfIdentityContact(identityContact);
        
        //HACK: Because identityContact.mStableID is not filled correctly in the core
        NSString* sId = [[HOPAccount sharedAccount] getStableID];//
        NSString* stID = [NSString stringWithUTF8String:identityContact.mStableID];
        NSString* identityURI = [NSString stringWithUTF8String:identityContact.mIdentityURI];
        ret = [[HOPModelManager sharedModelManager] getIdentityContactByStableID:sId identityURI:identityURI];
        if (!ret)
        {
            NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPIdentityContact"];
            if (managedObject && [managedObject isKindOfClass:[HOPIdentityContact class]])
            {
                ret = (HOPIdentityContact*) managedObject;
                [ret updateWithIdentityContact:identityContact];
                //HACK: Because identityContact.mStableID is not filled correctly in the core
                ret.stableID = sId;
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (NSString*) getInnerBrowserWindowFrameURL
{
    NSString* ret = nil;
    
    if(identityPtr)
    {
        ret = [NSString stringWithCString:identityPtr->getInnerBrowserWindowFrameURL() encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}


- (void) notifyBrowserWindowVisible
{
    if(identityPtr)
    {
        identityPtr->notifyBrowserWindowVisible();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

- (void) notifyBrowserWindowClosed
{
    if(identityPtr)
    {
        identityPtr->notifyBrowserWindowClosed();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}
- (NSString*) getNextMessageForInnerBrowerWindowFrame
{
    NSString* ret = nil;
    
    if(identityPtr)
    {
        ret = [NSString stringWithCString:IHelper::convertToString( identityPtr->getNextMessageForInnerBrowerWindowFrame()) encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
    return ret;
}

- (void) handleMessageFromInnerBrowserWindowFrame:(NSString*) message
{
    if(identityPtr)
    {
        identityPtr->handleMessageFromInnerBrowserWindowFrame(IHelper::createElement([message UTF8String]));
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}
- (void) cancel
{
    if(identityPtr)
    {
        identityPtr->cancel();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

+ stateToString:(HOPIdentityState) state
{
    return [NSString stringWithUTF8String: IIdentity::toString((IIdentity::IdentityStates) state)];
}
+ (NSString*) stringForIdentityState:(HOPIdentityState) state
{
    return [NSString stringWithUTF8String: IIdentity::toString((IIdentity::IdentityStates) state)];
}

- (NSString *)description
{
    NSString* ret = nil;
    
    if (identityPtr)
        ret = [NSString stringWithUTF8String: IHelper::convertToString(IIdentity::toDebug(identityPtr))];
    else
        ret = NSLocalizedString(@"Core identity object is not created.", @"Core identity object is not created.");
    
    return ret;
}

- (void) startRolodexDownload:(NSString*) lastDownloadedVersion
{
    if(identityPtr)
    {
        self.flushAllRolodexContacts = NO;
        self.versionDownloadedStr = nil;
        self.arrayLastDownloadedRolodexContacts = nil;
        self.rolodexContactsObtained = NO;
        
        identityPtr->startRolodexDownload([lastDownloadedVersion UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

- (void) refreshRolodexContacts
{
    if(identityPtr)
    {
        identityPtr->refreshRolodexContacts();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

- (BOOL) getDownloadedRolodexContacts:(BOOL*) outFlushAllRolodexContacts outVersionDownloaded:(NSString**) outVersionDownloaded outRolodexContacts:(NSArray**) outRolodexContacts
{
    BOOL ret = NO;
    if(identityPtr)
    {
        *outFlushAllRolodexContacts = self.flushAllRolodexContacts;
        if ([self.versionDownloadedStr length] > 0)
            *outVersionDownloaded = self.versionDownloadedStr;
        
        *outRolodexContacts = self.arrayLastDownloadedRolodexContacts;
        ret = self.rolodexContactsObtained;
        /*bool flushAllRolodexContacts;
        String versionDownloadedStr;
        RolodexContactListPtr rolodexContacts;
        ret = identityPtr->getDownloadedRolodexContacts(flushAllRolodexContacts,versionDownloadedStr, rolodexContacts);
        
        *outFlushAllRolodexContacts = flushAllRolodexContacts;
        if (versionDownloadedStr)
            *outVersionDownloaded = [NSString stringWithCString:versionDownloadedStr encoding:NSUTF8StringEncoding];
        
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
                            [hopRolodexContact updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[self getIdentityProviderDomain] homeUserIdentityURI:[self getIdentityURI]];
                            [[HOPModelManager sharedModelManager] saveContext];
                        }
                        else
                        {
                            //Create a new menaged object for new rolodex contact
                            NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPRolodexContact"];
                            if ([managedObject isKindOfClass:[HOPRolodexContact class]])
                            {
                                hopRolodexContact = (HOPRolodexContact*)managedObject;
                                [hopRolodexContact updateWithCoreRolodexContact:rolodexContact identityProviderDomain:[self getIdentityProviderDomain] homeUserIdentityURI:[self getIdentityURI]];
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
                *outRolodexContacts = [NSArray arrayWithArray:tempArray];
        }*/
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid core identity object!"];
    }
    
    return ret;
}

- (void) startTimerForContactsDeletion
{
    [self stopTimerForContactsDeletion];
    
    self.deletionTimer = [NSTimer scheduledTimerWithTimeInterval:flushContactsDownloadTime target:self selector:@selector(deleteMarkedRolodexContacts) userInfo:nil repeats:NO];
}

- (void) stopTimerForContactsDeletion
{
    if ([self.deletionTimer isValid])
        [self.deletionTimer invalidate];
}

- (void) deleteMarkedRolodexContacts
{
    
}

- (void) destroyCoreObject
{
    if(identityPtr)
        identityPtr.reset();
}

#pragma mark - Internal methods
- (id) initWithIdentityPtr:(IIdentityPtr) inIdentityPtr
{
    self = [super init];
    if (self)
    {
        identityPtr = inIdentityPtr;
        NSString* uri = [NSString stringWithCString:identityPtr->getIdentityURI() encoding:NSUTF8StringEncoding];
        if (uri)
            self.identityBaseURI = [NSString stringWithString:[HOPUtility getBaseIdentityURIFromURI:uri]];
    }
    return self;
}

- (id) initWithIdentityPtr:(IIdentityPtr) inIdentityPtr openPeerIdentityDelegate:(boost::shared_ptr<OpenPeerIdentityDelegate>) inOpenPeerIdentityDelegate
{
    self = [super init];
    if (self)
    {
        identityPtr = inIdentityPtr;
        openPeerIdentityDelegatePtr = inOpenPeerIdentityDelegate;
        NSString* uri = [NSString stringWithCString:identityPtr->getIdentityURI() encoding:NSUTF8StringEncoding];
        if (uri)
            self.identityBaseURI = [NSString stringWithString:[HOPUtility getBaseIdentityURIFromURI:uri]];
    }
    return self;
}

- (void) setLocalDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate
{
    openPeerIdentityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
}

- (IIdentityPtr) getIdentityPtr
{
    return identityPtr;
}

- (String) log:(NSString*) message
{
    if (identityPtr)
        return String("HOPIdentity [") + string(identityPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPIdentity: ") + [message UTF8String];
}
@end
