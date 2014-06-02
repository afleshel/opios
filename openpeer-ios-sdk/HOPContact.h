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

@class HOPAccount;

@interface HOPContact : NSObject

- (id) init __attribute__((unavailable("Don't use init for HOPContact object creation. Use class method contactWithPeerFile.")));

/**
 Contact initializer used when the contact's data (stableUniqueId and peerFile) are stored locally.
 @param publicPeerFile Public peer file of the contact that will be created (self or remote). This is passed if peer file is sored locally. Otherwise it is nil
 @return Ponter to the created HOPContact object
 */
- (id) initWithPeerFile:(NSString*) publicPeerFile;

/**
 Returns HOPContact object for logged in user.
 @return HOPContact object
 */
+ (HOPContact*) getForSelf;

/**
 Checks if HOPContact object is self contact.
 @return YES if contact is self, NO if contact is remote
 */
- (BOOL) isSelf;

/**
 Returns peer URI from the HOPContact object.
 @return A string representation of peer URI
 */
- (NSString*) getPeerURI;

/**
 Returns peer file public from the contact object.
 @return A string peer file public
 */
- (NSString*) getPeerFilePublic;


/**
 Returns HOPAccount object of logged user.
 @return Account object
 */
- (HOPAccount*) getAssociatedAccount;

/**
 Gives a hint to core about contact location
 @returns Contact location id.
 */
- (void) hintAboutLocation:(NSString*) contactsLocationID;

/**
 Destroys contact core object.
 */
- (void) destroyCoreObject;
@end
