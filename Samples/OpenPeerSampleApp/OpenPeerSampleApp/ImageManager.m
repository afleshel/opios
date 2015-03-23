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
#import "FileUploader.h"
#import "FileDownloader.h"
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

@interface UIImage (FixOrient)
- (UIImage *)fixOrientation;
@end

@interface ImageManager ()

@property (nonatomic,strong) NSMutableDictionary *dictionaryDownloadingInProgress;
@property (nonatomic,strong) NSMutableArray *arrayOfInvalidUrls;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic,strong) NSMutableDictionary *dictionaryOfUploads;
@property (nonatomic,strong) NSMutableDictionary *dictionaryOfDownloads;

- (id) initSingleton;

- (void) onFileUploaded:(NSNotification*) notification;
- (void) onFileDownloaded:(NSNotification*) notification;

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
        self.dictionaryOfDownloads = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFileUploaded:) name:notificationFileUploaded object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFileDownloaded:) name:notificationFileDownloaded object:nil];
    }
    return self;
}

/*- (void) donwloadImageForAvatar:(HOPAvatar*) inAvatar tableView:(UITableView*) inTableView indexPath:(NSIndexPath*) inIndexPath
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
*/
- (UIImage*) getAvatarImageForIdentity:(HOPIdentity*) identity
{
    UIImage* ret = nil;
    if (identity)
    {
        HOPAvatar* avatar = [identity getAvatarForWidth:[NSNumber numberWithFloat:AVATAR_WIDTH] height:[NSNumber numberWithFloat:AVATAR_HEIGHT]];
        if (avatar)
        {
            ret = [self imageForKey:avatar.url];//[avatar getImage];
        }
    }
    return ret;
}

- (void) storeImage:(UIImage*) image forKey:(NSString*) key
{
    if (image && key.length > 0)
    {
        UIImage* fixedOrientation = [image fixOrientation];
        [[SDImageCache sharedImageCache] storeImage:fixedOrientation forKey:key];
    }
}

- (UIImage*) imageForKey:(NSString*) key
{
    UIImage* ret = nil;
    
    if (key.length)
        ret = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    return ret;
}


- (void) loadImageURL:(NSString*) url toImageView:(UIImageView*) imageView
{
    if (imageView && url.length > 0)
        [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
}

- (void) downloadSharedImageForMessage:(HOPMessage*) message
{
    if (![self.dictionaryOfDownloads objectForKey:message.messageID])
    {
        FileDownloader* fileDownloader = [[FileDownloader alloc] initWithFileID:message.messageID];
        if (fileDownloader)
        {
            [self.dictionaryOfDownloads setObject:fileDownloader forKey:message.messageID];
            [fileDownloader downloadFile];
        }
    }
}

- (void) shareImage:(UIImage*) image forConversation:(HOPConversation*) conversation
{
    if (image)
    {
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
    }
}

- (void) onFileUploaded:(NSNotification*) notification
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

- (void) onFileDownloaded:(NSNotification*) notification
{
    NSDictionary* dict = notification.object;
    if (dict.count > 0)
    {
        NSString* messageID = [dict objectForKey:@"messageID"];
        UIImage* image = [dict objectForKey:@"image"];
        if (messageID.length > 0 && image)
        {
            [[ImageManager sharedImageManager] storeImage:image forKey:messageID];
            [self.dictionaryOfUploads removeObjectForKey:messageID];
            [[SessionManager sharedSessionManager] fileDownloadFinishedForMessageID:messageID];
        }
    }
}
@end

@implementation UIImage (FixOrient)

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
