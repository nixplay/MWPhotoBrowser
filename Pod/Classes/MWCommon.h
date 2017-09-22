//
//  MWPreprocessor.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 01/10/2013.
//

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IPHONE_CLASSIC @"iPhone Classic"
#define IPHONE_4 @"iPhone 4 or 4S"
#define IPHONE_5 @"iPhone 5 or 5S or 5C"
#define IPHONE_6 @"iPhone 6 or 6S"
#define IPHONE_6PLUS @"iPhone 6+ or 6S+"
#define IPHONE_X @"iPhone X"
#define IPHONE_UNKNOWN @"unknown"
