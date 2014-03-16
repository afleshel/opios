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

@class HOPIdentityContact;

/**
 Wrapper for identity state data.
 */
@interface HOPIdentityState : NSObject

@property (nonatomic, assign) HOPIdentityStates state;
@property (nonatomic, assign) unsigned short lastErrorCode;
@property (nonatomic, strong) NSString* lastErrorReason;
@end


@interface HOPIdentity : NSObject

@property (nonatomic, strong) NSString* identityBaseURI;
@property (copy) NSString* identityId;
@property (nonatomic, strong) NSTimer* deletionTimer;

/**
 Converts identity state enum to string
 @param state HOPIdentityStates Identity state enum
 @return String representation of identity state
 */
+ stateToString:(HOPIdentityStates) state __attribute__((deprecated("use method stringForIdentityState instead")));
+ (NSString*) stringForIdentityState:(HOPIdentityStates) state;

/**
 Creates identity object and starts identity login. This method is called only on login procedure. During relogin procedure this method is not invoked.
 @param inIdentityDelegate HOPIdentityDelegate delegate
 @param identityProviderDomain NSString Used when identity URI is of legacy or oauth-type
 @param identityURIOridentityBaseURI NSString Base URI of identity provider (e.g. identity://facebook.com/),  or contact specific identity URI (e.g. identity://facebook.com/contact_facebook_id)
@param outerFrameURLUponReload NSString String that will be passed from JS after login is completed.
 @return HOPIdentity object if IIdentityPtr object is created sucessfully, otherwise nil
 */
+ (id) loginWithDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain  identityURIOridentityBaseURI:(NSString*) identityURIOridentityBaseURI outerFrameURLUponReload:(NSString*) outerFrameURLUponReload;
- (id) init __attribute__((unavailable("Use one of loginWithDelegate: static methods to create an identity object.")));
/**
 Creates identity object and starts identity login for preauthorized identites. This method is called only on login procedure. During relogin procedure this method is not invoked.
 @param inIdentityDelegate HOPIdentityDelegate delegate
 @param identityProviderDomain NSString Used when identity URI is of legacy or oauth-type
 @param identityPreauthorizedURI NSString Contact identity URI provided by identity provider (e.g. identity://name_provider_domain.com/contact_id),  or contact specific identity URI (e.g. identity://facebook.com/contact_facebook_id)
 @param identityAccessToken NSString Access token obtained from YOUR server.
 @param identityAccessSecret NSString Access secret obtained from YOUR server.
 @param identityAccessSecretExpires NSDate Access secret expire date.
 @return HOPIdentity object if IIdentityPtr object is created sucessfully, otherwise nil
 */
+ (id) loginWithDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate identityProviderDomain:(NSString*) identityProviderDomain identityPreauthorizedURI:(NSString*) identityURI identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires;

/**
 Retrieves unique object id
 @returns NSNumber Unique object id
 */
- (NSNumber*) getObjectId;

/**
 Retrieves identity state
 @returns HOPIdentityState Identity state
 */
- (HOPIdentityState*) getState;

/**
 Retrieves whether identiy is attached or not.
 @returns BOOL YES if attached, otherwise NO
 */
- (BOOL) isDelegateAttached;

/**
 Attaches identity delegate with specified redirection URL
 @param inIdentityDelegate HOPIdentityDelegate IIdentityDelegate delegate
 @param redirectAfterLoginCompleteURL NSString Redirection URL that will be received after login is completed
 */
- (void) attachDelegate:(id<HOPIdentityDelegate>) inIdentityDelegate redirectionURL:(NSString*) redirectionURL;

/**
 Attaches identity delegate for preauthorized login.
 @param inIdentityDelegate HOPIdentityDelegate IIdentityDelegate delegate
 @param identityAccessToken NSString Access token obtained from YOUR server.
 @param identityAccessSecret NSString Access secret obtained from YOUR server.
 @param identityAccessSecretExpires NSDate Access secret expire date.
 */
- (void) attachDelegateAndPreauthorizedLogin:(id<HOPIdentityDelegate>) inIdentityDelegate identityAccessToken:(NSString*) identityAccessToken identityAccessSecret:(NSString*) identityAccessSecret identityAccessSecretExpires:(NSDate*) identityAccessSecretExpires;

/**
 Retrieves identity URI
 @return NSString identity URI
 */
- (NSString*) getIdentityURI;

/**
 Retrieves base identity URI
 @returns NSString base identity URI
 */
- (NSString*) getBaseIdentityURI;

/**
 Retrieves identity provider domain
 @returns NSString identity provider domain
 */
- (NSString*) getIdentityProviderDomain;

/**
 Retrieves identity contact for logged in user
 @returns HOPIdentityContact identity contact
 */
- (HOPIdentityContact*) getSelfIdentityContact;


/**
 Retrieves identity inner browser frame URL
 @return NSString inner browser frame URL
 */
- (NSString*) getInnerBrowserWindowFrameURL;


/**
 Notifies core that web wiev is now visible.
 */
- (void) notifyBrowserWindowVisible;

/**
 Notifies core that redirection URL for completed login is received, and that web view can be closed.
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
 Starts indentity contacts downloading using rolodex service. 
 @param lastDownloadedVersion NSString If a previous version of the rolodex was downloaded/stored, pass in the version of the last information downloaded to prevent redownloading infomration again
 */
- (void) startRolodexDownload:(NSString*) lastDownloadedVersion;

/**
 Tells rolodex server to refresh its list of contacts. After contacts are refreshed it will be downloaded and delegate method will be invoked. 
 */
- (void) refreshRolodexContacts;

/**
 Retrieves list of contacts downloaded using rolodex service.
 @param outFlushAllRolodexContacts BOOL This value is returned by core and if its value is YES, be prepeared to remove all your rolodex contacts stored locally if they are not downloaded in some period of time
 @param outVersionDownloaded NSString This is output parameter that will hold information about rolodex download version
 @param outRolodexContacts NSArray This is outpit list of all downloaded contacts
 @return BOOL Returns YES if contacts are downloaded
 */
- (BOOL) getDownloadedRolodexContacts:(BOOL*) outFlushAllRolodexContacts outVersionDownloaded:(NSString**) outVersionDownloaded outRolodexContacts:(NSArray**) outRolodexContacts;

/**
 Cancels identity login.
 */
- (void) cancel;

/**
 Starts timer after which expire all marked contacts will be deleted.
 */
- (void) startTimerForContactsDeletion;

/**
 Stops deletion timer..
 */
- (void) stopTimerForContactsDeletion;

- (void) destroyCoreObject;
@end
