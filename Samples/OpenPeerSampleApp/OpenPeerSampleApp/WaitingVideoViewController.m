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

#import "WaitingVideoViewController.h"
#import "Session.h"
#import "SessionManager.h"
#import <OpenPeerSDK/HOPRolodexContact+External.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAvatar.h>
#import <OpenPeerSDK/HOPImage.h>
#import <OpenPeerSDK/HOPConversationEvent+External.h>
//#import <OpenPeerSDK/HOPParticipants.h>
#import <OpenPeerSDK/HOPAccount.h>
@interface WaitingVideoViewController()

@property (weak, nonatomic) IBOutlet UIImageView *callerImage;
@property (weak, nonatomic) IBOutlet UIImageView *calleeImage;
@property (weak, nonatomic) IBOutlet UIImageView *connectingAnimationImageView;
@property (weak, nonatomic) IBOutlet UILabel *participantName;
@property (weak, nonatomic) IBOutlet UILabel *callerName;
@property (weak, nonatomic) IBOutlet UILabel *callEndedLabel;
@property (weak, nonatomic) IBOutlet UILabel* statusLabel;

@property (weak, nonatomic) Session* session;
-(NSMutableArray*)getAnimationImages;

@end

@implementation WaitingVideoViewController
	
const int CONNECTING_ANIMATION_IMAGES_COUNT = 13;
const int CONNECTING_ANIMATION_IMAGES_IPHONE_COUNT = 29;
const int CONNECTING_ANIMATION_DURATION = 2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithSession:(Session*) inSession
{
    self = [self initWithNibName:@"WaitingVideoViewController" bundle:nil];
    if (self)
    {
        self.session = inSession;
    }
    return self;
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
    
    self.statusLabel.text = self.statusText;
    
    HOPRolodexContact* contact = [self.session.lastConversationEvent getContacts][0];
    self.participantName.text = contact.name;
    self.callerName.text = [[HOPAccount sharedAccount] getFullName];
    
    HOPAvatar* avatar = [contact getAvatarForWidth:[NSNumber numberWithFloat:self.calleeImage.frame.size.width] height:[NSNumber numberWithFloat:self.calleeImage.frame.size.height]];
    
    if (avatar && avatar.avatarImage.image)
    {
        [self.calleeImage setImage:[UIImage imageWithData:avatar.avatarImage.image]];
    }
    
    self.connectingAnimationImageView.animationImages = [self getAnimationImages];
    self.connectingAnimationImageView.animationDuration = CONNECTING_ANIMATION_DURATION;
    self.connectingAnimationImageView.animationRepeatCount = 0; //Repeats indefinitely
    [self.connectingAnimationImageView startAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.connectingAnimationImageView stopAnimating];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


-(NSMutableArray*)getAnimationImages 
{
    NSMutableArray* images = [[NSMutableArray alloc] init];

    for (int i=0; i< CONNECTING_ANIMATION_IMAGES_IPHONE_COUNT; i++)
    {
        if (i < 10)
        {
            [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"iPhone_loader_0000%d.png", i]]];
        }
        else
        {
            [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"iPhone_loader_000%d.png", i]]];
        }
    }
    
    return images;
}

- (IBAction) callHangup:(id)sender
{

    [[SessionManager sharedSessionManager] endCallForSession:self.session];
}
@end
