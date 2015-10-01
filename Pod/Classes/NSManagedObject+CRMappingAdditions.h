//
//  NSManagedObject+CRMappingAdditions.h
//  Pods
//
//  Created by Vincil Bishop on 6/24/15.
//
//

#import <CoreData/CoreData.h>
#import "EKMappingProtocol.h"
#import "CRMappableObject.h"

@interface NSManagedObject (CRMappingAdditions)<CRMappableObject,EKManagedMappingProtocol>


@end
