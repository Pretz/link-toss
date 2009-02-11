//
//  main.m
//  Link Toss
//
//  Created by Alex Pretzlav on 12/28/07.
//  Copyright Alex Pretzlav 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
  NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
  [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                       forEventClass:kInternetEventClass andEventID:kAEGetURL];
  return NSApplicationMain(argc,  (const char **) argv);
}

/** Heee I aint gonna free nuthin' cuz tha app just quits after handlin' a URL.  HA! HA!
 */
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
  if ([event numberOfItems] == 0) {
    NSLog(@"Failed to get URL");
    [[NSApplication sharedApplication] terminate:self];
    return;
  }
  NSString * appToLaunch = nil;
  NSMutableDictionary * appsForURLs = [NSMutableDictionary dictionary];
  NSString *urlString = [[event descriptorAtIndex:1] stringValue];
  if (! urlString) {
    NSLog(@"Can't seem to get target URL");
    [[NSApplication sharedApplication] terminate:self];
    return;
  }
  /* Actual target URL */
  NSURL * urlToOpen = [NSURL URLWithString: urlString];
  /* Apps that can open URLs */
  NSArray * goodApps = [self appsThatOpen: urlToOpen];
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
  urlSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObject: urlToOpen];
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
