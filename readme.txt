Thank you for downloading Hookflash's Open Peer iOS SDK.

Prebuilt sdk version and sample application project you can download from this here: http://openpeer.org/open-peer-sdk-for-ios/

This release is a 1.0.16 release of the SDK and Hookflash will be publishing updates to the SDK regularly.

For a quick introduction to the code please read the following. For more detailed instructions please go to http://docs.hookflash.com.


From your terminal, please clone the "opios" git repository:
git clone --recursive https://github.com/openpeer/opios.git

This repository will yield the iOS Object-C SDK, sample application and dependency librarys like the C++ open peer core, stack, media and libraries needed to support the underlying SDK.

Directory structure:
opios/                            - contains the project files for building the Open Peer iOS SDK framework
opios/openpeer-ios-sdk/           - contains the Open Peer iOS SDK header files
opios/openpeer-ios-sdk/source/    - contains the implementation of the iOS SDK header files
opios/openpeer-ios-sdk/internal/  - contains the wrapper interface that implements the Objective-C to C++ interaction
opios/Samples/                    - contains the Open Peer iOS Samples application(s)

How to build:

0) If you haven't installed xcode command line tools so far, please go to Xcode->Preferences->Downloads and download command line tools.
	Also before calling "prepare.sh", please make sure to remove any file called "user-config.jam" from your HOME directory. If this file is present, the file can conflict with boost building properly on your system.

For example:
cp ~/user-config.jam user-config.jam.save
rm ~/user-config.jam

1) Prepare dvelopment environment by running prepare.sh script from your terminal:

pushd opios/
./prepare.sh
popd


2) From X-code, load sdk project:

opios/SampleWithSDK.xcworkspace

3) Select OpenPeerSDK scheme and make a build. This will build framework with debug symbols and save it in the opios/ folder. To make a production framework run archiving.

4) After OpenPeerSDK is successfully built, select OpenPeerSampleApp project and update following files:

	CustomerSpecific.plist (this file is added in git.ignore)
		applicationId = @"<-- insert application ID here (e.g. com.domain.appName) -->";
		applicationIdSharedSecret = @"<-- insert shared secret here -->"; (Get it from the https://fly.hookflash.me/apps)
		applicationName = @"<-- enter application name here (e.g. OpenPeerSampleApp) -->";
		applicationImageURL = @"<-- enter application image url (e.g. http://hookflash.com/wp-content/themes/CleanSpace/images/logo.png) -->";
		applicationURL = @"<-- enter application url (e.g. www.openpeer.org) -->";

	DefaultSettings.plist (this file contains valid settings that can be used until you set your developer environment)
		outerFrameURL = @"<-- enter outer frame url here (e.g. https://app-javascript.hookflash.me/outer.html?view=choose) -->";
		namespaceGrantServiceURL = @"<-- enter outer namespace grant service url here (e.g. https://app-javascript.hookflash.me/outernamespacegrant.html) -->";
		identityProviderDomain = @"<-- enter identity provider domain here (e.g. idprovider-javascript.hookflash.me) -->";
		identityFederateBaseURI = @"<-- enter federated identity base uri here (e.g. identity://idprovider-javascript.hookflash.me/) -->";
		lockBoxServiceDomain =  @"<-- enter lockbox service domain here (e.g. hcs-javascript.hookflash.me) -->";
		defaultOutgoingTelnetServer = @"<-- enter outgoing telnet server here (e.g. tcp.logger.hookflash.me:8055) -->";
		localTelnetLoggerPort = @"<-- enter outgoing telnet server here (e.g. 59999) -->";
		
		
	If you want to change your application data or login settings, you can create a QR code with URL of json file(e.g. www.my_test_server.com/settings.json) that contains desired data. 
	JSON file format is: 
	
	
	{"root":
		{
			"outerFrameURL": "<-- enter outer frame url here (e.g. https://app-javascript.hookflash.me/outer.html?view=choose) -->",
			"identityProviderDomain": "<-- enter identity provider domain here (e.g. idprovider-javascript.hookflash.me) -->",
			"identityFederateBaseURI": "<-- enter federated identity base uri here (e.g. identity://idprovider-javascript.hookflash.me/) -->",
			"namespaceGrantServiceURL": "<-- enter outer namespace grant service url here (e.g. https://app-javascript.hookflash.me/outernamespacegrant.html) -->",
			"lockBoxServiceDomain": "<-- enter lockbox service domain here (e.g. hcs-javascript.hookflash.me) -->",
			"defaultOutgoingTelnetServer": "<-- enter outgoing telnet server here (e.g. tcp.logger.hookflash.me:8055) -->"
			"localTelnetLoggerPort": "<-- enter outgoing telnet server here (e.g. 59999) -->";
		}
	}
	
	

5) Now you can hit the run on OpenPeerSampleApp scheme


6) In case you just want to add OpenPeerSDK.framework to your project, beside adding frameworks liste below, it is required to add boost and curl libraries and data model bundle OpenpeerDataModel.bundle. Libraries are in OpenPeerSDK.framework/Libraries, and bundle in OpenPeerSDK.framework/Resources


Required frameworks:
	CoreAudio.framework
	CoreVideo.framework
	CoreMedia.framework
	CoreImage.framework
	CoreGraphics.framework
	AudioToolbox.framework
	AVFoundation.framework
	AssetsLibrary.framework
	MobileCoreServices.framework
	CFNetwork.framework
	Foundation.framework
	Security.framework
	SystemConfiguration.framework
	UIKit.framework
	CoreTelephony.framework
	AudioToolbox.framework
	CoreData.framework
	libresolve.dylib
	libz.dylib
	libsqlite3.dylib
	libstdc++.6.0.9.dylib



Exploring the dependency libraries:
Core Projects/zsLib      - asynchronous communication library for C++
Core Projects/udns       - C language DNS resolution library
Core Projects/cryptopp   – C++ cryptography language
Core Projects/hfservices - C++ Hookflash Open Peer communication services layer
Core Projects/hfstack    – C++ Hookflash Open Peer stack
Core Projects/hfcore     – C++ Hookflash Open Peer core API (works on the Open Peer stack)
Core Projects/webrtc     – iPhone port of the webRTC media stack


Exploring the SDK:
openpeer-ios-sdk/         - header files used to build Open Peer iOS applications
openpeer-ios-sdk/Source   - implementation of header files
openpeer-ios-sdk/Internal – internal implementation of iOS to C++ wrapper for SDK
Samples/OpenPeerSampleApp - basic example of how to use the SDK


Exploring the header files:

HOPAccount.h
- Object representing Open Peer account.

HOPCache.h
- Object used for caching user data.

HOPCall.h
- Object used for placing audio/video calls created with the contact of a conversation thread.

HOPConctact.h
- Contact object representing a local or remote peer contact/person.

HOPConversationThread.h
- Conversation object where contacts are added and text and calls can be performed.

HOPIdentity.h
- Identity object used for identity login and downloading rolodex contacts.

HOPIdentityLookup.h
- Object used to lookup identities of peer contacts to obtain peer contact information.

HOPIdentityLookupInfo.h
- Object representing information about the identity URI and date of last update.

HOPLogger.h
- Object used for managing core debug logs.

HOPMediaEngine.h
- Object used for media control.

HOPMediaEngineRtpRtcpStatistics.h
- Object representing media engine stats.

HOPMessage.h
- Object representing sent/received message.

HOPModelManager.h
- Object used for core data manipulation.

HOPProtocols.h
- Object-C protocols to implement callback event routines.

HOPStack.h
- Object to be constructed after HOPClient object, pass in all the listener event protocol objects

HOPTypes.h
- Place where are defined most of enums used in SDK

HOPUtility.h
- Exposed some helper methods

Branches:

Our current activity is being performed on "20140401-dev-stable" but this branch is unstable. Individual activity is on other sub-branches from this branch.
https://github.com/openpeer/opios/tree/20140401-dev-stable

To see all branches go to:
https://github.com/openpeer/opios/branches


Contact info:

Please contact robin@hookflash.com if you have any suggestions to improve the API. Please use support@hookflash.com for any bug reports. New feature requests should be directed to erik@hookflash.com.

Thank you for your interest in the Hookflash Open Peer iOS SDK.

License:

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



