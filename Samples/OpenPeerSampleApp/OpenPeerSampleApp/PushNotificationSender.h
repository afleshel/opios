/*
 
 Copyright (c) 2014, Hookflash Inc.
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
#import "Delegates.h"

@class HOPMessageRecord;
@class HOPConversation;

@interface PushNotificationSender : NSObject<HTTPDownloaderDelegate>

@property (nonatomic, copy) NSData* deviceToken;
@property (nonatomic, copy) NSString* peerURI;
@property (nonatomic, copy, getter=getLocation) NSString* location;
@property  (nonatomic) int pushesToSend;

- (void) prepare;
- (void) registerDeviceToken:(NSData*) inDeviceToken peerURI:(NSString*) inPeerURI;

- (void) sendPushNotificationMessage:(NSString*) message outgoingCall:(BOOL) outgoingCall recipients:(NSArray*) recipients;
- (void) sendRichPushNotificationMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipients:(NSArray*) recipients;

- (NSString*) getListOfRecipientsFromPeerURIsArray:(NSArray*) array;
- (NSDictionary*) createPushMessage:(NSString*) message missedCall:(BOOL) missedCall recipients:(NSArray*) recipients;
- (NSDictionary*) createRichPushMessage:(HOPMessageRecord*) message conversation:(HOPConversation*) conversation recipient:(HOPRolodexContact*) recipient recipients:(NSArray*) recipients;

- (NSArray*) getDeviceTokensForContact:(HOPRolodexContact*) contact;
- (void) requestDeviceTokenForPeerURI:(NSString*) peerURI;
- (void) registerDeviceTokenWithOpenPeer;
- (void) onDeviceTokenReceivedForPeerURI:(NSString*) peerURI;

- (void) onMessageSent:(NSString*) messageID;
@end
