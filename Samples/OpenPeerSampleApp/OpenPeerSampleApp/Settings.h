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

#import <Foundation/Foundation.h>
#import <OpenPeerSDK/HOPTypes.h>
#import "Delegates.h"

typedef enum
{
    LOGGER_STD_OUT,
    LOGGER_TELNET,
    LOGGER_OUTGOING_TELNET
}LoggerTypes;

typedef enum
{
    TELNET_ENABLE,
    TELNET_SERVER_OR_PORT,
    TELNET_COLOR,
    
    TOTAL_TELNET_OPTIONS
}TelnetLoggerOptions;

typedef enum
{
    MODULE_APPLICATION,
    MODEULE_SDK,
    MODULE_MEDIA,
    MODULE_WEBRTC,
    MODULE_CORE,
    MODULE_STACK_MESSAGE,
    MODULE_STACK,
    MODULE_SERVICES,
    MODULE_SERVICES_WIRE,
    MODULE_SERVICES_ICE,
    MODULE_SERVICES_TURN,
    MODULE_SERVICES_RUDP,
    MODULE_SERVICES_HTTP,
    MODULE_SERVICES_MLS,
    MODULE_SERVICES_TCP,
    MODULE_SERVICES_TRANSPORT,
    MODULE_ZSLIB,
    MODULE_ZSLIB_SOCKET,
    MODULE_JAVASCRIPT,
    
    TOTAL_MODULES
}Modules;





@interface Settings : NSObject<HTTPDownloaderDelegate>

@property (nonatomic) BOOL isMediaAECOn;
@property (nonatomic) BOOL isMediaAGCOn;
@property (nonatomic) BOOL isMediaNSOn;

@property (nonatomic) BOOL isRemoteSessionActivationModeOn;
@property (nonatomic) BOOL isFaceDetectionModeOn;
@property (nonatomic) BOOL isRedialModeOn;

@property (nonatomic) BOOL enabledStdLogger;

@property (strong, nonatomic) NSMutableDictionary* appModulesLoggerLevel;
@property (strong, nonatomic) NSMutableDictionary* telnetLoggerSettings;
@property (strong, nonatomic) NSMutableDictionary* outgoingTelnetLoggerSettings;
@property (strong, nonatomic) NSMutableDictionary* loginSettings;

@property (strong, nonatomic) NSString *instanceId;


+ (id) sharedSettings;
- (id) init __attribute__((unavailable("HOPAccount is singleton class.")));

- (void) enableMediaAEC:(BOOL) enable;
- (void) enableMediaAGC:(BOOL) enable;
- (void) enableMediaNS:(BOOL) enable;

- (void) enableRemoteSessionActivationMode:(BOOL) enable;
- (void) enableFaceDetectionMode:(BOOL) enable;
- (void) enableRedialMode:(BOOL) enable;

- (void) enable:(BOOL) enable logger:(LoggerTypes) type;
- (BOOL) isLoggerEnabled:(LoggerTypes) type;

- (void) setServerOrPort:(NSString*) server logger:(LoggerTypes) type;
- (NSString*) getServerPortForLogger:(LoggerTypes) type;

- (void) setColorizedOutput:(BOOL) colorized logger:(LoggerTypes) type;
- (BOOL) isColorizedOutputForLogger:(LoggerTypes) type;

- (HOPLoggerLevel) getLoggerLevelForAppModule:(Modules) module;
- (HOPLoggerLevel) getLoggerLevelForAppModuleKey:(NSString*) moduleKey;
- (void) setLoggerLevel:(HOPLoggerLevel) level forAppModule:(Modules) module;

- (NSString*) getStringForModule:(Modules) module;
- (NSString*) getStringForLogLevel:(HOPLoggerLevel) level;

- (void) saveDefaultsLoggerSettings;

- (BOOL) isQRSettingsResetEnabled;
- (void) enableQRSettingsReset:(BOOL) enable;

- (NSString*) getOuterFrameURL;
- (NSString*) getNamespaceGrantServiceURL;
- (NSString*) getIdentityProviderDomain;
- (NSString*) getIdentityFederateBaseURI;
- (NSString*) getLockBoxServiceDomain;
- (NSString*) getDefaultOutgoingTelnetServer;

- (BOOL) isAppDataSet;
- (BOOL) isLoginSettingsSet;
- (BOOL) isAppSettingsSetForPath:(NSString*) path;

- (NSArray*) getMissingAppSettings;
- (NSMutableDictionary*) dictionaryWithRemovedAllInvalidEntriesForPath:(NSString*) path;
- (NSMutableDictionary*) dictionaryForJSONString:(NSString*) jsonString;
- (NSString*) createUserAgentFromDictionary:(NSMutableDictionary*) inDictionary;

- (void) updateDeviceInfo;
- (void) snapshotCurrentSettings;
- (void) storeQRSettings:(NSDictionary*) inDictionary;
- (void) removeAppliedQRSettings;

- (BOOL) updateAppSettings;
- (BOOL) checkIfReloginInfoIsValid;
@end
