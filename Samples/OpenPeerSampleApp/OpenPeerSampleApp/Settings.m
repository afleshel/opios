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

#import "Settings.h"
#import "AppConsts.h"
#import "OpenPeer.h"
#import "Logger.h"
#import "CustomerSpecific.h"
#import "SBJsonParser.h"

@interface Settings ()

- (NSString*) getArchiveStringForModule:(Modules) module;
@end

@implementation Settings



/**
 Retrieves singleton object of the Settings.
 @return Singleton object of the Settings.
 */
+ (id) sharedSettings
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

- (id)initSingleton
{
    self = [super init];
    if (self)
    {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaAEC])
            self.isMediaAECOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaAEC] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaAGC])
            self.isMediaAGCOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaAGC] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaNS])
            self.isMediaNSOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveMediaNS] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveRemoteSessionActivationMode])
            self.isRemoteSessionActivationModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveRemoteSessionActivationMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveFaceDetectionMode])
            self.isFaceDetectionModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveFaceDetectionMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveRedialMode])
            self.isRedialModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveRedialMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveStdLogger])
            self.enabledStdLogger = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveStdLogger] boolValue];
        
        self.appModulesLoggerLevel =[[[NSUserDefaults standardUserDefaults] objectForKey:archiveModulesLogLevels] mutableCopy];
        if (!self.appModulesLoggerLevel)
            self.appModulesLoggerLevel = [[NSMutableDictionary alloc] init];
        
        self.telnetLoggerSettings =[[[NSUserDefaults standardUserDefaults] objectForKey:archiveTelnetLogger] mutableCopy];
        if (!self.telnetLoggerSettings)
        {
            self.telnetLoggerSettings = [[NSMutableDictionary alloc] init];
            [self.telnetLoggerSettings setObject:defaultTelnetPort forKey:@"server"];
            [self.telnetLoggerSettings setObject:[NSNumber numberWithBool:YES] forKey:@"colorized"];
        }
        
        self.outgoingTelnetLoggerSettings =[[[NSUserDefaults standardUserDefaults] objectForKey:archiveOutgoingTelnetLogger] mutableCopy];
        if (!self.outgoingTelnetLoggerSettings)
        {
            self.outgoingTelnetLoggerSettings = [[NSMutableDictionary alloc] init];
            [self.outgoingTelnetLoggerSettings setObject:defaultOutgoingTelnetServer forKey:@"server"];
            [self.outgoingTelnetLoggerSettings setObject:[NSNumber numberWithBool:YES] forKey:@"colorized"];
        }
        
        self.loginSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveLoginSettings] mutableCopy];
        if (!self.loginSettings)
        {
            self.loginSettings = [[NSMutableDictionary alloc] init];
            /*[self.loginSettings setObject:outerFrameURL forKey:@"outerFrameURL"];
            [self.loginSettings setObject:namespaceGrantServiceURL forKey:@"namespaceGrantServiceURL"];
            [self.loginSettings setObject:identityProviderDomain forKey:@"identityProviderDomain"];
            [self.loginSettings setObject:identityFederateBaseURI forKey:@"identityFederateBaseURI"];
            [self.loginSettings setObject:lockBoxServiceDomain forKey:@"lockBoxServiceDomain"];
            //[self.loginSettings setObject:defaultOutgoingTelnetServer forKey:@"defaultOutgoingTelnetServer"];*/
        }
    }
    return self;
}

- (void) enableMediaAEC:(BOOL) enable
{
    self.isMediaAECOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isMediaAECOn] forKey:archiveMediaAEC];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void) enableMediaAGC:(BOOL) enable
{
    self.isMediaAGCOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isMediaAGCOn] forKey:archiveMediaAGC];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void) enableMediaNS:(BOOL) enable
{
    self.isMediaNSOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isMediaNSOn] forKey:archiveMediaNS];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) enableRemoteSessionActivationMode:(BOOL) enable
{
    self.isRemoteSessionActivationModeOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isRemoteSessionActivationModeOn] forKey:archiveRemoteSessionActivationMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) enableFaceDetectionMode:(BOOL) enable
{
    self.isFaceDetectionModeOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isFaceDetectionModeOn] forKey:archiveFaceDetectionMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) enableRedialMode:(BOOL) enable
{
    self.isRedialModeOn = enable;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isRedialModeOn] forKey:archiveRedialMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) enable:(BOOL) enable logger:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_STD_OUT:
            self.enabledStdLogger = enable;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.enabledStdLogger] forKey:archiveStdLogger];
            break;
            
        case LOGGER_TELNET:
            [self.telnetLoggerSettings setObject:[NSNumber numberWithBool:enable] forKey:@"enabled"];
            [[NSUserDefaults standardUserDefaults] setObject:self.telnetLoggerSettings forKey:archiveTelnetLogger];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            [self.outgoingTelnetLoggerSettings setObject:[NSNumber numberWithBool:enable] forKey:@"enabled"];
            [[NSUserDefaults standardUserDefaults] setObject:self.outgoingTelnetLoggerSettings forKey:archiveOutgoingTelnetLogger];
            break;
            
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    //[Logger start:enable logger:type];
}

- (BOOL) isLoggerEnabled:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_STD_OUT:
            return self.enabledStdLogger;
            break;
            
        case LOGGER_TELNET:
            return [[self.telnetLoggerSettings objectForKey:@"enabled"] boolValue];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            return [[self.outgoingTelnetLoggerSettings objectForKey:@"enabled"] boolValue];
            break;
            
        default:
            break;
    }
    return NO;
}

- (void) setServerOrPort:(NSString*) server logger:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_TELNET:
            [self.telnetLoggerSettings setObject:server forKey:@"server"];
            [[NSUserDefaults standardUserDefaults] setObject:self.telnetLoggerSettings forKey:archiveTelnetLogger];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            [self.outgoingTelnetLoggerSettings setObject:server forKey:@"server"];
            [[NSUserDefaults standardUserDefaults] setObject:self.outgoingTelnetLoggerSettings forKey:archiveOutgoingTelnetLogger];
            
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) getServerPortForLogger:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_TELNET:
            return [self.telnetLoggerSettings objectForKey:@"server"];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            return [self.outgoingTelnetLoggerSettings objectForKey:@"server"];
            break;
            
        default:
            break;
    }
    return nil;
}

- (void) setColorizedOutput:(BOOL) colorized logger:(LoggerTypes) type
{
    switch (type)
    {
        case LOGGER_TELNET:
            [self.telnetLoggerSettings setObject:[NSNumber numberWithBool:colorized] forKey:@"colorized"];
            [[NSUserDefaults standardUserDefaults] setObject:self.telnetLoggerSettings forKey:archiveTelnetLogger];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            [self.outgoingTelnetLoggerSettings setObject:[NSNumber numberWithBool:colorized] forKey:@"colorized"];
            [[NSUserDefaults standardUserDefaults] setObject:self.outgoingTelnetLoggerSettings forKey:archiveOutgoingTelnetLogger];
            break;
            
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) isColorizedOutputForLogger:(LoggerTypes) type
{
    BOOL ret = NO;
    switch (type)
    {
        case LOGGER_TELNET:
            ret = [[self.telnetLoggerSettings objectForKey:@"colorized"] boolValue];
            break;
            
        case LOGGER_OUTGOING_TELNET:
            ret = [[self.outgoingTelnetLoggerSettings objectForKey:@"colorized"] boolValue];
            break;
            
        default:
            break;
    }
    return ret;
}

- (HOPLoggerLevels) getLoggerLevelForAppModule:(Modules) module
{
    HOPLoggerLevels ret = HOPLoggerLevelNone;
    
    NSString* archiveString = [self getArchiveStringForModule:module];
    if ([archiveString length] > 0)
        ret = [self getLoggerLevelForAppModuleKey:archiveString];
    
    return ret;
}

- (HOPLoggerLevels) getLoggerLevelForAppModuleKey:(NSString*) moduleKey
{
    HOPLoggerLevels ret = HOPLoggerLevelNone;
    
    NSNumber* retNumber = [self.appModulesLoggerLevel objectForKey:moduleKey];
    if (retNumber)
        ret = (HOPLoggerLevels)[retNumber intValue];
    
    return ret;
}

- (void) setLoggerLevel:(HOPLoggerLevels) level forAppModule:(Modules) module
{
    NSString* archiveString = [self getArchiveStringForModule:module];
    [self.appModulesLoggerLevel setObject:[NSNumber numberWithInt:level] forKey:archiveString];
    [self saveModuleLogLevels];
}

- (void) saveModuleLogLevels
{
    [[NSUserDefaults standardUserDefaults] setObject:self.appModulesLoggerLevel forKey:archiveModulesLogLevels];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) getStringForModule:(Modules) module
{
    NSString* ret = nil;
    
    switch (module)
    {
        case MODULE_APPLICATION:
            ret = @"Application";
            break;
            
        case MODEULE_SDK:
            ret = @"SDK (iOS)";
            break;

        case MODULE_MEDIA:
            ret = @"SDK (media)";
            break;

        case MODULE_WEBRTC:
            ret = @"SDK (webRTC)";
            break;

        case MODULE_CORE:
            ret = @"SDK (core)";
            break;

        case MODULE_STACK_MESSAGE:
            ret = @"SDK (messages)";
            break;

        case MODULE_STACK:
            ret = @"SDK (stack)";
            break;

        case MODULE_SERVICES:
            ret = @"SDK (services)";
            break;

        case MODULE_SERVICES_WIRE:
            ret = @"SDK (services packets)";
            break;

        case MODULE_SERVICES_ICE:
            ret = @"SDK (STUN/ICE)";
            break;

      case MODULE_SERVICES_TURN:
            ret = @"SDK (TURN)";
            break;

        case MODULE_SERVICES_RUDP:
            ret = @"SDK (RUDP)";
            break;

        case MODULE_SERVICES_HTTP:
            ret = @"SDK (HTTP)";
            break;

        case MODULE_SERVICES_MLS:
            ret = @"SDK (MLS)";
            break;

        case MODULE_SERVICES_TCP:
            ret = @"SDK (TCP Messaging)";
            break;

        case MODULE_SERVICES_TRANSPORT:
            ret = @"SDK (Transport Stream)";
            break;

        case MODULE_ZSLIB:
            ret = @"SDK (zsLib)";
            break;
            
        case MODULE_JAVASCRIPT:
            ret = @"JavaScript";
            break;
            default:
            break;
    }
    
    return ret;
}

- (NSString*) getArchiveStringForModule:(Modules) module
{
    NSString* ret = nil;
    
    switch (module)
    {
        case MODULE_APPLICATION:
            ret = moduleApplication;
            break;
            
        case MODEULE_SDK:
            ret = moduleSDK;
            break;
            
        case MODULE_MEDIA:
            ret = moduleMedia;
            break;
            
        case MODULE_WEBRTC:
            ret = moduleWebRTC;
            break;
            
        case MODULE_CORE:
            ret = moduleCore;
            break;
            
        case MODULE_STACK_MESSAGE:
            ret = moduleStackMessage;
            break;
            
        case MODULE_STACK:
            ret = moduleStack;
            break;
            
        case MODULE_SERVICES:
            ret = moduleServices;
            break;
            
        case MODULE_SERVICES_WIRE:
            ret = moduleServicesWire;
            break;

        case MODULE_SERVICES_ICE:
            ret = moduleServicesIce;
            break;

        case MODULE_SERVICES_TURN:
          ret = moduleServicesTurn;
          break;

        case MODULE_SERVICES_RUDP:
          ret = moduleServicesRudp;
          break;

        case MODULE_SERVICES_HTTP:
            ret = moduleServicesHttp;
            break;

        case MODULE_SERVICES_MLS:
            ret = moduleServicesMls;
            break;

        case MODULE_SERVICES_TCP:
            ret = moduleServicesTcp;
            break;

        case MODULE_SERVICES_TRANSPORT:
            ret = moduleServicesTransport;
            break;

        case MODULE_ZSLIB:
            ret = moduleZsLib;
            break;
            
        case MODULE_JAVASCRIPT:
            ret = moduleJavaScript;
            break;
            
            default:
            break;
    }
    return ret;
}

- (NSString*) getStringForLogLevel:(HOPLoggerLevels) level
{
    switch (level)
    {
        case HOPLoggerLevelNone:
            return @"NONE";
            break;
            
        case HOPLoggerLevelBasic:
            return @"BASIC";
            break;
            
        case HOPLoggerLevelDetail:
            return @"DETAIL";
            break;
            
        case HOPLoggerLevelDebug:
            return @"DEBUG";
            break;
            
        case HOPLoggerLevelTrace:
            return @"TRACE";
            break;

        case HOPLoggerLevelInsane:
            return @"INSANE";
            break;

        default:
            break;
    }
    return nil;
}

- (void) saveDefaultsLoggerSettings
{
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_APPLICATION];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_SERVICES];
    [self setLoggerLevel:HOPLoggerLevelDebug forAppModule:MODULE_SERVICES_WIRE];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_SERVICES_ICE];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_SERVICES_TURN];
    [self setLoggerLevel:HOPLoggerLevelDebug forAppModule:MODULE_SERVICES_RUDP];
    [self setLoggerLevel:HOPLoggerLevelDebug forAppModule:MODULE_SERVICES_HTTP];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_SERVICES_MLS];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_SERVICES_TCP];
    [self setLoggerLevel:HOPLoggerLevelDebug forAppModule:MODULE_SERVICES_TRANSPORT];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_CORE];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_STACK_MESSAGE];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_STACK];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_ZSLIB];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODEULE_SDK];
    [self setLoggerLevel:HOPLoggerLevelDetail forAppModule:MODULE_WEBRTC];
    [self setLoggerLevel:HOPLoggerLevelDetail forAppModule:MODULE_MEDIA];
    [self setLoggerLevel:HOPLoggerLevelTrace forAppModule:MODULE_JAVASCRIPT];
    
    [self setColorizedOutput:YES logger:LOGGER_STD_OUT];
    [self setColorizedOutput:YES logger:LOGGER_TELNET];
    [self setColorizedOutput:YES logger:LOGGER_OUTGOING_TELNET];
    
    [self enable:YES logger:LOGGER_STD_OUT];
    [self enable:YES logger:LOGGER_TELNET];
    [self enable:YES logger:LOGGER_OUTGOING_TELNET];
}

- (void) setOuterFrameURL:(NSString*) inOuterFrameURL
{
    if ([inOuterFrameURL length] > 0)
    {
        [self.loginSettings setObject:inOuterFrameURL forKey:@"outerFrameURL"];
        [self saveLoginSettings];
    }
}

- (NSString*) getOuterFrameURL
{
    return [self.loginSettings objectForKey:@"outerFrameURL"];
}

- (void) setNamespaceGrantServiceURL:(NSString*) inNamespaceGrantServiceURL
{
    [self.loginSettings setObject:inNamespaceGrantServiceURL forKey:@"namespaceGrantServiceURL"];
    [self saveLoginSettings];
}

- (NSString*) getNamespaceGrantServiceURL
{
    return [self.loginSettings objectForKey:@"namespaceGrantServiceURL"];
}

- (void) setIdentityProviderDomain:(NSString*) inIdentityProviderDomain
{
    [self.loginSettings setObject:inIdentityProviderDomain forKey:@"identityProviderDomain"];
    [self saveLoginSettings];
}

- (NSString*) getIdentityProviderDomain
{
    return [self.loginSettings objectForKey:@"identityProviderDomain"];
}

- (void) setIdentityFederateBaseURI:(NSString*) inIdentityFederateBaseURI
{
    [self.loginSettings setObject:inIdentityFederateBaseURI forKey:@"identityFederateBaseURI"];
    [self saveLoginSettings];
}

- (NSString*) getIdentityFederateBaseURI
{
    return [self.loginSettings objectForKey:@"identityFederateBaseURI"];
}

- (void) setLockBoxServiceDomain:(NSString*) inLockBoxServiceDomain
{
    [self.loginSettings setObject:inLockBoxServiceDomain forKey:@"lockBoxServiceDomain"];
    [self saveLoginSettings];
}

- (NSString*) getLockBoxServiceDomain
{
    return [self.loginSettings objectForKey:@"lockBoxServiceDomain"];
}

//- (void) setDefaultOutgoingTelnetServer:(NSString*) inDefaultOutgoingTelnetServer
//{
//    [self.loginSettings setObject:inDefaultOutgoingTelnetServer forKey:@"defaultOutgoingTelnetServer"];
//    [self saveLoginSettings];
//}
//
//- (NSString*) getDefaultOutgoingTelnetServer
//{
//    return [self.loginSettings objectForKey:@"defaultOutgoingTelnetServer"];
//}

- (void) saveLoginSettings
{
    [[NSUserDefaults standardUserDefaults] setObject:self.loginSettings forKey:archiveLoginSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) setLoginSettingsFromJSON:(NSString *)loginSettingsJSON
{
    BOOL ret = NO;
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* inputDictionary = [parser objectWithString: loginSettingsJSON];
    if ([inputDictionary count] > 0)
    {
        [self setOuterFrameURL:[inputDictionary objectForKey:@"outerFrameURL"]];
        [self setNamespaceGrantServiceURL:[inputDictionary objectForKey:@"namespaceGrantServiceURL"]];
        [self setIdentityProviderDomain:[inputDictionary objectForKey:@"identityProviderDomain"]];
        [self setIdentityFederateBaseURI:[inputDictionary objectForKey:@"identityFederateBaseURI"]];
        [self setLockBoxServiceDomain:[inputDictionary objectForKey:@"lockBoxServiceDomain"]];
        //[self setDefaultOutgoingTelnetServer:[inputDictionary objectForKey:@"defaultOutgoingTelnetServer"]];
        [self setServerOrPort:[inputDictionary objectForKey:@"defaultOutgoingTelnetServer"] logger:LOGGER_OUTGOING_TELNET];
        
        ret = YES;
    }
    
    return ret;
}
- (BOOL) isLoginSettingsSet
{
    return [self.loginSettings count] > 0;
}
@end
