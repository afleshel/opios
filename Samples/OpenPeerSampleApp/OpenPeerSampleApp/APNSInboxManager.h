//
//  APNSInboxManager.h
//  OpenPeerSampleApp
//
//  Created by Sergej on 3/19/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UAInboxPushHandler.h"
#import "UAPush.h"
#import "Delegates.h"

@interface APNSInboxManager : NSObject<UAInboxPushHandlerDelegate,UAPushNotificationDelegate,HTTPDownloaderDelegate,UAInboxMessageListDelegate>

+ (id) sharedAPNSInboxManager;

- (void) setup;
- (void) handleNewMessages;
- (void) handleAPNS:(NSDictionary *)apnsInfo;

- (void) getAllMessages;
@end
