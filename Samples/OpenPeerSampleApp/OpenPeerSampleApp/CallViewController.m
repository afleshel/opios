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

#import "CallViewController.h"
#import "Session.h"
#import "SessionManager.h"
#import <OpenpeerSDK/HOPMediaEngine.h>
#import <QuartzCore/QuartzCore.h>

@interface CallViewController ()

@property (nonatomic) BOOL callRecording;
@property (strong,nonatomic) NSTimer *sessionDurationTimer;
@property (nonatomic) NSInteger sessionDurationInSeconds;


@property (weak,nonatomic) UIButton *buttonWithAnimation;

- (void) makePulsingAnimationForButton:(UIButton*) button;

@end

@implementation CallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {

    }
    return self;
}

//Only execute this init method in child class
- (id) initWithSession:(Session*) inSession
{
    return nil;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.buttonWithAnimation)
        [self makePulsingAnimationForButton:self.buttonWithAnimation];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad
{
    [super viewDidLoad];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) muteCall:(id)sender
{
    BOOL muteCall = ![[HOPMediaEngine sharedInstance] getMuteEnabled];
    [[HOPMediaEngine sharedInstance] setMuteEnabled:muteCall];
    ((UIButton*) sender).selected = muteCall;
}

- (IBAction)actionSwitchToSpeaker:(id)sender
{
    BOOL speakersOn = ![[HOPMediaEngine sharedInstance] getLoudspeakerEnabled];
    [[HOPMediaEngine sharedInstance] setLoudspeakerEnabled:speakersOn];
    ((UIButton*) sender).selected = speakersOn;
}

- (IBAction) callHangup:(id)sender
{
    [[SessionManager sharedSessionManager] endCallForSession:self.session];
}

- (IBAction) pauseCall:(id)sender
{
    //BOOL putOnHold = [[ActionManager sharedActionManager] putCallOnHoldForSession:self.session];
    
    //if (putOnHold)
    //    [_tmrSessionDuration invalidate];
}

- (IBAction) recordCall:(id)sender
{
    ((UIButton*) sender).selected = !((UIButton*) sender).selected;
    if (((UIButton*) sender).selected)
    {
        self.buttonWithAnimation = ((UIButton*) sender);
        [self makePulsingAnimationForButton:self.buttonWithAnimation];
    }
    else
    {
        [((UIButton*) sender).layer removeAllAnimations];
        self.buttonWithAnimation = nil;
    }
}


//Implemented on client side
-(void) setDefaults
{
    
    
}

//Implemented on client side
- (void) handleCallStateChanged
{
    
}


- (void) makePulsingAnimationForButton:(UIButton*) button
{
    CABasicAnimation *theAnimation;
    
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=1.5;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.1];
    [button.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}


@end
