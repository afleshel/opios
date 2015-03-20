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
