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

#import "HOPModelManager.h"
#import "HOPIdentity+External.h"
#import "HOPAssociatedIdentity.h"
#import "HOPPublicPeerFile.h"
#import "HOPAvatar.h"
#import "HOPOpenPeerAccount.h"
#import "HOPAPNSData.h"
#import "HOPCacheData.h"
#import "HOPConversationRecord.h"
#import "HOPMessage.h"
#import "HOPConversationThreadRecord.h"
#import "HOPCoreContact.h"
#import "HOPConversationThread_Internal.h"
#import "HOPUtility.h"
#import "HOPIdentityProvider.h"
#import "HOPContact+External.h"
#import "HOPConversationEvent.h"
#import "HOPParticipantInfo.h"
#import "HOPCoreContact_Internal.h"
#import "HOPAccount_Internal.h"
#import "OpenPeerConstants.h"
#import <CoreData/CoreData.h>
#import <openpeer/core/IHelper.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/types.h>
#import "HOPConversation.h"
#import "OpenPeerUtility.h"
#import "HOPIdentityLookup.h"
#import "HOPIdentityProvider.h"
#include <openpeer/stack/IPeerFilePublic.h>

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

- (HOPIdentity *) getIdentityByIdentityURI:(NSString*) identityURI
{
    HOPIdentity* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"(identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPIdentity *) getIdentityByPeerURI:(NSString*) peerURI
{
    HOPIdentity* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO];
        NSArray* array = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"contact.publicPeerFile.peerURI MATCHES '%@'",peerURI] orderDescriptors:@[sortDescriptor]];
        if (array.count > 0)
            ret = array[0];
    }
    return ret;
}

- (HOPContact *) getContactByPeerURI:(NSString*) peerURI
{
    HOPContact* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSArray* array = [self getResultsForEntity:@"HOPContact" withPredicateString:[NSString stringWithFormat:@"publicPeerFile.peerURI MATCHES '%@'",peerURI] orderDescriptors:nil];
        if (array.count > 0)
            ret = array[0];
    }
    return ret;
}

- (NSArray *) getIdentitiesByPeerURI:(NSString*) peerURI
{
	NSArray* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO];
        ret = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"contact.publicPeerFile.peerURI MATCHES '%@'",peerURI] orderDescriptors:@[sortDescriptor]];
    }
    
    
    return ret;
}

- (NSArray*) getAllIdentitiesForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* ret = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(selfIdentity.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        HOPAssociatedIdentity* associatedIdentity = [results objectAtIndex:0];
        ret = [associatedIdentity.identities allObjects];
    }
    return ret;
}

- (NSArray*) getIdentitiesForAccountIdentityURI:(NSString*) homeUserIdentityURI openPeerContacts:(BOOL) openPeerContacts
{
    NSArray* ret = nil;
    NSString* stringFormat = nil;
    
    if (openPeerContacts)
    {
        stringFormat = [NSString stringWithFormat:@"(contact != nil && associatedIdentity.selfIdentity.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    else
    {
        stringFormat = [NSString stringWithFormat:@"(contact == nil  && associatedIdentity.selfIdentity.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    
    ret = [self getResultsForEntity:@"HOPIdentity" withPredicateString:stringFormat orderDescriptors:nil];
    
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

- (HOPAssociatedIdentity*) addAssociatedIdentityForBaseIdentityURI:(NSString*) baseIdentityURI domain:(NSString*) domain name:(NSString*) name selfIdentityProfile:(HOPIdentity*) identity
{
    HOPAssociatedIdentity* ret = nil;
    
    ret = [NSEntityDescription insertNewObjectForEntityForName:@"HOPAssociatedIdentity" inManagedObjectContext:[self managedObjectContext]];
    
    HOPIdentityProvider* identityProvider = [self getIdentityProviderForBaseURI:baseIdentityURI domain:domain];
    if (!identityProvider)
        identityProvider = [self addIdentityProviderForBaseURI:baseIdentityURI domain:domain name:name];

    ret.identityProvider = identityProvider;
    
    if (identity)
        ret.selfIdentity = identity;
    
    if ([[HOPAccount sharedAccount] getOpenPeerUser])
        ret.account = [[HOPAccount sharedAccount] getOpenPeerUser];
    
    [self saveContext];
    
    return ret;
}

- (HOPAssociatedIdentity *) getAssociatedIdentityByDomain:(NSString*) identityProviderDomain identityName:(NSString*) identityName homeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    HOPAssociatedIdentity* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(identityProvider.domain MATCHES '%@' AND identityProvider.baseURI MATCHES '%@' AND selfIdentity.identityURI MATCHES '%@')", identityProviderDomain, identityName, homeUserIdentityURI] orderDescriptors:nil];
    
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

- (HOPOpenPeerAccount*) getLoggedInAccount
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

- (void) deleteAllMarkedIdentitiesForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* objectsForDeleteion = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(ANY identities.readyForDeletion == YES AND selfIdentity.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        HOPAssociatedIdentity* associatedIdentity = [results objectAtIndex:0];
        objectsForDeleteion = [associatedIdentity.identities allObjects];
        for (NSManagedObject* objectToDelete in objectsForDeleteion)
        {
            [self deleteObject:objectToDelete];
        }
        [self saveContext];
    }
}

- (NSArray*) getAllIdentitiesMarkedForDeletionForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
     NSArray* ret = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"(readyForDeletion == YES AND associatedIdentity.selfIdentity.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    return ret;
}

- (NSArray*) getIdentitiesForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime
{
    NSArray* ret = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"(associatedIdentity.selfIdentity.identityURI MATCHES '%@' AND (ANY associatedIdentity.identities.contact == nil OR ANY associatedIdentity.identities.lastUpdated < %@)",homeUserIdentityURI,lastRefreshTime] orderDescriptors:nil];
    
    return ret;
}


- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI
{
    NSArray* ret = [self getResultsForEntity:@"HOPAPNSData" withPredicateString:[NSString stringWithFormat:@"(contact.publicPeerFile.peerURI MATCHES '%@')",peerURI] orderDescriptors:nil];
    
    return ret;
}

- (void) setAPNSData:(NSString*) deviceToken type:(NSString*) type PeerURI:(NSString*) peerURI
{
    if ([[self getAPNSDataForPeerURI:peerURI] count] == 0)
    {
        HOPContact* contact = [self getContactForPeerURI:peerURI];
        if (contact)
        {
            HOPAPNSData* apnsData = (HOPAPNSData*)[self createObjectForEntity:@"HOPAPNSData"];
            apnsData.deviceToken = deviceToken;
            apnsData.contact = contact;
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

- (HOPMessage *) getMessageRecordByID:(NSString*) messageID
{
    HOPMessage* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPMessage" withPredicateString:[NSString stringWithFormat:@"(messageID MATCHES '%@')", messageID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
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

- (HOPConversationRecord*) getConversationRecordForParticipants:(NSArray*) participants
{
    HOPConversationRecord* ret = nil;
    if (participants.count > 0)
    {
        NSString* cbcID = [HOPUtility getCBCIDForContacts:participants];
        
        NSArray* results = nil;
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivity" ascending:NO];
        
        results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"homeUser.stableId MATCHES '%@' AND ANY events.participants.cbcID MATCHES '%@'",[self getLoggedInAccount].stableId,cbcID] orderDescriptors:@[sortDescriptor]];
        
        
        if ([results count] > 0)
            ret = [results objectAtIndex:0];
    }
    return ret;
}

- (HOPConversationRecord*) getConversationRecordForParticipants:(NSArray*) participants type:(NSString*) type
{
    HOPConversationRecord* ret = nil;
    if (participants.count > 0)
    {
        NSString* cbcID = [HOPUtility getCBCIDForContacts:participants];
        
        NSArray* results = nil;
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivity" ascending:NO];
        
        results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"homeUser.stableId MATCHES '%@' AND cbcID MATCHES '%@' AND type MATCHES '%@'",[self getLoggedInAccount].stableId,cbcID,type] orderDescriptors:@[sortDescriptor]];
        
        
        if ([results count] > 0)
            ret = [results objectAtIndex:0];
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
        
        if (conversationThread.conversationType == HOPConversationThreadTypeContactBased)
        {
            NSString* cbcID = [HOPUtility getCBCIDForContacts:conversationThread.participants];
            results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"homeUser.stableId MATCHES '%@' AND ANY events.participants.cbcID MATCHES '%@'",[self getLoggedInAccount].stableId,cbcID] orderDescriptors:@[sortDescriptor]];
        }
        else if (conversationThread.conversationType == HOPConversationThreadTypeThreadBased)
        {
            results = [self getResultsForEntity:@"HOPConversationRecord" withPredicateString:[NSString stringWithFormat:@"sessionID MATCHES '%@'",[conversationThread getThreadId]] orderDescriptors:@[sortDescriptor]];
        }

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


- (HOPConversationRecord*) createConversationRecordForConversationThread:(HOPConversationThread*) conversationThread type:(NSString*) type date:(NSDate*) date topic:(NSString*) topic name:(NSString*) name participants:(NSArray*) participants
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
                ret.homeUser = [self getLoggedInAccount];
                ret.sessionID = [conversationThread getThreadId].length > 0 ?  [conversationThread getThreadId] : [HOPUtility getGUIDstring];
                ret.creationTime = date;
                ret.type = type;
                ret.topic = topic;
                ret.name = name;
                ret.cbcID = [HOPUtility getCBCIDForContacts:participants];
            }
        
            ret.lastActivity = date;
            [ret addConversationThreadRecordsObject:conversationThreadRecord];
            
            for (HOPContact* participant in participants)
            {
                [ret addParticipantsObject:participant];
            }
            
            [self saveContext];
        }
    }
    return ret;
}


- (void) replaceMessageWithID:(NSString*) replacesMessageID newMessageID:(NSString*) newMessageID messageText:(NSString*) messageText
{
    if ([replacesMessageID length] > 0)
    {
        HOPMessage* messageObj = [[HOPModelManager sharedModelManager] getMessageRecordByID:replacesMessageID];
        HOPMessage* newMessageObj = [[HOPModelManager sharedModelManager] getMessageRecordByID:newMessageID];
        
        if (messageObj)
        {
            //messageObj.messageID = newMessageID;
            messageObj.visible = [NSNumber numberWithBool:NO];
            if ([messageText length] == 0 || [messageText isEqualToString:@" "])
            {
                newMessageObj.removed = [NSNumber numberWithBool:YES];
                //[[HOPModelManager sharedModelManager] deleteObject:messageObj];
            }
//            else
//            {
//                messageObj.text = messageText;
//            }
            newMessageObj.edited = [NSNumber numberWithBool:YES];
        }
        [[HOPModelManager sharedModelManager] saveContext];
    }
}

- (void) updateMessageStateForConversation:(HOPConversation*) conversation lastDeliveryState:(HOPConversationThreadMessageDeliveryState) messageDeliveryStat
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    NSArray* results = [self getResultsForEntity:@"HOPMessage" withPredicateString:[NSString stringWithFormat:@"(session.sessionID MATCHES '%@' AND outMessageStatus MATCHES '%@' AND showStatus = YES)", [conversation getConversationID], [HOPConversationThread stringForMessageDeliveryState: messageDeliveryStat]] orderDescriptors:sortDescriptors];
    
    if ([results count] > 1)
    {
        for (int i = 1; i < [results count]; i++)
        {
            HOPMessage* message = [results objectAtIndex:i];
            message.showStatus = [NSNumber numberWithBool:NO];
        }
        [self saveContext];
    }
}


- (HOPContact*) getContactForPeerURI:(NSString*) peerURI
{
    HOPContact* ret = nil;
    
    if ([peerURI length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPContact" withPredicateString:[NSString stringWithFormat:@"(publicPeerFile.peerURI MATCHES '%@')", peerURI] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
        }
    }
    
    return ret;
}

- (HOPContact*) getOpenPeerContactForStableID:(NSString*) stableID
{
    HOPContact* ret = nil;
    
    if ([stableID length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPContact" withPredicateString:[NSString stringWithFormat:@"(stableID MATCHES '%@')", stableID] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
            
        }
    }
    
    return ret;
}

- (HOPContact*) getOpenPeerContactForIdentityURI:(NSString*) identityURI
{
    HOPContact* ret = nil;
    
    if ([identityURI length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPContact" withPredicateString:[NSString stringWithFormat:@"(ANY identities.identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
            
        }
    }
    
    return ret;
}

- (HOPContact*) getOpenPeerContactForIdentityContact:(IdentityContact) inIdentityContact
{
    HOPContact* ret = nil;
    
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
        ret = [self getContactForPeerURI:peerURI];
    }

    return ret;
}


- (HOPPublicPeerFile*) savePublicPeerFile:(NSString*) publicPeerFile peerURI:(NSString*) peerURI contact:(HOPContact*) contact
{
    HOPPublicPeerFile* ret = nil;
    
    if ([peerURI length] > 0)
    {
        ret = [self getPublicPeerFileForPeerURI:peerURI];
        if (!publicPeerFile)
        {
            ret = (HOPPublicPeerFile*) [self createObjectForEntity:@"HOPPublicPeerFile"];
            
            ret.peerURI = peerURI;
            contact.publicPeerFile = ret;
        }
        
        if (publicPeerFile.length > 0)
        {
            ret.peerFile = publicPeerFile;
        }
        
        [self saveContext];
    }
    
    
    return ret;
}


- (HOPConversationEvent*) addConversationEvent:(NSString*) eventType conversationRecord:(HOPConversationRecord*) conversationRecord partcipants:(NSArray*) participants title:(NSString*) title
{
    HOPConversationEvent* event = nil;
    if (conversationRecord && participants.count > 0)
    {
        HOPParticipantInfo* temp = [self getParticiapantsForListOfContacts:participants];
        event = (HOPConversationEvent*)[self createObjectForEntity:@"HOPConversationEvent"];
        
        event.eventID = [HOPUtility getGUIDstring];
        event.time = [NSDate date];
        event.eventType = eventType;
        event.session = conversationRecord;
        //conversationRecord.topic = title;
        event.participants = temp;
        event.name = title;
        
        //[temp addEventsObject:event];
        
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
        ret = [self getResultsForEntity:@"HOPContact" withPredicateString:[NSString stringWithFormat:@"publicPeerFile.peerURI IN %@",peerURIs] orderDescriptors:nil];
    }
    
    
    return ret;
}

- (HOPParticipantInfo*) addParticiapantsForListOfContacts:(NSArray*) contacts
{
    HOPParticipantInfo* ret = (HOPParticipantInfo*)[self createObjectForEntity:@"HOPParticipantInfo"];
    NSString* cbcID = @"";
    for (HOPContact* contact in contacts)
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

- (HOPParticipantInfo*) getParticiapantsForListOfContacts:(NSArray*) contacts
{
    HOPParticipantInfo* ret = nil;
    
    if (contacts.count > 0)
    {
        NSArray* result = [self getResultsForEntity:@"HOPParticipantInfo" withPredicateString:nil orderDescriptors:nil];
        
        NSMutableSet *set = [NSMutableSet new];
        
        for (HOPContact* contact in contacts)
        {
            [set addObject:contact];
        }
        
        if (result.count > 0)
        {
            for (HOPParticipantInfo* p in result)
            {
                if ([set isEqualToSet:p.participants])
                    ret = p;
            }
        }
        
        if (!ret)
            ret = [self addParticiapantsForListOfContacts:set.allObjects];
    }
    
    
    return ret;
}

- (NSFetchRequest*) getMessagesFetchRequestForConversation:(HOPConversation*) conversation sortAscending:(BOOL) ascending
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessage" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(visible == YES AND session.sessionID MATCHES '%@')",[conversation getConversationID]]];
    [fetchRequest setPredicate:predicate];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:ascending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}


- (HOPIdentity*) getIdentityForAccount
{
    HOPIdentity* ret = nil;
    HOPOpenPeerAccount* account = [self getLoggedInAccount];
    if (account && account.stableId.length > 0)
        ret = [[self getOpenPeerContactForStableID:account.stableId] getPreferredIdentity];
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


- (NSArray*) addUnkownContactsFromConversationThread:(HOPConversationThread*) thread
{
    NSMutableArray* ret = nil;
    if (thread)
    {
        ContactListPtr contactList = [thread getConversationThreadPtr]->getContacts();
        
        for (ContactList::iterator contact = contactList->begin(); contact != contactList->end(); ++contact)
        {
            IContactPtr contactPtr = *contact;
            if (!contactPtr->isSelf())
            {
                HOPIdentity* identity = [self getIdentityByPeerURI:[NSString stringWithUTF8String:contactPtr->getPeerURI()]];
                
                if (!identity || !identity.contact)
                {
                    NSArray* contacts = [self createIdentitiesForCoreContact:contactPtr fromConversation:[thread getConversationThreadPtr]];
                    if (contacts.count > 0)
                    {
                        if (!ret)
                            ret = [NSMutableArray arrayWithObject:contacts[0]];
                        else
                            [ret addObject:contacts[0]];
                    }
                }
            }
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid conversation thread object!"];
    }
    
    return ret;
}

- (NSArray*) createIdentitiesForCoreContact:(IContactPtr) contactPtr fromConversation:(IConversationThreadPtr) conversationThreadPtr
{
    NSMutableArray* ret = nil;
    
    IdentityContactListPtr identityContactListPtr = conversationThreadPtr->getIdentityContactList(contactPtr);
    
    for (IdentityContactList::iterator identityContactInfo = identityContactListPtr->begin(); identityContactInfo != identityContactListPtr->end(); ++identityContactInfo)
    {
        IdentityContact identityContact = *identityContactInfo;
        if (identityContact.hasData())
        {
            NSString* identityURI = nil;
            NSString* name = nil;
            NSString* stableID = nil;
            NSString* peerURI = nil;
            
            if (identityContact.mIdentityURI)
                identityURI = [NSString stringWithCString:identityContact.mIdentityURI encoding:NSUTF8StringEncoding];
            
            if (identityContact.mName)
                name = [NSString stringWithCString:identityContact.mName encoding:NSUTF8StringEncoding];
            
            if (identityContact.mStableID)
                stableID = [NSString stringWithCString:identityContact.mStableID encoding:NSUTF8StringEncoding];
            
            if (contactPtr->getPeerURI())
                peerURI = [NSString stringWithUTF8String:contactPtr->getPeerURI()];
            
            if (identityURI.length > 0 && name.length > 0 && stableID.length > 0)
            {
                //Create identity
                HOPIdentity* identity = [self getIdentityByIdentityURI:identityURI];
                
                if (!identity)
                {
                    identity = (HOPIdentity*)[self createObjectForEntity:@"HOPIdentity"];
                    identity.identityURI = identityURI;
                }
                
                identity.name = name;
                //End identity creation
                
                //----------------------------
                
                
                //Public peer file creation
                HOPPublicPeerFile* publicPeerFile = nil;
                if ([peerURI length] > 0)
                {
                    publicPeerFile = [self getPublicPeerFileForPeerURI:peerURI];
                    if (!publicPeerFile)
                    {
                        publicPeerFile = (HOPPublicPeerFile*) [self createObjectForEntity:@"HOPPublicPeerFile"];
                        publicPeerFile.peerURI = peerURI;
                    }
                    
                    IPeerFilePublicPtr publicPeer = identityContact.mPeerFilePublic ? identityContact.mPeerFilePublic : contactPtr->getPeerFilePublic();
                    if (publicPeer)
                    {
                        publicPeerFile.peerFile = [NSString stringWithCString: IHelper::convertToString(IHelper::convertToElement(publicPeer)) encoding:NSUTF8StringEncoding];
                    }
                }
                //End public peer file creation
                
                //----------------------------
                
                //Create open peer contact
                HOPContact*  hopOpenPeerContact = [self  getOpenPeerContactForIdentityContact:identityContact];
                if (!hopOpenPeerContact)
                {
                    hopOpenPeerContact = (HOPContact*)[self createObjectForEntity:@"HOPContact"];
                }
                
                hopOpenPeerContact.stableID = stableID;
                [hopOpenPeerContact addIdentitiesObject:identity];
                hopOpenPeerContact.publicPeerFile = publicPeerFile;
                //End open peer contact creation
                
                [self saveContext];
                
                if (publicPeerFile.peerFile.length == 0)
                {
                    if (!ret)
                        ret = [NSMutableArray new];
                    
                    [ret addObject:hopOpenPeerContact];
                }
            }
        }
    }
    
    return ret;
}

- (HOPIdentity*) createIdentityForCoreIdentity:(IdentityContact) identityContact isSelf:(BOOL) isSelf
{
    HOPIdentity* ret = [self identityForCoreIdentity:identityContact];
    if (ret)
    {
        HOPPublicPeerFile* publicPeerFile = nil;
        
        if (identityContact.mPeerFilePublic)
        {
            if (identityContact.mPeerFilePublic->getPeerURI())
            {
                NSString* peerURI = [NSString stringWithUTF8String:identityContact.mPeerFilePublic->getPeerURI()];
                if (peerURI.length)
                    publicPeerFile = [self publicPeerFileForPeerURI:peerURI publicPeer:identityContact.mPeerFilePublic];
            }
        }
        
        if (publicPeerFile)
        {
            if (identityContact.mStableID)
            {
                NSString* stableID = [NSString stringWithCString:identityContact.mStableID encoding:NSUTF8StringEncoding];
                if (stableID.length > 0)
                {
                    HOPContact* contact = [self openPeerContactForIdentities:ret publicPeerFile:publicPeerFile stableID:stableID];
                    [contact addIdentitiesObject:ret];
                    if (isSelf)
                        contact.account = [HOPAccount sharedAccount].openPeerAccount;   
                }
            }
        }
        
        [self saveContext];
    }
    
    return ret;
}

- (HOPIdentity*) identityForCoreIdentity:(IdentityContact) identityContact
{
    HOPIdentity* ret = nil;
    
    if (identityContact.hasData())
    {
        NSString* identityURI = nil;
        NSString* name = nil;

        
        if (identityContact.mIdentityURI)
            identityURI = [NSString stringWithCString:identityContact.mIdentityURI encoding:NSUTF8StringEncoding];
        
        if (identityContact.mName)
            name = [NSString stringWithCString:identityContact.mName encoding:NSUTF8StringEncoding];
        
        if (identityURI.length > 0 && name.length > 0)
        {
            //Create identity
            ret = [self getIdentityByIdentityURI:identityURI];
            
            if (!ret)
            {
                ret = (HOPIdentity*)[self createObjectForEntity:@"HOPIdentity"];
                ret.identityURI = identityURI;
            }
            
            ret.name = name;
            
            ret.expires = [OpenPeerUtility convertPosixTimeToDate:identityContact.mExpires];
            ret.lastUpdated = [OpenPeerUtility convertPosixTimeToDate:identityContact.mLastUpdated];
            ret.identityProofBundle = [NSString stringWithCString:core::IHelper::convertToString(identityContact.mIdentityProofBundleEl) encoding:NSUTF8StringEncoding];
            ret.priority = [NSNumber numberWithInt:identityContact.mPriority];
            ret.weight = [NSNumber numberWithInt:identityContact.mWeight];
        }
    }
    return ret;
}

- (HOPPublicPeerFile*) publicPeerFileForPeerURI:(NSString*) peerURI publicPeer:(IPeerFilePublicPtr) publicPeer
{
    HOPPublicPeerFile* ret = nil;
    if ([peerURI length] > 0)
    {
        ret = [self getPublicPeerFileForPeerURI:peerURI];
        if (!ret)
        {
            ret = (HOPPublicPeerFile*) [self createObjectForEntity:@"HOPPublicPeerFile"];
            ret.peerURI = peerURI;
        }
        
        if (publicPeer)
        {
            ret.peerFile = [NSString stringWithCString: IHelper::convertToString(IHelper::convertToElement(publicPeer)) encoding:NSUTF8StringEncoding];
        }
    }
    return ret;
}

- (HOPContact*) openPeerContactForIdentities:(HOPIdentity*) identity publicPeerFile:(HOPPublicPeerFile*) publicPeerFile stableID:(NSString*) stableID
{
    HOPContact* ret = nil;
    
    if (stableID.length > 0)
        ret = [self getOpenPeerContactForStableID:stableID];
    
    if (!ret)
    {
        if (identity && identity.identityURI.length > 0)
            ret = [self getOpenPeerContactForIdentityURI:identity.identityURI];
    }
    
    if (!ret)
    {
        if (publicPeerFile)
            ret = [self getContactForPeerURI:publicPeerFile.peerURI];
    }
    
    if (!ret)
    {
        ret = (HOPContact*)[self createObjectForEntity:@"HOPContact"];
        ret.stableID = stableID;
        [ret addIdentitiesObject:identity];
        ret.publicPeerFile = publicPeerFile;
    }
    return ret;
}

- (NSArray*) getAllContactsForLoggedInAccount
{
    NSArray* ret = nil;
    
    NSString* stableID = [[HOPAccount sharedAccount] getStableID];
    
    if (stableID.length > 0)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        ret = [self getResultsForEntity:@"HOPIdentity" withPredicateString:[NSString stringWithFormat:@"(associatedIdentity.account.stableId MATCHES '%@')",stableID] orderDescriptors:@[sortDescriptor]];
    }
  
    return ret;
}
@end


