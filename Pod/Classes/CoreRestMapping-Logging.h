//
//  CoreRestMapping-Logging.h
//  Pods
//
//  Created by Vincil Bishop on 6/24/15.
//
//

#ifndef Pods_CoreRestMapping_Logging_h
#define Pods_CoreRestMapping_Logging_h
#endif

#import <CocoaLumberjack/CocoaLumberjack.h>

#define LOG_LEVEL_DEF CRRestLogLevel

#ifdef DEBUG
#ifndef CRREST_LOGGING_ON
#define CRREST_LOGGING_ON 1
#endif
#endif

#ifndef CRREST_LOGGING_ON
#define CRREST_LOGGING_ON 0
#endif

#if CRREST_LOGGING_ON
static const DDLogLevel CRRestLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel CRRestLogLevel = DDLogLevelOff;
#endif