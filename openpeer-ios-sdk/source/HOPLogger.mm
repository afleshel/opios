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

#import "HOPLogger.h"
#import <openpeer/core/ILogger.h>

ZS_DECLARE_SUBSYSTEM(application)

using namespace openpeer;
using namespace openpeer::core;

void HOPLog(HOPLoggerLevel logLevel, NSString* format,...)
{
    va_list argumentList;
    va_start(argumentList, format);
    NSString *fullString = [[NSString alloc] initWithFormat:format arguments:argumentList];
    va_end(argumentList);
    
    switch (logLevel)
    {
        case HOPLoggerLevelBasic:
            ZS_LOG_BASIC(zsLib::String("Application: ") + [fullString UTF8String]);
            break;
            
        case HOPLoggerLevelDetail:
            ZS_LOG_DETAIL(zsLib::String("Application: ") + [fullString UTF8String]);
            break;
            
        case HOPLoggerLevelDebug:
            ZS_LOG_DEBUG(zsLib::String("Application: ") + [fullString UTF8String]);
            break;
            
        case HOPLoggerLevelTrace:
            ZS_LOG_TRACE(zsLib::String("Application: ") + [fullString UTF8String]);
            break;

        case HOPLoggerLevelInsane:
            ZS_LOG_INSANE(zsLib::String("Application: ") + [fullString UTF8String]);
            break;

        case HOPLoggerLevelNone:
        default:
            break;
    }
}

@implementation HOPLogger


+ (NSString*) stringForSeverity:(HOPLoggerSeverity) severity
{
    NSString* ret = nil;
    switch (severity)
    {
        case HOPLoggerSeverityInformational:
            ret = NSLocalizedString(@"Informational",@"Informational");
            break;
            
        case HOPLoggerSeverityWarning:
            ret = NSLocalizedString(@"Warning",@"Warning");
            break;
            
        case HOPLoggerSeverityError:
            ret = NSLocalizedString(@"Error",@"Error");
            break;
            
        case HOPLoggerSeverityFatal:
            ret = NSLocalizedString(@"Fatal error",@"Fatal error");
            break;
            
        default:
            ret = @"";
            break;
    }
    
    return ret;
}

+ (NSString*) stringForLevel:(HOPLoggerLevel) level
{
    NSString* ret = nil;
    switch (level)
    {
        case HOPLoggerLevelNone:
            ret = NSLocalizedString(@"None",@"None");
            break;
            
        case HOPLoggerLevelBasic:
            ret = NSLocalizedString(@"Basic",@"Basic");
            break;
            
        case HOPLoggerLevelDetail:
            ret = NSLocalizedString(@"Detail",@"Detail");
            break;
            
        case HOPLoggerLevelDebug:
            ret = NSLocalizedString(@"Debug",@"Debug");
            break;
            
        case HOPLoggerLevelTrace:
            ret = NSLocalizedString(@"Trace",@"Trace");
            break;

        case HOPLoggerLevelInsane:
            ret = NSLocalizedString(@"Insane",@"Insane");
            break;

        default:
            ret = @"";
            break;
    }
    
    return ret;
}

+ (void) installStdOutLoggerWithColorizedOutput: (BOOL) colorizeOutput
{
    ILogger::installStdOutLogger(colorizeOutput);
}

+ (void) installStdOutLogger
{
    ILogger::installStdOutLogger(NO);
}

+ (void) installFileLogger: (NSString*) filename colorizeOutput: (BOOL) colorizeOutput
{
    if ([filename length] > 0)
        ILogger::installFileLogger([filename UTF8String], colorizeOutput);
    else
        [NSException raise:NSInvalidArgumentException format:@"Invalid file name!"];
}

+ (void) installTelnetLogger: (unsigned short) listenPort maxSecondsWaitForSocketToBeAvailable:(unsigned long) maxSecondsWaitForSocketToBeAvailable colorizeOutput: (BOOL) colorizeOutput
{
    ILogger::installTelnetLogger(listenPort, maxSecondsWaitForSocketToBeAvailable, colorizeOutput);
}

+ (void) installOutgoingTelnetLogger: (NSString*) serverToConnect colorizeOutput: (BOOL) colorizeOutput stringToSendUponConnection: (NSString*) stringToSendUponConnection
{
    NSString* str = stringToSendUponConnection ? [stringToSendUponConnection stringByAppendingString:@"\n"] : @"";
    
    if ([serverToConnect length] > 0)
        ILogger::installOutgoingTelnetLogger([serverToConnect UTF8String], colorizeOutput,[str UTF8String]);
    else
        [NSException raise:NSInvalidArgumentException format:@"Invalid server name!"];
}

+ (void) installWindowsDebuggerLogger
{
    ILogger::installDebuggerLogger();
}

+ (void) installCustomLogger: (id<HOPStackDelegate>) delegate
{
    ILogger::installCustomLogger();
}

+ (unsigned int) getApplicationSubsystemID
{
    return ILogger::getApplicationSubsystemID();
}

+ (HOPLoggerLevel) getLogLevel: (unsigned int) subsystemUniqueID
{
    return (HOPLoggerLevel) ILogger::getLogLevel(subsystemUniqueID);
}

+ (void) setLogLevel: (HOPLoggerLevel) level
{
    ILogger::setLogLevel((ILogger::Level) level);
}

+ (void) setLogLevelByID: (unsigned long) subsystemUniqueID level: (HOPLoggerLevel) level
{
    ILogger::setLogLevel((zsLib::PTRNUMBER)subsystemUniqueID, (ILogger::Level) level);
}

+ (void) setLogLevelbyName: (NSString*) subsystemName level: (HOPLoggerLevel) level
{
    if ([subsystemName length] > 0)
        ILogger::setLogLevel([subsystemName UTF8String], (ILogger::Level) level);
    else
        [NSException raise:NSInvalidArgumentException format:@"Invalid subsystem name!"];
}

+ (void) log: (unsigned int) subsystemUniqueID severity: (HOPLoggerSeverity) severity level: (HOPLoggerLevel) level message: (NSString*) message function: (NSString*) function filePath: (NSString*) filePath lineNumber: (unsigned long) lineNumber
{
    NSString* strMessage = message ? message : @"";
    NSString* strFunction = function ? function : @"";
    NSString* strFilePath = filePath ? filePath : @"";
    
    ILogger::log((zsLib::PTRNUMBER) subsystemUniqueID, (ILogger::Severity) severity, (ILogger::Level) level, [strMessage UTF8String], [strFunction UTF8String], [strFilePath UTF8String], lineNumber);
}

+ (void) uninstallStdOutLogger
{
    ILogger::uninstallStdOutLogger();
}

+ (void) uninstallFileLogger
{
    ILogger::uninstallFileLogger();
}
+ (void) uninstallTelnetLogger
{
    ILogger::uninstallTelnetLogger();
}
+ (void) uninstallOutgoingTelnetLogger
{
    ILogger::uninstallOutgoingTelnetLogger();
}
+ (void) uninstallDebuggerLogger
{
    ILogger::uninstallDebuggerLogger();
}

+ (BOOL) isTelnetLoggerListening
{
    return ILogger::isTelnetLoggerListening();
}

+ (BOOL) isTelnetLoggerConnected
{
    return ILogger::isTelnetLoggerConnected();
}

+ (BOOL) isOutgoingTelnetLoggerConnected
{
    return ILogger::isOutgoingTelnetLoggerConnected();
}
@end
