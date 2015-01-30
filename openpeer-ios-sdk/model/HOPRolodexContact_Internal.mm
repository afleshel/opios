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

#import "HOPRolodexContact_Internal.h"
#import "HOPAvatar_Internal.h"
#import "HOPAssociatedIdentity.h"
#import "HOPPublicPeerFile.h"
#import "HOPIdentityContact.h"
#import "HOPModelManager_Internal.h"
#import "HOPContact.h"
#import "OpenPeerStorageManager.h"
#import "HOPUtility.h"
#import "HOPOpenPeerContact.h"

@implementation HOPRolodexContact

@dynamic identityURI;
@dynamic name;
@dynamic profileURL;
@dynamic vProfileURL;
@dynamic avatars;
@dynamic identityContact;
@dynamic associatedIdentity;
@dynamic readyForDeletion;
@dynamic associatedIdentityForHomeUser;
@dynamic openPeerContact;

- (void) updateWithCoreRolodexContact:(RolodexContact) inRolodexContact identityProviderDomain:(NSString*)identityProviderDomain homeUserIdentityURI:(NSString*)homeUserIdentityURI
{
    NSString* baseIdentityURI = [HOPUtility getBaseIdentityURIFromURI:homeUserIdentityURI];
    HOPAssociatedIdentity* associated = [[HOPModelManager sharedModelManager] getAssociatedIdentityByDomain:identityProviderDomain identityName:baseIdentityURI homeUserIdentityURI:homeUserIdentityURI];
    if (!associated)
    {
        associated = [[HOPModelManager sharedModelManager] addAssociatedIdentityForBaseIdentityURI:baseIdentityURI domain:identityProviderDomain name:baseIdentityURI /*account:nil*/ selfRolodexProfileProfile:self];
    }
    
    self.associatedIdentity = associated;
    self.identityURI = [NSString stringWithCString:inRolodexContact.mIdentityURI encoding:NSUTF8StringEncoding];
    NSString* tempName = [NSString stringWithCString:inRolodexContact.mName encoding:NSUTF8StringEncoding];
    if (tempName.length > 0)
        self.name = [NSString stringWithCString:inRolodexContact.mName encoding:NSUTF8StringEncoding];
    self.profileURL = [NSString stringWithCString:inRolodexContact.mProfileURL encoding:NSUTF8StringEncoding];
    self.vProfileURL = [NSString stringWithCString:inRolodexContact.mVProfileURL encoding:NSUTF8StringEncoding];
    
    NSMutableSet* tempAvatars = nil;//[[NSMutableSet alloc] init];
    
    if (inRolodexContact.mAvatars.size() > 0)
    {
        tempAvatars = [[NSMutableSet alloc] init];
        for (RolodexContact::AvatarList::iterator avatar = inRolodexContact.mAvatars.begin(); avatar != inRolodexContact.mAvatars.end(); ++avatar)
        {
            NSString* avatarURL = [NSString stringWithUTF8String:avatar->mURL];
            
            if ([avatarURL length] > 0)
            {
                HOPAvatar* hopAvatar = [[HOPModelManager sharedModelManager] getAvatarByURL:avatarURL];
                
                if (!hopAvatar)
                {
                    hopAvatar = [NSEntityDescription insertNewObjectForEntityForName:@"HOPAvatar" inManagedObjectContext:[[HOPModelManager sharedModelManager]managedObjectContext]];
                }
                
                [hopAvatar updateWithAvatar:*avatar];
                [tempAvatars addObject:hopAvatar];
            }
            
        }
    }
    
    if ([tempAvatars count] > 0)
        self.avatars = [NSSet setWithSet:tempAvatars];
}

- (HOPContact*) getCoreContact
{
    HOPContact* ret = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:self.openPeerContact.publicPeerFile.peerURI];
    if (!ret)
    {
        ret = [[HOPContact alloc] initWithPeerFile:self.openPeerContact.publicPeerFile.peerFile];
    }
    return ret;
}
@end