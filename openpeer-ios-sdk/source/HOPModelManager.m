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
#import "OpenPeerConstants.h"
#import <CoreData/CoreData.h>

@interface HOPModelManager()

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
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"OpenPeerDataModel" ofType:@"bundle"];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"OpenPeerModel" withExtension:@"momd"];
    NSManagedObjectModel* modelData = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSURL *modelURL2 = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"OpenPeerCacheModel" withExtension:@"momd"];
    NSManagedObjectModel* modelCache = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL2];
    
    _managedObjectModel = [NSManagedObjectModel modelByMergingModels:@[modelData,modelCache]];
    
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
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *pathDirectory = [libraryPath stringByAppendingPathComponent:databaseDirectory];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:pathDirectory withIntermediateDirectories:YES attributes:nil error:&error])
    {
        [NSException raise:@"Failed creating directory" format:@"[%@], %@", pathDirectory, error];
    }
    
    NSString *path = [pathDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",databaseName]];
    NSURL *storeURL = [NSURL fileURLWithPath:path];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
#warning TODO: remove this comment
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
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
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
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

- (HOPCacheData*) getCacheDataForPath:(NSString*) path
{
    HOPCacheData* ret = nil;
    
    NSArray* results = [self getResultsInBackgroundForEntity:@"HOPCacheData" withPredicateString:[NSString stringWithFormat:@"(path MATCHES '%@') AND ( (expire == nil) || (expire >= %f))", path, [[NSDate date] timeIntervalSince1970]] orderDescriptors:nil];
    
    ret = [results count] > 0 ? ((HOPCacheData*)results[0]) : nil;
    
    return ret;
}

- (void) setCookie:(NSString*) data withPath:(NSString*) path expires:(NSDate*) expires
{
    if ([path length] > 0)
    {
        [self.backgroundManagedObjectContext performBlockAndWait:
         ^{
            HOPCacheData* cacheData = [self getCacheDataForPath:path];

            if (!cacheData)
                cacheData = (HOPCacheData*)[self createObjectInBackgroundForEntity:@"HOPCacheData"];
            
            cacheData.data = data;
            cacheData.path = path;
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
         HOPCacheData* cacheData = [self getCacheDataForPath:path];
         ret = cacheData.data;

     }];
    return ret;
}

- (void) removeExpiredCookies
{
    [self.backgroundManagedObjectContext performBlock:
     ^{
        NSArray* objectsToDelete = [self getResultsInBackgroundForEntity:@"HOPCacheData" withPredicateString:[NSString stringWithFormat:@" (expire < %f)", [[NSDate date] timeIntervalSince1970]] orderDescriptors:nil];
        
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
            HOPCacheData* cacheData = [self getCacheDataForPath:path];
            if (cacheData)
                [self.backgroundManagedObjectContext deleteObject:cacheData];
            
            [self saveBackgroundContext];
        }];
    }
}
@end


