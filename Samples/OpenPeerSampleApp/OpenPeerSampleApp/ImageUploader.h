//
//  ImageUploader.h
//  OpenPeerSampleApp
//
//  Created by Sergej Jovanovic on 19/03/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUploader : NSObject

- (id) initWithDataToUpload:(NSData*) dataToUpload fileID:(NSString*) fileID fileName:(NSString*) fileName;
- (void) upload;
@end
