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

#import "ImageManager.h"
#import "IconDownloader.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "SessionManager.h"
#import  "MessageManager.h"
#import "ImageUploader.h"
#import <OpenpeerSDK/HOPAvatar+External.h>
#import <OpenpeerSDK/HOPIdentity+External.h>
#import <OpenpeerSDK/HOPMessage.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPConversation.h>
#import <OpenpeerSDK/HOPUtility.h>
#import <OpenpeerSDK/HOPContact+External.h>

#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <Parse/Parse.h>

@interface ImageManager ()

@property (nonatomic,strong) NSMutableDictionary *dictionaryDownloadingInProgress;
@property (nonatomic,strong) NSMutableArray *arrayOfInvalidUrls;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic,strong) NSMutableDictionary *dictionaryOfUploads;

- (id) initSingleton;
@end

@implementation ImageManager

+ (id) sharedImageManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    
    dispatch_once(&pred, ^
    {
        _sharedObject = [[self alloc ] initSingleton];
    });
    
    return _sharedObject;
}

- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        self.dictionaryDownloadingInProgress = [[NSMutableDictionary alloc] init];
        self.arrayOfInvalidUrls = [[NSMutableArray alloc] init];
        self.dictionaryOfUploads = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUploadFinished:) name:notificationFileUploadDone object:nil];
    }
    return self;
}

- (void) donwloadImageForAvatar:(HOPAvatar*) inAvatar tableView:(UITableView*) inTableView indexPath:(NSIndexPath*) inIndexPath
{
    //If image is already tried to be downloaded from this url and its failed don't try again
    if ([self.arrayOfInvalidUrls containsObject:inAvatar.url])
        return;
    
    UITableView* tableView = inTableView;
    NSIndexPath* indexPath = inIndexPath;
    __block HOPAvatar* avatar = inAvatar;
    
    IconDownloader *iconDownloader = [self.dictionaryDownloadingInProgress objectForKey:avatar.url];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        [iconDownloader setCompletionHandler:^(UIImage* downloadedImage, NSString* url)
         {
             if (downloadedImage)
             {
                 [avatar storeImage:downloadedImage];
                 
                 UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                 
                 if (cell)
                 {
                     cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
                     cell.imageView.clipsToBounds = YES;
                     
                     // Display the newly loaded image
                     cell.imageView.image = downloadedImage;
                     
                     [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                 }
             }
             else
             {
                 [self.arrayOfInvalidUrls addObject:url];
             }
             
             // Remove the IconDownloader from the in progress list.
             // This will result in it being deallocated.
             [self.dictionaryDownloadingInProgress removeObjectForKey:url];
             
         }];
        [self.dictionaryDownloadingInProgress setObject:iconDownloader forKey:avatar.url];
        [iconDownloader startDownloadForURL:avatar.url];
    }
}

- (UIImage*) getAvatarImageForIdentity:(HOPIdentity*) identity
{
    UIImage* ret = nil;
    if (identity)
    {
        HOPAvatar* avatar = [identity getAvatarForWidth:[NSNumber numberWithFloat:AVATAR_WIDTH] height:[NSNumber numberWithFloat:AVATAR_HEIGHT]];
        if (avatar)
        {
            ret = [avatar getImage];
        }
    }
    return ret;
}

- (void) storeImage:(UIImage*) image forKey:(NSString*) key
{
    if (image && key.length > 0)
        [[SDImageCache sharedImageCache] storeImage:image forKey:key];
}

- (UIImage*) imageForKey:(NSString*) key
{
    UIImage* ret = nil;
    
    if (key.length)
        ret = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    return ret;
}

//- (UIImage*) thumbnailForKey:(NSString*) key
//{
//    UIImage *resizedImage = [self resizedImageWithContentMode:UIViewContentModeScaleAspectFill
//                                                       bounds:CGSizeMake(thumbnailSize, thumbnailSize)
//                                         interpolationQuality:quality];
//    
//    // Crop out any part of the image that's larger than the thumbnail size
//    // The cropped rect must be centered on the resized image
//    // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
//    CGRect cropRect = CGRectMake(round((resizedImage.size.width - 100) / 2),
//                                 round((resizedImage.size.height - 100) / 2),
//                                 thumbnailSize,
//                                 thumbnailSize);
//    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
//    
//    return croppedImage;
//}

- (void) loadImageURL:(NSString*) url toImageView:(UIImageView*) imageView
{
    if (imageView && url.length > 0)
        [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
}

- (void) downloadSharedImageForMessage:(HOPMessage*) message
{
    PFQuery *query = [PFQuery queryWithClassName:@"SharedPhoto"];
    NSString* fileName = message.messageID;//[NSString stringWithFormat:@"%@.jpg",message.messageID];
    [query whereKey:@"fileID" equalTo:fileName];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!error) {
             PFFile *file = [object objectForKey:@"imageFile"];
             // file has not been downloaded yet, we just have a handle on this file
             
             [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
              {
                  UIImage* image = [UIImage imageWithData:data];
                  if (image)
                  {
                      [[ImageManager sharedImageManager] storeImage:image forKey:message.messageID];
                      message.visible = [NSNumber numberWithBool:YES];
                      [[HOPModelManager sharedModelManager]saveContext];
                  }
              } progressBlock:^(int percentDone)
             {
                  if (percentDone%5 == 0)
                  {
                      NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:message.messageID, @"messageID", [NSNumber numberWithInt:percentDone], @"procent", nil];
                      if (dict)
                          [[NSNotificationCenter defaultCenter] postNotificationName:notificationFileUploadProgress object:dict];
                  }
              }];
             
             
         }
     }];
}

- (void) shareImage:(UIImage*) image forConversation:(HOPConversation*) conversation
{
    if (image)
    {
//        NSData *imageData = UIImageJPEGRepresentation(image,1);
//        if (imageData && imageData.length > 9000000)
//        {
//            imageData = UIImageJPEGRepresentation(image, 0.9);
//        }
        
        float commpressionFactor = 0.9;
        NSData *imageData = nil;
        
        do
        {
            imageData = UIImageJPEGRepresentation(image, commpressionFactor);
            commpressionFactor -= 0.05;
        }
        while (imageData.length > 5000000);
        if (imageData)
        {
            NSString* msgID = [HOPUtility getGUIDstring];
            HOPMessage* msg = [[MessageManager sharedMessageManager] createSystemMessageForFileShareWithID:msgID size:imageData.length resolution:image.size conversation:conversation];
            
            if (msg)
            {
                [[ImageManager sharedImageManager] storeImage:image forKey:msgID];
                
                msg.visible = [NSNumber numberWithBool:YES];

                [[HOPModelManager sharedModelManager]saveContext];
                

                FileUploader* fileUploader = [[FileUploader alloc] initWithDataToUpload:imageData fileID:msgID fileName:@"Shared Photo"];
                if (fileUploader)
                {
                    [self.dictionaryOfUploads setObject:fileUploader forKey:msgID];
                    [fileUploader upload];
                }
            }

        }
        //NSString* fileName = msgID;
        
        
        /*PFFile *imageFile = [PFFile fileWithName:fileName data:imageData];
        
        PFObject *userPhoto = [PFObject objectWithClassName:@"SharedPhoto"];
        userPhoto[@"imageName"] = @"Shared Photo";
        userPhoto[@"imageFile"] = imageFile;
        userPhoto[@"peerURI"] = [((HOPContact*)conversation.participants[0]) getPeerURI];
        userPhoto[@"fileID"] = fileName;
        [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (succeeded)
             {
                 msg.visible = [NSNumber numberWithBool:YES];
                 [conversation sendMessage:msg];
                 [[HOPModelManager sharedModelManager]saveContext];
             }
             else
             {
                 NSLog(@"%@", error);
             }
         }];*/
    }
}

- (void) fileUploadFinished:(NSNotification*) notification
{
    NSDictionary* dict = notification.object;
    if (dict.count > 0)
    {
        NSString* messageID = [dict objectForKey:@"messageID"];
        if (messageID.length > 0)
        {
            [self.dictionaryOfUploads removeObjectForKey:messageID];
            [[SessionManager sharedSessionManager] fileUploadFinishedForMessageID:messageID];
        }
    }
}

/*- (void) showFullscreenImage:(UITapGestureRecognizer*) gesture
{
    UIImageView *tempImage = [[UIImageView alloc]initWithImage:((UIImageView*)gesture.view).image];
    self.imageView = tempImage;
    
    self.fullScreenView = [[UIScrollView alloc] initWithFrame:[[OpenPeer sharedOpenPeer] mainViewController].view.bounds];
    self.fullScreenView.contentSize = CGSizeMake(self.imageView.frame.size.width , self.imageView.frame.size.height);
    self.fullScreenView.maximumZoomScale = 1;
    self.fullScreenView.minimumZoomScale = .37;
    self.fullScreenView.clipsToBounds = YES;
    self.fullScreenView.delegate = self;
    [self.fullScreenView addSubview:self.imageView];
    self.fullScreenView.zoomScale = .37;
    
    [[[OpenPeer sharedOpenPeer] mainViewController].view addSubview:self.fullScreenView];
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)inScroll
{
    return self.imageView;
}*/
@end
