/*
 
 Copyright (c) 2014, Hookflash Inc.
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

#import "HOPContact.h"

@class HOPCoreContact;
@class HOPIdentity;
@class HOPContact;
@class HOPAvatar;

@interface HOPContact(External)


- (BOOL) isSelf;

/**
 *  Returns preferred identity contact based on priority and weight
 *
 *  @return prefered identity object
 */
- (HOPIdentity*) getPreferredIdentity;

/**
 *  Returns the name of the preferred identity
 *
 *  @return contact name
 */
- (NSString*) getName;

/**
 *  Returns the public peer file
 *
 *  @return public peer file
 */
- (NSString*) getPeerFilePublic;

/**
 *  Returns contact peer URI
 *
 *  @return peer URI
 */
- (NSString*) getPeerURI;

/**
 *  Returns the avatar of the preferred identity
 *
 *  @return HOPAvatar object
 */
- (HOPAvatar*) getAvatar;

/**
 *  Return YES if contact is a friend from some of associated identities, or it is unknown contact
 *
 *  @return YES, if it is known
 */
- (BOOL) isKnown;

- (NSString*) getPushNotificationDeviceToken;
- (NSString*) getPushNotificationType;

/**
 *  Returns list of contact associated identity URIs
 *
 *  @return list of identity URIs
 */
- (NSArray*) getIdentityURIs;

/**
 *  Returns contact object for logged in account
 *
 *  @return self contact object
 */
+ (HOPContact*) getSelf;


/**
 *  Compare two contact objects
 *
 *  @param cotnact contact object to compare
 *
 *  @return YES if same
 */
- (BOOL) isSame:(HOPContact*) cotnact;

/**
 *  Give a hint abput location for contact
 *
 *  @param locationID
 */
- (void) hintAboutLocation:(NSString*) locationID;
@end
