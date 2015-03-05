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


#import <Foundation/Foundation.h>
#import "HOPProtocols.h"
#import "HOPTypes.h"

#define OPENPEER_SDK_SETTING_CONVERSATION_TYPE                   @"applicationConversationType"

/**
 Singleton class to handle various app settings.
 */
@interface HOPSettings : NSObject

/**
 Returns singleton object of this class.
 */
+ (id)sharedSettings;
- (id) init __attribute__((unavailable("HOPSettings is singleton class.")));

//- (void) setupWithDelegate:(id<HOPSettingsDelegate>) inDelegate;
/**
 Creates open peer setup delelgate.
 */
- (void) setup;

/**
 Applies settings from a json string.
 @param jsonSettings NSSTring* json settings
 */
- (BOOL) applySettings:(NSString*)jsonSettings;

/**
 Applies default core settings.
 */
- (void) applyDefaults;

/**
 Stores settings from dictionary. First it does mapping from applicaiton settings keys to core keys.
 @param inDictionary NSDictionary* dictionary with settings
 */
- (void) storeSettingsFromDictionary:(NSDictionary*) inDictionary;

/**
 Stores settings from dictionary file path.
 @param path NSString* dictionary file path
 */
- (void) storeSettingsFromPath:(NSString*) path;

/**
 Stores authorized application id
 @param inAuthorizedApplicationId NSString* authorized application id
 */
- (void) storeAuthorizedApplicationId:(NSString*) inAuthorizedApplicationId;

/**
 Retrieves authorized application id
 @return NSString* authorized application id
 */
- (NSString*) getAuthorizedApplicationId;

/**
 Retrieves unique vendor specific device Id
 @return NSString* unique vendor specific device Id
 */
- (NSString*) getDeviceId;

/**
 Retrieves unique run-time instance Id
 @return NSString* unique run-time instance Id
 */
- (NSString*) getInstanceId;

/**
 Use this method to store following values device id, iOS version, platgorm name, user agent
 @param object NSString* one of above mentioned settings
 @param key NSString* settings key
 */
- (void) storeCalculatedSettingObject:(id) object key:(NSString*) key;

/**
 Stores individual setting
 @param object NSString* settings value
 @param key NSString* settings key
 */
- (void) storeSettingsObject:(id) object key:(NSString*) key;

/**
 Retrieves core settings key for application settings key
 @param key NSString* application settings key
 @return NSString* settings core key
 */
- (NSString*) getCoreKeyForAppKey:(NSString*) key;

/**
 Retrieves dictionary with all currenlty set settings values with core settings keys
 @return NSDictionary* dictionary with currently set settings
 */
- (NSDictionary*) getCurrentSettingsDictionary;

- (NSString*) getDefaultCovnersationTypeStr;
- (HOPConversationThreadType) getDefaultCovnersationType;
@end
