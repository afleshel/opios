//
//  ImageUploader.m
//  OpenPeerSampleApp
//
//  Created by Sergej Jovanovic on 19/03/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import "ImageUploader.h"
#import <Parse/Parse.h>

@interface FileUploader ()

//@property  (nonatomic, strong) UIImage* image;
//@property  (nonatomic, copy) NSString* imageID;
//@property  (nonatomic, copy) NSString* imageName;

@property  (nonatomic, strong) NSData* data;
@property  (nonatomic, copy) NSString* fileID;
@property  (nonatomic, copy) NSString* fileName;
@property (nonatomic, assign) UIBackgroundTaskIdentifier uploadBackgroundTaskId;
@end

@implementation FileUploader

/*- (id) initWithImageForUpload:(UIImage*) imageForUpload imageID:(NSString*) imageID imageName:(NSString*) imageName
{
    self = [super init];
    
    if (self)
    {
        if (imageForUpload && [imageForUpload isKindOfClass:[UIImage class]])
        {
            self.image = imageForUpload;
        }
        self.imageID = imageID;
        self.imageName = imageName;
        self.uploadBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}*/

- (id) initWithDataToUpload:(NSData*) dataToUpload fileID:(NSString*) fileID fileName:(NSString*) fileName
{
    self = [super init];
    
    if (self)
    {
        if (dataToUpload)
        {
            self.data = dataToUpload;
        }
        self.fileID = fileID;
        self.fileName = fileName;
        self.uploadBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}

/*- (void)upload
{
    if (self.data && self.fileID.length > 0)
    {
        float commpressionFactor = 1.0;
        NSData *imageData = nil;
        if (imageData)
        {
            do
            {
                imageData = UIImageJPEGRepresentation(self.image, commpressionFactor);
                commpressionFactor -= 0.05;
            }
            while (imageData.length > 5000000);
        }

        if (imageData)
        {
            PFFile *imageFile = [PFFile fileWithName:self.imageID data:imageData];
        
            if (imageFile)
            {
                // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
                self.uploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
               {
                   [[UIApplication sharedApplication] endBackgroundTask:self.uploadBackgroundTaskId];
               }];
                
                [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                {
                    if (succeeded)
                    {
                        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"File upload has succeeded");
                    
                        PFObject *userPhoto = [PFObject objectWithClassName:@"SharedPhoto"];
                    
                        if (userPhoto)
                        {
                            userPhoto[@"imageName"] = self.imageName.length > 0 ? self.imageName : @"Shared Photo";
                            userPhoto[@"imageFile"] = imageFile;
                            userPhoto[@"fileID"] = self.imageID;
                        
                            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                            {
                                 if (succeeded)
                                 {
                                     //                             msg.visible = [NSNumber numberWithBool:YES];
                                     //                             [conversation sendMessage:msg];
                                     //                             [[HOPModelManager sharedModelManager]saveContext];
                                 }
                         } ];
                        }
                    }
                    else
                    {
                        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"File upload failed: %@", error);//NSLog(@"%@", error);
                    }
                    
                    [[UIApplication sharedApplication] endBackgroundTask:self.uploadBackgroundTaskId];
                } progressBlock:^(int percentDone)
                {
                    
                }];
            }

        }
    }
}
 */
- (void)upload
{
    if (self.data && self.fileID.length > 0)
    {
        if (self.data)
        {
            PFFile *file = [PFFile fileWithName:self.fileID data:self.data];
            
            if (file)
            {
                // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
                self.uploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                   {
                       [[UIApplication sharedApplication] endBackgroundTask:self.uploadBackgroundTaskId];
                   }];
                
                [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {
                     if (succeeded)
                     {
                         OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"File upload has succeeded");
                         
                         PFObject *userPhoto = [PFObject objectWithClassName:@"SharedPhoto"];
                         
                         if (userPhoto)
                         {
                             userPhoto[@"imageName"] = self.fileName.length > 0 ? self.fileName : @"Shared Photo";
                             userPhoto[@"imageFile"] = file;
                             userPhoto[@"fileID"] = self.fileID;
                             
                             [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                              {
                                  if (succeeded)
                                  {
                                      NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:self.fileID, @"messageID", nil];
                                      if (dict)
                                          [[NSNotificationCenter defaultCenter] postNotificationName:notificationFileUploadDone object:dict];
                                  }
                              } ];
                         }
                     }
                     else
                     {
                         OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"File upload failed: %@", error);//NSLog(@"%@", error);
                     }
                     
                     [[UIApplication sharedApplication] endBackgroundTask:self.uploadBackgroundTaskId];
                 } progressBlock:^(int percentDone)
                 {
                     if (percentDone%5 == 0)
                     {
                         NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:self.fileID, @"messageID", [NSNumber numberWithInt:percentDone], @"procent", nil];
                         if (dict)
                             [[NSNotificationCenter defaultCenter] postNotificationName:notificationFileUploadProgress object:dict];
                     }
                 }];
            }
            
        }
    }
}

@end
