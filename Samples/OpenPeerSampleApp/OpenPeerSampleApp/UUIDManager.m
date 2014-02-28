/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "UUIDManager.h"
#import <Security/Security.h>
#import "Utility.h"

@interface UUIDManager()

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void) writeToKeychain;
- (BOOL) readFromKeychain;
@end

//Unique string used to identify the keychain item:
static const UInt8 kKeychainItemIdentifier[]    = "com.Hookflash.Keychain\\GrantId";

@implementation UUIDManager

@synthesize keychainData = _keychainData;
@synthesize genericPasswordQuery = _genericPasswordQuery;

+ (id) sharedUUIDManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

#pragma mark - init/dealloc
- (id)initSingleton
{
    if ((self = [super init])) 
    {
        self.keychainData = [[NSMutableDictionary alloc] init];
        
        // Set up the keychain search dictionary:
        genericPasswordQuery = [[NSMutableDictionary alloc] init];
        // This keychain item is a generic password.
        [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                                 forKey:(__bridge id)kSecClass];
        
        // The kSecAttrGeneric attribute is used to store a unique string that is used
        // to easily identify and find this keychain item. The string is first
        // converted to an NSData object:
        NSData *keychainItemID = [NSData dataWithBytes:kKeychainItemIdentifier
                                                length:strlen((const char *)kKeychainItemIdentifier)];
        [genericPasswordQuery setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
        
        // Return the attributes of the first match only:
        [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        
        // Return the attributes of the keychain item (the password is
        //  acquired in the secItemFormatToDictionary: method):
        [genericPasswordQuery setObject:(id)kCFBooleanTrue
                                 forKey:(__bridge id)kSecReturnAttributes];
    }
    return self;
}

#pragma mark - UUID get/save
- (NSString*) getUUID
{
    NSString* ret = nil;
    
    if ([self readFromKeychain])
        ret = [self.keychainData objectForKey:(__bridge id)kSecValueData];
    else 
    {
        ret = [self  generateUUID];
    }
    
    return ret;
}

- (NSString *)generateUUID
{
    NSString* ret = [Utility getGUIDstring];
    [self saveUUID:ret];
    return ret;
}

#pragma mark - Keychain read/save
- (BOOL) readFromKeychain
{
    BOOL ret = YES;
    
    OSStatus keychainErr = noErr;
    
    //Initialize the dictionary used to hold return data from the keychain:
    NSMutableDictionary *outDictionary = nil;
    CFDictionaryRef cfOutDictionary = NULL;
    
    // If the keychain item exists, return the attributes of the item: 
    keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery,
                                      (CFTypeRef *)&cfOutDictionary);
    if (keychainErr == noErr) 
    {
        outDictionary = (__bridge_transfer NSMutableDictionary *)cfOutDictionary;
        // Convert the data dictionary into the format used by the view controller:
        self.keychainData = [self secItemFormatToDictionary:outDictionary];
    } 
    else if (keychainErr == errSecItemNotFound) 
    {
        ret = NO;
        NSLog(@"UUID not found in keychain");
    } 
    else 
    {
        ret = NO;
        // Any other error is unexpected.
        NSLog(@"Reading keychain serious error.\n");
    }
    return ret;
}

// This method modifies an existing keychain item, or--if the item does not already
//   exist--creates a new keychain item with the new attribute value plus
//  default values for the other attributes.
- (void)writeToKeychain
{
    NSDictionary *attributes = nil;
    NSMutableDictionary *updateItem = nil;
    
    CFDictionaryRef cfAttributes = NULL;
    
    // If the keychain item already exists, modify it:
    if (SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery,
                            (CFTypeRef *)&cfAttributes) == noErr)
    {
        attributes = (__bridge_transfer NSDictionary *)cfAttributes;
        // First, get the attributes returned from the keychain and add them to the
        // dictionary that controls the update:
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        // Second, get the class value from the generic password query dictionary and
        // add it to the updateItem dictionary:
        [updateItem setObject:[genericPasswordQuery objectForKey:(__bridge id)kSecClass]
                       forKey:(__bridge id)kSecClass];
        
        // Finally, set up the dictionary that contains new values for the attributes:
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainData];
        //Remove the class--it's not a keychain attribute:
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        // You can update only a single keychain item at a time.
        NSAssert(SecItemUpdate((__bridge CFDictionaryRef)updateItem,
                               (__bridge CFDictionaryRef)tempCheck) == noErr,
                 @"Couldn't update the Keychain Item." );
    }
    else
    {
        // No previous item found; add the new item.
        
        // No pointer to the newly-added items is needed, so pass NULL for the second parameter:
        NSAssert(SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainData],
                            NULL) == noErr, @"Couldn't add the Keychain Item." );
    }
}

- (void) saveUUID:(NSString*) uuid
{
    [self.keychainData setObject:uuid forKey:(__bridge id)kSecValueData];
    [self writeToKeychain];
}

#pragma mark - Helper methods
// This method takes the attribute dictionary obtained from the keychain item, acquires 
// the password from the keychain, and adds it to the attribute dictionary.
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for the keychain item.
    
    // Create a return dictionary populated with the attributes:
    NSMutableDictionary *returnDictionary = [NSMutableDictionary
                                             dictionaryWithDictionary:dictionaryToConvert];
    
    // To acquire the password data from the keychain item,
    // first add the search key and class attribute required to obtain the password:
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    // Then call Keychain Services to get the password:
    NSData *passwordData = nil;
    CFTypeRef cfPasswordData = NULL;
    OSStatus keychainError = noErr; //
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary,
                                        (CFTypeRef *)&cfPasswordData);
    if (keychainError == noErr)
    {
        passwordData = (__bridge NSData *)cfPasswordData;
        // Remove the kSecReturnData key; we don't need it anymore:
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        // Convert the password to an NSString and add it to the return dictionary:
        NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                                       length:[passwordData length] encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
    }
    // Don't do anything if nothing is found.
    else if (keychainError == errSecItemNotFound) {
        NSLog(@"Nothing was found in the keychain.\n");
    }
    // Any other error is unexpected.
    else
    {
        NSLog(@"Serious error.\n");
    }
    
    return returnDictionary;
}

// This method takes the attributes that
//   you want to add to the keychain item and sets up a dictionary in the format
//  needed by Keychain Services:
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for a keychain item search.
    
    // Create the return dictionary:
    NSMutableDictionary *returnDictionary =
    [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    // Add the keychain item class and the generic attribute:
    NSData *keychainItemID = [NSData dataWithBytes:kKeychainItemIdentifier
                                            length:strlen((const char *)kKeychainItemIdentifier)];
    [returnDictionary setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    // Convert the password NSString to NSData to fit the API paradigm:
    NSString *passwordString = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(__bridge id)kSecValueData];
    return returnDictionary;
}
@end
