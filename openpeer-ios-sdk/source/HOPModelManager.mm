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
#import "HOPHomeUser.h"
#import "HOPAPNSData.h"
#import "HOPCacheData.h"
#import "HOPSessionRecord.h"
#import "HOPMessageRecord.h"
#import "HOPContact.h"
#import "OpenPeerConstants.h"
#import <CoreData/CoreData.h>
#import <openpeer/core/IHelper.h>

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
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];

    
    NSString *pathCache = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",cacheDatabaseName]];
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
        ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"identityContact.peerFile.peerURI MATCHES '%@'",peerURI] orderDescriptors:@[sortDescriptor]];
    }
    
    
    return ret;
}

- (NSArray*) getAllRolodexContactForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* ret = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(homeUserProfile.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
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
        stringFormat = [NSString stringWithFormat:@"(identityContact != nil || identityContact.@count > 0 && associatedIdentity.homeUserProfile.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    else
    {
        stringFormat = [NSString stringWithFormat:@"(identityContact == nil || identityContact.@count == 0 && associatedIdentity.homeUserProfile.identityURI MATCHES '%@')",homeUserIdentityURI];
    }
    
    ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:stringFormat orderDescriptors:nil];
    
    return ret;
}

- (HOPIdentityContact*) getIdentityContactByStableID:(NSString*) stableID identityURI:(NSString*) identityURI
{
    HOPIdentityContact* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPIdentityContact" withPredicateString:[NSString stringWithFormat:@"(stableID MATCHES '%@' AND rolodexContact.identityURI MATCHES '%@')", stableID, identityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (NSArray*) getIdentityContactsByStableID:(NSString*) stableID;
{
    NSArray* ret = nil;
    
    if ([stableID length] > 0)
    {
//        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identityContact.priority" ascending:NO];
//        ret = [self getResultsForEntity:@"HOPIdentityContact" withPredicateString:[NSString stringWithFormat:@"stableID MATCHES '%@'",stableID] orderDescriptors:@[sortDescriptor]];
        ret = [self getResultsForEntity:@"HOPIdentityContact" withPredicateString:[NSString stringWithFormat:@"stableID MATCHES '%@'",stableID] orderDescriptors:nil];
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

- (HOPAssociatedIdentity *) getAssociatedIdentityByDomain:(NSString*) identityProviderDomain identityName:(NSString*) identityName homeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    HOPAssociatedIdentity* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(domain MATCHES '%@' AND baseIdentityURI MATCHES '%@' AND homeUserProfile.identityURI MATCHES '%@')", identityProviderDomain, identityName, homeUserIdentityURI] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPAssociatedIdentity*) getAssociatedIdentityBaseIdentityURI:(NSString*) baseIdentityURI homeUserStableId:(NSString*) homeUserStableId
{
    HOPAssociatedIdentity* ret = nil;
    
    if ([homeUserStableId length] > 0)
    {
        NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(baseIdentityURI MATCHES '%@' AND homeUser.stableId MATCHES '%@')", baseIdentityURI, homeUserStableId] orderDescriptors:nil];
        
        if([results count] > 0)
        {
            ret = [results objectAtIndex:0];
        }
    }
    
    return ret;
}

- (NSArray*) getAllIdentitiesInfoForHomeUserIdentityURI:(NSString*) identityURI
{
    NSArray* ret = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(homeUserProfile.identityURI MATCHES '%@')", identityURI] orderDescriptors:nil];
    
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

- (HOPHomeUser*) getLastLoggedInHomeUser
{
    HOPHomeUser* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPHomeUser" withPredicateString:@"(loggedIn == YES)" orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPHomeUser*) getHomeUserByStableID:(NSString*) stableID
{
    HOPHomeUser* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPHomeUser" withPredicateString:[NSString stringWithFormat:@"(stableId MATCHES '%@')", stableID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (void) deleteAllMarkedRolodexContactsForHomeUserIdentityURI:(NSString*) homeUserIdentityURI
{
    NSArray* objectsForDeleteion = nil;
    NSArray* results = [self getResultsForEntity:@"HOPAssociatedIdentity" withPredicateString:[NSString stringWithFormat:@"(ANY rolodexContacts.readyForDeletion == YES AND homeUserProfile.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
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
     NSArray* ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"(readyForDeletion == YES AND associatedIdentity.homeUserProfile.identityURI MATCHES '%@')",homeUserIdentityURI] orderDescriptors:nil];
    
    return ret;
}

- (NSArray*) getRolodexContactsForRefreshByHomeUserIdentityURI:(NSString*) homeUserIdentityURI lastRefreshTime:(NSDate*) lastRefreshTime
{
    NSArray* ret = [self getResultsForEntity:@"HOPRolodexContact" withPredicateString:[NSString stringWithFormat:@"(associatedIdentity.homeUserProfile.identityURI MATCHES '%@' AND (ANY associatedIdentity.rolodexContacts.identityContact == nil OR ANY associatedIdentity.rolodexContacts.identityContact.lastUpdated < %@)",homeUserIdentityURI,lastRefreshTime] orderDescriptors:nil];
    
    return ret;
}

- (NSArray*) getAPNSDataForPeerURI:(NSString*) peerURI
{
    NSMutableArray* ret = nil;
     NSArray* apnsData = [self getResultsForEntity:@"HOPAPNSData" withPredicateString:[NSString stringWithFormat:@"(publicPeer.peerURI MATCHES '%@')",peerURI] orderDescriptors:nil];
    
    if ([apnsData count] > 0)
    {
        ret = [[NSMutableArray alloc] init];
        for (HOPAPNSData* data in apnsData)
        {
            [ret addObject:data.deviceToken];
        }
    }
    return ret;
}

- (void) setAPNSData:(NSString*) deviceToken PeerURI:(NSString*) peerURI
{
    if ([[self getAPNSDataForPeerURI:peerURI] count] == 0)
    {
        HOPPublicPeerFile* publicPeerFile = [self getPublicPeerFileForPeerURI:peerURI];
        if (publicPeerFile)
        {
            HOPAPNSData* apnsData = (HOPAPNSData*)[self createObjectForEntity:@"HOPAPNSData"];
            apnsData.deviceToken = deviceToken;
            apnsData.publicPeer = publicPeerFile;
            [self saveContext];
        }
    }
}

- (NSManagedObject*) createObjectInBackgroundForEntity:(NSString*) entityName
{
    NSManagedObject* ret = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.backgroundManagedObjectContext];
    return ret;
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


- (HOPSessionRecord *) getSessionRecordByID:(NSString*) sessionID
{
    HOPSessionRecord* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPSessionRecord" withPredicateString:[NSString stringWithFormat:@"(sessionID MATCHES '%@')", sessionID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPSessionRecord *) getMessageRecordByID:(NSString*) messageID
{
    HOPSessionRecord* ret = nil;
    
    NSArray* results = [self getResultsForEntity:@"HOPMessageRecord" withPredicateString:[NSString stringWithFormat:@"(messageID MATCHES '%@')", messageID] orderDescriptors:nil];
    
    if([results count] > 0)
    {
        ret = [results objectAtIndex:0];
    }
    
    return ret;
}

- (HOPSessionRecord*) addSession:(NSString*) sessionID type:(NSString*) type date:(NSDate*) date name:(NSString*) name participants:(NSArray*) participants
{
    HOPSessionRecord* sessionRecord = nil;
    if ([sessionID length] > 0)
    {
        sessionRecord = (HOPSessionRecord*)[self createObjectForEntity:@"HOPSessionRecord"];
        sessionRecord.sessionID = sessionID;
        sessionRecord.date = date;
        sessionRecord.type = type;
        sessionRecord.name = name;
        
        for (HOPRolodexContact* participant in participants)
        {
            HOPPublicPeerFile* publicPeerFile = participant.identityContact.peerFile;
            [sessionRecord addParticipantsObject:publicPeerFile];
        }
        [self saveContext];
    }
    return sessionRecord;
}

- (HOPMessageRecord*) addMessage:(NSString*) messageText type:(NSString*) type date:(NSDate*) date session:(NSString*) sessionRecordId rolodexContact:(HOPRolodexContact*) rolodexContact messageId:(NSString*)messageId
{
    HOPMessageRecord* messageRecord = nil;
    if ([messageText length] > 0 && [type length] > 0 && date != nil && [sessionRecordId length] > 0 && [messageId length] > 0)
    {
        if ([self getMessageRecordByID:messageId] == nil)
        {
            HOPSessionRecord* sessionRecord = [self getSessionRecordByID:sessionRecordId];
            messageRecord = (HOPMessageRecord*)[self createObjectForEntity:@"HOPMessageRecord"];
            messageRecord.text = messageText;
            messageRecord.date = date;
            messageRecord.type = type;
            messageRecord.fromPeer = rolodexContact.identityContact.peerFile;
            messageRecord.session = sessionRecord;
            messageRecord.messageID = messageId;
        }
        
        [self saveContext];
    }
    else
    {
        //NSString* str = [NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,sessionRecordId, messageId];
        ZS_LOG_ERROR(Debug, [self log:([NSString stringWithFormat:@"Some message data are invalid: messageText: %@ - type: %@ - date: %@ - sessionRecordId: %@ - messageId: %@", messageText, type, date,sessionRecordId, messageId])]);
    }
    
    return messageRecord;
}

- (void) clearSessionRecords
{
    NSArray* results = [self getResultsForEntity:@"HOPMessageRecord" withPredicateString:nil orderDescriptors:nil];
    
    for (HOPMessageRecord* record in results)
    {
        [self deleteObject:record];
    }
    
    results = [self getResultsForEntity:@"HOPSessionRecord" withPredicateString:nil orderDescriptors:nil];
    
    for (HOPSessionRecord* record in results)
    {
        [self deleteObject:record];
    }
    
    [self saveContext];
}
@end


