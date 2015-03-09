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


#import <Foundation/Foundation.h>
#import "HOPTypes.h"
#import "HOPProtocols.h"

@class HOPIdentity;

/**
 Wrapper for identity state data.
 */
@interface HOPIdnState : NSObject

@property (nonatomic, assign) HOPAccountIdentityState state;
@property (nonatomic, assign) unsigned short lastErrorCode;
@property (nonatomic, strong) NSString* lastErrorReason;
@end


@interface HOPAccountIdentity : NSObject

@property (nonatomic, strong) NSString* identityBaseURI;
@property (copy) NSString* identityId;
@property (nonatomic, strong) NSTimer* deletionTimer;

@property (nonatomic, assign) BOOL isAssociating;
@property (nonatomic, assign) BOOL isLoggingIn;

/**
*  Converts identity state enum to string. (Deprecated)
*
*  @param state Identity state
*
*  @return A string representation of identity state.
*/
+ stateToString:(HOPAccountIdentityState) state __attribute__((deprecated("use method stringForIdentityState instead")));

/**
 *  Converts identity state enum to string.
 *
 *  @param state Identity state
 *
 *  @return A string representation of identity state.
 */
+ (NSString*) stringForIdentityState:(HOPAccountIdentityState) state;


/**
 *  Creates identity object and starts identity login. This method is called only on login procedure. During relogin procedure this method is not called.
 *
 *  @param inIdentityDelegate           Delegate object that implements the HOPIdentityDelegate protocol
 *  @param identityProviderDomain       Identity provider domain
 *  @param identityURIOridentityBaseURI Base URI of identity provider (e.g. identity://facebook.com/),  or contact specific identity URI (e.g. identity://facebook.com/contact_facebook_id)
 *  @param outerFrameURLUponReload      Outer frame URL on reload
 *
 *  @return HOPAccountIdentity object if login is started successfully
 */
+ (id) loginWithDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain  identityURIOridentityBaseURI:(NSString*) identityURIOridentityBaseURI outerFrameURLUponReload:(NSString*) outerFrameURLUponReload;

/**
 *  Creates identity object and starts identity login for preauthorized identites. This method is called only on login procedure. During relogin procedure this method is not invoked.
 *
 *  @param inIdentityDelegate          Delegate object that implements the HOPIdentityDelegate protocol
 *  @param identityProviderDomain      Identity provider domain
 *  @param identityURI                 Contact identity URI provided by identity provider (e.g. identity://name_provider_domain.com/contact_id),  or contact specific identity URI (e.g. identity://facebook.com/contact_facebook_id)
 *  @param identityAccessToken         Access token obtained from YOUR server.
 *  @param identityAccessSecret        Access secret obtained from YOUR server.
 *  @param identityAccessSecretExpires Access secret expiry date.
 *
 *  @return HOPAccountIdentity object if login is started successfully
 */
+ (id) loginWithDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain identityPreauthorizedURI:(NSString*) identityURI identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires;

/**
 *  This init method is not available. You need to use class method loginWithDelegate:identityProviderDomain:identityURIOridentityBaseURI:outerFrameURLUponReload:.
 *
 */
- (id) init __attribute__((unavailable("Use one of loginWithDelegate: static methods to create an identity object.")));

/**
 *  Returns unique object id
 *
 *  @return Unique object id
 */
- (NSNumber*) getObjectId;

/**
 *  Returns the identity state.
 *
 *  @return Identity state enum
 */
- (HOPIdnState*) getState;

/**
 Returns whether identiy is attached or not.
 @return YES if attached, otherwise NO
 */
- (BOOL) isDelegateAttached;


/**
 *  Attaches identity delegate with specified redirection URL.
 *
 *  @param inIdentityDelegate Delegate object that implements the HOPIdentityDelegate protocol
 *  @param redirectionURL     Redirection URL that will be received after login is completed
 */
- (void) attachDelegate:(id<HOPAccountIdentityDelegate>) inIdentityDelegate redirectionURL:(NSString*) redirectionURL;

/**
 *  Attaches identity delegate for preauthorized login.
 *
 *  @param inIdentityDelegate          Delegate object that implements the HOPIdentityDelegate protocol
 *  @param identityAccessToken         Access token obtained from YOUR server
 *  @param identityAccessSecret        Access secret obtained from YOUR server
 *  @param identityAccessSecretExpires Access secret expiry date
 */
- (void) attachDelegateAndPreauthorizedLogin:(id<HOPAccountIdentityDelegate>) inIdentityDelegate identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires;

/**
 Returns identity URI.
 @return Identity URI
 */
- (NSString*) getIdentityURI;

/**
 Returns base identity URI.
 @return Base identity URI
 */
- (NSString*) getBaseIdentityURI;

/**
 Returns identity provider domain.
 @return Identity provider domain
 */
- (NSString*) getIdentityProviderDomain;

/**
 Returns identity contact for logged in user
 @return HOPIdentity object
 */
- (HOPIdentity*) getSelfIdentity;


/**
 Returns identity inner browser frame URL.
 @return Inner browser frame URL
 */
- (NSString*) getInnerBrowserWindowFrameURL;


/**
 Notifies SDK that web wiev is now visible.
 */
- (void) notifyBrowserWindowVisible;

/**
 Notifies SDK that redirection URL for completed login is received, and that web view can be closed.
 */
- (void) notifyBrowserWindowClosed;

/**
 Returns JSON message from SDK that needs to be passed to inner browser frame.
 @return JSON message
 */
- (NSString*) getNextMessageForInnerBrowerWindowFrame;

/**
 Passes JSON message from inner browser frame to the SDK.
 @param JSON message
 */
- (void) handleMessageFromInnerBrowserWindowFrame:(NSString*) message;


/**
 *  Starts contacts download using rolodex service.
 *
 *  @param lastDownloadedVersion If a previous version of the rolodex was downloaded/stored, pass in the version of the last information downloaded to prevent redownloading infomration again
 */
- (void) startIdentitiesDownload:(NSString*) lastDownloadedVersion;

/**
 Tells rolodex server to refresh its list of contacts. After contacts are refreshed it will be downloaded and delegate method will be invoked. 
 */
- (void) refreshIdentities;

/**
 Returns list of contacts downloaded using rolodex service.
 @param outFlushAllIdentities  This value is returned by core and if its value is YES, be prepeared to remove all your rolodex contacts stored locally if they are not downloaded in some period of time
 @param outVersionDownloaded  This is output parameter that will hold information about rolodex download version
 @param outIdentities  This is outpit list of all downloaded contacts
 @return BOOL Returns YES if contacts are downloaded, otherwise NO
 */
- (BOOL) getDownloadedIdentities:(BOOL*) outFlushAllIdentities outVersionDownloaded:(NSString**) outVersionDownloaded outIdentities:(NSArray**) outIdentities;

/**
 Cancels identity login.
 */
- (void) cancel;

/**
 Starts timer after which expire all marked contacts will be deleted.
 */
- (void) startTimerForContactsDeletion;

/**
 Stops deletion timer.
 */
- (void) stopTimerForContactsDeletion;

/**
 Destroys identity core object.
 */
- (void) destroyCoreObject;

- (BOOL) isValid;


@end
