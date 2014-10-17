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
#import "Logger.h"
#import "HTTPDownloader.h"
#import "AppConsts.h"

@interface QRScannerViewController ()

@property (nonatomic, strong) HTTPDownloader* settingsDownloader;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, weak) IBOutlet UIButton* buttonLogger;
@property (nonatomic, weak) IBOutlet UIButton* buttonCancel;

- (IBAction)actionReadQRCode:(id)sender;
- (IBAction)actionProceedWithlogin:(id)sender;
- (IBAction)actionStartLogger:(id)sender;
- (IBAction)actionCancelScan:(id)sender;
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
    
    self.buttonCancel.layer.cornerRadius = 5.0;
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

- (void) handleQRCode:(NSString*) value
{
    if ([value length] > 0)
    {
        NSString* jsonURL = nil;
        NSString* postData = nil;
        
        if ([value rangeOfString:@"&post="].location != NSNotFound)
        {
            NSArray* arrayOfStrings = [value componentsSeparatedByString:@"&post="];
            if ([arrayOfStrings count] > 1)
            {
                jsonURL = [arrayOfStrings objectAtIndex:0];
                postData = [arrayOfStrings objectAtIndex:1];
            }
        }
        else
            jsonURL = value;
        
        if ([Utility isValidURL:jsonURL])
        {
            [self loadSettingsfromURL:jsonURL postDate:postData];
        }
        else
        {
            //Check if JSON is valid
            if ([Utility isValidJSON:value])
            {
                //[[HOPSettings sharedSettings] applySettings:str];
                NSDictionary* settings = [[Settings sharedSettings] dictionaryForJSONString:value];
                if (settings)
                {
                    [[Settings sharedSettings] snapshotCurrentSettings];
                    [[Settings sharedSettings] storeQRSettings:settings];
                    [[HOPSettings sharedSettings] storeSettingsFromDictionary:settings];
                }
                [self actionProceedWithlogin:nil];
            }
            else
            {
                self.buttonCancel.hidden = YES;
                self.buttonLogger.hidden = NO;
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Invalid login settings!"
                                                                    message:@"Please, scan another QR code or proceed with already set login settings"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Ok",nil];
                [alertView show];
            }
            
        }
    }
    else
    {
        [self actionProceedWithlogin:nil];
    }

}
- (IBAction)actionReadQRCode:(id)sender
{
    self.buttonCancel.hidden = NO;
    self.buttonLogger.hidden = YES;
    
    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if (input) {
        [self.session addInput:input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:self.output];
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    [self.session startRunning];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.bounds = self.view.bounds;
    self.previewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.view bringSubviewToFront:self.buttonCancel];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    @synchronized(self.session)
    {
        if (self.session.isRunning)
        {
            // Vibrate
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            for (AVMetadataObject *metadata in metadataObjects)
            {
                if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode])
                {
                    [self.session stopRunning];
                    NSString* value = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                    [self.previewLayer removeFromSuperlayer];
                    [self handleQRCode:value];
                    break;
                }
            }
        }
    }
}

- (IBAction)actionProceedWithlogin:(id)sender
{
    [self.view removeFromSuperview];
    [[OpenPeer sharedOpenPeer] setup];
}

- (void) loadSettingsfromURL:(NSString*) jsonURL postDate:(NSString*) postData
{    
    if ([jsonURL length] == 0)
    {
        [self actionProceedWithlogin:nil];
        return;
    }
    
    self.settingsDownloader = nil;
    self.settingsDownloader = [[HTTPDownloader alloc] initSettingsDownloadFromURL:jsonURL postDate:postData];
    self.settingsDownloader.delegate = self;
    if (![self.settingsDownloader startDownload])
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                            message:@"Please, check your Internet connection and try to scan QR code again or proceed login with default values."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
}


- (IBAction)actionStartLogger:(id)sender
{
    [Logger startTelnetLoggerOnStartUp];
}

- (IBAction)actionCancelScan:(id)sender
{
    self.buttonCancel.hidden = YES;
    self.buttonLogger.hidden = NO;
    [self.session stopRunning];
    [self.previewLayer removeFromSuperlayer];
}

#pragma mark - SettingsDownloaderDelegate

- (void) httpDownloader:(HTTPDownloader*) downloader downloaded:(NSString*) downloaded
{
    NSDictionary* settingsDictionary = nil;
    BOOL showErrorNotification = YES;
    //Apply downloaded settings
    if ([downloaded length] > 0 && [downloaded rangeOfString:@">404<"].location == NSNotFound)
    {
        settingsDictionary = [[Settings sharedSettings] dictionaryForJSONString:downloaded];
        
        if ([settingsDictionary count] > 0)
        {
            [[Settings sharedSettings] snapshotCurrentSettings];
            [[Settings sharedSettings] storeQRSettings:settingsDictionary];
            [[HOPSettings sharedSettings] storeSettingsFromDictionary:settingsDictionary];
            showErrorNotification = NO;
        }
    }
    else
    {
        if ([downloaded length] > 0)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Settings download error: 404 Not found");
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Received empty settings string.");
        }
    }
    
    if (showErrorNotification)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                            message:@"Login will proceed with default settings."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeyEnabledLogger])
    {
        NSString* str = [[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyDefaultLogLevel];
        [Logger startTelnetLoggerWithLogLevel:str];
    }
    [self actionProceedWithlogin:nil];
}

- (void) httpDownloader:(HTTPDownloader *) downloader didFailWithError:(NSError *)error
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                        message:@"Please, check your Internet connection and try to scan QR code again or proceed login with default values."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Ok",nil];
    [alertView show];
    self.settingsDownloader = nil;
    [self actionProceedWithlogin:nil];
}

@end

