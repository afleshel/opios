//
//  HOPOpenPeerContact_Internal.h
//  openpeer-ios-sdk
//
//  Created by Sergej on 10/2/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <HOPOpenPeerContact+External.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IConversationThread.h>

using namespace openpeer;
using namespace openpeer::core;

@interface HOPOpenPeerContact ()

+ (id) createOpenPeerContacFromCoreContact:(IContactPtr) contactPtr conversationThread:(IConversationThreadPtr) conversationThreadPtr;
@end
