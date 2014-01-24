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

#import "CustomerSpecific.h"

#error VALUES BELOW NEED TO BE SET TO SUPPORT CUSTOMER DEVELOPER ENVIRONMENT

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//-----------------------------------------------------------------------------
// If you have not done so already, please go to http://fly.hookflash.me to
// create your application and obtain your app ID and shared secret.
//-----------------------------------------------------------------------------
// Setting the application shared secret in the client is not recommended.
// Instead, the recommended solution is for your client download an authorized
// application ID from your own server using whatever method you determine is
// most appropriate.
//-----------------------------------------------------------------------------
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

//-----------------------------------------------------------------------------
NSString* const applicationId = @"<-- insert application ID here (e.g. com.domain.appName) -->";

NSString* const applicationIdSharedSecret = @"<-- insert shared secret here -->";
//-----------------------------------------------------------------------------

// set customer spplication name
NSString* const applicationName = @"OpenPeerSampleApp";

// set customer spplication image url
NSString* const applicationImageURL = @"http://hookflash.com/wp-content/themes/CleanSpace/images/logo.png";

// set customer spplication url
NSString* const applicationURL = @"https://www.openpeer.org/";
//-----------------------------------------------------------------------------


// set outer frame url
NSString* const outerFrameURL = @"https://app-javascript.hookflash.me/outer.html?view=choose";

// set outer namespace grant url
NSString* const namespaceGrantServiceURL = @"https://app-javascript.hookflash.me/outernamespacegrant.html";

// set identity provider domain
NSString* const identityProviderDomain = @"idprovider-javascript.hookflash.me";

// set federated identity base
NSString* const identityFederateBaseURI = @"identity://idprovider-javascript.hookflash.me/";

// set lockbox service domain
NSString* const lockBoxServiceDomain =  @"hcs-javascript.hookflash.me";

// set default outgoing telent server
NSString * const defaultOutgoingTelnetServer = @"tcp.logger.hookflash.me:8055";
