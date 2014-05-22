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
Singleton class that represents the logged in OpenPeer user.
 */
@interface HOPAccount : NSObject

/**
 Returns singleton object of HOPAccount class.
 */
+ (HOPAccount*) sharedAccount;

/**
 *  This init method is not available, because HOPAccount is a singleton class.
 *
 */
- (id) init __attribute__((unavailable("HOPAccount is singleton class.")));

/**
 *  Converts account state enum to string.
 *
 *  @param state Account state
 *
 *  @return A string representation of account state.
 */
+ (NSString*) stateToString:(HOPAccountStates) state __attribute__((deprecated("use method stringForAccountState instead")));

/**
 *  Converts account state enum to string. (Deprecated)
 *
 *  @param state Account state
 *
 *  @return A string representation of account state.
 */
+ (NSString*) stringForAccountState:(HOPAccountStates) state;

/**
 *  Starts account login procedure.
 *
 *  @param inAccountDelegate                     Delegate object that implements the HOPAccountDelegate protocol
 *  @param inConversationThreadDelegate          Delegate object that implements the HOPConversationThreadDelegate protocol
 *  @param inCallDelegate                        Delegate object that implements the HOPCallDelegate protocol
 *  @param namespaceGrantOuterFrameURLUponReload An outer frame URL
 *  @param lockboxServiceDomain                  Lockbox service domain
 *  @param forceCreateNewLockboxAccount          A flag that tells core to create a new user if old user data is corrupted
 *
 *  @return YES if IAccount object is created sucessfull, otherwise, NO
 */
- (BOOL) loginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>) inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate namespaceGrantOuterFrameURLUponReload:(NSString*) namespaceGrantOuterFrameURLUponReload lockboxServiceDomain:(NSString*) lockboxServiceDomain forceCreateNewLockboxAccount:(BOOL) forceCreateNewLockboxAccount;

/**
 *  Starts relogin procedure.
 *
 *  @param inAccountDelegate              Delegate object that implements the HOPAccountDelegate protocol
 *  @param inConversationThreadDelegate   Delegate object that implements the HOPConversationThreadDelegate protocol
 *  @param inCallDelegate                 Delegate object that implements the HOPCallDelegate protocol
 *  @param lockboxOuterFrameURLUponReload An outer frame URL
 *  @param reloginInformation             A relogin information stored on login.
 *
 *  @return YES, if relogin procedure started succesfully, otherwise NO
 */
- (BOOL) reloginWithAccountDelegate:(id<HOPAccountDelegate>) inAccountDelegate conversationThreadDelegate:(id<HOPConversationThreadDelegate>) inConversationThreadDelegate callDelegate:(id<HOPCallDelegate>) inCallDelegate lockboxOuterFrameURLUponReload:(NSString *)lockboxOuterFrameURLUponReload reloginInformation:(NSString *)reloginInformation;

/**
 *  Returns the account state.
 *
 *  @return Account state enum
 */
- (HOPAccountState*) getState;


/**
 *  Returns the account stable ID.
 *
 *  @return Account state ID
 */
- (NSString*) getStableID;


/**
 *  Returns a relogin info for the logged in user. Relogin info contains": lockboxDomain, accountID, grandID, keyIdentityHalf, keyLockboxHalf.
 *
 *  @returns Relogin info packed in JSON format.
 */
- (NSString*) getReloginInformation;


/**
 *  Returns the home user location ID.
 *
 *  @return Location ID.
 */
- (NSString*) getLocationID;

/**
 *  Shutdowns account object. Called on logout.
 */
- (void) shutdown;

/**
 *  Returns user's private peer file.
 *
 *  @return Private peer file
 */
- (NSString*) getPeerFilePrivate;

/**
 *  Returns user's private peer file secret.
 *
 *  @return Private peer file secret
 */
- (NSData*) getPeerFilePrivateSecret;

/**
 *  Returns list of associated identites.
 *
 *  @return Array of associated identites
 */
- (NSArray*) getAssociatedIdentities;

/**
 *  Removes associated identities.
 *
 *  @param identities Array of HOPIdentities objects (identities) to remove from the list of associated identities
 */
- (void) removeIdentities:(NSArray*) identities;


/**
 *  Returns inner browser frame URL that needs to be loaded during account login process.
 *
 *  @return Inner browser frame URL
 */
- (NSString*) getInnerBrowserWindowFrameURL;

/**
 *  Notifies SDK that web wiev is now visible.
 */
- (void) notifyBrowserWindowVisible;

/**
 *  Notifies SDK that web view is closed
 */
- (void) notifyBrowserWindowClosed;

/**
 *  Returns JSON message that needs to be passed to inner browser frame.
 *
 *  @return JSON message
 */
- (NSString*) getNextMessageForInnerBrowerWindowFrame;

/**
 *  Passes JSON message from inner browser frame to the SDK.
 *
 *  @param message JSON message
 */
- (void) handleMessageFromInnerBrowserWindowFrame:(NSString*) message;

/**
 *  Checks if account core object is properly created.
 *
 *  @return YES, if it is created, otherwise NO
 */
- (BOOL) isCoreAccountCreated;

/**
 *  Destroys account core object.
 */
- (void) destroyCoreObject;

/**
 *  Returns a string that represents the contents of the receiving class.
 *
 *  @return A string that represents the contents of the receiving class.
 */
- (NSString *)description;
@end