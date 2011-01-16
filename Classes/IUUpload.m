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
#import "IUUpload.h"

@implementation IUUpload

#define KEY @"6c02d7bed348d1e3e31bdd26df79abf2"
#define UPLOAD @"http://api.imgur.com/2/upload.xml"
#define REDDIT_SUBMIT_URL @"http://www.reddit.com/submit?url=%@"

@synthesize files;
@synthesize reddit;

-(void)main {
    NSAutoreleasePool* autorelease = [[NSAutoreleasePool alloc] init];
    NSLock* lock = [[NSLock alloc] init];
    
    for (NSString* file in files) {
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/curl"];
        
        NSArray *arguments;
        arguments = [NSArray arrayWithObjects:
                     [NSString stringWithFormat:@"-F image=@%@", file],
                     [NSString stringWithFormat:@"-F key=%@", KEY],
                     UPLOAD,
                     nil];
        
        [task setArguments: arguments];
        
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *handle;
        handle = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [handle readDataToEndOfFile];
        
        NSString *string;
        string = [[NSString alloc] initWithData:data
                                       encoding:NSUTF8StringEncoding];
        
        // find the image and copy it to the clipboard
        NSError* error = nil;
        NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithXMLString:string
                                                              options:0
                                                                error:&error]
                              autorelease];
        if (error) {
            [NSApp presentError:error];
            continue;
        }
        
        NSArray* nodes = [doc nodesForXPath:@"/upload/links/original"
                                      error:&error];
        NSString* url = [[nodes objectAtIndex:0] stringValue];
        
        if (error) {
            [NSApp presentError:error];
            continue;
        }
        
        if ([nodes count] != 1) {
            NSLog(@"Wrong amount of nodes: %u", (uint)[nodes count]);
        }
        
        if (reddit) {
            NSURL* redditURL = [NSURL URLWithString:
                                [NSString
                                 stringWithFormat:REDDIT_SUBMIT_URL, url]];
            [[NSWorkspace sharedWorkspace] openURL:redditURL];
        }
        else {
            NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:[NSArray arrayWithObjects:
                                      NSStringPboardType,
                                      nil]
                               owner:nil];
            [pasteboard setString:url forType:NSStringPboardType];
        }
        
        // notify that the upload is finished
        [[NSSound soundNamed:@"Glass"] play];
        [GrowlApplicationBridge notifyWithTitle:@"Upload Complete"
                                    description:url
                               notificationName:@"Upload Complete"
                                       iconData:[NSData
                                                 dataWithContentsOfFile:file]
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];
        
        // keep track of the images we've uploaded
        [lock lock];
        [[NSApp delegate] addImage:file withImgurUrl:url];
        [lock unlock];
    }
    
    [autorelease release];
}

@end
