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
#import "Utility.h"
#import <OpenPeerSDK/HOPSettings.h>
#import <OpenPeerSDK/HOPUtility.h>
#import <OpenPeerSDK/HOPCache.h>
#import <OpenPeerSDK/HOPHomeUser.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import "HTTPDownloader.h"

@interface Settings ()
@property (nonatomic, strong) HTTPDownloader* settingsDownloader;
@property (nonatomic) int timeoutCounter;

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
        if ([[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaAEC])
            self.isMediaAECOn = [[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaAEC] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaAGC])
            self.isMediaAGCOn = [[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaAGC] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaNS])
            self.isMediaNSOn = [[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyMediaNS] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveRemoteSessionActivationMode])
            self.isRemoteSessionActivationModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveRemoteSessionActivationMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveFaceDetectionMode])
            self.isFaceDetectionModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveFaceDetectionMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:archiveRedialMode])
            self.isRedialModeOn = [[[NSUserDefaults standardUserDefaults] objectForKey:archiveRedialMode] boolValue];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyStdOutLogger])
            self.enabledStdLogger = [[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyStdOutLogger] boolValue];
        
        self.appModulesLoggerLevel =[[[NSUserDefaults standardUserDefaults] objectForKey:archiveModulesLogLevels] mutableCopy];
        
        if (!self.appModulesLoggerLevel)
            self.appModulesLoggerLevel = [[NSMutableDictionary alloc] init];
        
        self.timeoutCounter = 0;
    }
    return self;
}

- (void) enableMediaAEC:(BOOL) enable
{
    self.isMediaAECOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isMediaAECOn] key:settingsKeyMediaAEC];
}
- (void) enableMediaAGC:(BOOL) enable
{
    self.isMediaAGCOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isMediaAGCOn] key:settingsKeyMediaAGC];
}
- (void) enableMediaNS:(BOOL) enable
{
    self.isMediaNSOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isMediaNSOn] key:settingsKeyMediaNS];
}

- (void) enableRemoteSessionActivationMode:(BOOL) enable
{
    self.isRemoteSessionActivationModeOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isRemoteSessionActivationModeOn] key:archiveRemoteSessionActivationMode];
}

- (void) enableFaceDetectionMode:(BOOL) enable
{
    self.isFaceDetectionModeOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isFaceDetectionModeOn] key:archiveFaceDetectionMode];
}

- (void) enableRedialMode:(BOOL) enable
{
    self.isRedialModeOn = enable;
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:self.isRedialModeOn] key:archiveRedialMode];
}


- (NSString *)getArchiveKeyForLoggerType:(LoggerTypes)type
{
    NSString *key= nil;
    
    switch (type)
    {
        case LOGGER_STD_OUT:
            key = settingsKeyStdOutLogger;
            break;
            
        case LOGGER_TELNET:
            key = settingsKeyTelnetLogger;
            break;
            
        case LOGGER_OUTGOING_TELNET:
            key = settingsKeyOutgoingTelnetLogger;
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
        [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:enable] key:key];
    }
}

- (BOOL) isLoggerEnabled:(LoggerTypes) type
{
    BOOL ret = NO;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveEnabled];
        ret = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    }
    
    return ret;
}

- (void) setServerOrPort:(NSString*) server logger:(LoggerTypes) type
{
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        //key = [key stringByAppendingString:archiveServer];
        [[HOPSettings sharedSettings] storeSettingsObject:server key:key];
    }
}

- (NSString*) getServerPortForLogger:(LoggerTypes) type
{
    NSString* ret = nil;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        //key = [key stringByAppendingString:archiveServer];
        ret = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    }
    
    return ret;
}

- (void) setColorizedOutput:(BOOL) colorized logger:(LoggerTypes) type
{
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveColorized];
        [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:colorized] key:key];
    }
}

- (BOOL) isColorizedOutputForLogger:(LoggerTypes) type
{
    BOOL ret = NO;
    NSString* key = [self getArchiveKeyForLoggerType:type];
    
    if ([key length] > 0)
    {
        key = [key stringByAppendingString:archiveColorized];
        ret = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    }
    
    return ret;
}

- (HOPLoggerLevel) getLoggerLevelForAppModule:(Modules) module
{
    HOPLoggerLevel ret = HOPLoggerLevelNone;
    
    NSString* archiveString = [self getArchiveStringForModule:module];
    if ([archiveString length] > 0)
        ret = [self getLoggerLevelForAppModuleKey:archiveString];
    
    return ret;
}

- (HOPLoggerLevel) getLoggerLevelForAppModuleKey:(NSString*) moduleKey
{
    HOPLoggerLevel ret = HOPLoggerLevelNone;
    
    NSNumber* retNumber = [self.appModulesLoggerLevel objectForKey:moduleKey];
    if (retNumber)
        ret = (HOPLoggerLevel)[retNumber intValue];
    
    return ret;
}

- (void) setLoggerLevel:(HOPLoggerLevel) level forAppModule:(Modules) module
{
    NSString* archiveString = [self getArchiveStringForModule:module];
    [self.appModulesLoggerLevel setObject:[NSNumber numberWithInt:level] forKey:archiveString];
    [self saveModuleLogLevels];
}

- (void) saveModuleLogLevels
{
    [[HOPSettings sharedSettings] storeSettingsObject:self.appModulesLoggerLevel key:archiveModulesLogLevels];
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
            
        case MODULE_ZSLIB_SOCKET:
            ret = @"SDK (zsLib sockets)";
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
            
        case MODULE_ZSLIB_SOCKET:
            ret = moduleZsLibSocket;
            break;
            
        case MODULE_JAVASCRIPT:
            ret = moduleJavaScript;
            break;
            
            default:
            break;
    }
    return ret;
}

- (NSString*) getStringForLogLevel:(HOPLoggerLevel) level
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
    [self setLoggerLevel:HOPLoggerLevelDebug forAppModule:MODULE_ZSLIB_SOCKET];
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

- (BOOL) isQRSettingsResetEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:settingsKeyRemoveSettingsAppliedByQRCode];
}

- (void) enableQRSettingsReset:(BOOL) enable
{
    [[HOPSettings sharedSettings] storeSettingsObject:[NSNumber numberWithBool:enable] key:settingsKeyRemoveSettingsAppliedByQRCode];
}

- (NSString*) getOuterFrameURL
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyOuterFrameURL];
}

- (NSString*) getNamespaceGrantServiceURL
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyGrantServiceURL];
}

- (NSString*) getIdentityProviderDomain
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyIdentityProviderDomain];
}

- (NSString*) getIdentityFederateBaseURI
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyIdentityFederateBaseURI];
}

- (NSString*) getLockBoxServiceDomain
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyLockBoxServiceDomain];
}

- (NSString*) getDefaultOutgoingTelnetServer
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeyOutgoingTelnetLogger];
}
- (BOOL) isAppDataSet
{
    BOOL ret = YES;
    
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyAppId]] length] != 0;
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyAppIdSharedSecret]] length] != 0;
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyAppName]] length] != 0;
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyAppURL]] length] != 0;
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyAppImageURL]] length] != 0;
    
#ifdef APNS_ENABLED
    ret &= [[[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyUrbanAirShipAPIPushURL]] length] != 0;
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

- (BOOL) isAppSettingsSetForPath:(NSString*) path
{
    BOOL ret = YES;
    NSDictionary* customerSpecificDict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if ([customerSpecificDict count] > 0)
    {
        NSString* appID = [customerSpecificDict objectForKey:settingsKeyAppId];
        NSString* appSecret = [customerSpecificDict objectForKey:settingsKeyAppIdSharedSecret];
        NSString* appName = [customerSpecificDict objectForKey:settingsKeyAppName];
        
        if ([appID length] == 0 || [appSecret length] == 0 || [appName length] == 0)
            ret = NO;
    }
    
    return ret;
}

- (NSArray*) getMissingAppSettings
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    //Check if app id and app shared secret id are set
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyAppId] length] == 0)
        [ret addObject: settingsKeyAppId];
    

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyAppIdSharedSecret] length] == 0)
        [ret addObject: settingsKeyAppIdSharedSecret];
    return ret;
}

- (NSMutableDictionary*) dictionaryForJSONString:(NSString*) jsonString
{
    NSMutableDictionary* ret = nil;
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* inputDictionary = [parser objectWithString: jsonString];
    
    //Check if downloaded JSON is having root object
    if ([inputDictionary count] > 0 && [inputDictionary objectForKey:@"root"] != nil)
    {
        ret = [NSMutableDictionary dictionaryWithDictionary:[inputDictionary objectForKey:@"root"]];
        if (ret)
            [self createUserAgentFromDictionary:ret];
    }
    
    return ret;
}

- (NSString*) createUserAgentFromDictionary:(NSMutableDictionary*) inDictionary
{
    NSString* ret = nil;
    if ([inDictionary count] > 0)
    {
        NSString* temp = [inDictionary objectForKey: settingsKeyUserAgent];
        if ([temp length] > 0)
        {
            ret = @"";
            NSArray* partsOfString = [temp componentsSeparatedByString:@"$"];
            for (NSString* str in partsOfString)
            {
                NSString* toAppend = @"";
                if ([str compare:userAgentVariableAppName] == NSOrderedSame)
                {
                    toAppend = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
                }
                else if ([str compare:userAgentVariableAppVersion] == NSOrderedSame)
                {
                    toAppend = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                }
                else if ([str compare:userAgentVariableSystemOS] == NSOrderedSame)
                {
                    toAppend = [[UIDevice currentDevice] systemName];
                }
                else if ([str compare:userAgentVariableVersionOS] == NSOrderedSame)
                {
                    toAppend = [[UIDevice currentDevice] systemVersion];
                }
                else if ([str compare:userAgentVariableDeviceModel] == NSOrderedSame)
                {
                    toAppend = [[UIDevice currentDevice] model];
                    
                    if ([toAppend hasPrefix:@"iPhone"] || [toAppend hasPrefix:@"iPod"])
                        toAppend = @"iPhone";
                    else if ([toAppend hasPrefix:@"iPad"])
                        toAppend = @"iPad";
                }
                else if ([str compare:userAgentVariableDeveloperID] == NSOrderedSame)
                {
                    toAppend = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Hookflash Developer ID"];
                }
                else
                {
                    toAppend = str;
                }
                
                ret = [ret stringByAppendingString:toAppend];
            }
            
            if ([ret length] > 0)
                [inDictionary setObject:ret forKey:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyUserAgent]];
            
            [inDictionary removeObjectForKey:settingsKeyUserAgent];
        }
    }
    return ret;
}

- (NSMutableDictionary*) dictionaryWithRemovedAllInvalidEntriesForPath:(NSString*) path
{
    NSMutableDictionary* plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    if ([plistDictionary count] > 0)
    {
        for (NSString* key in [plistDictionary allKeys])
        {
           id value = [plistDictionary objectForKey:key];
            if ([value isKindOfClass:[NSString class]])
            {
                //If settings value starts with <-- remove it from the dictionary
                if ([((NSString*)value) rangeOfString:@"<--"].location != NSNotFound)
                {
                    [plistDictionary removeObjectForKey:key];
                }
            }
            
        }
    }
    
    return plistDictionary;
}

- (void) updateDeviceInfo
{
    //Get device info: device ID, iOS, platform and user agent
    NSString* deviceId = [HOPUtility hashString:[HOPUtility getGUIDstring]];
    if ([deviceId length] > 0)
        [[HOPSettings sharedSettings] storeCalculatedSettingObject:deviceId key:@"openpeer/calculated/device-id"];

    NSString* str = [Utility getDeviceOs];
    if ([str length] > 0)
        [[HOPSettings sharedSettings] storeCalculatedSettingObject:str key:@"openpeer/calculated/os"];
    
    NSString* system = [Utility getPlatform];
    if ([system length] > 0)
        [[HOPSettings sharedSettings] storeCalculatedSettingObject:system key:@"openpeer/calculated/system"];
    
    NSString* userAgent = [Utility getUserAgentName];
    if ([userAgent length] > 0)
        [[HOPSettings sharedSettings] storeCalculatedSettingObject:userAgent key:[[HOPSettings sharedSettings] getCoreKeyForAppKey:settingsKeyUserAgent]];
}

- (void) snapshotCurrentSettings
{
    //Save current settings value like dictionary
    NSDictionary* currentSettings = [[HOPSettings sharedSettings] getCurrentSettingsDictionary];
    if ([currentSettings count] > 0)
        [[NSUserDefaults standardUserDefaults] setObject:currentSettings forKey:settingsKeySettingsSnapshot];
}

- (void) storeQRSettings:(NSDictionary*) inDictionary
{
    [[NSUserDefaults standardUserDefaults] setObject:inDictionary forKey:settingsKeyAppliedQRSettings];
}


- (void) removeAppliedQRSettings
{
    //Load applied QR settings
    NSDictionary* appliedQRSettingsDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyAppliedQRSettings];
    //Load initial settings
    NSDictionary* preQRSettingsSnapshotDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:settingsKeySettingsSnapshot];
   
    for (NSString* key in appliedQRSettingsDictionary)
    {
        //Get core key for existing application
        NSString* coreKey = [[HOPSettings sharedSettings] getCoreKeyForAppKey:key];
        id qrValue = [appliedQRSettingsDictionary objectForKey:key];
        id currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:coreKey];
        id preValue = [preQRSettingsSnapshotDictionary objectForKey:coreKey];
        
        BOOL isEqual = NO;
        
        //Check if qr settings is changed since it is applied
        if ([[qrValue class] isSubclassOfClass:[NSNumber class]])
            isEqual = [qrValue compare:currentValue] == NSOrderedSame;
        else if ([[qrValue class] isSubclassOfClass:[NSString class]])
            isEqual = [qrValue isEqualToString:currentValue];
        else
            isEqual = qrValue == currentValue;
        
        //If qr settings is not changed remove it or replace with initial value
        if (isEqual)
        {
            if (preValue == nil)
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:coreKey];
            else
                [[NSUserDefaults standardUserDefaults] setObject:preValue forKey:coreKey];
        }
    }
}

- (void)updateDefaultSettingsFromPath:(NSString *)filePath notToUpdateKeys:(NSMutableArray *)notToUpdateKeys
{
    if ([filePath length] > 0)
    {
        //Clean disctionary from invalid entries
        NSDictionary* filteredDictionary = [[Settings sharedSettings] dictionaryWithRemovedAllInvalidEntriesForPath:filePath];
        if ([filteredDictionary count] > 0)
        {
            for (NSString* key in [filteredDictionary allKeys])
            {
                //Check if value for specific key should be updated
                if (![notToUpdateKeys containsObject:key])
                {
                    id value = [filteredDictionary objectForKey:key];
                    [[HOPSettings sharedSettings] storeSettingsObject:value key:[[HOPSettings sharedSettings]getCoreKeyForAppKey:key]];
                    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Updated value: %@ for key: %@",value,key);
                }
            }
        }
        
        //Save new default settings
        NSMutableDictionary* defaultSettings = nil;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyDefaultSettingsSnapshot])
            defaultSettings = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyDefaultSettingsSnapshot]];
        else
            defaultSettings = [[NSMutableDictionary alloc] init];
        [defaultSettings addEntriesFromDictionary:filteredDictionary];
        [[NSUserDefaults standardUserDefaults] setObject:defaultSettings forKey:settingsKeyDefaultSettingsSnapshot];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL) shouldOverwriteExistingSettings
{
    BOOL ret = NO;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"];
    if ([filePath length] > 0)
    {
        NSDictionary* settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
        //Check if all settings should be overwritten
        if ([settingsDictionary count] > 0)
        {
            ret = [settingsDictionary objectForKey:settingsKeyOverwriteExistingSettings] != nil ? ((NSNumber*)[settingsDictionary objectForKey:settingsKeyOverwriteExistingSettings]).boolValue : NO;
        }
    }
    
    return ret;
}

- (BOOL) updateAppSettings
{
    BOOL ret = NO;
    BOOL updateSettings = [Utility isAppUpdated];
    [self updateDeviceInfo];
    
    if (updateSettings)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Updating application settings");
        //Check if all settings can be overwritten. If not it will overwritten just settings that atil has default values
        BOOL overwrite = [self shouldOverwriteExistingSettings];
        
        NSMutableDictionary* defaultSettings = [[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyDefaultSettingsSnapshot];
        NSMutableArray* arrayOfChangedKeys = overwrite ? nil : [[NSMutableArray alloc] init];
        
        if (!overwrite)
        {
            //For each key check if value is changed comparing to default value
            for (NSString* key in [defaultSettings allKeys])
            {
                id defaultValue = [defaultSettings objectForKey:key];
                id currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:[[HOPSettings sharedSettings]getCoreKeyForAppKey:key]];
                
                if ([defaultValue isKindOfClass:[NSString class]] && [currentValue isKindOfClass:[NSString class]])
                {
                    if (![((NSString*) defaultValue) isEqualToString:((NSString*) currentValue)])
                        [arrayOfChangedKeys addObject:key];
                }
                else if ([defaultValue isKindOfClass:[NSNumber class]] && [currentValue isKindOfClass:[NSNumber class]])
                {
                    if (![((NSNumber*) defaultValue) isEqualToNumber:((NSNumber*) currentValue)])
                        [arrayOfChangedKeys addObject:key];
                }
                else if ([defaultValue isKindOfClass:[NSDictionary class]] && [currentValue isKindOfClass:[NSDictionary class]])
                {
                    if (![((NSDictionary*)defaultValue) isEqualToDictionary:((NSDictionary*)currentValue)])
                        [arrayOfChangedKeys addObject:key];
                }
                else
                {
                    if (currentValue && defaultValue != currentValue)
                        [arrayOfChangedKeys addObject:key];
                }
            }
        }
        else
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"No change in application settings");
        }
        
        //Update settings with new values
        [self updateDefaultSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"] notToUpdateKeys:arrayOfChangedKeys];
        [self updateDefaultSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"CustomerSpecific" ofType:@"plist"] notToUpdateKeys:arrayOfChangedKeys];
#ifndef DEBUG
        [self updateDefaultSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"CustomerSpecific_Release" ofType:@"plist"] notToUpdateKeys:arrayOfChangedKeys];
#endif
        [self snapshotCurrentSettings];
    }
    //Start settings download. If download is not started finish presetup
    ret = [self downloadLatestSettings];
    
    return ret;
}

- (BOOL) downloadLatestSettings
{
    BOOL ret = NO;
    NSString* settingsDownloadURL = [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeySettingsDownloadURL];
    
    if ([settingsDownloadURL length] > 0)
    {
        NSString* cachedSettingsDownloadURL = [[HOPCache sharedCache] fetchForCookieNamePath:settingsKeySettingsDownloadURL];
        //Check if cookie has expired, and run download if it has
        if ([cachedSettingsDownloadURL length] == 0 || ![cachedSettingsDownloadURL isEqualToString:settingsDownloadURL])
        {
            self.settingsDownloader = [[HTTPDownloader alloc] initSettingsDownloadFromURL:settingsDownloadURL postDate:nil];
            self.settingsDownloader.delegate = self;
            ret = [self.settingsDownloader startDownload];
        }
        else
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Cookie has not expired so settings are not downloaded");
        }
    }
    
    if (ret)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Downloading settings from url:%@",settingsDownloadURL);
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Settings download not started for url:%@",settingsDownloadURL);
    }
    
    return ret;
}

- (BOOL) checkIfReloginInfoIsValid
{
    BOOL ret = NO;
    
    HOPHomeUser* homeUser = [[HOPModelManager sharedModelManager] getLastLoggedInHomeUser];
    NSString* domain = [[NSUserDefaults standardUserDefaults] objectForKey:settingsKeyIdentityProviderDomain];
    
    ret = [homeUser.reloginInfo rangeOfString:domain].location != NSNotFound;
    
    return ret;
}

#pragma mark - SettingsDownloaderDelegate
- (void) httpDownloader:(HTTPDownloader *)downloader downloaded:(NSString *)downloaded
{
    if ([downloaded length] > 0 && [downloaded rangeOfString:@">404<"].location == NSNotFound)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Settings are successfully downloaded");
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Downloaded settings: %@",downloaded);
        NSDictionary* settingsDictionary = [[Settings sharedSettings] dictionaryForJSONString:downloaded];
        [[HOPSettings sharedSettings] storeSettingsFromDictionary:settingsDictionary];
        //After downloading settings are applied make a settings snaplshot
        [self snapshotCurrentSettings];
        int expiryTime = [[NSUserDefaults standardUserDefaults] integerForKey:settingsKeySettingsDownloadExpiryTime];
        [[HOPCache sharedCache] store:[[NSUserDefaults standardUserDefaults] stringForKey:settingsKeySettingsDownloadURL] expireDate:[[NSDate date] dateByAddingTimeInterval:expiryTime] cookieNamePath:settingsKeySettingsDownloadURL];
    }
    else
    {
        if ([downloaded length] > 0)
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Settings download error: 404 Not found");
        }
        else
        {
            OPLog(HOPLoggerSeverityWarning, HOPLoggerLevelDebug, @"Received empty settings string.");
        }
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                            message:@"Login will proceed with default settings."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
    
    [[OpenPeer sharedOpenPeer] finishPreSetup];
}

- (void) httpDownloader:(HTTPDownloader *) downloader didFailWithError:(NSError *)error
{
    BOOL showErrorMessage = NO;
    if (error.code == kCFURLErrorTimedOut)
    {
        OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Settings download failed. Reason:%@",error);
        self.timeoutCounter++;
        if (self.timeoutCounter > 2)
        {
            showErrorMessage = YES;
            [[OpenPeer sharedOpenPeer] finishPreSetup];
        }
        else
        {
            [self downloadLatestSettings];
        }
    }
    //OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Settings download failed. Reason:%@",error);
    
    if (showErrorMessage)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Downloading login settings failed!"
                                                            message:@"Login will proceed with previous settings."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok",nil];
        [alertView show];
    }
    
}
@end
