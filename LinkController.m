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
+ (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  NSLog(@"Handling Event");
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
//  NSLog(@"Locating apps to open %@: %@", thisURL, apps);
  return [apps autorelease];
}

+(void)openURL:(NSURL*)url {
  NSString * appToLaunch = nil;
  /* Apps that can open URLs */
  NSArray * goodApps = [self appsThatOpen:url];
//  NSLog(@"Apps that open %@: %@", url, goodApps);
  NSMutableDictionary * appsForURLs = [NSMutableDictionary dictionaryWithCapacity:[goodApps count]];
  for (int i = 0; i < [goodApps count]; i++) {
    //    NSLog((NSString *) CFURLCopyFileSystemPath((CFURLRef) CFArrayGetValueAtIndex(goodApps, i), kCFURLPOSIXPathStyle));
    [appsForURLs setObject: [NSNumber numberWithInt:i+1] forKey:[[goodApps objectAtIndex:i] path]];
  }
  NSArray */*of NSDictionary*/runningApps = [[NSWorkspace sharedWorkspace] launchedApplications];
  NSString *preferredBrowserPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultBrowser"];
  BOOL usePreferredBrowser = NO;

  /* Check each app that is running, and see if it handles URLS. If so, choose it as the app to launch */
  for (int i = 0; i < [runningApps count]; i++) {
    // Skip Link Toss
    if ([[[runningApps objectAtIndex:i] objectForKey:@"NSApplicationBundleIdentifier"]
         isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
      continue;

    if ([appsForURLs objectForKey:[[runningApps objectAtIndex:i] objectForKey:@"NSApplicationPath"]]) {
      NSString *runningBrowserPath = [[runningApps objectAtIndex:i] objectForKey:@"NSApplicationPath"];
      if ([runningBrowserPath isEqualToString:preferredBrowserPath]) {
        usePreferredBrowser = YES;
        break;
      }
      appToLaunch = runningBrowserPath;
    }
  }
  LSLaunchURLSpec urlSpec;
  urlSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObject: url];
  urlSpec.passThruParams = NULL;
  urlSpec.launchFlags = kLSLaunchDefaults;
  urlSpec.asyncRefCon = NULL;
  if (!usePreferredBrowser && appToLaunch) {
    urlSpec.appURL = (CFURLRef) [goodApps objectAtIndex:[[appsForURLs objectForKey:appToLaunch] intValue] - 1];
  }
  else {
    urlSpec.appURL = (CFURLRef) [NSURL fileURLWithPath:preferredBrowserPath];
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
  NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
  [appleEventManager setEventHandler:[self class] andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                       forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Force two run loops to handle events before becoming foreground
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  [self performSelector:@selector(becomeFrontAndDisplayWindow) withObject:nil afterDelay:0];
}

-(void)becomeFrontAndDisplayWindow {
  NSLog(@"Becoming front");
  ProcessSerialNumber psn;
  GetCurrentProcess(&psn);
  OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
  if (returnCode != 0) {
    NSLog(@"Unable to become foreground application, terminating");
    [[NSApplication sharedApplication] terminate:self];
  }
  
  SetFrontProcess(&psn);
  [[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle mainBundle] bundlePath]];
  [NSMenu setMenuBarVisible:YES];
  
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
  [chooserWindow makeKeyAndOrderFront:self];
}

-(IBAction)browserChooserUsed:(id)sender {
  NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
  [sharedDefaults setObject:[[browserChooser selectedItem] representedObject] forKey:@"DefaultBrowser"];
  [sharedDefaults setObject:[[browserChooser selectedItem] title] forKey:@"DefaultBrowserName"];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app{
  return YES;
}


@end
