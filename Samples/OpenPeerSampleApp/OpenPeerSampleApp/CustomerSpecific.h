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

//WARNING: If you got a linker error related to the strings below, please check if they are set correctly in the file CustomerSpecific.m
extern NSString* const applicationId;
extern NSString* const applicationIdSharedSecret;

extern NSString* const applicationName;
extern NSString* const applicationImageURL;
extern NSString* const applicationURL;

extern NSString* const outerFrameURL;
extern NSString* const namespaceGrantServiceURL;
extern NSString* const identityProviderDomain;
extern NSString* const identityFederateBaseURI;
extern NSString* const lockBoxServiceDomain;
extern NSString* const defaultOutgoingTelnetServer;

#ifdef APNS_ENABLED
extern NSString* const masterAppSecretDev;
extern NSString* const masterAppSecret;
extern NSString* const developmentAppKey;
extern NSString* const developmentAppSecret;
extern NSString* const productionAppKey;
extern NSString* const productionAppSecret;
extern NSString* const apiPushURL;
#endif