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

#import "OpenPeerCacheDelegate.h"
#import "OpenPeerUtility.h"
#import "HOPModelManager.h"

OpenPeerCacheDelegate::OpenPeerCacheDelegate(id<HOPCacheDelegate> inCacheDelegate)
{
    cacheDelegate = inCacheDelegate;
}

boost::shared_ptr<OpenPeerCacheDelegate>  OpenPeerCacheDelegate::create(id<HOPCacheDelegate> inCacheDelegate)
{
    return boost::shared_ptr<OpenPeerCacheDelegate> (new OpenPeerCacheDelegate(inCacheDelegate));
}

String OpenPeerCacheDelegate::fetch(const char *cookieNamePath)
{
    String ret;
    NSString* path = [NSString stringWithUTF8String:cookieNamePath];
    if (path)
    {
        NSString* cookie = [[HOPModelManager sharedModelManager] getCookieWithPath:path];//[cacheDelegate fetchCookieWithPath:path];
        if ([cookie length] > 0)
            ret = [cookie UTF8String];
    }
    return ret;
}

void OpenPeerCacheDelegate::store(const char *cookieNamePath,Time expires,const char *str)
{
    NSString* cookie = [NSString stringWithUTF8String:str];
    NSString* path = [NSString stringWithUTF8String:cookieNamePath];
    NSDate* date = [OpenPeerUtility convertPosixTimeToDate:expires];
    
    //[cacheDelegate storeCookie:cookie cookieNamePath:path expireTime:date];
    [[HOPModelManager sharedModelManager]setCookie:cookie withPath:path expires:date];
}

void OpenPeerCacheDelegate::clear(const char *cookieNamePath)
{
    NSString* path = [NSString stringWithUTF8String:cookieNamePath];
    [[HOPModelManager sharedModelManager] removeCookieForPath:path];
    //[cacheDelegate clearCookieWithPath:path];
}