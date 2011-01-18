/*
 * Base64 Methods
 *
 * Created by Matt Gallagher on 2009/06/03.
 * Copyright 2009 Matt Gallagher. All rights reserved.
 *
 * Permission is given to use this source code file, free of charge, in any
 * project, commercial or otherwise, entirely at your risk, with the condition
 * appreciated but not required.
 */

#import <Cocoa/Cocoa.h>


@interface NSData (Base64)
+ (NSData *)dataFromBase64EncodedString:(NSString *)aString;
- (NSString *)base64EncodedString;
@end
