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

#import "HOPAccount_Internal.h"
#import "HOPIdentity_Internal.h"

#import "OpenPeerStorageManager.h"

#import <openpeer/core/IAccount.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IIdentity.h>
#import <openpeer/core/IHelper.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPAccountState

@end

@implementation HOPAccount

+ (id)sharedAccount
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

+ (NSString*) stateToString:(HOPAccountStates) state
{
    return [NSString stringWithUTF8String: IAccount::toString((IAccount::AccountStates) state)];
}
+ (NSString*) stringForAccountState:(HOPAccountStates) state
{
    return [NSString stringWithUTF8String: IAccount::toString((IAccount::AccountStates) state)];
}

- (id)initSingleton
{
    self = [super init];
    if (self)
    {
        self.dictionaryOfIdentities = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (BOOL) loginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>) inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate namespaceGrantOuterFrameURLUponReload:(NSString*) namespaceGrantOuterFrameURLUponReload  grantID:(NSString*) grantID lockboxServiceDomain:(NSString*) lockboxServiceDomain forceCreateNewLockboxAccount:(BOOL) forceCreateNewLockboxAccount
{
    BOOL passedWithoutErrors = NO;
    
    //Check if valid parameters are passed
    if (!inAccountDelegate || !inConversationThreadDelegate || !inCallDelegate || [namespaceGrantOuterFrameURLUponReload length] == 0 || [grantID length] == 0  || [lockboxServiceDomain length] == 0 )
    {
        ZS_LOG_ERROR(Debug, [self log:@"Passed invalid parameters."]);
        return passedWithoutErrors;
    }
    
    //If core account object already exists, shut it down
    if (accountPtr)
    {
        ZS_LOG_DEBUG([self log:@"Core account object already exists. Shuting down existing account object."]);
        accountPtr->shutdown();
    }
    
    //Set account, conversation thread and call delegates
    [self setLocalDelegates:inAccountDelegate conversationThread:inConversationThreadDelegate callDelegate:inCallDelegate];
    
    //Start login. This static method will create an account core object
    accountPtr = IAccount::login(openpeerAccountDelegatePtr, openpeerConversationDelegatePtr, openpeerCallDelegatePtr, [namespaceGrantOuterFrameURLUponReload UTF8String], [grantID UTF8String], [lockboxServiceDomain UTF8String], forceCreateNewLockboxAccount);
    
    //If core account object is created, return that login process is started successfully
    if (accountPtr)
    {
        ZS_LOG_DEBUG([self log:@"Account object created successfully."]);
        passedWithoutErrors = YES;
    }
    else
    {
        ZS_LOG_DEBUG([self log:@"Account object is NOT created successfully."]);
    }
    
    return passedWithoutErrors;
}


- (BOOL)reloginWithAccountDelegate:(id<HOPAccountDelegate>)inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>)inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>)inCallDelegate lockboxOuterFrameURLUponReload:(NSString *)lockboxOuterFrameURLUponReload reloginInformation:(NSString *)reloginInformation
{
    BOOL passedWithoutErrors = NO;
    
    //Check if valid arguments are passed
    if (!inAccountDelegate || !inConversationThreadDelegate || !inCallDelegate || [lockboxOuterFrameURLUponReload length] == 0 || [reloginInformation length] == 0)
    {
        ZS_LOG_ERROR(Debug, [self log:@"Passed invalid arguments."]);
        return passedWithoutErrors;
    }
    
    //Set account, conversation thread and call delegates
    [self setLocalDelegates:inAccountDelegate conversationThread:inConversationThreadDelegate callDelegate:inCallDelegate];
    
    //Start relogin. This static method will create an account core object
    accountPtr = IAccount::relogin(openpeerAccountDelegatePtr, openpeerConversationDelegatePtr, openpeerCallDelegatePtr, [lockboxOuterFrameURLUponReload UTF8String],IHelper::createElement([reloginInformation UTF8String]));
    
    //If core account object is created return that relogin process is started successfully
    if (accountPtr)
    {
        ZS_LOG_DEBUG([self log:@"Account object created successfully."]);
        passedWithoutErrors = YES;
    }
    else
    {
        ZS_LOG_DEBUG([self log:@"Account object is NOT created successfully."]);
    }
    
    return passedWithoutErrors;
}

- (HOPAccountState*) getState
{
    HOPAccountState* ret = nil;
    
    if(accountPtr)
    {
        ret = [[HOPAccountState alloc] init];
        WORD errorCode;
        String errorReason;
        ret.state  = (HOPAccountStates) accountPtr->getState(&errorCode, &errorReason);
        ret.errorCode = errorCode;
        ret.errorReason = [NSString stringWithUTF8String:errorReason];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    
    return ret;
}

- (NSString*) getStableID
{
    NSString* ret = nil;
    
    if(accountPtr)
    {
        String stableId = accountPtr->getStableID();
        
        if (stableId && stableId.length() > 0)
        {
            ret = [NSString stringWithUTF8String: stableId];
        }
        else
        {
            ZS_LOG_WARNING(Debug, [self log:@"Account object doesn't have a valid stable id!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}

- (NSString*) getReloginInformation
{
    NSString* ret = nil;
    
    if(accountPtr)
    {
        if (accountPtr->getReloginInformation())
        {
            String reloginInfo = IHelper::convertToString(accountPtr->getReloginInformation());
            if (reloginInfo.length() > 0)
                ret = [NSString stringWithUTF8String: reloginInfo];
        }
        else
        {
            ZS_LOG_WARNING(Debug, [self log:@"Account object relogin information are not available!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}

- (NSString*) getLocationID
{
    NSString* ret = nil;
    
    if(accountPtr)
    {
        ret = [NSString stringWithUTF8String: accountPtr->getLocationID()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}


- (void) shutdown
{
    if(accountPtr)
    {
        accountPtr->shutdown();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}


- (NSString*) getPeerFilePrivate
{
    NSString* xml = nil;
    if(accountPtr)
    {
        zsLib::XML::ElementPtr element = accountPtr->savePeerFilePrivate();
        if (element)
        {
            xml = [NSString stringWithUTF8String: IHelper::convertToString(element)];
        }
        else
        {
            ZS_LOG_WARNING(Debug, [self log:@"Account object private peer file is not available!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return xml;
}


- (NSData*) getPeerFilePrivateSecret
{
    NSData* ret = nil;
    if(accountPtr)
    {
        SecureByteBlockPtr secure = accountPtr->getPeerFilePrivateSecret();
        if (secure)
        {
            byte* secureInBytes = secure->BytePtr();
            int sizeInBytes = secure->SizeInBytes();
            ret = [NSData dataWithBytes:secureInBytes length:sizeInBytes];
        }
        else
        {
            ZS_LOG_WARNING(Debug, [self log:@"Account object private peer file secret is not available!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}


- (NSArray*) getAssociatedIdentities
{
    NSMutableArray* array = nil;
    
    if(accountPtr)
    {
        IdentityListPtr associatedIdentities = accountPtr->getAssociatedIdentities();
        
        if (associatedIdentities->size() > 0)
        {
            array = [[NSMutableArray alloc] init];
            for (IdentityList::iterator it = associatedIdentities->begin(); it != associatedIdentities->end(); ++it)
            {
                NSString* identityURI = [NSString stringWithUTF8String: it->get()->getIdentityURI()];
                HOPIdentity* identity = [[OpenPeerStorageManager sharedStorageManager] getIdentityForPUID:it->get()->getID()];
                
                if (!identity)
                {
                    identity = [[HOPIdentity alloc] initWithIdentityPtr:*it openPeerIdentityDelegate:boost::shared_ptr<OpenPeerIdentityDelegate>()];
                    [[OpenPeerStorageManager sharedStorageManager] setIdentity:identity forPUID:it->get()->getID()];
                }
                if (identity)
                    [array addObject:identity];
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return array;
}

- (void) removeIdentities:(NSArray*) identities
{
    if(accountPtr)
    {
        IdentityList identitiesToRemove;
        
        if ([identities count] > 0)
        {
            for (HOPIdentity* identity in identities)
            {
                if ([identity getIdentityPtr])
                {
                    identitiesToRemove.push_back([identity getIdentityPtr]);
                }
            }
            accountPtr->removeIdentities(identitiesToRemove);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}

- (NSString*) getInnerBrowserWindowFrameURL
{
    NSString* ret = nil;
    
    if(accountPtr)
    {
        ret = [NSString stringWithUTF8String:accountPtr->getInnerBrowserWindowFrameURL()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}

- (void) notifyBrowserWindowVisible
{
    if(accountPtr)
    {
        accountPtr->notifyBrowserWindowVisible();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}

- (void) notifyBrowserWindowClosed
{
    if(accountPtr)
    {
        accountPtr->notifyBrowserWindowClosed();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}

- (NSString*) getNextMessageForInnerBrowerWindowFrame
{
    NSString* ret = nil;
    
    if(accountPtr)
    {
        ret = [NSString stringWithCString:IHelper::convertToString( accountPtr->getNextMessageForInnerBrowerWindowFrame()) encoding:NSUTF8StringEncoding];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
    return ret;
}

- (void) handleMessageFromInnerBrowserWindowFrame:(NSString*) message
{
    if(accountPtr)
    {
        accountPtr->handleMessageFromInnerBrowserWindowFrame(IHelper::createElement([message UTF8String]));
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}

- (BOOL) isCoreAccountCreated
{
    return accountPtr ? YES : NO;
}

- (NSString *)description
{
    NSString* ret = nil;
    
    if (accountPtr)
      ret = [NSString stringWithUTF8String: IHelper::convertToString(IAccount::toDebug(accountPtr))];
    else
        ret = NSLocalizedString(@"Core account object is not created.", @"Core account object is not created.");
    
    return ret;
}


#pragma mark - Internal methods
- (void)setLocalDelegates:(id<HOPAccountDelegate>)inAccountDelegate conversationThread:(id<HOPConversationThreadDelegate>)inConversationThread callDelegate:(id<HOPCallDelegate>)inCallDelegate
{
    openpeerAccountDelegatePtr = OpenPeerAccountDelegate::create(inAccountDelegate);
    openpeerConversationDelegatePtr = OpenPeerConversationThreadDelegate::create(inConversationThread);
    openpeerCallDelegatePtr = OpenPeerCallDelegate::create(inCallDelegate);
}
- (IAccountPtr) getAccountPtr
{
    return accountPtr;
}

- (String) log:(NSString*) message
{
    if (accountPtr)
        return String("HOPAccount [") + string(accountPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPAccount: ") + [message UTF8String];
}
@end
