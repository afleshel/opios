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

#import "HOPUtility.h"
#include <zsLib/String.h>
#import <openpeer/services/IHelper.h>

@implementation HOPUtility

+ (NSString*) getBaseIdentityURIFromURI:(NSString*) identityURI
{
    NSString* ret = @"";
    NSArray* identityParts = [identityURI componentsSeparatedByString:@"/"];
    if ([identityParts count] > 3)
    {
        int maxCount = [identityParts count] - 1;
        for (int i = 0; i < maxCount; i++)
        {
            ret = [ret stringByAppendingFormat:@"%@/",[identityParts objectAtIndex:i]];
        }
    }
    return ret;
}

+ (NSString*) getContactIdFromURI:(NSString*) identityURI
{
    {
        NSString* ret = @"";
        NSArray* identityParts = [identityURI componentsSeparatedByString:@"/"];
        if ([identityParts count] > 3)
        {
            int index = [identityParts count] - 1;
            ret = [identityParts objectAtIndex:index];
        }
        return ret;
    }
}

+ (BOOL) isBaseIdentityURI:(NSString*) identityURI
{
    BOOL ret = YES;
    NSArray* identityParts = [identityURI componentsSeparatedByString:@"/"];
    if ([identityParts count] > 3)
    {
        int index = [identityParts count] - 1;
        ret = [[identityParts objectAtIndex:index] length] == 0;
    }
    return ret;
}

+ (NSString*) hashString:(NSString*) stringToHash
{
    NSString* ret = nil;
    
    if ([stringToHash length] > 0)
    {
        zsLib::String value = openpeer::services::IHelper::convertToHex(*openpeer::services::IHelper::hash([stringToHash UTF8String]),FALSE);
        if (value.size() > 0)
            ret = [NSString stringWithUTF8String:value];
    }
    
    return ret;
}


+ (NSString *)getGUIDstring
{
    // get new UUID(in windows world is guid)
    CFUUIDRef guid = CFUUIDCreate(nil);
    NSString *strGuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, guid));
    CFRelease(guid);
    return strGuid;
}
@end
