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
#include <openpeer/core/types.h>
#include <openpeer/core/ISettings.h>
#import "HOPProtocols.h"

using namespace openpeer;
using namespace openpeer::core;

ZS_DECLARE_CLASS_PTR(OpenPeerSettingsDelegate)

/**
 Wrapper Class that creates settings object used in core.
 */
class OpenPeerSettingsDelegate : public ISettingsDelegate
{
protected:
    //id<HOPSettingsDelegate> settingsDelegate;
    
    //OpenPeerSettingsDelegate(id<HOPSettingsDelegate> settingsDelegate);
    OpenPeerSettingsDelegate();
    
    NSMutableDictionary* dictionarySettings;
    NSString* authorizedApplicationId;
    NSString* authorizedApplicationIdCoreKey;
    
public:
    
    ~OpenPeerSettingsDelegate();
    
    /**
     Create SettingsDelegateWrapper object packed in boost shared pointer.
     @returns SettingsDelegateWrapper object boost shared object
     */
//    static OpenPeerSettingsDelegatePtr create(id<HOPSettingsDelegate> inSettingsDelegate);
    static OpenPeerSettingsDelegatePtr create();
    
    String getString(const char *key) const;
    LONG getInt(const char *key) const;
    ULONG getUInt(const char *key) const;
    bool getBool(const char *key) const;
    float getFloat(const char *key) const;
    double getDouble(const char *key) const;
    
    void setString(const char *key,const char *value);
    void setInt(const char *key,LONG value);
    void setUInt(const char *key,ULONG value);
    void setBool(const char *key,bool value);
    void setFloat(const char *key,float value);
    void setDouble(const char *key,double value);
    
    void clear(const char *key);
    void clearAll();
    
    void addSettingWithKey(NSString* inSetting, NSString* key);
    NSDictionary* getCurrentSettingsDictionary();
    
    NSString* stringFoKey(NSString* key) const;
    NSNumber* numberForKey(NSString* key) const;
    void setObjectForKey(id object, NSString* key);
};