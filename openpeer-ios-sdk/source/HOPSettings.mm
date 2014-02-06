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

#import "HOPSettings_Internal.h"
#import "OpenPeerSettingsDelegate.h"
#import <zsLib/Log.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@implementation HOPSettings

+ (id)sharedSettings
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void) setupWithDelegate:(id<HOPSettingsDelegate>) inDelegate
{
    openPeerSettingsDelegatePtr = OpenPeerSettingsDelegate::create(inDelegate);
    ISettings::setup(openPeerSettingsDelegatePtr);
}

- (BOOL) applySettings:(NSString*)jsonSettings
{
    BOOL ret = NO;
    if ([jsonSettings length] > 0)
    {
        ret = ISettings::apply([jsonSettings UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Passed empty JSON file."]);
    }
    
    return ret;
}

- (void) applyDefaults
{
    ISettings::applyDefaults();
}


- (void) deleteLocalDelegate
{
    openPeerSettingsDelegatePtr.reset();
}


- (String) log:(NSString*) message
{
    return String("HOPSettings: ") + [message UTF8String];
}


@end