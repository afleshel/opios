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

#import <Foundation/Foundation.h>
#import "HOPTypes.h"
#import "HOPProtocols.h"

@class HOPIdentity;

@interface HOPAccountState : NSObject

@property (nonatomic, assign) HOPAccountStates state;
@property (nonatomic, assign) unsigned short errorCode;
@property (nonatomic, strong) NSString* errorReason;

@end

/**
 Singleton class to represent the logged in openpeer user.
 */
@interface HOPAccount : NSObject

+ (HOPAccount*) sharedAccount;
- (id) init __attribute__((unavailable("HOPAccount is singleton class.")));

/**
 Converts account state enum to string
 @param state HOPAccountStates Account state enum
 @returns String representation of account state
 */
+ (NSString*) stateToString:(HOPAccountStates) state __attribute__((deprecated("use method stringForAccountState instead")));
+ (NSString*) stringForAccountState:(HOPAccountStates) state;

/**
 Login method for verified identity.
 @param inAccountDelegate HOPAccountDelegate delegate
 @param inConversationThreadDelegate HOPConversationThreadDelegate delegate
 @param inCallDelegate HOPCallDelegate delegate
 @param namespaceGrantOuterFrameURLUponReload NSString
 @param grantID NSString
 @param lockboxServiceDomain NSString lockbox service domain
 @param forceCreateNewLockboxAccount BOOL flag that it telling core to create a new user if old user data is corrupted
 @returns YES if IAccount object is created sucessfully
 */
- (BOOL) loginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>) inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate namespaceGrantOuterFrameURLUponReload:(NSString*) namespaceGrantOuterFrameURLUponReload  grantID:(NSString*) grantID lockboxServiceDomain:(NSString*) lockboxServiceDomain forceCreateNewLockboxAccount:(BOOL) forceCreateNewLockboxAccount;


/**
 Relogin method for exisitng user.
 @param inAccountDelegate HOPAccountDelegate delegate
 @param inConversationThreadDelegate HOPConversationThreadDelegate delegate
 @param inCallDelegate HOPCallDelegate delegate
 @param lockboxOuterFrameURLUponReload NSString private peer file
 @param reloginInformation NSString login information retrieved from the local storage and packed in xml form
 @returns YES if IAccount object is created sucessfully
 */
- (BOOL) reloginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>) inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate lockboxOuterFrameURLUponReload:(NSString *)lockboxOuterFrameURLUponReload reloginInformation:(NSString *)reloginInformation;

/**
 Retrieves account state
 @returns Account state enum
 */
- (HOPAccountState*) getState;


/**
 Retrieves account atable id
 @returns NSString stable id
 */
- (NSString*) getStableID;


/**
 Retrieves relogin info for logged user. Relogin info contains": lockboxDomain, accountID, grandID, keyIdentityHalf, keyLockboxHalf.
 @returns NSString relogin info in packed in JSON format.
 */
- (NSString*) getReloginInformation;

/**
 Retrieves user location id.
 @returns location id
 */
- (NSString*) getLocationID;

/**
 Shutdowns account object. Called on logout.
 */
- (void) shutdown;

/**
 Retrieves user private peer file.
 @returns NSString private peer file
 */
- (NSString*) getPeerFilePrivate;

/**
 Retrieves user's private peer file secret.
 @returns private peer file secret
 */
- (NSData*) getPeerFilePrivateSecret;

/**
 Retrieves list of associated identites.
 @returns list of associated identites
 */
- (NSArray*) getAssociatedIdentities;

/**
 Removes associated identities.
 @params identities NSArray list of HOPIdentities objects
 */
- (void) removeIdentities:(NSArray*) identities;

/**
 Retrieves inner browser frame URL that needs to be loaded during account login process.
 @returns NSString inner browser frame URL
 */
- (NSString*) getInnerBrowserWindowFrameURL;

/**
 Notifies core that web wiev is now visible.
 */
- (void) notifyBrowserWindowVisible;

/**
 Notifies core that that web view is closed.
 */
- (void) notifyBrowserWindowClosed;

/**
 Retrieves JSON message from core that needs to be passed to inner browser frame.
 @returns NSString JSON message
 */
- (NSString*) getNextMessageForInnerBrowerWindowFrame;

/**
 Passes JSON message from inner browser frame to core.
 @param NSString JSON message
 */
- (void) handleMessageFromInnerBrowserWindowFrame:(NSString*) message;

/**
 Check if core account is created.
 */
- (BOOL) isCoreAccountCreated;

/**
 Destroy core account object.
 */
- (void) destroyCoreObject;
@end