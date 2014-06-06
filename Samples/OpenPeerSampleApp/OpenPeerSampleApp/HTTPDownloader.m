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

#import "HTTPDownloader.h"
#import "Settings.h"
#import "OpenPeer.h"
#import <OpenPeerSDK/HOPSettings.h>
#import <OpenPeerSDK/HOPCache.h>

@interface HTTPDownloader ()

@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) NSString* url;
@property (nonatomic, copy) NSString* postData;
@property (nonatomic, copy) NSString* auth;
@end

@implementation HTTPDownloader

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

- (id) initSettingsDownloadFromURL:(NSString*) inURL postDate:(NSString*) inPostData auth:(NSString*) inAuth
{
    self = [self initSettingsDownloadFromURL:inURL postDate:inPostData];
    if (self)
    {
        self.auth = inAuth;
    }
    return self;
}

- (BOOL)startDownload
{
    BOOL ret = YES;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:20.0];
    
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    
    if (self.postData)
    {
        [theRequest setHTTPMethod:@"POST"];
        //[theRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [theRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [theRequest setHTTPBody:[self.postData dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if ([self.auth length] > 0)
    {
        [theRequest setValue:self.auth forHTTPHeaderField:@"Authorization"];
    }
    
    // create the connection with the request and start loading the data
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!self.urlConnection)
    {
        // Release the receivedData object.
        self.receivedData = nil;
        
        ret = NO;
        
        OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Start downloading failed for url %@",self.url);
    }
    
    return ret;
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
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Downloading failed for url %@. Error: %@ %@",self.url,[error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    [self.delegate httpDownloader:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.receivedData length] > 0)
    {
        NSString* str = [[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding];
        
        //Apply downloaded settings
        if ([str length] > 0)
        {
            [self.delegate httpDownloader:self downloaded:str];
        }
        else
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Downloaded empty string for url %@",self.url);
        }
    }
    self.urlConnection = nil;
    self.receivedData = nil;
    
}
@end
