/*
 
 Copyright (c) 2013, SMB Phone Inc.
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

#include "HOPIdentityLookupInfo_Internal.h"
#include "OpenPeerUtility.h"
#include "OpenPeerStorageManager.h"
#include "HOPCoreContact_Internal.h"
#import "HOPIdentityContact.h"
#import "HOPRolodexContact.h"
#import <openpeer/core/IContact.h>

@implementation HOPIdentityLookupInfo

- (id)initWithIdentityURI:(NSString*) uri dateOfLastUpdate:(NSDate*) dateOfLastUpdate
{
    self = [super init];
    if (self)
    {
        self.identityURI = uri;
        self.lastUpdated = dateOfLastUpdate;
    }
    return self;
}

- (id)initWithIdentityContact:(HOPIdentityContact *)inIdentityContact
{
    self = [self initWithIdentityURI:inIdentityContact.rolodexContact.identityURI dateOfLastUpdate:inIdentityContact.lastUpdated];
    return self;
}

- (id)initWithRolodexContact:(HOPRolodexContact *)inRolodexContact
{
    self = [self initWithIdentityURI:inRolodexContact.identityURI dateOfLastUpdate:nil];
    return self;
}

- (id) initWithCoreRolodexContact:(RolodexContact) inRolodexContact
{
    self = [self initWithIdentityURI:[NSString stringWithCString:inRolodexContact.mIdentityURI encoding:NSUTF8StringEncoding] dateOfLastUpdate:nil];
    return self;
}

- (id) initWithCoreIdentityContact:(IdentityContact) inIdentityContact
{
    self = [self initWithIdentityURI:[NSString stringWithCString:inIdentityContact.mIdentityURI encoding:NSUTF8StringEncoding] dateOfLastUpdate:[OpenPeerUtility convertPosixTimeToDate:inIdentityContact.mLastUpdated]];
    return self;
}

- (id) initWithCoreIdentityLookupInfo:(IIdentityLookup::IdentityLookupInfo) inIdentityLookupInfo
{
    self = [self initWithIdentityURI:[NSString stringWithCString:inIdentityLookupInfo.mIdentityURI encoding:NSUTF8StringEncoding] dateOfLastUpdate:[OpenPeerUtility convertPosixTimeToDate:inIdentityLookupInfo.mLastUpdated]];
    return self;
}


@end