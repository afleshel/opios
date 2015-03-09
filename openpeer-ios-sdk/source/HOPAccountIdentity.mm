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


#import "HOPAccountIdentity_Internal.h"
#import <openpeer/core/IIdentity.h>
#import <openpeer/core/IHelper.h>

#import "HOPAccount_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPModelManager_Internal.h"
#import "OpenPeerIdentityDelegate.h"
#import "OpenPeerUtility.h"
#import "HOPUtility.h"
#import "HOPIdentity_Internal.h"
#import "OpenPeerConstants.h"
#import "HOPContact.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPIdnState


@end

@interface HOPAccountIdentity()

- (void) deleteMarkedIdentities;

@end



@implementation HOPAccountIdentity

+ (id) loginWithDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain  identityURIOridentityBaseURI:(NSString*) identityURIOridentityBaseURI outerFrameURLUponReload:(NSString*) outerFrameURLUponReload
{
    HOPAccountIdentity* ret = nil;
    
    ZS_LOG(Debug,"Starting identity login");
    
    if (!inIdentityDelegate || [outerFrameURLUponReload length] == 0 || [identityURIOridentityBaseURI length] == 0 || [identityProviderDomain length] == 0)
    {
        ZS_LOG_ERROR(Debug, "Invalid input parameters!");
        return ret;
    }
    
    OpenPeerIdentityDelegatePtr identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
    
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
    
    if ([HOPAccount sharedAccount].openPeerAccount.associatedIdentities.count > 0)
        ret.isAssociating = YES;
    else
        ret.isLoggingIn = YES;
    
    return ret;
}

+ (id) loginWithDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain identityPreauthorizedURI:(NSString*) identityURI identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires
{
    HOPAccountIdentity* ret = nil;
    
    if (!inIdentityDelegate || [identityURI length] == 0 || [identityAccessToken length] == 0 || [identityAccessSecret length] == 0)
    {
        ZS_LOG_ERROR(Debug, "Invalid input parameters!");
        return ret;
    }
    
    OpenPeerIdentityDelegatePtr identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);

    IIdentity::Token identityToken;
    identityToken.mID = [identityAccessToken UTF8String];
    identityToken.mSecret = [identityAccessSecret UTF8String];
    identityToken.mExpires = zsLib::timeSinceEpoch(zsLib::Seconds(static_cast<zsLib::Seconds::rep>([identityAccessSecretExpires timeIntervalSince1970])));

    IIdentityPtr identity = IIdentity::loginWithIdentityPreauthorized([[HOPAccount sharedAccount]getAccountPtr], identityDelegatePtr, [identityProviderDomain UTF8String], [identityURI UTF8String], identityToken);
    
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
    
    if ([HOPAccount sharedAccount].openPeerAccount.associatedIdentities.count > 0)
        ret.isAssociating = YES;
    else
        ret.isLoggingIn = YES;
    
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
    HOPAccountIdentityState state = (HOPAccountIdentityState)identityPtr->getState(&lastErrorCode, &lastErrorReason);
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

- (void) attachDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate redirectionURL:(NSString*) redirectionURL
{
    if(identityPtr)
    {
        OpenPeerIdentityDelegatePtr identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
        openPeerIdentityDelegatePtr = identityDelegatePtr;
        identityPtr->attachDelegate(identityDelegatePtr,[redirectionURL UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}


- (void) attachDelegateAndPreauthorizedLogin:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires
{
    if(identityPtr)
    {
        if (inIdentityDelegate && [identityAccessToken length] > 0 && [identityAccessSecret length] > 0 )
        {
            IIdentity::Token token;
            token.mID = [identityAccessToken UTF8String];
            token.mSecret = [identityAccessSecret UTF8String];
            token.mExpires = zsLib::timeSinceEpoch(zsLib::Seconds(static_cast<zsLib::Seconds::rep>([identityAccessSecretExpires timeIntervalSince1970])));
            OpenPeerIdentityDelegatePtr identityDelegatePtr = OpenPeerIdentityDelegate::create(inIdentityDelegate);
            identityPtr->attachDelegateAndPreauthorizedLogin(identityDelegatePtr, token);
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

- (HOPIdentity*) getSelfIdentity
{
    HOPIdentity* ret = nil;
    
    if(identityPtr)
    {
        IdentityContact identityContact;
        identityPtr->getSelfIdentityContact(identityContact);
        
        NSString* identityURI = [NSString stringWithUTF8String:identityContact.mIdentityURI];
        ret = [[HOPModelManager sharedModelManager] getIdentityByIdentityURI:identityURI];
        if (!ret)
        {
            ret = [[HOPModelManager sharedModelManager] createIdentityForCoreIdentity:identityContact isSelf:YES];
        }
        else
        {
            ret.contact.account = [HOPAccount sharedAccount].openPeerAccount;
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

+ stateToString:(HOPAccountIdentityState) state
{
    return [NSString stringWithUTF8String: IIdentity::toString((IIdentity::IdentityStates) state)];
}
+ (NSString*) stringForIdentityState:(HOPAccountIdentityState) state
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

- (void) startIdentitiesDownload:(NSString*) lastDownloadedVersion
{
    if(identityPtr)
    {
        self.flushAllIdentities = NO;
        self.versionDownloadedStr = nil;
        self.arrayLastDownloadedIdentities = nil;
        self.identitiesObtained = NO;
        
        identityPtr->startRolodexDownload([lastDownloadedVersion UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid identity object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid identity object!"];
    }
}

- (void) refreshIdentities
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

- (BOOL) getDownloadedIdentities:(BOOL*) outFlushAllIdentities outVersionDownloaded:(NSString**) outVersionDownloaded outIdentities:(NSArray**) outIdentities
{
    BOOL ret = NO;
    if(identityPtr)
    {
        *outFlushAllIdentities = self.flushAllIdentities;
        if ([self.versionDownloadedStr length] > 0)
            *outVersionDownloaded = self.versionDownloadedStr;
        
        *outIdentities = self.arrayLastDownloadedIdentities;
        ret = self.identitiesObtained;
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
    
    self.deletionTimer = [NSTimer scheduledTimerWithTimeInterval:flushContactsDownloadTime target:self selector:@selector(deleteMarkedIdentities) userInfo:nil repeats:NO];
}

- (void) stopTimerForContactsDeletion
{
    if ([self.deletionTimer isValid])
        [self.deletionTimer invalidate];
}

- (void) deleteMarkedIdentities
{
    //[[HOPModelManager sharedModelManager] deleteAllMarkedRolodexContactsForHomeUserIdentityURI:[self getIdentityURI]];
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

- (id) initWithIdentityPtr:(IIdentityPtr) inIdentityPtr openPeerIdentityDelegate:(OpenPeerIdentityDelegatePtr) inOpenPeerIdentityDelegate
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

- (void) setLocalDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate
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
        return String("HOPAccountIdentity [") + string(identityPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPAccountIdentity: ") + [message UTF8String];
}

- (BOOL) isValid
{
    BOOL ret = NO;
    
    if (identityPtr)
        ret = YES;
    
    return ret;
}
@end
