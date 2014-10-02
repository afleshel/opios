//
//  HOPOpenPeerContact_Internal.c
//  openpeer-ios-sdk
//
//  Created by Sergej on 10/2/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "HOPOpenPeerContact_Internal.h"
#import <openpeer/core/IHelper.h>
#import "OpenPeerStorageManager.h"
#import "HOPContact.h"
#import "HOPModelManager_Internal.h"
#import "HOPIdentityContact_Internal.h"

@implementation HOPOpenPeerContact

@dynamic stableID;
@dynamic apnsData;
@dynamic identityContacts;
@dynamic publicPeerFile;
@dynamic sessionRecords;
@dynamic participants;

+ (id) createOpenPeerContacFromCoreContact:(IContactPtr) contactPtr conversationThread:(IConversationThreadPtr) conversationThreadPtr
{
    HOPOpenPeerContact* ret = nil;
    
    IdentityContactListPtr identityContactListPtr = conversationThreadPtr->getIdentityContactList(contactPtr);
    
    for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
    {
        IdentityContact identityContact = *identityContactInfo;
        if (identityContact.hasData())
        {
            //NSString* sId = [NSString stringWithUTF8String:identityContact.mStableID];
            NSString* identityURI = [NSString stringWithUTF8String:identityContact.mIdentityURI];
            HOPIdentityContact* hopIdentityContact = [[HOPModelManager sharedModelManager] getIdentityContactWithIdentityURI:identityURI];
            
            if (!hopIdentityContact)
            {
                NSManagedObject* managedObject = [[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPIdentityContact"];
                if (managedObject && [managedObject isKindOfClass:[HOPIdentityContact class]])
                {
                    hopIdentityContact = (HOPIdentityContact*) managedObject;
                }
            }
            
            if (hopIdentityContact)
            {
                [hopIdentityContact updateWithIdentityContact:identityContact];
                
                ret = [[HOPModelManager sharedModelManager]  getOpenPeerContactForIdentityContact:identityContact];
                if (ret)
                    [ret addIdentityContactsObject:hopIdentityContact];
                else
                    ret = [[HOPModelManager sharedModelManager] createOpenPeerContactForIdentityContact:identityContact];
            }
            
        }
    }
    
    return ret;
}

@end
