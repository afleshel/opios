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

#import "FileDownloader.h"
#import <Parse/Parse.h>

@interface FileDownloader ()

@property (atomic, assign) int percentPrvious;
@property  (nonatomic, copy) NSString* fileID;

@property (nonatomic, assign) UIBackgroundTaskIdentifier downloadBackgroundTaskId;
@end

@implementation FileDownloader

- (id) initWithFileID:(NSString*) fileID
{
    self = [super init];
    
    if(self)
    {
        self.fileID = fileID;
        self.downloadBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    
    return self;
}

- (void) downloadFile
{
    PFQuery *query = [PFQuery queryWithClassName:@"SharedPhoto"];
    [query whereKey:@"fileID" equalTo:self.fileID];
    self.downloadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.downloadBackgroundTaskId];
    }];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!error)
         {
             PFFile *file = [object objectForKey:@"imageFile"];
             // file has not been downloaded yet, we just have a handle on this file
             
             [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
              {
                  if (!error)
                  {
                      UIImage* image = [UIImage imageWithData:data];
                      if (image)
                      {
                          NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:self.fileID, @"messageID", image, @"image", nil];
                          if (dict)
                              [[NSNotificationCenter defaultCenter] postNotificationName:notificationFileDownloaded object:dict];
                      }
                      OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"downloadFile - DOWNLOAD FINISHED");
                  }
                  else
                  {
                      OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug,@"File download has failed. Error: %@", error.description);
                  }
                  [[UIApplication sharedApplication] endBackgroundTask:self.downloadBackgroundTaskId];
              } progressBlock:^(int percentDone)
              {
                  OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane,@"downloadFile - Procent: %d", percentDone);
                  if (percentDone%5 == 0 && percentDone > self.percentPrvious)
                  {
                      NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:self.fileID, @"messageID", [NSNumber numberWithInt:percentDone], @"procent", nil];
                      if (dict)
                          [[NSNotificationCenter defaultCenter] postNotificationName:notificationFileUploadProgress object:dict];
                      
                      self.percentPrvious = percentDone;
                      
                  }
              }];
         }
         else
         {
             [[UIApplication sharedApplication] endBackgroundTask:self.downloadBackgroundTaskId];
             OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug,@"File download has failed. Error: %@", error.description);
         }
     }];
}
@end
