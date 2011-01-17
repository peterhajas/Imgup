// Copyright (c) 2010, Nate Stedman <natesm@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#import <Growl/Growl.h>
#import "IUAppDelegate.h"
#import "IUStatusItem.h"
#import "IUDropView.h"
#import "IUUpload.h"

#define THUMB_SIZE 100

#define JPEG_KEYS [NSArray arrayWithObjects:NSImageCompressionFactor, nil]
#define JPEG_OBJECTS [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.9f],\
                                               nil]
#define JPEG_PROPERTIES [NSDictionary dictionaryWithObjects:JPEG_OBJECTS \
                                                    forKeys:JPEG_KEYS]

#define HISTORY_FILE [NSString stringWithFormat:@"%@/history.plist", \
                      [self applicationSupportDirectory]]

@implementation IUAppDelegate

@synthesize history;
@synthesize recentUploads;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [GrowlApplicationBridge setGrowlDelegate:@""]; 
    
    // create a drop view
    dropView = [[IUDropView alloc] initWithFrame:
                NSMakeRect(0, 0, SIZE, SIZE)];
    
    item = [[IUStatusItem alloc] initWithView:dropView menu:menu];
    
    // load the old history
    if ([[NSFileManager defaultManager] fileExistsAtPath:HISTORY_FILE] == YES) {
        history = [NSMutableArray arrayWithContentsOfFile:HISTORY_FILE];
    }
    
    // or create a new array if it isn't there
    else {
        history = [[NSMutableArray alloc] init];
    }
}

-(IBAction)onPreferences:(NSMenuItem *)sender {
    
}

-(IBAction)onUploadClipboard:(NSMenuItem *)sender {
    // write to a temp file
    
    // upload!
    /*IUUpload* upload = [[IUUpload alloc] init];
    [upload setFiles:[NSArray arrayWithObject:file];
    [upload setReddit:commandDown()];
    [[dropView uploads] addOperation:upload];*/
}

-(IBAction)onQuit:(NSMenuItem *)sender {
    [NSApp terminate:nil];
}

-(void)addImage:(NSString*)file withImgurUrl:(NSString*)url {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]
                                 initWithCapacity:2];
    
    // track the image
    [dict setValue:[[NSURL URLWithString:url] lastPathComponent]
            forKey:FILE_KEY];
    [dict setValue:url forKey:URL_KEY];
    [history insertObject:dict atIndex:0];
    
    // load the image (locally)
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:file];
    
    // find the size that will fit the image within 100x100
    NSSize origSize = [image size];
    NSSize size = origSize;
    if (size.width > size.height) {
        size.height = (size.height / size.width) * THUMB_SIZE;
        size.width = THUMB_SIZE;
    }
    else {
        size.width = (size.width / size.height) * THUMB_SIZE;
        size.height = THUMB_SIZE;
    }
    
    // scale down the image
    NSImage* sized = [[NSImage alloc] initWithSize:size];
    [sized lockFocus];
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
             fromRect:NSMakeRect(0, 0, origSize.width, origSize.height)
            operation:NSCompositeSourceOver
             fraction:1.0];
    [sized unlockFocus];
    
    
    // save the thumbnail
    [[NSBitmapImageRep representationOfImageRepsInArray:[[[NSImage alloc]
                                                         initWithData:
                                                         [sized
                                                          TIFFRepresentation]]
                                                         representations]
                                              usingType:NSJPEGFileType
                                             properties:nil]
     writeToFile:[self imagePath:[dict valueForKey:FILE_KEY]] atomically:YES];
    
    // write the plist to a file
    [history writeToFile:HISTORY_FILE atomically:YES];
}

-(NSString*)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory,
		NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] :
                                               NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Imgup"];
}

-(NSString*)imagePath:(NSString*)filename {
    // create the thumbnail directory if needed
    NSString* path = [NSString stringWithFormat:@"%@/Thumbnails/",
                      [[NSApp delegate] applicationSupportDirectory]];
    if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return [NSString stringWithFormat:@"%@%@", path, filename];
}

@end
