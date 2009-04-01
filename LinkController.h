//
//  LinkController.h
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright 2007 Alex Pretzlav. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LinkController : NSObject {
    IBOutlet NSPopUpButton * browserChooser;
    IBOutlet NSWindow * chooserWindow;
}
+(NSArray *)appsThatOpen:(NSURL *)thisURL;
+(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
+(void)openURL:(NSURL*)url;

-(IBAction)quitButtonPressed:(id)sender;
-(IBAction)browserChooserUsed:(id)sender;
-(void)initChooserWindow;

@end
