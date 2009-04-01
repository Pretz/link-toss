//
//  LinkController.m
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright 2007 Alex Pretzlav. All rights reserved.
//

#import "LinkController.h"

extern int noUI;

@implementation LinkController

/** Heee I aint gonna free nuthin' cuz tha app just quits after handlin' a URL.  HA! HA!
 */
+ (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
  noUI = YES;
  if ([event numberOfItems] == 0) {
    NSLog(@"Failed to get URL");
    [[NSApplication sharedApplication] terminate:self];
    return;
  }

  NSString *urlString = [[event descriptorAtIndex:1] stringValue];
  if (! urlString) {
    NSLog(@"Can't seem to get target URL");
    [[NSApplication sharedApplication] terminate:self];
    return;
  }
  /* Actual target URL */
  NSURL * urlToOpen = [NSURL URLWithString: urlString];
  [self openURL:urlToOpen];
}

+(NSArray *)appsThatOpen:(NSURL *)thisURL{
  NSArray * apps = (NSArray *) LSCopyApplicationURLsForURL((CFURLRef) thisURL, kLSRolesViewer);
  NSLog(@"Locating apps to open %@: %@", thisURL, apps);
  return [apps autorelease];
}

+(void)openURL:(NSURL*)url {
  NSString * appToLaunch = nil;
  /* Apps that can open URLs */
  NSArray * goodApps = [self appsThatOpen: url];
  NSLog(@"Apps that open %@: %@", url, goodApps);
  NSMutableDictionary * appsForURLs = [NSMutableDictionary dictionaryWithCapacity:[goodApps count]];
  int i;
  for (i = 0; i < [goodApps count]; i++) {
    //    NSLog((NSString *) CFURLCopyFileSystemPath((CFURLRef) CFArrayGetValueAtIndex(goodApps, i), kCFURLPOSIXPathStyle));
    [appsForURLs setObject: [NSNumber numberWithInt:i+1] forKey:[[goodApps objectAtIndex:i] path]];
  }
  NSArray * runningApps = [[NSWorkspace sharedWorkspace] launchedApplications];
  /* Check each app that is running, and see if it handles URLS. If so, choose it as the app to launch */
  for (i = 0; i < [runningApps count]; i++) {
    if ([[[runningApps objectAtIndex: i] objectForKey:@"NSApplicationBundleIdentifier"]
         isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
      continue;
    //    NSLog([[runningApps objectAtIndex:j] objectForKey:@"NSApplicationPath"]);
    if ([appsForURLs objectForKey: [[runningApps objectAtIndex:i] objectForKey:@"NSApplicationPath"]]) {
      //      NSLog([[runningApps objectAtIndex:j] objectForKey:@"NSApplicationPath"]);
      appToLaunch = [[runningApps objectAtIndex:i] objectForKey:@"NSApplicationPath"];
    }
  }
  LSLaunchURLSpec urlSpec;
  urlSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObject: url];
  urlSpec.passThruParams = NULL;
  urlSpec.launchFlags = kLSLaunchDefaults;
  urlSpec.asyncRefCon = NULL;
  if (appToLaunch) {    
    urlSpec.appURL = (CFURLRef) [goodApps objectAtIndex:[[appsForURLs objectForKey:appToLaunch] intValue]-1];
  }
  else {
    urlSpec.appURL = (CFURLRef) [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultBrowser"]];
  }
  LSOpenFromURLSpec(&urlSpec, NULL);
  [[NSApplication sharedApplication] terminate:self];
}

-(BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  NSLog(@"Open: %@", filename);
  [LinkController openURL: [NSURL fileURLWithPath:filename]];
  return YES;
}

- (void)awakeFromNib {
  NSLog(@"Okay, I loaded");
}

-(IBAction)quitButtonPressed:(id)sender {
  [[NSApplication sharedApplication] terminate:self];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  if (!noUI) {
    ProcessSerialNumber psn;
    GetCurrentProcess(&psn);
    OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    if (returnCode == 0) {
      NSLog(@"Bundle path: %@", [[NSBundle mainBundle] bundlePath]);
      [self initChooserWindow]; 
      SetFrontProcess(&psn);
      [NSMenu setMenuBarVisible:YES];
      [chooserWindow makeKeyAndOrderFront:self];
      [[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle mainBundle] bundlePath]];
    }
  }
}

-(void)initChooserWindow {
  NSLog(@"Done Launching");
  /* Make sure we have _some_ default browser */
  NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultBrowserName;
  if (! (defaultBrowserName = [sharedDefaults objectForKey:@"DefaultBrowserName"])){
    defaultBrowserName = @"Safari.app";
    [sharedDefaults setObject:@"/Applications/Safari.app" forKey:@"DefaultBrowser"];
    [sharedDefaults setObject:defaultBrowserName forKey:@"DefaultBrowserName"];
  }
  NSArray * appsForList = [LinkController appsThatOpen:[NSURL URLWithString:@"http:"]];
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
}

-(IBAction)browserChooserUsed:(id)sender {
  NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
  [sharedDefaults setObject:[[browserChooser selectedItem] representedObject] forKey:@"DefaultBrowser"];
  [sharedDefaults setObject:[[browserChooser selectedItem] title] forKey:@"DefaultBrowserName"];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app{
  return YES;
}

- (id)init {
  self = [super init];
  return self;
  noUI = NO;
}
@end
