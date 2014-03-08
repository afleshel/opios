/*
 
 Copyright (c) 2013, SMB Phone Inc.
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

#import <OpenpeerSDK/HOPAvatar+External.h>

@interface ImageManager ()

@property (nonatomic,strong) NSMutableDictionary *dictionaryDownloadingInProgress;
@property (nonatomic,strong) NSMutableArray *arrayOfInvalidUrls;

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
@end
