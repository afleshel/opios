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

#import "HOPModelManager.h"
#import "HOPRolodexContact.h"
#import "HOPIdentityContact.h"
#import "HOPAssociatedIdentity.h"
#import "HOPPublicPeerFile.h"
#import "HOPAvatar.h"
#import "HOPOpenPeerAccount.h"
#import "HOPAPNSData.h"
#import "HOPCacheData.h"
#import "HOPConversationRecord.h"
#import "HOPMessageRecord.h"
#import "HOPConversationThreadRecord.h"
#import "HOPContact.h"
#import "HOPConversationThread.h"
#import "HOPUtility.h"
#import "HOPIdentityProvider.h"
#import "HOPOpenPeerContact.h"
#import "HOPConversationEvent.h"
#import "HOPParticipants.h"
#import "HOPContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "OpenPeerConstants.h"
#import <CoreData/CoreData.h>
#import <openpeer/core/IHelper.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/types.h>

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

#define removeOnNextRunExpireTimeInterval  31536000

@interface HOPModelManager()

@property (nonatomic, copy) NSString* cachePath;
@property (copy) NSString* dataPath;
@property BOOL backupData;

- (id) initSingleton;
- (NSArray*) getResultsForEntity:(NSString*) entityName withPredicateString:(NSString*) predicateString orderDescriptors:(NSArray*) orderDescriptors;
@end

@implementation HOPModelManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id)sharedModelManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void) setDataPath:(NSString*) path backupData:(BOOL) inBackupData
{
    //This value can be set only if persistent store cordindator is not initialized
    if (_persistentStoreCoordinator == nil)
    {
        _dataPath = path;
        _backupData = inBackupData;
    }
}

- (void) setCachePath:(NSString*) path
{
    //This value can be set only if persistent store cordindator is not initialized
    if (_persistentStoreCoordinator == nil)
    {
        _cachePath = path;
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext != nil)
    {
        return _backgroundManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil)
    {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _backgroundManagedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSBundle* mainBundle = [NSBundle mainBundle];
    if (mainBundle)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"OpenpeerDataModel" ofType:@"bundle"];
        if (bundlePath)
        {
            NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"OpenPeerModel" withExtension:@"momd"];
            if (modelURL)
                _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        }
    }
  
    if (!_managedObjectModel)
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid managed object model!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid managed object model!"];
    }
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    //Get path for data db path
    NSString *dataPathDirectory = [self.dataPath length] == 0 ? nil : self.dataPath;
    
    if ([dataPathDirectory length] == 0)
    {
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        dataPathDirectory = [libraryPath stringByAppendingPathComponent:databaseDirectory];
    }
    
    //Create a folder if doesn't exists
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPathDirectory withIntermediateDirectories:YES attributes:nil error:&error])
    {
        [NSException raise:@"Failed creating directory" format:@"[%@], %@", dataPathDirectory, error];
    }
    
    //Create data store url
    NSString *pathData = [dataPathDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",databaseName]];
    NSURL *storeDataURL = [NSURL fileURLWithPath:pathData];
    
    
    //Set cache path
    self.cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];

    
    NSString *pathCache = [self.cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",cacheDatabaseName]];
    NSURL *storeCacheURL = [NSURL fileURLWithPath:pathCache];

    
    //Perform lightweight migration if it is necessary;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSPersistentStore* storeData = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Data" URL:storeDataURL options:options error:&error];
    
    if (!storeData)
    {
        NSString* str = [NSString stringWithFormat:@"Error while creating a data persistent store. Error: %@, %@", error, [error userInfo]];
        ZS_LOG_ERROR(Debug, [self log:str]);
        
        //If lightweight migration fails delete the existing store
        BOOL storeIsDeleted = [[NSFileManager defaultManager] removeItemAtURL:storeDataURL error:nil];
        
        if (storeIsDeleted)
        {
            ZS_LOG_DEBUG([self log: @"Existing data store is deleted."]);
            //Try again to add persisiten store
            storeData = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Data" URL:storeDataURL options:options error:&error];
            
            if (!storeData)
            {
                str = [NSString stringWithFormat:@"Error while creating a data persistent store. Error: %@, %@", error, [error userInfo]];
                ZS_LOG_ERROR(Debug, [self log:str]);
            }
        }
        else
        {
            ZS_LOG_DEBUG([self log: @"Failed to delete data store."]);
        }
    }
    
    //Set weather data will be backed up or not
    BOOL success = [storeDataURL setResourceValue: [NSNumber numberWithBool: !self.backupData]
                                           forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success)
    {
        NSString* str = [NSString stringWithFormat:@"Error excluding %@ from backup %@", [storeDataURL lastPathComponent], error];
        ZS_LOG_ERROR(Debug, [self log:str]);
    }

    
    NSPersistentStore* storeCache = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Cache" URL:storeCacheURL options:options error:&error];
    
    
    
    if (!storeCache)
    {
        NSString* str = [NSString stringWithFormat:@"Error while creating a cache persistent store. Error: %@, %@", error, [error userInfo]];
        ZS_LOG_ERROR(Debug, [self log:str]);
        //If lightweight migration fails delete the existing store
        BOOL storeIsDeleted = [[NSFileManager defaultManager] removeItemAtURL:storeCacheURL error:nil];
        
        if (storeIsDeleted)
        {
            ZS_LOG_DEBUG([self log: @"Existing cache store is deleted."]);
            //Try again to add persisiten store
            storeCache = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Cache" URL:storeDataURL options:options error:&error];
            
            if (!storeCache)
            {
                str = [NSString stringWithFormat:@"Error while creating a cache persistent store. Error: %@, %@", error, [error userInfo]];
                ZS_LOG_ERROR(Debug, [self log:str]);
            }
        }
        else
        {
            ZS_LOG_DEBUG([self log: @"Failed to delete cache store."]);
        }
    }
    
    success = [storeCacheURL setResourceValue: [NSNumber numberWithBool: YES]
                                            forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success)
    {
        NSString* str = [NSString stringWithFormat:@"Error excluding %@ from backup %@", [storeCacheURL lastPathComponent], error];
        ZS_LOG_ERROR(Debug, [self log:str]);
    }
    
    if (!storeData || !storeCache)
    {
        ZS_LOG_FATAL(Basic, [self log:@"Persistent store is not created. App is shuting down."]);
        exit(-1);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Core Data storing

- (void)saveContext
{
    NSError *error = nil;
    if (self.managedObjectContext != nil)
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
        {
            NSString* str = [NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]];
            ZS_LOG_ERROR(Debug, [self log:str]);
        }
    }
}

- (void) deleteObject:(NSManagedObject*) managedObjectToDelete
{
    [self.managedObjectContext deleteObject:managedObjectToDelete];
}

- (NSManagedObject*) createObjectForEntity:(NSString*) entityName
{
    NSManagedObject* ret = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
    return ret;
}

#pragma mark - Core Data retrieving
- (NSArray*) getResultsForEntity:(NSString*) entityName withPredicateString:(NSString*) predicateString orderDescriptors:(NSArray*) orderDescriptors
{
    NSArray* ret = nil;
    
    if ([entityName length] > 0)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        if ([predicateString length] > 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
            [fetchRequest setPredicate:predicate];
        }
        
        if ([orderDescriptors count] > 0)
            [fetchRequest setSortDescriptors:orderDescriptors];
        
        NSError *error;
        NSArray *fetchedObjects  = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (!error)
        {
            if([fetchedObjects count] > 0)
            {
                ret = fetchedObjects;
            }
        }
    }
    return ret;
}

- (HOPRolodexContact *) getRolodexContactByIdentityURI:(NSString*) identityURI
{
    HOPRolodexContact* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"(identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (NSArray *) getRolodexContactsByPeerURI:(NSString*) peerURI
{
	NSArray* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identityContact.priority" ascending:NO];
        ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"identityContact.openPeerContact.publicPeerFile.peerURI MATCHES '%@'",peerURI] orderDescriptors:@[sortDescriptor]];
    }
    
    
    return ret;
}

- (NSArray*) getAllRolodexContactForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* ret = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(selfRolodexContact.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        HOPAssociatedIdentity* associatedIdentity = [results objectAtIndex:0];
        ret = [associatedIdentity.rolodexContacts allObjects];
    }
    return ret;
}

- (NSArray*) getRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI openPeerContacts:(BOOL) openPeerContacts
{
    NSArray* ret = nil;
    NSString* stringFormat = nil;
    
    if (openPeerContacts)
    {
        stringFormat = [NSString stringWithFormat:@"(identityContact != nil || identityContact.@count > 0 && associatedIdentity.selfRolodexContact.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    else
    {
        stringFormat = [NSString stringWithFormat:@"(identityContact == nil || identityContact.@count == 0 && associatedIdentity.selfRolodexContact.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    
    ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:stringFormat orderDescriptors:nil];
    
    return ret;
}


- (HOPIdentityContact*) getIdentityContactWithIdentityURI:(NSString*) identityURI
{
    HOPIdentityContact* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPIdentityContact" withPredicateString:[NSString stringWithFormat:@"(rolodexContact.identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}


- (HOPPublicPeerFile*) getPublicPeerFileForPeerURI:(NSString*) peerURI
{
    HOPPublicPeerFile* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPPublicPeerFile" withPredicateString:[NSString stringWithFormat:@"(peerURI MATCHES '%@')", peerURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPIdentityProvider*) addIdentityProviderForBaseURI:(NSString*) baseURI domain:(NSString*) domain name:(NSString*) name
{
    HOPIdentityProvider* ret = nil;
    
    ret = [NSEntityDescription insertNewObjectForEntityForName:@"HOPIdentityProvider" inManagedObjectContext:[self managedObjectContext]];
    
    ret.baseURI = baseURI;
    ret.domain = domain;
    ret.name = name;
    
    return ret;
}

- (HOPIdentityProvider*) getIdentityProviderForBaseURI:(NSString*) baseURI domain:(NSString*) domain
{
    HOPIdentityProvider* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPIdentityProvider" withPredicateString:[NSString stringWithFormat:@"(baseURI MATCHES '%@' AND domain MATCHES '%@')", baseURI, domain] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPAssociatedIdentity*) addAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI domain:(NSString*) domain name:(NSString*) name selfRolodexProfileProfile:(HOPRolodexContact*) rolodexContact
{
    HOPAssociatedIdentity* ret = nil;
    
    ret = [NSEntityDescription insertNewObjectForEntityForName:@"HOPAssociatedIdentity" inManagedObjectContext:[self managedObjectContext]];
    
    HOPIdentityProvider* identityProvider = [self getIdentityProviderForBaseURI:baseIdentityURI domain:domain];
    if (!identityProvider)
        identityProvider = [self addIdentityProviderForBaseURI:baseIdentityURI domain:domain name:name];

    ret.identityProvider = identityProvider;
    
    if (rolodexContact)
        ret.selfRolodexContact = rolodexContact;
    
    if ([[HOPAccount sharedAccount] getOpenPeerUser])
        ret.account = [[HOPAccount sharedAccount] getOpenPeerUser];
    
    [self saveContext];
    
    return ret;
}

- (HOPAssociatedIdentity *) getAssociatedIdentityByDomain:(NSString*) identityProviderDomain identityName:(NSString*) identityName homeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    HOPAssociatedIdentity* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(identityProvider.domain MATCHES '%@' AND identityProvider.baseURI MATCHES '%@' AND selfRolodexContact.identityURI MATCHES '%@')", identityProviderDomain, identityName, homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPAssociatedIdentity*) getAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI homeUserStableId:(NSString*) homeUserStableId
{
    HOPAssociatedIdentity* ret = nil;
    
    if ([homeUserStableId length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(identityProvider.baseURI MATCHES '%@' AND account.stableId MATCHES '%@')", baseIdentityURI, homeUserStableId] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
        }
    }
    
    return ret;
}


- (HOPAvatar*) getAvatarByURL:(NSString*) url
{
    HOPAvatar* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPAvatar" withPredicateString:[NSString stringWithFormat:@"(url MATCHES '%@')", url] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPOpenPeerAccount*) getLastLoggedInUser
{
    HOPOpenPeerAccount* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPOpenPeerAccount" withPredicateString:@"(loggedIn == YES)" orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPOpenPeerAccount*) getAccountForStableID:(NSString*) stableID
{
    HOPOpenPeerAccount* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPOpenPeerAccount" withPredicateString:[NSString stringWithFormat:@"(stableId MATCHES '%@')", stableID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (void) deleteAllMarkedRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* objectsForDeleteion = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(ANY rolodexContacts.readyForDeletion == YES AND selfRolodexContact.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        HOPAssociatedIdentity* associatedIdentity = [results objectAtIndex:0];
        objectsForDeleteion = [associatedIdentity.rolodexContacts allObjects];
        for (NSManagedObject* objectToDelete in objectsForDeleteion)
        {
            [self deleteObject:objectToDelete];
        }
        [self saveContext];
    }
}

- (NSArray*) getAllRolodexContactsMarkedForDeletionForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
     NSArray* ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"(readyForDeletion == YES AND associatedIdentity.selfRolodexContact.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    return ret;
}

- (NSArray*) getRolodexContactsForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime
{
    NSArray* ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"(associatedIdentity.selfRolodexContact.identityURI MATCHES '%@' AND (ANY associatedIdentity.rolodexContacts.identityContact == nil OR ANY associatedIdentity.rolodexContacts.identityContact.lastUpdated < %@)",homeUserIdentityURI,lastRefreshTime] orderDescriptors:nil];
    
    return ret;
}

- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI
{
    NSMutableArray* ret = nil;
    
    if ([peerURI length] > 0)
    {
         NSArray* apnsData = [self getResultsForEntity:@"HOPAPNSData" withPredicateString:[NSString stringWithFormat:@"(contact.publicPeerFile.peerURI MATCHES '%@')",peerURI] orderDescriptors:nil];
        
        if ([apnsData count] > 0)
        {
            ret = [[NSMutableArray alloc] init];
            for (HOPAPNSData* data in apnsData)
            {
                [ret addObject:data.deviceToken];
            }
        }
    }
    return ret;
}

- (NSArray*) getPushNotificationDataForPeerURI:(NSString*) peerURI
{
    NSArray* ret = [self getResultsForEntity:@"HOPAPNSData" withPredicateString:[NSString stringWithFormat:@"(contact.publicPeerFile.peerURI MATCHES '%@')",peerURI] orderDescriptors:nil];
    
    return ret;
}

- (void) setAPNSData:(NSString*) deviceToken type:(NSString*) type PeerURI:(NSString*) peerURI
{
    if ([[self getAPNSDataForPeerURI:peerURI] count] == 0)
    {
        HOPOpenPeerContact* openPeerContact = [self getOpenPeerContactForPeerURI:peerURI];
        if (openPeerContact)
        {
            HOPAPNSData* apnsData = (HOPAPNSData*)[self createObjectForEntity:@"HOPAPNSData"];
            apnsData.deviceToken = deviceToken;
            apnsData.contact = openPeerContact;
            apnsData.type = type;
            [self saveContext];
        }
    }
}

- (NSManagedObject*) createObjectInBackgroundForEntity:(NSString*) entityName
{
    NSManagedObject* ret = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.backgroundManagedObjectContext];
    return ret;
}

- (void) clearAPNSData
{
    NSArray* ret = [self getResultsForEntity:@"HOPAPNSData" withPredicateString:nil orderDescriptors:nil];
    
    for (HOPAPNSData* data in ret)
    {
        [self deleteObject:data];
    }
    [self saveContext];
}
- (void)saveBackgroundContext
{
    NSError *error = nil;
    if (self.backgroundManagedObjectContext != nil)
    {
        if ([self.backgroundManagedObjectContext hasChanges] && ![self.backgroundManagedObjectContext save:&error])
        {
            NSString* str = [NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]];
            ZS_LOG_ERROR(Debug, [self log:str]);
        }
    }
}

- (NSArray*) getResultsInBackgroundForEntity:(NSString*) entityName withPredicateString:(NSString*) predicateString orderDescriptors:(NSArray*) orderDescriptors
{
    __block NSArray* ret = nil;
    
    if ([entityName length] > 0)
    {
        //[self.backgroundManagedObjectContext performBlockAndWait:
        //^{
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.backgroundManagedObjectContext];
                [fetchRequest setEntity:entity];
                
                if ([predicateString length] > 0)
                {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
                    [fetchRequest setPredicate:predicate];
                }
                
                if ([orderDescriptors count] > 0)
                    [fetchRequest setSortDescriptors:orderDescriptors];
                
                NSError *error;
                NSArray *fetchedObjects  = [self.backgroundManagedObjectContext executeFetchRequest:fetchRequest error:&error];
                
                if (!error)
                {
                    if([fetchedObjects count] > 0)
                    {
                        ret = fetchedObjects;
                    }
                }
        //}];
    }
    return ret;
}

- (HOPCacheData*) getCacheDataForPath:(NSString*) path withExpireCheck:(BOOL) expireCheck
{
    HOPCacheData* ret = nil;
    
    NSArray* results = nil;
    
    if (expireCheck)
        results = [self getResultsInBackgroundForEntity:@"HOPCacheData" withPredicateString:[NSString stringWithFormat:@"(path MATCHES '%@') AND ( (expire == nil) || (expire >= %f))", path, [[NSDate date] timeIntervalSince1970]] orderDescriptors:nil];
    else
        results = [self getResultsInBackgroundForEntity:@"HOPCacheData" withPredicateString:[NSString stringWithFormat:@"(path MATCHES '%@')", path] orderDescriptors:nil];
    
    ret = [results count] > 0 ? ((HOPCacheData*)results[0]) : nil;
    
    return ret;
}

- (void) setCookie:(NSString*) data withPath:(NSString*) path expires:(NSDate*) expires
{
    if ([path length] > 0)
    {
        [self.backgroundManagedObjectContext performBlockAndWait:
         ^{
            HOPCacheData* cacheData = [self getCacheDataForPath:path withExpireCheck:NO];

            if (!cacheData)
                cacheData = (HOPCacheData*)[self createObjectInBackgroundForEntity:@"HOPCacheData"];
            
            cacheData.data = data;
            cacheData.path = path;
            if (expires == nil)
            {
                NSDate* expireDate = [[NSDate date] dateByAddingTimeInterval:removeOnNextRunExpireTimeInterval];
                cacheData.expire = [NSNumber numberWithDouble:[expireDate timeIntervalSince1970]];
                cacheData.removeOnNextRun = [NSNumber numberWithBool:YES];
            }
            else
                cacheData.expire = [NSNumber numberWithDouble:[expires timeIntervalSince1970]];
             
             [self saveBackgroundContext];
         }];
    }
}

- (NSString*) getCookieWithPath:(NSString*) path
{
    __block NSString* ret = nil;
    
    [self.backgroundManagedObjectContext performBlockAndWait:
     ^{
         HOPCacheData* cacheData = [self getCacheDataForPath:path withExpireCheck:YES];
         ret = cacheData.data;

     }];
    return ret;
}

- (void) removeExpiredCookies
{
    [self.backgroundManagedObjectContext performBlock:
     ^{
        NSArray* objectsToDelete = [self getResultsInBackgroundForEntity:@"HOPCacheData" withPredicateString:[NSString stringWithFormat:@" (removeOnNextRun == YES OR expire < %f)", [[NSDate date] timeIntervalSince1970]] orderDescriptors:nil];
        
        for (NSManagedObject* object in objectsToDelete)
            [self.backgroundManagedObjectContext deleteObject:object];
         
         [self saveBackgroundContext];
     }];
}

- (void) removeCookieForPath:(NSString*) path
{
    if ([path length] > 0)
    {
        [self.backgroundManagedObjectContext performBlockAndWait:
         ^{
            HOPCacheData* cacheData = [self getCacheDataForPath:path withExpireCheck:NO];
            if (cacheData)
                [self.backgroundManagedObjectContext deleteObject:cacheData];
            
            [self saveBackgroundContext];
        }];
    }
}

- (String) log:(NSString*) message
{
    return String("HOPModelManager: ") + [message UTF8String];
}


- (HOPConversationRecord *) getConversationRecordByID:(NSString*) conversationID
{
    HOPConversationRecord* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"(sessionID MATCHES '%@')", conversationID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPMessageRecord *) getMessageRecordByID:(NSString*) messageID
{
    HOPMessageRecord* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPMessageRecord" withPredicateString:[NSString stringWithFormat:@"(messageID MATCHES '%@')", messageID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}


- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date conversationThreadID:(NSString*) conversationThreadID openPeerContact:(HOPOpenPeerContact*) openPeerContact messageId:(NSString*)messageId conversationEvent:(HOPConversationEvent*) conversationEvent
{
    HOPMessageRecord* messageRecord = nil;
    if ([messageText length] > 0 && [type length] > 0 && date != nil && [conversationThreadID length] > 0 && [messageId length] > 0)
    {
        if ([self getMessageRecordByID:messageId] == nil)
        {
            NSArray* sessionRecords = [self getConversationRecordsForThreadID:conversationThreadID];
            if ([sessionRecords count] > 0)
            {
                HOPConversationRecord* sessionRecord = [sessionRecords objectAtIndex:0];//[self getSessionRecordByID:sessionRecordId];
                messageRecord = (HOPMessageRecord*)[self createObjectForEntity:@"HOPMessageRecord"];
                messageRecord.text = messageText;
                messageRecord.date = date;
                messageRecord.type = type;
                messageRecord.sender = openPeerContact;
                messageRecord.session = sessionRecord;
                messageRecord.conversationEvent = conversationEvent;
                messageRecord.messageID = messageId;
                sessionRecord.lastActivity = [NSDate date];
            }
        }
        
        [self saveContext];
    }
    else
    {
        //NSString* str = [NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,sessionRecordId, messageId];
        ZS_LOG_ERROR(Debug, [self log:([NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,conversationThreadID, messageId])]);
    }
    
    return messageRecord;
}

- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date  visible:(BOOL) visible  conversationThreadID:(NSString*) conversationThreadID openPeerContact:(HOPOpenPeerContact*) openPeerContact messageId:(NSString*)messageId conversationEvent:(HOPConversationEvent*) conversationEvent
{
    HOPMessageRecord* messageRecord = nil;
    if ([messageText length] > 0 && [type length] > 0 && date != nil && [conversationThreadID length] > 0 && [messageId length] > 0)
    {
        if ([self getMessageRecordByID:messageId] == nil)
        {
            NSArray* sessionRecords = [self getConversationRecordsForThreadID:conversationThreadID];
            if ([sessionRecords count] > 0)
            {
                HOPConversationRecord* sessionRecord = [sessionRecords objectAtIndex:0];//[self getSessionRecordByID:sessionRecordId];
                messageRecord = (HOPMessageRecord*)[self createObjectForEntity:@"HOPMessageRecord"];
                messageRecord.text = messageText;
                messageRecord.date = date;
                messageRecord.visible = [NSNumber numberWithBool:visible];
                messageRecord.type = type;
                messageRecord.sender = openPeerContact;
                messageRecord.session = sessionRecord;
                messageRecord.conversationEvent = conversationEvent;
                messageRecord.messageID = messageId;
                sessionRecord.lastActivity = [NSDate date];
            }
        }
        
        [self saveContext];
    }
    else
    {
        //NSString* str = [NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,sessionRecordId, messageId];
        ZS_LOG_ERROR(Debug, [self log:([NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,conversationThreadID, messageId])]);
    }
    
    return messageRecord;
}

- (NSString*) getPeerURIForHomeUser
{
    HOPOpenPeerAccount* homeUser = [self getLastLoggedInUser];
    HOPAssociatedIdentity* associatedIdentity = [[homeUser.associatedIdentities allObjects] objectAtIndex:0];
    return associatedIdentity.selfRolodexContact.identityContact.openPeerContact.publicPeerFile.peerURI;
}

- (HOPConversationThreadRecord*) getConversationThreadRecordForThreadID:(NSString*) threadID
{
    HOPConversationThreadRecord* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPConversationThreadRecord" withPredicateString:[NSString stringWithFormat:@"(threadID MATCHES '%@')", threadID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (NSArray*) getConversationRecordsForThreadID:(NSString*) threadID
{
    NSArray* ret = nil;
    if ([threadID length] > 0)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivity" ascending:NO];
        ret = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"ANY conversationThreadRecords.threadID MATCHES '%@'",threadID] orderDescriptors:@[sortDescriptor]];
    }
    return ret;
}


- (HOPConversationRecord*) getConversationRecordForConversationThread:(HOPConversationThread*) conversationThread
{
    HOPConversationRecord* ret = nil;
    if (conversationThread)
    {
        NSArray* results = nil;
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivity" ascending:NO];
        
        results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"homeUser.stableId MATCHES '%@'",[self getLastLoggedInUser].stableId] orderDescriptors:@[sortDescriptor]];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"ALL participants IN %@", [conversationThread getContacts]];
        
        results = [results filteredArrayUsingPredicate:predicate];

        if ([results count] > 0)
            ret = [results objectAtIndex:0];
    }
    return ret;
}

- (NSArray*) getSessionRecordsForParticipants:(NSArray*) participants
{
    NSArray* ret = nil;
    if ([participants count] > 0)
    {
        ret = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"ALL participants IN %@",participants] orderDescriptors:nil];
    }
    return ret;
}

- (HOPConversationThreadRecord*) createRecordForConversationThread:(HOPConversationThread*) conversationThread conversationRecord:(HOPConversationRecord*) conversationRecord
{
    HOPConversationThreadRecord* ret = nil;
    
    if (conversationThread)
    {
        ret = [self getConversationThreadRecordForThreadID:[conversationThread getThreadId]];
        if (!ret)
        {
            ret = (HOPConversationThreadRecord*)[self createObjectForEntity:@"HOPConversationThreadRecord"];
            ret.creationTime = [NSDate date];
            ret.lastUpdate = [NSDate date];
            ret.threadID = [conversationThread getThreadId];
            
            if (conversationRecord)
            {
                [ret addSessionReordsObject:conversationRecord];
            }
            [self saveContext];
        }
    }
    
    return ret;
}

- (HOPConversationRecord*) createConversationRecordForConversationThread:(HOPConversationThread*) conversationThread type:(NSString*) type date:(NSDate*) date name:(NSString*) name participants:(NSArray*) participants
{
    HOPConversationRecord* ret = nil;
    if (conversationThread)
    {
        HOPConversationThreadRecord *conversationThreadRecord = [self createRecordForConversationThread:conversationThread conversationRecord:nil];
        
        if (conversationThreadRecord)
        {
            ret = [self getConversationRecordForConversationThread:conversationThread];
            
            if (!ret)
            {
                ret = (HOPConversationRecord*)[self createObjectForEntity:@"HOPConversationRecord"];
                ret.homeUser = [self getLastLoggedInUser];
                ret.sessionID = [HOPUtility getGUIDstring];
                ret.creationTime = date;
                ret.type = type;
                ret.name = name;
            }
        
            ret.lastActivity = date;
            [ret addConversationThreadRecordsObject:conversationThreadRecord];
            
            for (HOPOpenPeerContact* participant in participants)
            {
//                HOPOpenPeerContact* openPeerContact = participant.identityContact.openPeerContact;
                [ret addParticipantsObject:participant];
            }
            
            [self saveContext];
        }
    }
    return ret;
}

- (NSFetchRequest*) getMessagesFetchRequestForConversationID:(NSString*) conversationID sortAscending:(BOOL) ascending
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessageRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(visible == YES AND session.sessionID MATCHES '%@')",conversationID]];
    
    [fetchRequest setPredicate:predicate];
    
	[fetchRequest setFetchBatchSize:20];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:ascending];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (void) replaceMessageWithID:(NSString*) replacesMessageID newMessageID:(NSString*) newMessageID messageText:(NSString*) messageText
{
    if ([replacesMessageID length] > 0)
    {
        HOPMessageRecord* messageObj = [[HOPModelManager sharedModelManager] getMessageRecordByID:replacesMessageID];
        
        if (messageObj)
        {
            messageObj.messageID = newMessageID;
            if ([messageText length] == 0)
            {
                messageObj.deleted = [NSNumber numberWithBool:YES];
                //[[HOPModelManager sharedModelManager] deleteObject:messageObj];
            }
            else
            {
                messageObj.text = messageText;
            }
            messageObj.edited = [NSNumber numberWithBool:YES];
        }
        [[HOPModelManager sharedModelManager] saveContext];
    }
}

- (void) updateMessageStateForConversation:(HOPConversationRecord*) conversationRecord lastDeliveryState:(HOPConversationThreadMessageDeliveryState) messageDeliveryStat
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    NSArray* results = [self getResultsForEntity:@"HOPMessageRecord" withPredicateString:[NSString stringWithFormat:@"(session.sessionID MATCHES '%@' AND outMessageStatus MATCHES '%@' AND showStatus = YES)", conversationRecord.sessionID, [HOPConversationThread stringForMessageDeliveryState: messageDeliveryStat]] orderDescriptors:sortDescriptors];
    
    if ([results count] > 1)
    {
        for (int i = 1; i < [results count]; i++)
        {
            HOPMessageRecord* message = [results objectAtIndex:i];
            message.showStatus = [NSNumber numberWithBool:NO];
        }
        [self saveContext];
    }
}


- (HOPOpenPeerContact*) getOpenPeerContactForPeerURI:(NSString*) peerURI
{
    HOPOpenPeerContact* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPOpenPeerContact" withPredicateString:[NSString stringWithFormat:@"(publicPeerFile.peerURI MATCHES '%@')", peerURI] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
        }
    }
    
    return ret;
}

- (HOPOpenPeerContact*) getOpenPeerContactForStableID:(NSString*) stableID
{
    HOPOpenPeerContact* ret = nil;
    
    if ([stableID length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPOpenPeerContact" withPredicateString:[NSString stringWithFormat:@"(stableID MATCHES '%@')", stableID] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
            
        }
    }
    
    return ret;
}

- (HOPOpenPeerContact*) getOpenPeerContactForIdentityURI:(NSString*) identityURI
{
    HOPOpenPeerContact* ret = nil;
    
    if ([identityURI length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPOpenPeerContact" withPredicateString:[NSString stringWithFormat:@"(ANY identityContacts.rolodexContact.identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
            
        }
    }
    
    return ret;
}

- (HOPOpenPeerContact*) getOpenPeerContactForIdentityContact:(IdentityContact) inIdentityContact
{
    HOPOpenPeerContact* ret = nil;
    
    NSString* stableID = [NSString stringWithUTF8String:inIdentityContact.mStableID];
    ret = [self getOpenPeerContactForStableID:stableID];
    
    if (!ret)
    {
        NSString* identityURI = [NSString stringWithUTF8String:inIdentityContact.mIdentityURI];
        ret = [self getOpenPeerContactForIdentityURI:identityURI];
    }
    
    if (!ret)
    {
        NSString* peerURI =  [NSString stringWithUTF8String: IHelper::getPeerURI(inIdentityContact.mPeerFilePublic)];
        ret = [self getOpenPeerContactForPeerURI:peerURI];
    }

    return ret;
}

- (HOPOpenPeerContact*) createOpenPeerContactForIdentityContact:(IdentityContact) inIdentityContact
{
    HOPOpenPeerContact* ret = nil;
    
    ret = (HOPOpenPeerContact*)[self createObjectForEntity:@"HOPOpenPeerContact"];
    if (ret)
    {
        NSString* stableID = [NSString stringWithUTF8String:inIdentityContact.mStableID];
        if ([stableID length] > 0)
            ret.stableID = stableID;
        else
            ret.stableID = [[HOPAccount sharedAccount] getStableID];
        
        if(stableID.length == 0)
            return ret;
        
        NSString* identityURI = [NSString stringWithUTF8String:inIdentityContact.mIdentityURI];
        if ([identityURI length] > 0)
        {
            HOPIdentityContact* contact = [self getIdentityContactWithIdentityURI:identityURI];
            if (contact)
                [ret addIdentityContactsObject:contact];
        }
        
        NSString* peerURI =  [NSString stringWithUTF8String: IHelper::getPeerURI(inIdentityContact.mPeerFilePublic)];
        if ([peerURI length] > 0)
        {
            HOPPublicPeerFile* publicPeerFile = [self getPublicPeerFileForPeerURI:peerURI];
            if (!publicPeerFile)
            {
                publicPeerFile = (HOPPublicPeerFile*) [self createObjectForEntity:@"HOPPublicPeerFile"];
                if (publicPeerFile)
                {
                    publicPeerFile.peerFile = [NSString stringWithCString: IHelper::convertToString(IHelper::convertToElement(inIdentityContact.mPeerFilePublic)) encoding:NSUTF8StringEncoding];
                    publicPeerFile.peerURI = peerURI;
                    ret.publicPeerFile = publicPeerFile;
                }
            }
        }
        [self saveContext];
    }
    
    return ret;
}

- (void) updateOpenPeerContact:(HOPOpenPeerContact*) contact identityContact:(IdentityContact) inIdentityContact
{
    if (contact)
    {
        NSString* stableID = [NSString stringWithUTF8String:inIdentityContact.mStableID];
        if ([stableID length] > 0)
            contact.stableID = stableID;
        
        NSString* identityURI = [NSString stringWithUTF8String:inIdentityContact.mIdentityURI];
        if ([identityURI length] > 0)
        {
            HOPIdentityContact* identityContact = [self getIdentityContactWithIdentityURI:identityURI];
            if (identityContact)
                [contact addIdentityContactsObject:identityContact];
        }
        
        NSString* peerURI =  [NSString stringWithUTF8String: IHelper::getPeerURI(inIdentityContact.mPeerFilePublic)];
        if ([peerURI length] > 0)
        {
            HOPPublicPeerFile* publicPeerFile = [self getPublicPeerFileForPeerURI:peerURI];
            if (!publicPeerFile)
            {
                publicPeerFile = (HOPPublicPeerFile*) [self createObjectForEntity:@"HOPPublicPeerFile"];
                if (publicPeerFile)
                {
                    publicPeerFile.peerFile = [NSString stringWithCString: IHelper::convertToString(IHelper::convertToElement(inIdentityContact.mPeerFilePublic)) encoding:NSUTF8StringEncoding];
                    publicPeerFile.peerURI = peerURI;
                }
            }
            
            contact.publicPeerFile = publicPeerFile;
        }
        [self saveContext];
    }
}

- (HOPConversationEvent*) addConversationEvent:(NSString*) eventType conversationRecord:(HOPConversationRecord*) conversationRecord partcipants:(NSArray*) participants title:(NSString*) title
{
    HOPConversationEvent* event = nil;
    if (conversationRecord && participants.count > 0)
    {
        HOPParticipants* temp = [self getParticiapantsForListOfContacts:participants];
        event = (HOPConversationEvent*)[self createObjectForEntity:@"HOPConversationEvent"];
        
        event.time = [NSDate date];
        event.eventType = eventType;
        event.session = conversationRecord;
        conversationRecord.name = title;
        event.participants = temp;
        event.name = title;
        for (HOPConversationEvent* oldEvent in temp.events)
        {
            oldEvent.showEvent = [NSNumber numberWithBool:NO];
        }
        event.showEvent = [NSNumber numberWithBool:YES];
        //[event addParticipants:[NSSet setWithArray:participants]];
        
        [self saveContext];
    }
    
    return event;
}

- (NSArray *) getOpenPeerContactsByPeerURIs:(NSArray*) peerURIs
{
    NSArray* ret = nil;
    
    if (peerURIs.count > 0)
    {
        ret = [self getResultsForEntity:@"HOPOpenPeerContact" withPredicateString:[NSString stringWithFormat:@"publicPeerFile.peerURI IN %@",peerURIs] orderDescriptors:nil];
    }
    
    
    return ret;
}

- (HOPParticipants*) addParticiapantsForListOfContacts:(NSArray*) contacts
{
    HOPParticipants* ret = [self createObjectForEntity:@"HOPParticipants"];
    NSString* cbcID = @"";
    for (HOPOpenPeerContact* contact in contacts)
    {
        if (cbcID.length == 0)
            cbcID = contact.stableID;
        else
            cbcID = [cbcID stringByAppendingString:[NSString stringWithFormat:@"_%@",contact.stableID]];
        
        [ret addParticipantsObject:contact];
    }
    ret.cbcID = cbcID;
    
    [self saveContext];
    return ret;
}

- (HOPParticipants*) getParticiapantsForListOfContacts:(NSArray*) contacts
{
    HOPParticipants* ret = nil;
    
    if (contacts.count > 0)
    {
        //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(participants,$p,ALL $p.stableID IN %@)",[contacts valueForKeyPath: @"stableID"]];
//        NSArray* result = [self getResultsForEntity:@"HOPParticipants" withPredicateString:[NSString stringWithFormat:@"SUBQUERY(participants,$p,ALL $p.stableID IN %@).@count > 0",[contacts valueForKeyPath: @"stableID"]] orderDescriptors:nil];
        NSArray* result = [self getResultsForEntity:@"HOPParticipants" withPredicateString:nil orderDescriptors:nil];
        
//        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//        NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPParticipants" inManagedObjectContext:self.managedObjectContext];
//        [fetchRequest setEntity:entity];
//        
//        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"ALL participants IN %@",contacts];
//        [fetchRequest setPredicate:predicate];
//        
//        NSArray* result  = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        
        if (result.count > 0)
        {
            for (HOPParticipants* p in result)
            {
                NSSet *set = [NSSet setWithArray:contacts];
                
                if ([set isEqualToSet:p.participants])
                    return p;
//                if ([p.participants.allObjects isEqualToArray:contacts])
//                    ret = p;
            }
        }
        
        if (!ret)
            ret = [self addParticiapantsForListOfContacts:contacts];
    }
    
    
    return ret;
}

- (NSFetchRequest*) getMessagesFetchRequestForParticipants:(HOPParticipants*) participants sortAscending:(BOOL) ascending
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessageRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(visible == YES AND conversationEvent.participants.cbcID MATCHES '%@' AND conversationEvent.session.homeUser.stableId MATCHES '%@')",participants.cbcID,[self getLastLoggedInUser].stableId]];
    
    [fetchRequest setPredicate:predicate];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:ascending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (HOPOpenPeerContact*) getOpenPeerContactForAccount
{
    HOPOpenPeerContact* ret = nil;
    HOPOpenPeerAccount* account = [self getLastLoggedInUser];
    if (account && account.stableId.length > 0)
        ret = [self getOpenPeerContactForStableID:account.stableId];
    return ret;
}


- (HOPOpenPeerContact*) createOrUpdateOpenPeerContactForItentities:(NSArray*) identities coreContact:(IContactPtr) coreContact
{
    HOPOpenPeerContact* ret = nil;
    NSString* peerFile = [HOPContact getPeerFilePublicFromCoreContact:coreContact];//[NSString stringWithUTF8String:coreContact->ge];
    NSString* peerURI = [NSString stringWithUTF8String:coreContact->getPeerURI()];
    
    if (peerFile.length > 0 && peerURI.length > 0 && identities.count >0)
    {
        for (HOPIdentityContact* identity in identities)
        {
            ret = [self getOpenPeerContactForIdentityURI:identity.rolodexContact.identityURI];
            if (ret)
                break;
        }
        
        if (ret)
        {
            HOPPublicPeerFile* publicPeerFile = [self createPublicPeerFileForPeerURI:peerURI peerFile:peerFile];
            ret.publicPeerFile = publicPeerFile;
            [self saveContext];
        }
    }
    
    return ret;
}

- (HOPPublicPeerFile*) createPublicPeerFileForPeerURI:(NSString*) peerURI peerFile:(NSString*) peerFile
{
    HOPPublicPeerFile* ret = (HOPPublicPeerFile*)[[HOPModelManager sharedModelManager] createObjectForEntity:@"HOPPublicPeerFile"];
    if (ret)
    {
        ret.peerURI = peerURI;
        ret.peerFile = peerFile;
    }
    [self saveContext];
    return ret;
}
@end


