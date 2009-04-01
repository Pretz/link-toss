//
//  main.m
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright Alex Pretzlav 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LinkController.h"

@class LinkHandler;
BOOL noUI = NO;

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pl = [[NSAutoreleasePool alloc] init];
    NSMutableArray *strs = [NSMutableArray arrayWithCapacity:argc-1];
    int i;
    for (i = 0; i < argc; i++) {
        [strs addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    NSLog(@"%@", strs);
    NSLog(@"blehhhhhhhh blehhhhh blehhhhhhh");
    [pl release];
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:[LinkController class] andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    return NSApplicationMain(argc,  (const char **) argv);
}