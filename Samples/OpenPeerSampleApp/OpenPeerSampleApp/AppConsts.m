/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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

#import "AppConsts.h"

NSString* const identityFacebookBaseURI = @"identity://facebook.com/";


//Property list keys
NSString * const settingsKeyAppliedQRSettings = @"appliedQRSettings";
NSString * const settingsKeySettingsSnapshot = @"settingsSnapshot";
NSString * const settingsKeyDefaultSettingsSnapshot = @"defaultSettingsSnapshot";
NSString * const settingsKeyOverwriteExistingSettings = @"applicationOverwriteSettings";
NSString * const settingsKeyUserAgent = @"userAgent";

NSString * const settingsKeyMediaAEC = @"archiveMediaAEC";
NSString * const settingsKeyMediaAGC = @"archiveMediaAGC";
NSString * const settingsKeyMediaNS = @"archiveMediaNS";

//UserAgent Variables
NSString * const userAgentVariableAppName = @"appName";
NSString * const userAgentVariableAppVersion = @"appVersion";
NSString * const userAgentVariableSystemOS = @"systemOs";
NSString * const userAgentVariableVersionOS = @"versionOs";
NSString * const userAgentVariableDeviceModel = @"deviceModel";
NSString * const userAgentVariableDeveloperID = @"developerID";

NSString * const settingsKeyAppId = @"applicationID";
NSString * const settingsKeyAppIdSharedSecret = @"applicationSharedSecret";
NSString * const settingsKeyAppName = @"applicationName";
NSString * const settingsKeyAppImageURL = @"applicationImageURL";
NSString * const settingsKeyAppURL = @"applicationURL";
NSString * const settingsKeyAPNSUrbanAirShip = @"APNS-UrbanAirShip";
NSString * const settingsKeyAPNSParse = @"APNS-Parse";
NSString * const settingsKeyTelnetLogger = @"localTelnetLoggerPort";
NSString * const settingsKeyOutgoingTelnetLogger = @"defaultOutgoingTelnetServer";
NSString * const settingsKeyStdOutLogger = @"archiveStdOutLogger";
NSString * const settingsKeyEnabledLogger = @"isLoggerEnabled";
NSString * const settingsKeyRemoveSettingsAppliedByQRCode = @"applicationRemoveSettingsAppliedByQRCode";
NSString * const settingsKeyOuterFrameURL = @"outerFrameURL";
NSString * const settingsKeyGrantServiceURL = @"namespaceGrantServiceURL";
NSString * const settingsKeyIdentityProviderDomain = @"identityProviderDomain";
NSString * const settingsKeyIdentityFederateBaseURI = @"identityFederateBaseURI";
NSString * const settingsKeyLockBoxServiceDomain = @"lockBoxServiceDomain";
//NSString * const settingsKeyOutgoingTelnetLoggerServer = @"defaultOutgoingTelnetServer";
NSString * const settingsKeySettingsDownloadURL = @"applicationSettingsDownloadURL";
NSString * const settingsKeySettingsDownloadExpiryTime = @"applicationSettingsDownloadExpiryTime";
NSString * const settingsKeyQRScannerShownAtStart = @"applicationQRScannerShownAtStart";
NSString * const settingsKeySplashScreenAllowsQRScannerGesture = @"applicationSplashScreenAllowsQRScannerGesture";
NSString * const settingsKeySettingsVersion = @"applicationSettingsVersion";
NSString * const settingsKeyBackgroundingPhaseRichPush = @"applicationSettingsBackgroundingPhaseRichPush";
NSString * const settingsKeyDefaultLogLevel = @"logLevelForServicesHttp";
NSString * const settingsKeyRedirectAfterLoginCompleteURL = @"redirectAfterLoginCompleteURL";
NSString * const settingsDeviceTokenDownloadURL = @"deviceTokenDownloadURL";
NSString * const settingsDeviceTokenUploadURL = @"deviceTokenUploadURL";
NSString * const settingsKeyDefaultConversationType = @"applicationConversationType";

NSString * const archiveEnabled = @"enabled";
NSString * const archiveServer = @"Server";
NSString * const archiveColorized = @"colorized";

NSString * const localNotificationKey = @"localNotification";

#ifdef APNS_ENABLED
NSString* const settingsKeyUrbanAirShipMasterAppSecretDev = @"masterAppSecretDev";
NSString* const settingsKeyUrbanAirShipMasterAppSecret = @"masterAppSecret";
NSString* const settingsKeyUrbanAirShipDevelopmentAppKey = @"developmentAppKey";
NSString* const settingsKeyUrbanAirShipDevelopmentAppSecret = @"developmentAppSecret";
NSString* const settingsKeyUrbanAirShipProductionAppKey = @"productionAppKey";
NSString* const settingsKeyUrbanAirShipProductionAppSecret = @"productionAppSecret";
NSString* const settingsKeyUrbanAirShipAPIPushURL = @"apiPushURL";

NSString* const settingsKeyParseDevelopmentAppID = @"developmentAppID";
NSString* const settingsKeyParseDevelopmentClientKey = @"developmentClientKey";
NSString* const settingsKeyParseProductionAppID = @"productionAppID";
NSString* const settingsKeyParseProductionClientKey = @"productionClientKey";

NSString* const settingsKeyDefaultAPNSProvider = @"applicationDefaultAPNSProvider";

NSString* const settingsKeyAPNSTimeOut = @"applicationTimeBetweenTwoPushes";
#endif

//Contact Profile xml tags
NSString* const profileXmlTagProfile = @"profile";
NSString* const profileXmlTagName = @"name";
NSString* const profileXmlTagIdentities = @"identities";
NSString* const profileXmlTagIdentityBundle = @"identityBundle";
NSString* const profileXmlTagIdentity = @"identity";
NSString* const profileXmlTagSignature = @"signature";
NSString* const profileXmlTagAvatar = @"avatar";
NSString* const profileXmlTagContactID = @"contactID";
NSString* const profileXmlTagPublicPeerFile = @"publicPeerFile";
NSString* const profileXmlTagSocialId = @"socialId";
NSString* const profileXmlAttributeId = @"id";
NSString* const profileXmlTagUserID = @"userID";

//Message types
NSString* const messageTypeText = @"text/x-application-hookflash-message-text";
NSString* const messageTypeSystem = @"text/x-application-hookflash-message-system";

NSString * const TagEvent           = @"event";
NSString * const TagId              = @"id";
NSString * const TagText            = @"text";

NSString * const systemMessageRequest = @"?";

//Notifications
NSString * const notifictionAppReturnedFromBackground = @"notifictionAppReturnedFromBackground";
NSString * const notificationRemoteSessionModeChanged = @"notificationRemoteSessionModeChanged";
NSString * const notificationCrashReportSent = @"notificationCrashReportSent";
NSString * const notificationComposingStatusChanged = @"notificationComposingStatusChanged";
NSString * const notificationMessagesRead = @"notificationMessagesRead";
NSString * const notificationFileUploadProgress = @"notificationFileUploadProgress";
NSString * const notificationFileUploadDone = @"notificationFileUploadDone";

NSString * const notificationTypeApple = @"apns";
NSString * const notificationTypeAndroid = @"apid";

NSString * const defaultTelnetPort = @"59999";

NSString * const stringDeletedeMessageText = @"This message has been removed.";

NSString * const archiveRemoteSessionActivationMode = @"archiveRemoteSessionActivationMode";
NSString * const archiveFaceDetectionMode = @"archiveFaceDetectionMode";
NSString * const archiveRedialMode = @"archiveRedialMode";

NSString * const archiveModulesLogLevels = @"archiveModulesLogLevels";

NSString * const moduleApplication = @"openpeer_application";
NSString * const moduleSDK = @"openpeer_sdk";
NSString * const moduleMedia = @"openpeer_media";
NSString * const moduleWebRTC = @"openpeer_webrtc";
NSString * const moduleCore = @"openpeer_core";
NSString * const moduleStackMessage = @"openpeer_stack_message";
NSString * const moduleStack = @"openpeer_stack";
NSString * const moduleServices = @"openpeer_services";
NSString * const moduleServicesWire = @"openpeer_services_wire";
NSString * const moduleServicesIce = @"openpeer_services_ice";
NSString * const moduleServicesTurn = @"openpeer_services_turn";
NSString * const moduleServicesRudp = @"openpeer_services_rudp";
NSString * const moduleServicesHttp = @"openpeer_services_http";
NSString * const moduleServicesMls = @"openpeer_services_mls";
NSString * const moduleServicesTcp = @"openpeer_services_tcp_messaging";
NSString * const moduleServicesTransport = @"openpeer_services_transport_stream";
NSString * const moduleZsLib = @"zsLib";
NSString * const moduleZsLibSocket = @"zsLib_socket";
NSString * const moduleJavaScript = @"openpeer_javascript";


