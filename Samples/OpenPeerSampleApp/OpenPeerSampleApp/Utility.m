/*
 
 Copyright (c) 2012, SMB Phone Inc.
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

#import "Utility.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import <AVFoundation/AVFoundation.h>

@implementation Utility

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

+ (NSString *) base64StringFromData: (NSData *)data length: (int)length
{
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0;
    
    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", _base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }
    return result;
}

+(NSString *)decodeBase64:(NSString *)data64based
{
    const char *objPointer = [data64based cStringUsingEncoding:NSASCIIStringEncoding];
    if (objPointer == NULL)  return nil;
    size_t intLength = strlen(objPointer);
    int intCurrent;
    int i = 0, j = 0, k;
    
    unsigned char * objResult;
    objResult = calloc(intLength, sizeof(unsigned char));
    
    // Run through the whole string, converting as we go
    while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
        if (intCurrent == '=') {
            if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
                                                       // the padding character is invalid at this point -- so this entire string is invalid
                free(objResult);
                return nil;
            }
            continue;
        }
        
        intCurrent = _base64DecodingTable[intCurrent];
        if (intCurrent == -1) {
            // we're at a whitespace -- simply skip over
            continue;
        } else if (intCurrent == -2) {
            // we're at an invalid character
            free(objResult);
            return nil;
        }
        
        switch (i % 4) {
            case 0:
                objResult[j] = intCurrent << 2;
                break;
                
            case 1:
                objResult[j++] |= intCurrent >> 4;
                objResult[j] = (intCurrent & 0x0f) << 4;
                break;
                
            case 2:
                objResult[j++] |= intCurrent >>2;
                objResult[j] = (intCurrent & 0x03) << 6;
                break;
                
            case 3:
                objResult[j++] |= intCurrent;
                break;
        }
        i++;
    }
    
    // mop things up if we ended on a boundary
    k = j;
    if (intCurrent == '=') {
        switch (i % 4) {
            case 1:
                // Invalid state
                free(objResult);
                return nil;
                
            case 2:
                k++;
                // flow through
            case 3:
                objResult[k] = 0;
        }
    }
    
    NSData* retData = [[NSData alloc] initWithBytesNoCopy:objResult length:j freeWhenDone:YES];
    NSString* retString = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
    return retString;
    // Cleanup and setup the return NSData
    //return [[NSString alloc] initWithData:[[[NSData alloc] initWithBytesNoCopy:objResult length:j freeWhenDone:YES] autorelease] encoding:NSUTF8StringEncoding];
    //return string should be autorelease
    //[[[NSData alloc] initWithBytesNoCopy:objResult length:j freeWhenDone:YES] autorelease];
    
}

+ (NSString*) getDeviceOs
{
    NSString* deviceOs = [NSString stringWithFormat:@"%@ %@,",[[UIDevice currentDevice] systemName],[[UIDevice currentDevice]  systemVersion]];
    return deviceOs;
}

+ (NSString*) getPlatform
{
    size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    //sysctlbyname("hw.model", NULL, &size, NULL, 0);
	char *machine = (char*)malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
    //sysctlbyname("hw.model", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);
    
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 1G";
	if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([platform hasPrefix:@"iPhone3"]) return @"iPhone 4";
    if ([platform hasPrefix:@"iPhone4"]) return @"iPhone 4S";
    if ([platform hasPrefix:@"iPhone6,2"]) return @"iPhone 5S";
    
	if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
	if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
    if ([platform hasPrefix:@"iPod3"])   return @"iPod Touch 3G";
    if ([platform hasPrefix:@"iPod4"])   return @"iPod Touch 4G";
    
    
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1";
	if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2";
    if ([platform hasPrefix:@"iPad3"])    return @"iPad 3";
    
	if ([platform isEqualToString:@"i386"])   return @"iPhone Simulator";
	return platform;
    //return [[UIDevice currentDevice] model];
}

+ (NSString*) getUserAgentName
{
    NSString* developerId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Hookflash Developer ID"] == nil ? @"" : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Hookflash Developer ID"];
    
    
    NSString* appName = [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"];
    NSString* appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* appOs = [[UIDevice currentDevice] systemName];
    NSString* appVersionOs = [[UIDevice currentDevice] systemVersion];
    NSString* deviceModel = [[UIDevice currentDevice] model];
    
    NSString* model = nil;
    
    if ([deviceModel hasPrefix:@"iPhone"] || [deviceModel hasPrefix:@"iPod"])
        model = @"iPhone";
    else if ([deviceModel hasPrefix:@"iPad"])
        model = @"iPad";
    
    NSString* userAgent = [NSString stringWithFormat:@"%@/%@ (%@ %@;%@) HOPID/1.0 (%@)",appName,appVersion,appOs,appVersionOs,model,developerId];
    
    return userAgent;
}

+ (void)removeCookiesAndClearCredentials
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in [cookieStorage cookies])
    {
        [cookieStorage deleteCookie:each];
    }
}
//
//+ (NSString *)getGUIDstring
//{
//    // get new UUID(in windows world is guid)
//    CFUUIDRef guid = CFUUIDCreate(nil);
//    NSString *strGuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, guid));
//    CFRelease(guid);
//    return strGuid;
//}

+ (NSString*) getCallStateAsString:(HOPCallState) callState
{
    NSString *res = nil;
    
    switch (callState)
    {
            case HOPCallStateNone:
            //res = NSLocalizedString(@"none", @"");
                break;
            case HOPCallStatePreparing:
                res = NSLocalizedString(@"preparing", @"");
                break;
            case HOPCallStateIncoming:
                res = NSLocalizedString(@"incoming", @"");
                break;
            case HOPCallStatePlaced:
                res = NSLocalizedString(@"placed", @"");
                break;
            case HOPCallStateEarly:
                res = NSLocalizedString(@"early", @"");
                break;
            case HOPCallStateRinging:
                res = NSLocalizedString(@"ringing", @"");
                break;
            case HOPCallStateRingback:
                res = NSLocalizedString(@"ringback", @"");
                break;
            case HOPCallStateOpen:
                res = NSLocalizedString(@"open", @"");
                break;
            case HOPCallStateActive:
                res = NSLocalizedString(@"active", @"");
                break;
            case HOPCallStateInactive:
                res = NSLocalizedString(@"inactive", @"");
                break;
            case HOPCallStateHold:
                res = NSLocalizedString(@"hold", @"");
                break;
            case HOPCallStateClosing:
                res = NSLocalizedString(@"closing", @"");
                break;
            case HOPCallStateClosed:
                res = NSLocalizedString(@"closed", @"");
                break;
            default:
                return nil;
    }
    return res;
}

+ (NSString*) getMessageDeliveryStateAsString:(HOPConversationThreadMessageDeliveryState) messageState
{
    NSString *res = nil;
    
    switch (messageState)
    {
        case HOPConversationThreadMessageDeliveryStateDiscovering:
            res = NSLocalizedString(@"discovering", @"");
            break;
        case HOPConversationThreadMessageDeliveryStateUserNotAvailable:
            res = NSLocalizedString(@"user not available", @"");
            break;
        case HOPConversationThreadMessageDeliveryStateSent:
            res = NSLocalizedString(@"sent", @"");
            break;
        case HOPConversationThreadMessageDeliveryStateDelivered:
            res = NSLocalizedString(@"delivered", @"");
            break;
      case HOPConversationThreadMessageDeliveryStateRead:
            res = NSLocalizedString(@"read", @"");
            break;
    }
    return res;
}

+ (NSString*) getFunctionNameForRequest:(NSString*) requestString
{
    NSString* ret = @"";
    
    if ([requestString hasPrefix:@"https://datapass.hookflash.me/?method="])
        ret = [requestString substringFromIndex:[@"https://datapass.hookflash.me/?method=" length]];
    else if ([requestString hasPrefix:@"http://datapass.hookflash.me/?method="])
        ret = [requestString substringFromIndex:[@"http://datapass.hookflash.me/?method=" length]];
    
    NSArray *components = [ret componentsSeparatedByString:@";"];
    
    if ([components count] > 0)
        ret = [components objectAtIndex:0];
    return ret;
}

+ (NSString*) getParametersNameForRequest:(NSString*) requestString
{
    NSString* ret = @"";
    
    NSArray *components = [requestString componentsSeparatedByString:@";"];
    
    if ([components count] == 2)
    {
        
        NSString *params = (NSString*)[components objectAtIndex:1];
        if ([params hasPrefix:@"data="])
        {
            ret = [params substringFromIndex:[@"data=" length]];
        }
    }
    
    return ret;
}

+ (UIBarButtonItem*) createNavigationBackButtonForTarget:(id) target
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"iPhone_back_button.png"] forState:UIControlStateNormal];
    [button addTarget:target action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    UIBarButtonItem* backButon = [[UIBarButtonItem alloc] initWithCustomView: button];
    return backButon;
}

+ (NSString *)formatedMessageTimeStampForDate:(NSDate*) inDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    NSDateComponents *massageDayOfDate = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:inDate];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    if([today day] == [massageDayOfDate day] &&
       [today month] == [massageDayOfDate month] &&
       [today year] == [massageDayOfDate year] &&
       [today era] == [massageDayOfDate era])
    {
        //[df setDateFormat:@"hh:mm:ss aa"];
        [df setDateFormat:@"hh:mm aa"];
    }
    else
    {
        [df setDateFormat:@"MM/dd/yyyy hh:mm aa"];
    }
    
    return [df stringFromDate:inDate];
}

+ (NSString *)hexadecimalStringForData:(NSData *)data
{
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

+ (int) getNumberOfDeviceCameras
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}
+ (BOOL) hasCamera
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0;
}

+ (BOOL) isValidURL: (NSString *) candidate
{
    NSString *urlRegEx =@"^(http://www.|https://www.|http://|https://)[a-z0-9]+([-.]{1}[a-z0-9]+)*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?$";
    //@"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

+ (BOOL) isValidJSON:(NSString *)json
{
    BOOL ret = NO;

    if ([json length] > 0)
    {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        ret = jsonObj != nil;
    }
    
    return ret;
}

+ (NSString *) stringFromDate: (NSDate*) date
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [timeFormatter setDateFormat:@"yyyy:MM:dd HH:mm"];
    NSString* ret = [timeFormatter stringFromDate:date];
    return ret;
}

+ (NSDate *) dateFromTimeString: (NSString*) timeStr
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"yyyy:MM:dd HH:mm"];
    [timeFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate *date = [timeFormatter dateFromString:timeStr];
    return date;
}



+ (BOOL) isAppUpdated
{
    BOOL ret = YES;
    NSDate* appPreviousModificationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"appUpdateDate"];
    NSString *exePath = [[NSBundle mainBundle] executablePath];
    NSDictionary *exeAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:exePath error:nil];
    NSDate *lastModificationDate = [exeAttrs objectForKey:@"NSFileModificationDate"];
    
    if ([lastModificationDate isEqualToDate:appPreviousModificationDate])
        ret = NO;
    else
        [[NSUserDefaults standardUserDefaults] setObject:lastModificationDate forKey:@"appUpdateDate"];
        
    return ret;
}

+ (void) showLocalNotification:(NSString*) messageText additionalData:(NSDictionary*) additionalData
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.alertBody = messageText;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = @"message-received.wav";
    notification.userInfo = additionalData;
    //notification.applicationIconBadgeNumber = 10;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

+ (BOOL) isRuningForTheFirstTime
{
    BOOL ret = YES;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"isRuningForTheFirstTime"])
    {
        ret = NO;
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"isRuningForTheFirstTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return ret;
}

+ (NSString *)getLocalDateFromUTCdate:(NSDate *)utcDate
{
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    df.dateFormat = @"MM/dd/yyyy hh:mm aa";
//    [df setTimeZone:[NSTimeZone systemTimeZone]];
//    
//    return [df stringFromDate:utcDate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateString = [dateFormatter stringFromDate:utcDate];
    
    return dateString;
}

+ (NSString*) stringForEndingCallReason:(int) endingCallReason
{
    NSString* ret = nil;
    
    switch (endingCallReason)
    {
        case 0:
            ret = @"Call ended";
            break;
        case 404:
            ret = @"Call ended - no answer";
            break;
        case 408:
            ret = @"Call ended - network issue";
            break;
        default:
            ret = @"Call ended";
            break;
    }
    
    return ret;
}
+ (UIImage*) createImageFromImages:(NSArray*) images inFrame:(CGRect) frame
{
    UIImage* ret = nil;
    
    int root = sqrt(images.count) <= 2.0 ? 2 :  sqrt(images.count) + 1;
    
    float width = frame.size.width/(float)root;
    float height = frame.size.height/(float)root;
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
    
    int rowCounter = 0;
    int columnCounter = 0;
    float x = 0;
    float y = 0;
    for (UIImage* image in images)
    {
        if (columnCounter >= root)
        {
            columnCounter = 0;
            rowCounter++;
            x = 0;
            y += height;
        }
        
        [image drawInRect:CGRectMake(x, y, width, height)];
        
        x += width;
        columnCounter++;
    }
    
    ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return ret;
}
@end
