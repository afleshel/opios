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

#if defined(__cplusplus)
#define SDK_EXTERN extern "C"
#else
#define SDK_EXTERN extern
#endif

SDK_EXTERN void HOPLog(HOPLoggerLevel logLevel, NSString* format,...);

/**
 Singleton class to represent the openpeer stack.
 */
@interface HOPLogger : NSObject

/**
 Converts logger severity enum to string
 @param severity HOPLoggerSeverity Logger severity enum
 @returns String representation of logger severitiy
 */
+ (NSString*) stringForSeverity:(HOPLoggerSeverity) severity;

/**
 Converts logger level enum to string
 @param level HOPLoggerSeverity Logger level enum
 @returns String representation of logger severitiy
 */
+ (NSString*) stringForLevel:(HOPLoggerLevel) level;

/**
 Install a logger to output to the standard out.
 @param colorizeOutput BOOL Flag to enable/disable output colorization
 */
+ (void) installStdOutLoggerWithColorizedOutput: (BOOL) colorizeOutput;
+ (void) installStdOutLogger;
/**
 Install a logger to output to a file.
 @param filename NSString Name of the log file
 @param colorizeOutput BOOL Flag to enable/disable output colorization
 */
+ (void) installFileLogger: (NSString*) filename colorizeOutput: (BOOL) colorizeOutput;

/**
 Install a logger to output to a telnet prompt.
 @param listenPort unsigned short Port for listening
 @param maxSecondsWaitForSocketToBeAvailable unsigned long Specify how long will logger wait for socket
 @param colorizeOutput BOOL Flag to enable/disable output colorization
 */
+ (void) installTelnetLogger: (unsigned short) listenPort maxSecondsWaitForSocketToBeAvailable:(unsigned long) maxSecondsWaitForSocketToBeAvailable colorizeOutput: (BOOL) colorizeOutput;

/**
 Install a logger that sends a telnet outgoing to a telnet server.
 @param serverToConnect NSString Call Server address
 @param colorizeOutput BOOL Flag to enable/disable output colorization
 @param stringToSendUponConnection NSString String to send to the server when connection is established
 */
+ (void) installOutgoingTelnetLogger: (NSString*) serverToConnect colorizeOutput: (BOOL) colorizeOutput stringToSendUponConnection: (NSString*) stringToSendUponConnection;

/**
 Install a logger to output to the debugger window.
 */
+ (void) installWindowsDebuggerLogger;

/**
 Install a logger to monitor the functioning of the application internally.
 */
+ (void) installCustomLogger: (id<HOPLoggerDelegate>) delegate;

/**
 Gets the unique ID for the GUI's subsystem (to pass into the log routine for GUI logging)
 @return Return subsystem unique ID
 */
+ (unsigned int) getApplicationSubsystemID;// previous name getGUISubsystemUniqueID;

/**
 Gets the currently set log level for a particular subsystem.
 @param subsystemUniqueID unsigned int Unique ID of the log subsystem
 @returns Log level enum
 */
+ (HOPLoggerLevel) getLogLevel: (unsigned int) subsystemUniqueID;

/**
 Sets all subsystems to a specific log level.
 @param level HOPLoggerLevel Level to set
 */
+ (void) setLogLevel: (HOPLoggerLevel) level;

/**
 Sets a particular subsystem's log level by unique ID.
 @param subsystemUniqueID unsigned long Unique ID of the log subsystem
 @param level HOPLoggerLevel Level to set
 */
+ (void) setLogLevelByID: (unsigned long) subsystemUniqueID level: (HOPLoggerLevel) level;

/**
 Sets a particular subsystem's log level by its subsystem name.
 @param subsystemName NSString Name of the log subsystem
 @param level HOPLoggerLevel Level to set
 */
+ (void) setLogLevelbyName: (NSString*) subsystemName level: (HOPLoggerLevel) level;

/**
 Sends a message to the logger(s) for a particular subsystem.
 @param subsystemUniqueID unsigned long Unique ID of the log subsystem
 @param severity HOPLoggerSeverity Log severity
 @param level HOPLoggerLevel Log level
 @param message NSString Message to log
 @param function NSString Log function
 @param filePath NSString Path to log file
 @param lineNumber unsigned long Number of the log line
 @returns String representation of call closed reason enum
 */
+ (void) log: (unsigned int) subsystemUniqueID severity: (HOPLoggerSeverity) severity level: (HOPLoggerLevel) level message: (NSString*) message function: (NSString*) function filePath: (NSString*) filePath lineNumber: (unsigned long) lineNumber;

/**
 Uninstall various types of loggers.
 */
+ (void) uninstallStdOutLogger;
+ (void) uninstallFileLogger;
+ (void) uninstallTelnetLogger;
+ (void) uninstallOutgoingTelnetLogger;
+ (void) uninstallDebuggerLogger;

/**
 Checks if the telnet logger is listening for incoming telnet connections.
 @returns true if telnet logger is listening for connections
 */
+ (BOOL) isTelnetLoggerListening;

/**
 Checks if the telnet logger has a telnet client connected to the telnet logger port
 @returns true if telnet client is connected to telnet logger port
 */
+ (BOOL) isTelnetLoggerConnected;

/**
 Checks if the outgoing telnet logger is connected to a telnet logging server.
 @returns true if outgoing telnet logger is connected to a telnet logging server
 */
+ (BOOL) isOutgoingTelnetLoggerConnected;

@end