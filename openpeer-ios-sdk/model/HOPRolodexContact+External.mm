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

#import "HOPRolodexContact+External.h"
#import "HOPRolodexContact_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPContact.h"
#import "HOPIdentityContact.h"
#import "HOPPublicPeerFile.h"
#import "HOPModelManager.h"
#import "HOPContact.h"
#import "HOPUtility.h"
#import "HOPAssociatedIdentity.h"
#import "HOPOpenPeerContact.h"

@implementation HOPRolodexContact (External)


- (void) updateWithName:(NSString*) inName identityURI:(NSString*) inIdentityURI identityProviderDomain:(NSString*)identityProviderDomain  homeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSString* baseIdentityURI = [HOPUtility getBaseIdentityURIFromURI:inIdentityURI];
    HOPAssociatedIdentity* associated = [[HOPModelManager sharedModelManager] getAssociatedIdentityByDomain:identityProviderDomain identityName:baseIdentityURI homeUserIdentityURI:homeUserIdentityURI];
    if (!associated)
    {
//        associated = [NSEntityDescription insertNewObjectForEntityForName:@"HOPAssociatedIdentity" inManagedObjectContext:[[HOPModelManager sharedModelManager]managedObjectContext]];
//        
//        associated.baseIdentityURI = baseIdentityURI;
//        associated.name = baseIdentityURI;
//        associated.domain = identityProviderDomain;
        associated = [[HOPModelManager sharedModelManager] addAssociatedIdentityForBaseIdentityURI:baseIdentityURI domain:identityProviderDomain name:baseIdentityURI account:nil selfRolodexProfileProfile:nil];
    }
    
    self.name = inName;
}

- (BOOL) isSelf
{
    return [[self getCoreContact] isSelf];
}

- (HOPContact*) getCoreContact
{
    HOPContact* ret = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:self.identityContact.openPeerContact.publicPeerFile.peerURI];
    if (!ret)
    {
        ret = [[HOPContact alloc] initWithPeerFile:self.identityContact.openPeerContact.publicPeerFile.peerFile];
    }
    return ret;
}

- (HOPAvatar*) getAvatarForWidth:(NSNumber*) width height:(NSNumber*) height
{
    HOPAvatar* ret = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"width <= %f AND height <= %f", width,height];
    NSSet* filtered = [self.avatars filteredSetUsingPredicate:predicate];
    if (filtered)
        ret = [filtered anyObject];
    
    return ret;
}

- (NSString*) firstLetter
{
    //[self.name willAccessValueForKey:@"uppercaseFirstLetterOfName"];
    NSString *stringToReturn = [[self.name uppercaseString] substringToIndex:1];
    //[self didAccessValueForKey:@"uppercaseFirstLetterOfName"];
    return stringToReturn;
}
@end
