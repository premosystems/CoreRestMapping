//
//  NSManagedObject+CRRestAdditions.m
//  Pods
//
//  Created by Vincil Bishop on 6/24/15.
//
//

#import "NSManagedObject+CRRestAdditions.h"
#import "CoreRestMapping-Internal.h"

static AFHTTPSessionManager *_CRHTTPSessionManager;
static NSOperationQueue *_CRBackgroundOperationQueue;

@implementation NSManagedObject (CRRestAdditions)

+ (void) CR_setBackgroundOperationQueue:(NSOperationQueue*)operationQueue
{
    _CRBackgroundOperationQueue = operationQueue;
}

+ (NSOperationQueue*) CR_BackgroundQueue
{
    if (!_CRBackgroundOperationQueue) {
        _CRBackgroundOperationQueue = [NSOperationQueue new];
        _CRBackgroundOperationQueue.maxConcurrentOperationCount = 4;
    }
    
    return _CRBackgroundOperationQueue;
}

+ (void) CR_setHTTPSessionManager:(AFHTTPSessionManager*)HTTPSessionManager
{
    _CRHTTPSessionManager = HTTPSessionManager;
}

+ (AFHTTPSessionManager*) CR_HTTPSessionManager
{
    return _CRHTTPSessionManager;
}

+ (NSString*) CR_RESTPath
{
    return nil;
}

+ (NSString*) CR_rootResponseElement
{
    return nil;
}

#pragma mark - Entity Convenience Verbs -

+ (void) CR_getRemoteEntitiesWithCompletion:(CRRestCompletionBlock)completion
{
    [self CR_getRemoteEntitiesAtPath:[self CR_RESTPath] parameters:nil completion:completion];
}

+ (void) CR_getRemoteEntityWithID:(NSString*)identifier withCompletion:(CRRestCompletionBlock)completion
{
    [self CR_getRemoteEntityAtPath:[self CR_RESTPath] withID:identifier parameters:nil completion:completion];
}

+ (void) CR_createRemoteEntity:(NSDictionary*)entityRepresentation withCompletion:(CRRestCompletionBlock)completion
{
    [self CR_createRemoteEntity:entityRepresentation atPath:[self CR_RESTPath] completion:completion];
}

+ (void) CR_deleteRemoteEntities:(NSArray*)entities withCompletion:(CRRestCompletionBlock)completion
{
    [self CR_deleteRemoteEntities:entities atPath:[self CR_RESTPath] parameters:nil completion:completion];
}

+ (void) CR_updateRemoteEntity:(id)entity withCompletion:(CRRestCompletionBlock)completion
{
    [self CR_updateRemoteEntity:entity atPath:[self CR_RESTPath] completion:completion];
}

- (void) CR_updateRemoteWithCompletion:(CRRestCompletionBlock)completion
{
    [[self class] CR_updateRemoteEntity:self withCompletion:completion];
}

#pragma mark - Entity Verb Base Method -

+ (void) CR_createRemoteEntity:(NSDictionary*)entityRepresentation atPath:(NSString*)path completion:(CRRestCompletionBlock)completion {
    //NSString *urlString = [NSString stringWithFormat:@"%@%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],[self RESTPath]];
    
    [[NSManagedObject CR_HTTPSessionManager] POST:path parameters:entityRepresentation success:^(NSURLSessionDataTask *task, id responseObject) {
        
        if ([self CR_rootResponseElement] && [responseObject isKindOfClass:[NSDictionary class]]) {
			
			NSDictionary *responseDictionary = (NSDictionary*)responseObject;
			
			if (responseDictionary[[self CR_rootResponseElement]]) {
			
				responseObject = responseDictionary[[self CR_rootResponseElement]];
			}
        }
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
			
            id entity = [self CR_serializeAndSaveOneEntity:responseObject];
            
            if (completion) {
                completion(self,YES,nil,entity);
            }
			
		} else if ([responseObject isKindOfClass:[NSArray class]]) {
			
			NSArray *entities = [self CR_serializeAndSaveManyEntities:responseObject];
			
			if (completion) {
				completion(self,YES,nil,entities);
			}
		
		} else {
			
            if (completion) {
                
                NSError *error = [NSError errorWithDomain:kCRRestErrorDomain_UnexpectedType code:kCRRestErrorCode_UnexpectedType userInfo:@{NSLocalizedFailureReasonErrorKey:responseObject}];
                
                completion(self,NO,error,nil);
            }
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [self logError:error request:entityRepresentation path:[self CR_RESTPath] object:task method:@"POST"];
        
        if (completion) {
            completion(self,NO,error,nil);
        }
    }];
}

+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion
{
    [self CR_createRemoteEntities:requestDictionaries atPath:path parameters:params progress:nil completion:completion];
}


+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion {
    
    [self CR_createRemoteEntities:requestDictionaries atPath:path parameters:params queue:[NSManagedObject CR_BackgroundQueue] progress:progress completion:completion];
}


+ (void) CR_createRemoteEntities:(NSArray*)requestDictionaries atPath:(NSString*)path parameters:(NSDictionary*)params queue:(NSOperationQueue*)operationQueue progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *mutableOperations = [NSMutableArray new];
        
        __block NSMutableArray *errors = [NSMutableArray new];
        __block NSError *requestError = nil;
        [requestDictionaries enumerateObjectsUsingBlock:^(NSDictionary *requestDictionary, NSUInteger idx, BOOL *stop) {
            NSMutableURLRequest *request = [[NSManagedObject CR_HTTPSessionManager].requestSerializer requestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@/%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],path] parameters:requestDictionary error:&requestError];
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            operation.responseSerializer = [[NSManagedObject CR_HTTPSessionManager] responseSerializer];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if ([self CR_rootResponseElement] && [responseObject isKindOfClass:[NSDictionary class]]) {
                    responseObject = ((NSDictionary*)responseObject)[[self CR_rootResponseElement]];
                }
                
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    // Endpoint returns 201 if a new device was created.
                    [self CR_serializeAndSaveOneEntity:responseObject];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self logError:error request:requestDictionary path:[self CR_RESTPath] object:operation.request method:@"POST"];
                
                [errors addObject:error];
            }];
            [mutableOperations addObject:operation];
        }];
        
        if (requestError) {
            [errors addObject:requestError];
        }
        
        NSArray *operations = nil;
        
        operations = [AFURLConnectionOperation batchOfRequestOperations:mutableOperations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
            
            DDLogVerbose(@"%lu of %lu complete", (unsigned long)numberOfFinishedOperations, (unsigned long)totalNumberOfOperations);
            
            if (progress) {
                progress(self,YES,nil,@{@"numberOfFinishedOperations":[NSNumber numberWithUnsignedInteger:numberOfFinishedOperations],@"totalNumberOfOperations":[NSNumber numberWithUnsignedInteger:totalNumberOfOperations]});
            }
            
        } completionBlock:^(NSArray *operations) {
            
        }];
        
        [operationQueue addOperations:mutableOperations waitUntilFinished:YES];
        
        if (completion) {
            
            if (errors.count > 0) {
                
                completion(self,NO,errors[0],errors);
                
            } else {
                
                completion(self,YES,nil,operations);
            }
            
        }
        
        
    });
}


+ (void) CR_deleteRemoteEntity:(NSManagedObject*)entity completion:(CRRestCompletionBlock)completion {
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@/%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],[self CR_RESTPath],[entity CR_primaryKeyPropertyValue]];
    
    NSArray *entityDicts = nil;
    if (entity) {
        
        id<CRRestfulObject> object = entity;
        if ([[object class] objectMapping].primaryKey) {
            
            entityDicts = @[[entity valueForKey:[[object class] objectMapping].primaryKey]];
            
        } else {
            
            entityDicts = @[[entity CR_dictionaryRepresentation]];
        }
    }
    
    [[NSManagedObject CR_HTTPSessionManager] DELETE:urlString parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
            [entity MR_deleteEntity];
        }];
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[self CR_savedNotificationName] object:entityDicts];
            
        });
        
        
        if (completion) {
            completion(self,YES,nil,entity);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSString *entityDescription = [[entity CR_dictionaryRepresentation] description];
        [self logError:error request:entityDescription path:[self CR_RESTPath] object:task method:@"DELETE"];
        
        if (completion) {
            completion(self,NO,error,nil);
        }
        
    }];
}


+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion
{
    [self CR_deleteRemoteEntities:entities atPath:path parameters:params progress:nil completion:completion];
}


+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion
{
    [self CR_deleteRemoteEntities:entities atPath:path parameters:params queue:[NSManagedObject CR_BackgroundQueue] progress:progress completion:completion];
}


+ (void) CR_deleteRemoteEntities:(NSArray*)entities atPath:(NSString*)path parameters:(NSDictionary*)params queue:(NSOperationQueue*)operationQueue progress:(CRRestCompletionBlock)progress completion:(CRRestCompletionBlock)completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *mutableOperations = [NSMutableArray new];
        
        __block NSMutableArray *errors = [NSMutableArray new];
        __block NSError *requestError = nil;
        
        NSArray *entityDicts = nil;
        
        if (entities && entities.count > 0) {
            
            id<CRRestfulObject> object = entities[0];
            if ([[object class] objectMapping].primaryKey) {
                
                entityDicts = _.pluck(entities,[[object class] objectMapping].primaryKey);
                
            } else {
                
                entityDicts = _.arrayMap(entities,^id(NSManagedObject *managedObject) {
                    
                    return [managedObject CR_dictionaryRepresentation];
                    
                });
            }
        }
        
        [entities enumerateObjectsUsingBlock:^(NSManagedObject *entity, NSUInteger idx, BOOL *stop) {
            
            NSString *entityString = [entity description];
            
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext){
                [entity MR_deleteEntity];
            }];
            
            NSString *urlString = [NSString stringWithFormat:@"%@%@/%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],path,[entity CR_primaryKeyPropertyValue]];
            NSMutableURLRequest *request = [[NSManagedObject CR_HTTPSessionManager].requestSerializer requestWithMethod:@"DELETE" URLString:urlString parameters:nil error:&requestError];
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            operation.responseSerializer = [[AFJSONResponseSerializer alloc] init];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self logError:error request:entityString path:[self CR_RESTPath] object:operation.request method:@"DELETE"];
                
                [errors addObject:error];
            }];
            
            [mutableOperations addObject:operation];
            
        }];
        
        
        if (requestError) {
            [errors addObject:requestError];
        }
        
        NSArray *operations = nil;
        
        operations = [AFURLConnectionOperation batchOfRequestOperations:mutableOperations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
            DDLogVerbose(@"%lu of %lu complete", (unsigned long)numberOfFinishedOperations, (unsigned long)totalNumberOfOperations);
            
            if (progress) {
                progress(self,YES,nil,@{@"numberOfFinishedOperations":[NSNumber numberWithUnsignedInteger:numberOfFinishedOperations],@"totalNumberOfOperations":[NSNumber numberWithUnsignedInteger:totalNumberOfOperations]});
            }
            
        } completionBlock:^(NSArray *operations) {
            
            
            
        }];
        
        [operationQueue addOperations:mutableOperations waitUntilFinished:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[self CR_deletedNotificationName] object:entityDicts];
            
        });
        
        if (completion) {
            
            if (errors.count > 0) {
                
                completion(self,NO,errors[0],errors);
                
            } else {
                
                completion(self,YES,nil,operations);
            }
        }
        
    });
}


+ (void) CR_getRemoteEntitiesAtPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion
{
    [[NSManagedObject CR_HTTPSessionManager] GET:path parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        if ([self CR_rootResponseElement] && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *maybeResult = ((NSDictionary*)responseObject)[[self CR_rootResponseElement]];
			
			if (maybeResult) {
				responseObject = maybeResult;
			}
        }
        
        if ([responseObject isKindOfClass:[NSArray class]]) {
            
            NSArray *entities = [self CR_serializeAndSaveManyEntities:responseObject];
            
            if (completion) {
                completion(self,YES,nil,entities);
            }
        } else {
            if (completion) {
                
                NSError *error = [NSError errorWithDomain:kCRRestErrorDomain_UnexpectedType code:kCRRestErrorCode_UnexpectedType userInfo:@{NSLocalizedFailureReasonErrorKey:responseObject}];
                
                completion(self,NO,error,nil);
            }
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self logError:error request:params path:[self CR_RESTPath] object:task method:@"GET"];
        if (completion) {
            completion(self,NO,error,nil);
        }
    }];
}

+ (void) CR_getRemoteEntityAtPath:(NSString*)path withID:(NSString*)identifier parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion
{
    NSString *urlString = nil;
    
    if (identifier) {
        
        urlString = [NSString stringWithFormat:@"/%@/%@",path,identifier];
        
    } else {
        
        urlString = [NSString stringWithFormat:@"/%@",path];
    }
    
    [self CR_getRemoteEntityAtPath:urlString parameters:params completion:completion];
    
}

+ (void) CR_getRemoteEntityAtPath:(NSString*)path parameters:(NSDictionary*)params completion:(CRRestCompletionBlock)completion
{
    [[NSManagedObject CR_HTTPSessionManager] GET:path parameters:params success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
        
        if ([self CR_rootResponseElement] && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *maybeResult = ((NSDictionary*)responseObject)[[self CR_rootResponseElement]];
			
			if (maybeResult) {
				responseObject = maybeResult;
			}
			
        }
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id entity = [self CR_serializeAndSaveOneEntity:responseObject];
            
            if (completion) {
                completion(self,YES,nil,entity);
            }
        } else {
            if (completion) {
                
                NSError *error = [NSError errorWithDomain:kCRRestErrorDomain_UnexpectedType code:kCRRestErrorCode_UnexpectedType userInfo:@{NSLocalizedFailureReasonErrorKey:responseObject}];
                
                completion(self,NO,error,nil);
            }
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self logError:error request:[params description] path:[self CR_RESTPath] object:task method:@"GET"];
        if (completion) {
            completion(self,NO,error,nil);
        }
    }];
}


+ (void) CR_updateRemoteEntity:(NSManagedObject*)entity atPath:(NSString*)path completion:(CRRestCompletionBlock)completion
{
    NSString *uniqueID = [entity CR_primaryKeyPropertyValue];
	[self CR_updateRemoteEntity:entity atPath:path withID:uniqueID withParameters:[entity CR_dictionaryRepresentation] completion:completion];
}

+ (void) CR_updateRemoteEntity:(NSManagedObject*)entity atPath:(NSString*)path withID:(id)uniqueID withParameters:(NSDictionary*)parameters completion:(CRRestCompletionBlock)completion
{
	NSString *urlString = [NSString stringWithFormat:@"%@%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],path];
	
	if (uniqueID) {
		urlString = [NSString stringWithFormat:@"%@%@/%@",[[NSManagedObject CR_HTTPSessionManager].baseURL absoluteString],path,uniqueID];
	}

	[[NSManagedObject CR_HTTPSessionManager] PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
		
		if ([responseObject isKindOfClass:[NSDictionary class]]) {
			id entity = [self CR_serializeAndSaveOneEntity:responseObject];
			
			if (completion) {
				completion(self,YES,nil,entity);
			}
		} else {
			if (completion) {
				
				NSError *error = [NSError errorWithDomain:kCRRestErrorDomain_UnexpectedType code:kCRRestErrorCode_UnexpectedType userInfo:@{NSLocalizedFailureReasonErrorKey:responseObject}];
				
				completion(self,NO,error,nil);
			}
		}
		
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		[self logError:error request:entity path:[self CR_RESTPath] object:task method:@"PUT"];
		
		if (completion) {
			completion(self,NO,error,nil);
		}
	}];
}


+ (void) logError:(NSError*)error request:(id)request path:(NSString*)path object:(id)object method:(NSString*)method
{
    DDLogError(@"path: [%@] method:[%@] request: [%@] task: [%@] failed with error: [%@]",path,method,request,object,error);
}


@end
