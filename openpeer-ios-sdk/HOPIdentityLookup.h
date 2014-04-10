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
#import "HOPProtocols.h"

@interface HOPIdentityLookupResult : NSObject
@property (nonatomic, assign) BOOL wasSuccessful;
@property (nonatomic, assign) unsigned short errorCode;
@property (nonatomic, strong) NSString* errorReason;
@end

@interface HOPIdentityLookup : NSObject

/**
 Initializer for HOPIdentityLookup with passed HOPIdentityLookupDelegate delegate and list of identity URIs
 @param inDelegate HOPIdentityLookupDelegate delegate
 @param identityLookupInfos NSArray list of HOPIdentityLookupInfo objects
 @returns HOPIdentityLookup object
 */
- (id) initWithDelegate:(id<HOPIdentityLookupDelegate>) inDelegate identityLookupInfos:(NSArray*) identityLookupInfos identityServiceDomain:(NSString*) identityServiceDomain;

/**
 Retrieves whether identiy lookup is completed or not.
 @param error NSError this parameter will be initiated if some error occurs during lookup
 @returns BOOL YES if completed, otherwise NO
 */
- (BOOL) isComplete:(NSError**) error;


/**
 Retrieves identity lookup result.
 @returns HOPIdentityLookupResult Lookup result
 */
- (HOPIdentityLookupResult*) getLookupResult;

/**
 Cancels identity lookup.
 */
- (void) cancel;

/**
 Retrieves list of updated identity profiles received from lookup server
 @return NSArray List of updated identity profiles for contacts that are registered in OpenPeer system
 */
- (NSArray*) getUpdatedIdentities;

/**
 Retrieves list of unchanged identity profiles received from lookup server
 @return NSArray List of unchanged identity profiles for contacts that are registered in OpenPeer system
 */
- (NSArray*) getUnchangedIdentities;

/**
 Retrieves list of invalid identity profiles received from lookup server
 @return NSArray List of invalid identity profiles for contacts that were registered in OpenPeer system
 */
- (NSArray*) getInvalidIdentities;

/**
 Destroy core object.
 */
- (void) destroyCoreObject;
@end