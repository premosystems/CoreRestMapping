//
//  NSManagedObject+CRMappingAdditions.m
//  Pods
//
//  Created by Vincil Bishop on 6/24/15.
//
//

#import "NSManagedObject+CRMappingAdditions.h"
#import "CoreRestMapping-Internal.h"

static NSString *_defaultPrimaryKeyProperty;
static NSString *_defaultPrimaryKeyPath;

static NSDateFormatter *_defaultDateFormatter;

@implementation NSManagedObject (CRMappingAdditions)

+ (EKManagedObjectMapping*) objectMapping {
    
    return [EKManagedObjectMapping mappingForEntityName:NSStringFromClass(self) withBlock:^(EKManagedObjectMapping *mapping) {
        
        [mapping mapPropertiesFromArray:[[[self MR_entityDescription] attributesByName] allKeys]];
        
        // TODO: Make this conditionally set a primary key based on userInfo from the managed object model
        
    }];
}

+ (NSDateFormatter*) CR_dateFormatter
{
	if (!_defaultDateFormatter) {
		// ISO 8601 Date
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		[dateFormatter setLocale:enUSPOSIXLocale];
		//[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
	
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];


		_defaultDateFormatter = dateFormatter;
	}
	
	return _defaultDateFormatter;
}

+ (void) CR_setDefaultDateFormatter:(NSDateFormatter*)dateFormatter
{
	_defaultDateFormatter = dateFormatter;
}

+ (void) CR_setPrimaryKeyProperty:(NSString*)keyProperty
{
    _defaultPrimaryKeyProperty = keyProperty;
}

+ (void) CR_setPrimaryKeyPath:(NSString*)keyPath
{
    _defaultPrimaryKeyPath = keyPath;
}

+ (NSString*) CR_primaryKeyProperty
{
    return _defaultPrimaryKeyProperty;
}

+ (NSString*) CR_primaryKeyPath
{
    return _defaultPrimaryKeyPath;
}

- (NSString*) CR_primaryKeyPropertyValue
{
    NSString *primaryKeyPropery = [[self class] objectMapping].primaryKey;
    return [self valueForKey:primaryKeyPropery];
}


+ (NSString*) CR_deletedNotificationName
{
    NSString *notificationNameString = [NSString stringWithFormat:@"%@_DELETED",NSStringFromClass(self)];
    return notificationNameString;
}

+ (NSString*) CR_savedNotificationName
{
    NSString *notificationNameString = [NSString stringWithFormat:@"%@_SAVED",NSStringFromClass(self)];
    return notificationNameString;
}

+ (NSArray*) CR_arrayOfEntitiesWithArray:(NSArray*)arrayOfRepresentations
{
    // TODO: remove the identifier property of all objects...
    __block NSArray *entities = nil;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:context]];
    
    entities = [EKManagedObjectMapper syncArrayOfObjectsFromExternalRepresentation:arrayOfRepresentations withMapping:[[self class] objectMapping] fetchRequest:request inManagedObjectContext:context];
    
    return entities;
    
}

+ (NSArray*) CR_arrayOfRepresentationsWithEntities:(NSArray*)objects
{
    NSArray *collectionRepresentation = [EKSerializer serializeCollection:objects withMapping:[[self class] objectMapping]];
    
    return _.arrayMap(collectionRepresentation,^NSDictionary* (NSDictionary *representation){
        
        NSMutableDictionary *mutable = [representation mutableCopy];
        
        //[mutable removeObjectForKey:@"identifier"];
        return mutable;
    });
}

+ (instancetype) CR_entityWithDictionary:(NSDictionary*)dictionaryRepresentation
{
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    
    [managedObject CR_updateWithDictionary:dictionaryRepresentation];
    
    return managedObject;
}

+ (instancetype) CR_serializeAndSaveOneEntity:(NSDictionary*)objectDictionary
{
    id entity = [self CR_upsertWithDictionary:objectDictionary];
    [((NSManagedObject*)entity).managedObjectContext MR_saveToPersistentStoreAndWait];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *entityDicts = @[];
        
        @try {
            id<CRRestfulObject> object = entity;
            if ([[object class] objectMapping].primaryKey) {
                
                entityDicts = @[[entity valueForKey:[[object class] objectMapping].primaryKey]];
                
            } else {
                
                entityDicts = @[[entity CR_dictionaryRepresentation]];
            }
        }
        @catch (NSException *exception) {
            NSString *className = NSStringFromClass(self);
            DDLogError(@"%@ CR_serializeAndSaveOneEntity:",className);
        }
        @finally {
            [[NSNotificationCenter defaultCenter] postNotificationName:[self CR_savedNotificationName] object:entityDicts];
        }
        
    });

    
    return entity;
}


+ (NSArray*) CR_serializeAndSaveManyEntities:(NSArray*)objectDictionaryArray
{
    NSArray *entities = [self CR_arrayOfEntitiesWithArray:objectDictionaryArray];
    
    if (entities && entities.count > 0) {
       
        id<CRRestfulObject> object = entities[0];
        NSString *primaryKey = nil;
        if ([[object class] objectMapping].primaryKey) {
           primaryKey = [[[object class] objectMapping].primaryKey copy];
           
            
        }
        
        NSManagedObjectContext *context = ((NSManagedObject*)entities[0]).managedObjectContext;
        
        [context MR_saveToPersistentStoreAndWait];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSArray *entityDicts = @[];
            
            @try {
                
                if (primaryKey) {
                   
                    entityDicts = _.pluck(entities,primaryKey);
                    
                } else {
                    
                    entityDicts = _.arrayMap(entities,^id(NSManagedObject *managedObject) {
                        
                        if (managedObject) {
                            return [[managedObject MR_inThreadContext] CR_dictionaryRepresentation];
                        } else {
                            return @{};
                        }
                        
                    });
                }

            }
            @catch (NSException *exception) {
                NSString *className = NSStringFromClass(self);
                DDLogError(@"%@ CR_serializeAndSaveManyEntities:",className);
            }
            @finally {
                [[NSNotificationCenter defaultCenter] postNotificationName:[self CR_savedNotificationName] object:entityDicts];
            }
            
            
        });
    }
    
    return entities;
}


+ (instancetype) CR_upsertWithDictionary:(NSDictionary*)dictionaryRepresentation
{
    NSManagedObject *managedObject = nil;
    
    BOOL isUnique = [self CR_primaryKeyProperty] && [self CR_primaryKeyPath];
    
    if (isUnique) {
        
        managedObject = [self MR_findFirstByAttribute:[self CR_primaryKeyProperty] withValue:dictionaryRepresentation[[self CR_primaryKeyPath]]];
        
    }
    
    if (managedObject) {
        
        [managedObject CR_updateWithDictionary:dictionaryRepresentation];
        
    } else {
        
        managedObject = [self CR_entityWithDictionary:dictionaryRepresentation];
    }
    
    return managedObject;
}


- (void) CR_updateWithDictionary:(NSDictionary*)dictionaryRepresentation
{
    [EKManagedObjectMapper fillObject:self fromExternalRepresentation:dictionaryRepresentation withMapping:[[self class] objectMapping] inManagedObjectContext:self.managedObjectContext];
}

- (NSDictionary*) CR_dictionaryRepresentation
{
    NSMutableDictionary *representation = [[EKSerializer serializeObject:self withMapping:[[self class] objectMapping] fromContext:self.managedObjectContext] mutableCopy];
    //[representation removeObjectForKey:@"identifier"];
    [representation removeObjectForKey:@"created"];
    [representation removeObjectForKey:@"last_updated"];
    return representation;
}

@end
