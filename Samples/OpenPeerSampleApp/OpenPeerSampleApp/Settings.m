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
#import "SBJsonParser.h"

#define archiveTelnetLogger @"archiveTelnetLogger"
#define archiveOutgoingTelnetLogger @"archiveOutgoingTelnetLogger"
#define archiveStdOutLogger @"archiveStdOutLogger"
#define archiveEnabled @"enabled"
#define archiveServer @"server"
#define archiveColorized @"colorized"

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
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveStdOutLogger])
            self.enabledStdLogger = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveStdOutLogger] boolValue];
        
        self.appModulesLoggerLevel =[[[NSUserDefaults standardUserDefaults] objectForKey:archiveModulesLogLevels] mutableCopy];
        
        if (!self.appModulesLoggerLevel)
            self.appModulesLoggerLevel = [[NSMutableDictionary alloc] init];
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

#define archiveTelnetLogger @"archiveTelnetLogger"
#define archiveOutgoingTelnetLogger @"archiveOutgoingTelnetLogger"
#define archiveStdOutLogger @"archiveStdOutLogger"

- (NSString *)getArchiveKeyForLoggerType:(LoggerTypes)type
{
    NSString *key= nil;
    
    switch (type)
    {
        case LOGGER_STD_OUT:
            key = archiveStdOutLogger;
            break;
            
        case LOGGER_TELNET:
            key = archiveStdOutLogger;
            break;
            
        case LOGGER_OUTGOING_TELNET:
            key = archiveStdOutLogger;
            break;
            
        default:
            break;
    }
    return key;
}

- (void) enable:(BOOL) enable logger:(LoggerTypes) type
{
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveEnabled];
        [self setBool:enable key:key];
    }
}

- (BOOL) isLoggerEnabled:(LoggerTypes) type
{
    BOOL ret = NO;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveEnabled];
        ret = [self getBool:key];
    }
    
    return ret;
}

- (void) setServerOrPort:(NSString*) server logger:(LoggerTypes) type
{
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveServer];
        [self setString:server key:key];
    }
}

- (NSString*) getServerPortForLogger:(LoggerTypes) type
{
    NSString* ret = nil;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveServer];
        ret = [self getString:key];
    }
    
    return ret;
}

- (void) setColorizedOutput:(BOOL) colorized logger:(LoggerTypes) type
{
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveColorized];
        [self setBool:colorized key:key];
    }
}

- (BOOL) isColorizedOutputForLogger:(LoggerTypes) type
{
    BOOL ret = NO;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveColorized];
        ret = [self getBool:key];
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

- (NSString*) getOuterFrameURL
{
    return [self getString:@"outerFrameURL"];
}

- (NSString*) getNamespaceGrantServiceURL
{
    return [self getString:@"namespaceGrantServiceURL"];
}

- (NSString*) getIdentityProviderDomain
{
    return [self getString:@"identityProviderDomain"];
}

- (NSString*) getIdentityFederateBaseURI
{
    return [self getString:@"identityFederateBaseURI"];
}

- (NSString*) getLockBoxServiceDomain
{
    return [self getString:@"lockBoxServiceDomain"];
}

- (NSString*) getDefaultOutgoingTelnetServer
{
    return [self getString:@"defaultOutgoingTelnetServer"];
}

- (NSString*) getString:(NSString*) key
{
    NSString* ret = nil;
    
    if ([key length] > 0)
    {
        ret = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    }
    
    return ret;
}

- (long) getInt:(NSString*) key
{
    long ret = 0;
    
    if ([key length] > 0)
    {
        NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        ret = number.longValue;
    }
    
    return ret;
}

- (unsigned long) getUInt:(NSString*) key
{
    unsigned long ret = 0;
    
    if ([key length] > 0)
    {
        NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        ret = number.unsignedLongValue;
    }
    
    return ret;
}

- (BOOL) getBool:(NSString*) key
{
    BOOL ret = NO;
    
    if ([key length] > 0)
    {
        NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        ret = number.boolValue;
    }
    
    return ret;
}

- (float) getFloat:(NSString*) key
{
    float ret = 0.0;
    
    if ([key length] > 0)
    {
        NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        ret = number.floatValue;
    }
    
    return ret;
}

- (double) getDouble:(NSString*) key
{
    double ret = NO;
    
    if ([key length] > 0)
    {
        NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        ret = number.doubleValue;
    }
    
    return ret;
}

- (void) setString:(NSString*) value key:(NSString*) key
{
    if ([key length] > 0 && [value length] > 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) setInt:(long) value key:(NSString*) key
{
    if ([key length] > 0)
    {
        NSNumber* number = [NSNumber numberWithLong:value];
        if (number)
        {
            [[NSUserDefaults standardUserDefaults] setObject:number forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
- (void) setUInt:(unsigned long) value key:(NSString*) key
{
    if ([key length] > 0)
    {
        NSNumber* number = [NSNumber numberWithUnsignedLong:value];
        if (number)
        {
            [[NSUserDefaults standardUserDefaults] setObject:number forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
- (void) setBool:(BOOL) value key:(NSString*) key
{
    if ([key length] > 0)
    {
        NSNumber* number = [NSNumber numberWithBool:value];
        if (number)
        {
            [[NSUserDefaults standardUserDefaults] setObject:number forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
- (void) setFloat:(float) value key:(NSString*) key
{
    if ([key length] > 0)
    {
        NSNumber* number = [NSNumber numberWithFloat:value];
        if (number)
        {
            [[NSUserDefaults standardUserDefaults] setObject:number forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
- (void) setDouble:(double) value key:(NSString*) key
{
    if ([key length] > 0)
    {
        NSNumber* number = [NSNumber numberWithDouble:value];
        if (number)
        {
            [[NSUserDefaults standardUserDefaults] setObject:number forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void) clearForKey:(NSString*) key
{
    if ([key length] > 0)
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) storeSettingsFromPath:(NSString*) path
{
    NSDictionary* customerSpecificDict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if ([customerSpecificDict count] > 0)
    {
        for (NSString* key in [customerSpecificDict allKeys])
        {
            id value = [customerSpecificDict objectForKey:key];
            if ([value isKindOfClass:[NSDictionary class]])
            {
                for (NSString* subKey in [((NSDictionary*)value) allKeys])
                    [[Settings sharedSettings] setString:[((NSDictionary*)value) objectForKey:subKey] key:subKey];
            }
            else if ([value isKindOfClass:[NSString class]])
            {
                [[Settings sharedSettings] setString:value key:key];
            }
        }
    }
}

- (BOOL) isAppDataSet
{
    BOOL ret = YES;
    
    ret &= [[self getString:archiveAppId] length] != 0;
    ret &= [[self getString:archiveAppIdSharedSecret] length] != 0;
    ret &= [[self getString:archiveAppName] length] != 0;
    ret &= [[self getString:archiveAppURL] length] != 0;
    ret &= [[self getString:archiveAppImageURL] length] != 0;
    
#ifdef APNS_ENABLED
    ret &= [[self getString:archiveAppImageURL] length] != 0;
#endif
    return ret;
}

- (BOOL) isLoginSettingsSet
{
    BOOL ret = YES;
    
    ret &= [[self getOuterFrameURL] length] != 0;
    ret &= [[self getIdentityFederateBaseURI] length] != 0;
    ret &= [[self getIdentityProviderDomain] length] != 0;
    ret &= [[self getNamespaceGrantServiceURL] length] != 0;
    ret &= [[self getLockBoxServiceDomain] length] != 0;
    ret &= [[self getDefaultOutgoingTelnetServer] length] != 0;
    
    return ret;
}
@end
