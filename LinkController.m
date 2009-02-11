//
//  LinkController.m
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright 2007 Alex Pretzlav. All rights reserved.
//

#import "LinkController.h"

@implementation LinkController

- (void)awakeFromNib {
  NSLog(@"Okay, I loaded");
}

-(IBAction)quitButtonPressed:(id)sender {
  [[NSApplication sharedApplication] terminate:self];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  ProcessSerialNumber psn;
  GetCurrentProcess(&psn);
  TransformProcessType(&psn, kProcessTransformToForegroundApplication);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSLog(@"Done Launching");
  /* Make sure we have _some_ default browser */
  NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultBrowserName;
  if (! (defaultBrowserName = [sharedDefaults objectForKey:@"DefaultBrowserName"])){
    defaultBrowserName = @"Safari.app";
    [sharedDefaults setObject:@"/Applications/Safari.app" forKey:@"DefaultBrowser"];
    [sharedDefaults setObject:defaultBrowserName forKey:@"DefaultBrowserName"];
  }
  NSArray * appsForList = [self appsThatOpen:[NSURL URLWithString:@"http:"]];
  NSEnumerator *appEnumerator = [appsForList objectEnumerator];
  NSURL *thisAppURL;
  NSImage* iconImage;
  NSMenuItem *thisMenuItem;
  [browserChooser removeAllItems];
  NSString *pathToLinkToss = [[NSBundle mainBundle] bundlePath];
  NSString *nameOfLinkToss = [[NSFileManager defaultManager] displayNameAtPath: pathToLinkToss];
  /* Populates the dropdown list with browser names with icons,
   and associates each item with the URL to the applciation. */
  while ((thisAppURL = [appEnumerator nextObject])) {
    NSString * displayName;
    LSCopyDisplayNameForURL((CFURLRef) thisAppURL, (CFStringRef *)&displayName);
    if ([displayName isEqualToString:nameOfLinkToss]){
      continue; /* Don't put this app itself in the list! */
    }
    [browserChooser addItemWithTitle:[displayName autorelease]];
    thisMenuItem = [browserChooser itemWithTitle:displayName];
    iconImage = [[NSWorkspace sharedWorkspace] iconForFile: [thisAppURL path]];
    [iconImage setSize:NSMakeSize(16.0, 16.0)];
    [thisMenuItem setImage:iconImage];
    [thisMenuItem setRepresentedObject:[thisAppURL path]];
    if ([defaultBrowserName isEqualToString:displayName]){
      [browserChooser selectItemWithTitle:defaultBrowserName];
    }
  }
  ProcessSerialNumber psn;
  GetCurrentProcess(&psn);
  SetFrontProcess(&psn); 
  [NSMenu setMenuBarVisible:YES];
  [chooserWindow makeKeyAndOrderFront:self];
}

-(IBAction)browserChooserUsed:(id)sender {
  NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
  [sharedDefaults setObject:[[browserChooser selectedItem] representedObject] forKey:@"DefaultBrowser"];
  [sharedDefaults setObject:[[browserChooser selectedItem] title] forKey:@"DefaultBrowserName"];
}

-(NSArray *)appsThatOpen:(NSURL *)thisURL{
  NSArray * apps = (NSArray *) LSCopyApplicationURLsForURL((CFURLRef) thisURL, kLSRolesViewer);
  return [apps autorelease];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app{
  return YES;
}
- (id)init {
  self = [super init];
  return self;
}
@end
