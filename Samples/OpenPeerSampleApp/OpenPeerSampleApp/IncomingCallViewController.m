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

#import "IncomingCallViewController.h"
#import "SessionManager.h"
#import "SoundsManager.h"
#import <OpenPeerSDK/HOPConversation.h>

#import <OpenPeerSDK/HOPCall.h>
#import <OpenPeerSDK/HOPIdentity+External.h>
#import <OpenPeerSDK/HOPAvatar.h>
#import <OpenPeerSDK/HOPImage.h>
#import <OpenPeerSDK/HOPContact+External.h>

@interface IncomingCallViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *bgImgView;
@property (nonatomic, weak) IBOutlet UIImageView *imageViewCallerAvatar;
@property (nonatomic, weak) IBOutlet UIImageView *imageViewLogo;

@property (nonatomic, weak) IBOutlet UIButton *buttonAccept;
@property (nonatomic, weak) IBOutlet UIButton *buttonDecline;

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, weak) IBOutlet UILabel *labelCallType;
@property (nonatomic, weak) IBOutlet UILabel *labelCaller;
@end

@implementation IncomingCallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        
    }
    return self;
}

- (id)initWithConversation:(HOPConversation*) inConversation
{
    self = [self initWithNibName:@"IncomingCallView_iPhone" bundle:nil];
    if (self)
    {
        self.conversation = inConversation;
    }
    return self;
}

-(IBAction)acceptCall:(id)sender
{
    [[SessionManager sharedSessionManager] answerCallForConversation:self.conversation];
}

-(IBAction)declineCall:(id)sender
{
    [[SessionManager sharedSessionManager] endCallForConversation:self.conversation];
}

- (IBAction)toggleSilent:(id)sender 
{
    [[SoundManager sharedSoundsManager] stopCallingSound];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    HOPContact* contact = [self.conversation getParticipants][0];
    HOPIdentity* identity = [contact getDefaultIdentity];
    
    self.labelCallType.text = [self.conversation.currentCall hasVideo] ? NSLocalizedString(@"Video call from", nil) : NSLocalizedString(@"Audio call from", nil);
    
    self.buttonAccept.imageView.image = [self.conversation.currentCall hasVideo] ? [UIImage imageNamed:@"video_indicator_white_big.png"] : [UIImage imageNamed:@"handset_accept_icon.png"];
    
    self.labelCaller.text = identity.name;
    
    if ([identity.profileURL length] > 0)
    {
        NSURL* url = [NSURL URLWithString:identity.profileURL];
        [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
    }
    
    HOPAvatar* avatar = [identity getAvatarForWidth:[NSNumber numberWithFloat:self.imageViewCallerAvatar.frame.size.width] height:[NSNumber numberWithFloat:self.imageViewCallerAvatar.frame.size.height]];

    if (avatar && avatar.avatarImage.image)
    {
        [self.imageViewCallerAvatar setImage:[UIImage imageWithData:avatar.avatarImage.image]];
    }
    [self.webView.layer setCornerRadius:5.0];

    [self.imageViewLogo.layer setCornerRadius:5.0];
    [self.imageViewLogo setClipsToBounds:YES];
    
    [UIView animateWithDuration:1.5
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.imageViewLogo.alpha = 0.1;
                     }
                     completion:NULL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ================================================================================================
// UIWebView delegate
// ================================================================================================
#pragma mark - UIWebView delegate
-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelTrace, @"Failed loading a caller web profile with an error: %@", [error description]);
}


@end
