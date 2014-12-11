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

#import "VideoCallViewController.h"
#import <OpenPeerSDK/HOPMediaEngine.h>
#import "Utility.h"

@interface VideoCallViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *videoPreviewImageView;
@property (weak, nonatomic) IBOutlet UIView *controlView;

@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchCamera;

@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;

- (IBAction) actionSwitchCamera:(id)sender;
- (IBAction) actionShowChat:(id)sender;
- (IBAction) actionShowPreview:(id)sender;
@end

@implementation VideoCallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithConversation:(HOPConversation*) inConversation
{
    self = [self initWithNibName:@"VideoCallViewController" bundle:nil];
    if (self)
    {
        self.conversation = inConversation;
        //self.mediaNavigationViewController = [[[MediaNavigationViewController alloc] initWithSession:inSession] autorelease];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.videoPreviewImageView.layer.cornerRadius = 5;
    self.videoPreviewImageView.layer.masksToBounds = YES;
    
    self.buttonSwitchCamera.enabled = [Utility getNumberOfDeviceCameras] > 1;
    
    //Set default video orientation to be portrait
    [[HOPMediaEngine sharedInstance] setDefaultVideoOrientation:HOPMediaEngineVideoOrientationPortrait];
    
    //Set UIImageViews where will be shown camera preview and video
    [[HOPMediaEngine sharedInstance] setCaptureRenderView:self.videoPreviewImageView];
    [[HOPMediaEngine sharedInstance] setChannelRenderView:self.videoImageView];
    //Set default video orientation to be portrait
    [[HOPMediaEngine sharedInstance] setDefaultVideoOrientation:HOPMediaEngineVideoOrientationPortrait];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.tapGesture];
}

- (void)dealloc
{
    [[HOPMediaEngine sharedInstance] setCaptureRenderView:nil];
    [[HOPMediaEngine sharedInstance] setChannelRenderView:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) actionSwitchCamera:(id)sender
{
    HOPMediaEngineCameraType currentCameraType =  [[HOPMediaEngine sharedInstance] getCameraType];
    currentCameraType = currentCameraType == HOPMediaEngineCameraTypeFront ? HOPMediaEngineCameraTypeBack : HOPMediaEngineCameraTypeFront;
    [[HOPMediaEngine sharedInstance] setCameraType:currentCameraType];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    self.controlView.hidden = !self.controlView.hidden;
}

- (IBAction) actionShowChat:(id)sender
{
    [self.delegate hideVideo:YES];
}

- (IBAction) actionShowPreview:(id)sender
{
    self.videoPreviewImageView.hidden = !self.videoPreviewImageView.hidden;
}
@end
