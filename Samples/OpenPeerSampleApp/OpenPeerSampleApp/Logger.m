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

#import "Logger.h"
#import "AppConsts.h"
#import "OpenPeer.h"

#import "OpenpeerSDK/HOPLogger.h"

@implementation Logger

+ (void) setLogLevels
{
    //For each system you can choose log level from HOPClientLogLevelNone (turned off) to HOPClientLogLevelInsane (most detail).
    [HOPLogger setLogLevelbyName:moduleApplication level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleApplication]];
    [HOPLogger setLogLevelbyName:moduleServices level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServices]];
    [HOPLogger setLogLevelbyName:moduleServicesWire level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesWire]];
    [HOPLogger setLogLevelbyName:moduleServicesIce level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesIce]];
    [HOPLogger setLogLevelbyName:moduleServicesTurn level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesTurn]];
    [HOPLogger setLogLevelbyName:moduleServicesRudp level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesRudp]];
    [HOPLogger setLogLevelbyName:moduleServicesHttp level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesHttp]];
    [HOPLogger setLogLevelbyName:moduleServicesMls level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesMls]];
    [HOPLogger setLogLevelbyName:moduleServicesTcp level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesTcp]];
    [HOPLogger setLogLevelbyName:moduleServicesTransport level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleServicesTransport]];
    [HOPLogger setLogLevelbyName:moduleCore level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleCore]];
    [HOPLogger setLogLevelbyName:moduleStackMessage level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleStackMessage]];
    [HOPLogger setLogLevelbyName:moduleStack level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleStack]];
    [HOPLogger setLogLevelbyName:moduleWebRTC level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleWebRTC]];
    [HOPLogger setLogLevelbyName:moduleZsLib level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleZsLib]];
    [HOPLogger setLogLevelbyName:moduleSDK level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleSDK]];
    [HOPLogger setLogLevelbyName:moduleMedia level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleMedia]];
    [HOPLogger setLogLevelbyName:moduleJavaScript level:[[Settings sharedSettings] getLoggerLevelForAppModuleKey:moduleJavaScript]];
}


+ (void) startStdLogger:(BOOL) start
{
    if (start)
    {
        [HOPLogger installStdOutLogger:NO];
    }
    else
        [HOPLogger uninstallStdOutLogger];
}

/**
 Sets log levels and starts the logger.
 */
+ (void) startTelnetLogger:(BOOL) start
{
    if (start)
    {
        NSString* port =[[Settings sharedSettings] getServerPortForLogger:LOGGER_TELNET];
        BOOL colorized = [[Settings sharedSettings] isColorizedOutputForLogger:LOGGER_TELNET];
        if ([port length] > 0)
            [HOPLogger installTelnetLogger:[port intValue] maxSecondsWaitForSocketToBeAvailable:60 colorizeOutput:colorized];
    }
    else
    {
        [HOPLogger uninstallTelnetLogger];
    }
}

+ (void) startOutgoingTelnetLogger:(BOOL) start
{
    if (start)
    {
        NSString* server =[[Settings sharedSettings] getServerPortForLogger:LOGGER_OUTGOING_TELNET];
        BOOL colorized = [[Settings sharedSettings] isColorizedOutputForLogger:LOGGER_OUTGOING_TELNET];
        if ([server length] > 0)
            [HOPLogger installOutgoingTelnetLogger:server colorizeOutput:colorized stringToSendUponConnection:[[OpenPeer sharedOpenPeer] authorizedApplicationId]];
    }
    else
    {
        [HOPLogger uninstallOutgoingTelnetLogger];
    }
}

+ (void) startAllSelectedLoggers
{
    [self setLogLevels];
    [self startStdLogger:[[Settings sharedSettings] isLoggerEnabled:LOGGER_STD_OUT]];
    [self startTelnetLogger:[[Settings sharedSettings] isLoggerEnabled:LOGGER_TELNET]];
    [self startOutgoingTelnetLogger:[[Settings sharedSettings] isLoggerEnabled:LOGGER_OUTGOING_TELNET]];
}


+ (void) start:(BOOL) start logger:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_STD_OUT:
            [self startStdLogger:start];
            break;
            
        case LOGGER_TELNET:
            [self startTelnetLogger:start];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            [self startOutgoingTelnetLogger:start];
            break;
            
        default:
            break;
    }
    
}

+ (void) startTelnetLoggerOnStartUp
{
    [[Settings sharedSettings] saveDefaultsLoggerSettings];
    [Logger startAllSelectedLoggers];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OpenPeer" message:@"Logger is started! Almost all log levels are set to trace. If you want to change that, you can do that from the settings." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

@end
