//
//  OfflineManager.h
//  OpenPeerSampleApp
//
//  Created by Sergej on 5/7/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OfflineManager : NSObject

+ (id) sharedOfflineManager;
- (void) startNetworkMonitor;
- (void) showInfoAboutNetworkProblem;
@end
