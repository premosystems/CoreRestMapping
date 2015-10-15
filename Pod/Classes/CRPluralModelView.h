//
//  CRPluralModelView.h
//  Pods
//
//  Created by Vincil Bishop on 10/1/15.
//
//

#import <Foundation/Foundation.h>

@protocol CRRestfulObject;
@protocol CRMappableObject;

@protocol CRPluralModelView <NSObject>

/**
 *  An array of model objects conforming to the CRRestfulObject protocol.
 */
@property (nonatomic,strong) NSArray* CR_modelObjects;

/**
 *  Updated the model objects and view.
 *
 *  @param modelObjects The model objects to update.
 */
- (void) CR_updateWithModelObjects:(NSArray*)modelObjects;

@end
