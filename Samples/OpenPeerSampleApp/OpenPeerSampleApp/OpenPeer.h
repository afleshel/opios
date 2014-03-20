/*
 
 Copyright (c) 2012, SMB Phone Inc.
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

#import <Foundation/Foundation.h>
#import <OpenPeerSDK/HOPTypes.h>
#import "Settings.h"
#import "Delegates.h"

@class CallDelegate;
@class StackDelegate;
@class MediaEngineDelegate;
@class ConversationThreadDelegate;
@class AccountDelegate;
@class MainViewController;
@class IdentityDelegate;
@class IdentityLookupDelegate;
@class CacheDelegate;
@class BackgroundingDelegate;

@interface OpenPeer : NSObject<HTTPDownloaderDelegate>

@property (nonatomic,strong) CallDelegate *callDelegate;
@property (nonatomic,strong) StackDelegate *stackDelegate;
@property (nonatomic,strong) MediaEngineDelegate *mediaEngineDelegate;
@property (nonatomic,strong) ConversationThreadDelegate *conversationThreadDelegate;
@property (nonatomic,strong) AccountDelegate *accountDelegate;
@property (nonatomic,strong) MainViewController *mainViewController;
@property (nonatomic,strong) IdentityDelegate *identityDelegate;
@property (nonatomic,strong) IdentityLookupDelegate *identityLookupDelegate;
@property (nonatomic,strong) CacheDelegate *cacheDelegate;
@property (nonatomic,strong) BackgroundingDelegate *backgroundingDelegate;

@property (nonatomic,strong) NSString *authorizedApplicationId;

@property (nonatomic) BOOL isRemoteSessionActivationModeOn;
@property (nonatomic) BOOL isFaceDetectionModeOn;
@property (nonatomic) BOOL isRedialModeOn;

@property (nonatomic) BOOL isLocalTelnetOn;
@property (nonatomic) BOOL isRemoteTelnetOn;

@property (nonatomic) BOOL appEnteredBackground;
@property (nonatomic) BOOL appEnteredForeground;

@property (nonatomic, strong) NSString* deviceId;
@property (nonatomic, strong) NSString* deviceToken;

@property UIBackgroundTaskIdentifier backgroundingTaskId;

+ (id) sharedOpenPeer;

- (void) preSetup;
- (void) finishPreSetup;
- (void) setup;
- (void) shutdown;
- (void) shutdownCleanup;
@end
