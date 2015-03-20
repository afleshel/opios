//
//  NewChatCell.h
//  OpenPeerSampleApp
//
//  Created by Sergej on 3/10/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatCell.h"

@interface NewChatCell : ChatCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageDeliveryStatusLabel;
//@property (weak, nonatomic) IBOutlet UILabel *upload_downloadLabel;
@end
