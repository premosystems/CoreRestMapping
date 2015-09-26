//
//  NSManagedObject+CRRestAdditions.h
//  Pods
//
//  Created by Vincil Bishop on 6/24/15.
//
//

#import <CoreData/CoreData.h>
#import "CoreRestMapping-Blocks.h"

@class AFHTTPSessionManager;

@interface NSManagedObject (CRRestAdditions)

+ (void) CR_setBackgroundOperationQueue:(NSOperationQueue*)operationQueue;
+ (NSOperationQueue*) CR_BackgroundQueue;

+ (void) CR_setHTTPSessionManager:(AFHTTPSessionManager*)httpSessionManager;

+ (AFHTTPSessionManager*) CR_HTTPSessionManager;

+ (NSString*) CR_RESTPath;

+ (NSString*) CR_rootResponseElement;

/**
 *  Gets all entities from the RESTPath endpoint.
 *
 *  @param completion An optional completion block to be executed upon completion.
 *
 *  @discussion Once this call is complete, the retrieved objects will be serialized and stored in the persistent store.
 */
+ (void) CR_getRemoteEntitiesWithCompletion:(CRRestCompletionBlock)completion;

/**
 *  Gets a specific entity with an identifier, then serializes the response into CoreData.
 *
 *  @param identifier The identifier (_id) of the entity.
 *  @param completion A block to be executed when the transaction completes.
 */
+ (void) CR_getRemoteEntityWithID:(NSString*)identifier withCompletion:(CRRestCompletionBlock)completion;

+ (void) CR_createRemoteEntity:(NSDictionary*)entityRepresentation withCompletion:(CRRestCompletionBlock)completion;

/**
 *  Deletes the entities from the server.
 *
 *  @param entities     An array of NSManagedObject subclasses to delete.
 *  @param completion A completion block to be run when the transaction completes.
 *
 */
+ (void) CR_deleteRemoteEntities:(NSArray*)entities withCompletion:(CRRestCompletionBlock)completion;

/**
 *  Updates the entity, then serializes the response into CoreData.
 *
 *  @param entity     The entity with updated values to be PUT.
 *  @param completion A completion block to be run when the transaction completes.
 */
+ (void) CR_updateRemoteEntity:(id)entity withCompletion:(CRRestCompletionBlock)completion;

- (void) CR_updateRemoteWithCompletion:(CRRestCompletionBlock)completion;

+ (void) CR_createRemoteEntity:(NSDictionary*)entityRepresentation atPath:(NSString*)path completion:(CRRestCompletionBlock)completion;

/**
 *  Creates a collection of entities at a specific path, then serializes the response to CoreData.
 *
 *  @param requestDictionaries An array of NSDictionary object representations.
 *  @param path                The path to POST the entities to.
 *  @param params              Parameters to send along with the request.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion;

/**
 *  Creates a collection of entities at a specific path, then serializes the response to CoreData.
 *
 *  @param requestDictionaries An array of NSDictionary object representations.
 *  @param path                The path to POST the entities to.
 *  @param params              Parameters to send along with the request.
 *  @param progress            A progress block to be run when each operation completes.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion;

+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params queue:(NSOperationQueue*)operationQueue progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion;

/**
 *  Deletes a single entity.
 *
 *  @param entity     The entity to delete.
 *  @param completion A completion block to be run when the transaction completes.
 */
+ (void) CR_deleteRemoteEntity:(NSManagedObject*)entity completion:(CRRestCompletionBlock)completion;

/**
 *  Deletes a collection of entities at a specific path, then serializes the response to CoreData.
 *
 *  @param requestDictionaries An array of NSManagedObject subclasses to delete.
 *  @param path                The path to DELETE the entities from.
 *  @param params              Parameters to send along with the request.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion;


/**
 *  Deletes a collection of entities at a specific path, then serializes the response to CoreData.
 *
 *  @param requestDictionaries An array of NSManagedObject subclasses to delete.
 *  @param path                The path to DELETE the entities from.
 *  @param params              Parameters to send along with the request.
 *  @param progress            A progress block to be run when each operation completes.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion;


+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params queue:(NSOperationQueue*)operationQueue progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion;

/**
 *  Gets a collection of entities at a specific path, then serializes the response to CoreData.
 *
 *  @param path                The path to GET the entities from.
 *  @param params              Parameters to send along with the request.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_getRemoteEntitiesAtPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion;

/**
 *  Gets a single entity at a specific path, then serializes the response to CoreData.
 *
 *  @param path       The path to GET the entity from.
 *  @param identifier The identifier (_id) of the entity to GET.
 *  @param params              Parameters to send along with the request.
 *  @param completion          A completion block to be run when the transaction completes.
 */
+ (void) CR_getRemoteEntityAtPath:(NSString*)path withID:(NSString*)identifier parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion;

+ (void) CR_getRemoteEntityAtPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion;

/**
 *  Updates the supplied entity at a specific path.
 *
 *  @param entity     The entity with updated values to be PUT.
 *  @param path        The path to PUT the entities to.
 *  @param completion A completion block to be run when the transaction completes.
 */
+ (void) CR_updateRemoteEntity:(NSManagedObject*)entity atPath:(NSString*)path completion:(CRRestCompletionBlock)completion;

@end
