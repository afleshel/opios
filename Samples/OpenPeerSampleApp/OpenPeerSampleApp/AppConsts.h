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

extern NSString* const identityFacebookBaseURI;


//Property list keys
extern NSString * const settingsKeyAppId;
extern NSString * const settingsKeyAppIdSharedSecret;
extern NSString * const settingsKeyAppName;
extern NSString * const settingsKeyAppImageURL;
extern NSString * const settingsKeyAppURL;
extern NSString * const settingsKeyAPNS;
extern NSString * const settingsKeyTelnetLogger;
extern NSString * const settingsKeyOutgoingTelnetLogger;
extern NSString * const settingsKeyStdOutLogger;
extern NSString * const settingsKeyEnabledLogger;
extern NSString * const settingsKeyRemoveSettingsAppliedByQRCode;
extern NSString * const settingsKeyOuterFrameURL;
extern NSString * const settingsKeyGrantServiceURL;
extern NSString * const settingsKeyIdentityProviderDomain;
extern NSString * const settingsKeyIdentityFederateBaseURI;
extern NSString * const settingsKeyLockBoxServiceDomain;
//extern NSString * const settingsKeyOutgoingTelnetLoggerServer;
extern NSString * const settingsKeySettingsDownloadURL;
extern NSString * const settingsKeySettingsDownloadExpiryTime;
extern NSString * const settingsKeyQRScannerShownAtStart;
extern NSString * const settingsKeySplashScreenAllowsQRScannerGesture;
extern NSString * const settingsKeySettingsVersion;
extern NSString * const settingsKeyBackgroundingPhaseRichPush;
extern NSString * const settingsKeyDefaultLogLevel;
extern NSString * const settingsKeyRedirectAfterLoginCompleteURL;

extern NSString * const archiveEnabled;
extern NSString * const archiveServer;
extern NSString * const archiveColorized;

extern NSString * const settingsKeyAppliedQRSettings;
extern NSString * const settingsKeySettingsSnapshot;
extern NSString * const settingsKeyDefaultSettingsSnapshot;
extern NSString * const settingsKeyOverwriteExistingSettings;
extern NSString * const settingsKeyUserAgent;

extern NSString * const settingsKeyMediaAEC;
extern NSString * const settingsKeyMediaAGC;
extern NSString * const settingsKeyMediaNS;

//UserAgent Variables
extern NSString * const userAgentVariableAppName;
extern NSString * const userAgentVariableAppVersion;
extern NSString * const userAgentVariableSystemOS;
extern NSString * const userAgentVariableVersionOS;
extern NSString * const userAgentVariableDeviceModel;
extern NSString * const userAgentVariableDeveloperID;

extern NSString * const localNotificationKey;

#ifdef APNS_ENABLED
extern NSString* const settingsKeyUrbanAirShipMasterAppSecretDev;
extern NSString* const settingsKeyUrbanAirShipMasterAppSecret;
extern NSString* const settingsKeyUrbanAirShipDevelopmentAppKey;
extern NSString* const settingsKeyUrbanAirShipDevelopmentAppSecret;
extern NSString* const settingsKeyUrbanAirShipProductionAppKey;
extern NSString* const settingsKeyUrbanAirShipProductionAppSecret;
extern NSString* const settingsKeyUrbanAirShipAPIPushURL;

extern NSString* const settingsKeyAPNSTimeOut;
#endif

//Contact Profile xml tags
extern NSString* const profileXmlTagProfile;
extern NSString* const profileXmlTagName;
extern NSString* const profileXmlTagIdentities;
extern NSString* const profileXmlTagIdentityBundle;
extern NSString* const profileXmlTagIdentity;
extern NSString* const profileXmlTagSignature;
extern NSString* const profileXmlTagAvatar;
extern NSString* const profileXmlTagContactID;
extern NSString* const profileXmlTagPublicPeerFile;
extern NSString* const profileXmlTagSocialId;
extern NSString* const profileXmlAttributeId;
extern NSString* const profileXmlTagUserID;

//Message types
extern NSString* const messageTypeText;
extern NSString* const messageTypeSystem;

//System message tags
extern NSString * const TagEvent;
extern NSString * const TagId;
extern NSString * const TagText;

extern NSString * const systemMessageRequest;

//Notifications
extern NSString * const notificationRemoteSessionModeChanged;
extern NSString * const notifictionAppReturnedFromBackground;
extern NSString * const notificationCrashReportSent;
extern NSString * const notificationComposingStatusChanged;

extern NSString * const notificationTypeApple;
extern NSString * const notificationTypeAndroid;

//Settings
extern NSString * const defaultTelnetPort;


extern NSString * const archiveRemoteSessionActivationMode;
extern NSString * const archiveFaceDetectionMode;
extern NSString * const archiveRedialMode;
extern NSString * const archiveModulesLogLevels;
extern NSString * const moduleApplication;
extern NSString * const moduleSDK;
extern NSString * const moduleMedia;
extern NSString * const moduleWebRTC;
extern NSString * const moduleCore;
extern NSString * const moduleStackMessage;
extern NSString * const moduleStack;
extern NSString * const moduleServices;
extern NSString * const moduleServicesWire;
extern NSString * const moduleServicesIce;
extern NSString * const moduleServicesTurn;
extern NSString * const moduleServicesRudp;
extern NSString * const moduleServicesHttp;
extern NSString * const moduleServicesMls;
extern NSString * const moduleServicesTcp;
extern NSString * const moduleServicesTransport;
extern NSString * const moduleZsLib;
extern NSString * const moduleZsLibSocket;
extern NSString * const moduleJavaScript;

extern NSString * const stringDeletedeMessageText;