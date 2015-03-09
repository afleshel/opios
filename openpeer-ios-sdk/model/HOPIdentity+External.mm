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

#import "HOPIdentity+External.h"
#import "HOPIdentity_Internal.h"
#import "OpenPeerStorageManager.h"
#import "HOPCoreContact.h"
#import "HOPPublicPeerFile.h"
#import "HOPModelManager_Internal.h"
#import "HOPUtility.h"
#import "HOPAssociatedIdentity.h"
#import "HOPContact_Internal.h"
#import "HOPAPNSData.h"
#import "HOPOpenPeerAccount.h"
#import "HOPIdentityProvider.h"
#import "HOPAvatar.h"

@implementation HOPIdentity (External)


- (void) updateWithName:(NSString*) inName identityURI:(NSString*) inIdentityURI identityProviderDomain:(NSString*)identityProviderDomain  homeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSString* baseIdentityURI = [HOPUtility getBaseIdentityURIFromURI:inIdentityURI];
    HOPAssociatedIdentity* associated = [[HOPModelManager sharedModelManager] getAssociatedIdentityByDomain:identityProviderDomain identityName:baseIdentityURI homeUserIdentityURI:homeUserIdentityURI];
    if (!associated)
    {
        [[HOPModelManager sharedModelManager] addAssociatedIdentityForBaseIdentityURI:baseIdentityURI domain:identityProviderDomain name:baseIdentityURI selfIdentityProfile:nil];
    }
    
    if (inName.length > 0)
        self.name = inName;
}



+ (HOPIdentity*) getSelf
{
    HOPIdentity* ret = [[HOPModelManager sharedModelManager] getIdentityForAccount];
    return ret;
}

+ (void) hintAboutLocation:(NSString*) locationID peerURI:(NSString*) peerURI
{
    if (peerURI.length > 0 && locationID.length > 0)
    {
        HOPCoreContact* contact = [[OpenPeerStorageManager sharedStorageManager] getCoreContactForPeerURI:peerURI];
        
        if (!contact)
        {
            contact = [[HOPCoreContact alloc] initWithPeerURI:peerURI];
        }
        
        if (contact)
            [contact hintAboutLocation:locationID];
    }
}

- (BOOL) isOpenPeer
{
    return self.contact != nil;
}

- (BOOL) isKnown
{
    return self.associatedIdentity != nil;
}

//TODO: Remove image storage from the core data
- (HOPAvatar*) getAvatarForWidth:(NSNumber*) width height:(NSNumber*) height
{
    HOPAvatar* ret = nil;
//    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"width <= %f AND height <= %f", width,height];
//    NSSet* filtered = [self.avatars filteredSetUsingPredicate:predicate];
//    if (filtered)
//        ret = [filtered anyObject];
    
    if (self.avatars.count > 0)
        ret = self.avatars.allObjects[0];
    return ret;
}

- (NSString*) getAvatarURLForWidth:(NSNumber*) width height:(NSNumber*) height
{
    NSString* ret = nil;
    
    if (self.avatars.count > 0)
        ret = ((HOPAvatar*)self.avatars.allObjects[0]).url;
    return ret;
}

- (NSString*) firstLetter
{
    //[self.name willAccessValueForKey:@"uppercaseFirstLetterOfName"];
    NSString *stringToReturn = [[self.name uppercaseString] substringToIndex:1];
    //[self didAccessValueForKey:@"uppercaseFirstLetterOfName"];
    return stringToReturn;
}
- (NSString*) getPeerURI
{
    NSString* ret = nil;
    
    if (self.contact)
        ret = self.contact.publicPeerFile.peerURI;
    
    return ret;
}

- (NSString*) getStableID
{
    NSString* ret = nil;
    
    if (self.contact)
        ret = self.contact.stableID;
    
    return ret;
}
- (NSUInteger) getNumberOfAssociatedIdentities
{
    NSUInteger ret = 1;
    
    if (self.contact)
        ret = self.contact.identities.count;
    
    return ret;
}

/*- (NSArray*) getAssociatedIdentities
{
    NSMutableArray* ret = [NSMutableArray new];
    
    for (HOPAssociatedIdentity* associatedIdentity in self.associatedIdentity.account.associatedIdentities)
    {
        NSString* name = associatedIdentity.identityProvider.name;
        if (name.length > 0)
            [ret addObject:name];
    }
    return ret;
}*/

- (NSString*) getPushNotificationDeviceToken
{
    NSString* ret = nil;
    
    if (self.contact)
        ret = self.contact.apnsData.deviceToken;
    
    return ret;
}

- (NSString*) getPushNotificationType
{
    NSString* ret = nil;
    
    if (self.contact)
        ret = self.contact.apnsData.type;
    
    return ret;
}
@end
