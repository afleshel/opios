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
#import "SettingsDownloader.h"

@interface QRScannerViewController ()

@property (nonatomic, strong) ZXCapture* capture;
//@property (nonatomic, strong) NSURLConnection *urlConnection;
//@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) SettingsDownloader* settingsDownloader;

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

#pragma mark - ZXCaptureDelegate Methods
- (void)captureResult:(ZXCapture*)capture result:(ZXResult*)result
{
    if (result)
    {
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        NSString* str = result.text;

        if ([str length] > 0)
        {
            NSString* jsonURL = nil;
            NSString* postData = nil;
            
            if ([str rangeOfString:@"&post="].location != NSNotFound)
            {
                NSArray* arrayOfStrings = [str componentsSeparatedByString:@"&post="];
                if ([arrayOfStrings count] > 1)
                {
                    jsonURL = [arrayOfStrings objectAtIndex:0];
                    postData = [arrayOfStrings objectAtIndex:1];
                }
            }
            else
                jsonURL = str;
                
            if ([Utility isValidURL:jsonURL])
            {
                [self loadSettingsfromURL:jsonURL postDate:postData];
            }
            else
            {
                //Check if JSON is valid
                if ([Utility isValidJSON:str])
                {
                    //[[HOPSettings sharedSettings] applySettings:str];
                    NSDictionary* settings = [[Settings sharedSettings] dictionaryForJSONString:str];
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
    [self.view bringSubviewToFront:self.buttonLogger];
    [self.view bringSubviewToFront:self.buttonCancel];
    self.buttonCancel.hidden = NO;

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
    self.settingsDownloader = [[SettingsDownloader alloc] initSettingsDownloadFromURL:jsonURL postDate:postData];
    self.settingsDownloader.delegate = self;
    [self.settingsDownloader startDownload];
}


- (IBAction)actionStartLogger:(id)sender
{
    [Logger startTelnetLoggerOnStartUp];
}

- (IBAction)actionCancelScan:(id)sender
{
    self.buttonCancel.hidden = YES;
    [self.capture.layer removeFromSuperlayer];
}

#pragma mark - SettingsDownloaderDelegate
- (void)onSettingsDownloadCompletion:(NSDictionary *)inSettingsDictionary
{
    [[Settings sharedSettings] snapshotCurrentSettings];
    [[Settings sharedSettings] storeQRSettings:inSettingsDictionary];
    [[HOPSettings sharedSettings] storeSettingsFromDictionary:inSettingsDictionary];
    
    [self actionProceedWithlogin:nil];
}

- (void)onSettingsDownloadFailure
{
    [self actionProceedWithlogin:nil];
}
@end
