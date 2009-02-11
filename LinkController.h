//
//  LinkController.h
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright 2007 Alex Pretzlav. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "ApplicationServices/ApplicationServices.h"
//#import "CoreFoundation/CoreFoundation.h"
#import <Carbon/Carbon.h>

@interface LinkController : NSObject {
  IBOutlet NSPopUpButton * browserChooser;
  IBOutlet NSWindow * chooserWindow;
}

-(NSArray *)appsThatOpen:(NSURL *)aURL;
-(IBAction)quitButtonPressed:(id)sender;
-(IBAction)browserChooserUsed:(id)sender;

@end
