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

#import "QRScannerViewController.h"
#import "LoginManager.h"
#import "OpenPeer.h"
#import "Settings.h"
#import "Utility.h"
#import <OpenPeerSDK/HOPSettings.h>

@interface QRScannerViewController ()

@property (nonatomic, strong) ZXCapture* capture;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData* receivedData;

- (IBAction)actionReadQRCode:(id)sender;
- (IBAction)actionProceedWithlogin:(id)sender;

@end

@implementation QRScannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ZXCaptureDelegate Methods
- (void)captureResult:(ZXCapture*)capture result:(ZXResult*)result
{
    if (result)
    {
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        NSString* str = result.text;

        if ([str length] > 0 && ([str rangeOfString:@"{...}"].location == NSNotFound))
        {
            [self loadSettingsfromURL:str];
        }
        else
        {
            [self actionProceedWithlogin:nil];
        }
    }
    
    self.capture.delegate = nil;
    [self.capture.layer removeFromSuperlayer];
}

- (void)captureSize:(ZXCapture*)capture width:(NSNumber*)width height:(NSNumber*)height
{

}

- (IBAction)actionReadQRCode:(id)sender
{
    if (!self.capture)
    {
        self.capture = [[ZXCapture alloc] init];
        self.capture.rotation = 90.0f;
        
        // Use the back camera
        self.capture.camera = self.capture.back;
        
        self.capture.layer.frame = self.view.bounds;
    }
    
    [self.view.layer addSublayer:self.capture.layer];
    self.capture.delegate = self;
}

- (IBAction)actionProceedWithlogin:(id)sender
{
    BOOL isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
    if (!isSetLoginSettings)
    {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"];
        if ([filePath length] > 0)
        {
            [[Settings sharedSettings] storeSettingsFromPath:filePath];
        }
        
        isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
    }
    
    BOOL isSetAppData = [[Settings sharedSettings] isAppDataSet];
    if (!isSetAppData)
    {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"];
        if ([filePath length] > 0)
        {
            [[Settings sharedSettings] storeSettingsFromPath:filePath];
        }
        isSetAppData = [[Settings sharedSettings] isAppDataSet];
    }
    
    if (isSetAppData && isSetLoginSettings)
    {
        [self.view removeFromSuperview];
        [[HOPSettings sharedSettings] applyDefaults];
        [[OpenPeer sharedOpenPeer] setup];
    }
    else
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Local file with local settings is corrupted!"
                                                            message:@"Please try to scan QR code or reinstall the app."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
}

- (void) loadSettingsfromURL:(NSString*) url
{
    NSString* jsonURL = nil;
    if ([url rangeOfString:@"&post=base64"].location != NSNotFound)
    {
        NSArray* arrayOfStrings = [url componentsSeparatedByString:@"&post=base64"];
        if ([arrayOfStrings count] > 0)
        {
            jsonURL = [Utility decodeBase64:[arrayOfStrings objectAtIndex:0]];
        }
    }
    else
        jsonURL = url;
    
    if ([jsonURL length] == 0)
    {
        [self actionProceedWithlogin:nil];
        return;
    }
    
    // Create the request.
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:jsonURL]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];

    self.receivedData = [NSMutableData dataWithCapacity: 0];
    
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
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.receivedData length] > 0)
    {
        BOOL isSet = NO;
        NSString* strJSON = [[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding];
        
        //Apply downloaded settings
        if ([strJSON length] > 0)
            isSet = [[HOPSettings sharedSettings] applySettings:strJSON];
        
        BOOL isSetAppData = [[Settings sharedSettings] isAppDataSet];
        
        if (!isSetAppData)
        {
            NSString* filePath = [[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"];
            if ([filePath length] > 0)
            {
                [[Settings sharedSettings] storeSettingsFromPath:filePath];
            }
            isSetAppData = [[Settings sharedSettings] isAppDataSet];
        }

        BOOL isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
        if (!isSetLoginSettings)
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"];
            if ([filePath length] > 0)
            {
                [[Settings sharedSettings] storeSettingsFromPath:filePath];
            }
            
            isSetLoginSettings = [[Settings sharedSettings] isLoginSettingsSet];
        }
        
        isSet = isSetAppData && isSetLoginSettings;//[[Settings sharedSettings] isAppDataSet] && [[Settings sharedSettings] isLoginSettingsSet];
        //If set remove scanner and proceed with app setup
        if (isSet)
        {
            [self.view removeFromSuperview];
            [[OpenPeer sharedOpenPeer] setup];
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
