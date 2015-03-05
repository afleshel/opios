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

#import "UIDevice+Networking.h"

@implementation UIDevice (Networking)

/*!
  @function cellularConnected
  @discussion Determine whether the device is connected to the network via 
  Enhanced Data Rate for Global Evolution (EDGE) or General Packet Radio Service (GPRS).
  @result Returns true if device is connected via EDGE or GPRS to the network, false otherwise.
 */
+(BOOL)cellularConnected {
    return [UIDevice networkStatusForInternetConnection] == ReachableViaWWAN;
}
/*!
 @function wiFiConnected
 @discussion Determine whether the device is connected to the network via Wi-Fi.
 @result Returns true if device is connected via WI-FI the network, false otherwise.
 */
+(BOOL)wiFiConnected {
    return [UIDevice networkStatusForInternetConnection] == ReachableViaWiFi;
}

/*!
 @function networkConnected
 @discussion Determine whether the device is connected to the network via any transport mechanism.
 @result Returns true if device is connected to the network, false otherwise.
 */
+(BOOL)isNetworkReachable {
    return [UIDevice networkStatusForInternetConnection] != NotReachable;
}

+(void)startNotifier {
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
}

+(void)stopNotifier {
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    [reachability stopNotifier];
}

+(NetworkStatus)networkStatusForInternetConnection {
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    return [reachability currentReachabilityStatus];    
}

@end
