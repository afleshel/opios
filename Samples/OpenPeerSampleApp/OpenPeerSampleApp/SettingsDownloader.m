/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "SettingsDownloader.h"
#import "Settings.h"
#import "OpenPeer.h"
#import <OpenPeerSDK/HOPSettings.h>
#import <OpenPeerSDK/HOPCache.h>

@interface SettingsDownloader ()

@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) NSString* url;
@property (nonatomic, copy) NSString* postData;
@end

@implementation SettingsDownloader

- (id) initSettingsDownloadFromURL:(NSString*) inURL postDate:(NSString*) inPostData
{
    self = [super init];
    if (self)
    {
        self.url = inURL;
        self.postData = inPostData;
    }
    return self;
}

//- (void) downloadFromURL:(NSString*) url postDate:(NSString*) postData
- (void)startDownload
{
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:20.0];
    
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    
    if (self.postData)
    {
        [theRequest setHTTPMethod:@"POST"];
        [theRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [theRequest setHTTPBody:[self.postData dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // create the connection with the request and start loading the data
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!self.urlConnection)
    {
        // Release the receivedData object.
        self.receivedData = nil;
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                            message:@"Please, ckeck you internet connection and try to scan QR code again or proceed login with default values."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.urlConnection = nil;
    self.receivedData = nil;
    
    //Inform the user that there was an error with download
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                        message:@"Please, ckeck you internet connection and try to scan QR code again or proceed login with default values."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Ok",nil];
    [alertView show];
    
    [self.delegate onSettingsDownloadFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.receivedData length] > 0)
    {
        NSString* strJSON = [[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding];
        
        //Apply downloaded settings
        if ([strJSON length] > 0)
        {
            NSDictionary* settings = [[Settings sharedSettings] dictionaryForJSONString:strJSON];
            [self.delegate onSettingsDownloadCompletion:settings];
//            [[Settings sharedSettings] snapshotCurrentSettings];
//            [[Settings sharedSettings] storeQRSettings:settings];
//            [[HOPSettings sharedSettings] storeSettingsFromDictionary:settings];
//            [[OpenPeer sharedOpenPeer] finishPreSetup];
            //[[OpenPeer sharedOpenPeer] setup];
        }
        else
        {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Login settings are not valid!"
                                                                message:@"Please try to scan another QR code or proceed login with default values."
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Ok",nil];
            [alertView show];
        }
    }
    self.urlConnection = nil;
    self.receivedData = nil;
    
}
@end
