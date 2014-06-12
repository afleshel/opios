//
//  ActiveSessionTableViewCell.h
//  OpenPeerSampleApp
//
//  Created by Sergej on 6/9/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HOPSessionRecord;

@interface ActiveSessionTableViewCell : UITableViewCell

- (void) setSession:(HOPSessionRecord *)inSessionRecord;

@end
