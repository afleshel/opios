/*
 
 Copyright (c) 2015, Hookflash Inc.
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
#import "HOPAccountIdentity_Internal.h"

#import "OpenPeerStorageManager.h"
#import "OpenPeerUUIDManager.h"
#import "HOPModelManager_Internal.h"
#import "HOPAssociatedIdentity.h"
#import "HOPIdentity.h"
#import "HOPContact_Internal.h"
#import "HOPPublicPeerFile.h"

#import <openpeer/core/IAccount.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IIdentity.h>
#import <openpeer/core/IHelper.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPAccState

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

+ (NSString*) stateToString:(HOPAccountState) state
{
    return [NSString stringWithUTF8String: IAccount::toString((IAccount::AccountStates) state)];
}
+ (NSString*) stringForAccountState:(HOPAccountState) state
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


- (BOOL) loginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationDelegate:(id<HOPConversationDelegate>) inConversationDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate namespaceGrantOuterFrameURLUponReload:(NSString*) namespaceGrantOuterFrameURLUponReload lockboxServiceDomain:(NSString*) lockboxServiceDomain forceCreateNewLockboxAccount:(BOOL) forceCreateNewLockboxAccount
{
    ZS_LOG_DEBUG([self log:@"Starting account login"]);
    BOOL passedWithoutErrors = NO;
    NSString* grantID = [[OpenPeerUUIDManager sharedUUIDManager] getUUID];
    
    //Check if valid parameters are passed
    if (!inAccountDelegate || !inConversationDelegate || !inCallDelegate || [namespaceGrantOuterFrameURLUponReload length] == 0 || [grantID length] == 0  || [lockboxServiceDomain length] == 0 )
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
    [self setLocalDelegates:inAccountDelegate conversationDelegate:inConversationDelegate callDelegate:inCallDelegate];
    
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


- (BOOL)reloginWithAccountDelegate:(id<HOPAccountDelegate>)inAccountDelegate conversationDelegate:(id<HOPConversationDelegate>)inConversationDelegate callDelegate:(id<HOPCallDelegate>)inCallDelegate lockboxOuterFrameURLUponReload:(NSString *)lockboxOuterFrameURLUponReload
{
    BOOL passedWithoutErrors = NO;
    
    self.openPeerAccount = [[HOPModelManager sharedModelManager] getLoggedInAccount];
    
    if (self.openPeerAccount && self.openPeerAccount.reloginInfo.length > 0)
    {
        //Check if valid arguments are passed
        if (!inAccountDelegate || !inConversationDelegate || !inCallDelegate || [lockboxOuterFrameURLUponReload length] == 0)// || [reloginInformation length] == 0)
        {
            ZS_LOG_ERROR(Debug, [self log:@"Passed invalid arguments."]);
            return passedWithoutErrors;
        }
        
        //Set account, conversation thread and call delegates
        [self setLocalDelegates:inAccountDelegate conversationDelegate:inConversationDelegate callDelegate:inCallDelegate];
        
        //Start relogin. This static method will create an account core object
        accountPtr = IAccount::relogin(openpeerAccountDelegatePtr, openpeerConversationDelegatePtr, openpeerCallDelegatePtr, [lockboxOuterFrameURLUponReload UTF8String],IHelper::createElement([self.openPeerAccount.reloginInfo UTF8String]));
        
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
    }
    
    return passedWithoutErrors;
}

- (HOPAccState*) getState
{
    HOPAccState* ret = nil;
    
    if(accountPtr)
    {
        ret = [[HOPAccState alloc] init];
        WORD errorCode;
        String errorReason;
        ret.state  = (HOPAccountState) accountPtr->getState(&errorCode, &errorReason);
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
        
        [[HOPModelManager sharedModelManager] saveContext];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid account object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid account object!"];
    }
}

- (void) destroyCoreObject
{
    if(accountPtr)
        accountPtr.reset();
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
                HOPAccountIdentity* accountIdentity = [[OpenPeerStorageManager sharedStorageManager] getIdentityForPUID:it->get()->getID()];
                
                if (!accountIdentity)
                {
                    accountIdentity = [[HOPAccountIdentity alloc] initWithIdentityPtr:*it openPeerIdentityDelegate:boost::shared_ptr<OpenPeerIdentityDelegate>()];
                    [[OpenPeerStorageManager sharedStorageManager] setIdentity:accountIdentity forPUID:it->get()->getID()];
                }
                if (accountIdentity)
                    [array addObject:accountIdentity];
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
            for (HOPAccountIdentity* accountIdentity in identities)
            {
                if ([accountIdentity getIdentityPtr])
                {
                    identitiesToRemove.push_back([accountIdentity getIdentityPtr]);
                    [[HOPModelManager sharedModelManager] deleteObject:[accountIdentity getSelfIdentity].associatedIdentityForHomeUser];
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

- (BOOL) isAccountReady
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
- (void)setLocalDelegates:(id<HOPAccountDelegate>)inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>)inConversationThread callDelegate:(id<HOPCallDelegate>)inCallDelegate
{
    openpeerAccountDelegatePtr = OpenPeerAccountDelegate::create(inAccountDelegate);
    openpeerConversationDelegatePtr = OpenPeerConversationThreadDelegate::create(inConversationThread);
    openpeerCallDelegatePtr = OpenPeerCallDelegate::create(inCallDelegate);
}

- (void)setLocalDelegates:(id<HOPAccountDelegate>)inAccountDelegate conversationDelegate:(id<HOPConversationDelegate>)inConversationDelegate callDelegate:(id<HOPCallDelegate>)inCallDelegate
{
    openpeerAccountDelegatePtr = OpenPeerAccountDelegate::create(inAccountDelegate);
    openpeerConversationDelegatePtr = OpenPeerConversationThreadDelegate::create(inConversationDelegate);
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

- (HOPOpenPeerAccount*) getOpenPeerUser
{
    if (!_openPeerAccount)
    {
        _openPeerAccount = [[HOPModelManager sharedModelManager] getLoggedInAccount];
        
        if (!_openPeerAccount)
            _openPeerAccount = [[HOPModelManager sharedModelManager] getAccountForStableID:[[HOPAccount sharedAccount] getStableID]];
        
        if (!_openPeerAccount && accountPtr && [self getStableID].length > 0)
        {
            _openPeerAccount = (HOPOpenPeerAccount*)[[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPOpenPeerAccount"];
            _openPeerAccount.stableId = [[HOPAccount sharedAccount] getStableID];
            _openPeerAccount.reloginInfo = [[HOPAccount sharedAccount] getReloginInformation];
            _openPeerAccount.loggedIn = [NSNumber numberWithBool: YES];
        }
    }
    return _openPeerAccount;
}
#pragma mark - SDK methods
- (void) updateLoggedInAccount
{
    HOPOpenPeerAccount* previousLoggedInHomeUser = [[HOPModelManager sharedModelManager] getLoggedInAccount];
    self.openPeerAccount = [[HOPModelManager sharedModelManager] getAccountForStableID:[[HOPAccount sharedAccount] getStableID]];
    
    if (self.openPeerAccount)
    {
        //If is previous logged in user is different update loggedIn flag
        if (![self.openPeerAccount.loggedIn boolValue])
        {
            if (previousLoggedInHomeUser)
                previousLoggedInHomeUser.loggedIn = [NSNumber numberWithBool: NO];
            
            self.openPeerAccount.loggedIn = [NSNumber numberWithBool: YES];
            [[HOPModelManager sharedModelManager] saveContext];
        }
        
        //Update relogin info
        if (![self.openPeerAccount.reloginInfo isEqualToString:[self getReloginInformation]])
        {
            self.openPeerAccount.reloginInfo = [self getReloginInformation];
            
            [[HOPModelManager sharedModelManager] saveContext];
        }
    }
}
- (void) resetLoggedInAccount
{
    HOPOpenPeerAccount* homeUser = [[HOPModelManager sharedModelManager] getLoggedInAccount];
    homeUser.loggedIn = [NSNumber numberWithBool:NO];
    self.openPeerAccount = nil;
    [[HOPModelManager sharedModelManager] saveContext];
}

- (void) addAccountIdentity:(HOPAccountIdentity*) accountIdentity
{
    if (self.openPeerAccount)
    {
        HOPIdentity* userIdentity = [accountIdentity getSelfIdentity];
        
        HOPAssociatedIdentity*  associatedIdentity = [[HOPModelManager sharedModelManager] getAssociatedIdentityForBaseIdentityURI:[accountIdentity getBaseIdentityURI] homeUserStableId:[self getStableID]];
        
        if (!associatedIdentity)
        {
            associatedIdentity = [[HOPModelManager sharedModelManager] addAssociatedIdentityForBaseIdentityURI:[accountIdentity getBaseIdentityURI] domain:[accountIdentity getIdentityProviderDomain] name:[accountIdentity getBaseIdentityURI]  selfIdentityProfile:userIdentity];
        }
        else
        {
            associatedIdentity.selfIdentity = userIdentity;
            associatedIdentity.account = self.openPeerAccount;
            userIdentity.associatedIdentityForHomeUser = associatedIdentity;
        }
        [[HOPModelManager sharedModelManager] saveContext];
    }
}

- (NSString*) getPeerURI
{
    return self.openPeerAccount.contact.publicPeerFile.peerURI;
}
- (NSString*) getName
{
    return [self.openPeerAccount.contact getPreferredIdentity].name;
}

+ (BOOL)isReloginPossible
{
    HOPOpenPeerAccount* account = [[HOPModelManager sharedModelManager] getLoggedInAccount];
    return account != nil && account.reloginInfo.length > 0;
}

- (NSArray*) getSelfIdentities
{
    if (self.openPeerAccount && self.openPeerAccount.contact)
        return self.openPeerAccount.contact.identities.allObjects;
    else
        return nil;
}

- (NSArray*) getIdentities
{
    return [[HOPModelManager sharedModelManager] getAllContactsForLoggedInAccount];
}

- (HOPContact*) getSelfContact
{
    return self.openPeerAccount.contact;
}
/*
- (void) refreshAllIdentities
{
    for (HOPAccountIdentity* identity in [self getAssociatedIdentities])
    {
        [identity refreshIdentities];
    }
}*/
@end
