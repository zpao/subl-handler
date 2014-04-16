#import "App.h"

#import "NSURL+L0URLParsing.h"

@implementation App

NSString *defaultPath = @"/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl";

-(void)awakeFromNib {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    path = [d objectForKey:@"path"];
    
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

-(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    if (nil == path) path = defaultPath;
    
    // txmt://open/?url=file://~/.bash_profile&line=11&column=2
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    
    if (url && [[url host] isEqualToString:@"open"]) {
        NSDictionary *params = [url dictionaryByDecodingQueryString];
        NSString* url  = [params objectForKey:@"url"];
        if (url) {
            NSString *file = [url stringByReplacingOccurrencesOfString:@"file://" withString: @""];
            // TODO: support more than just www, maybe hook into limebox projects?
            NSString *limebox = [url stringByReplacingOccurrencesOfString:@"limebox://tfb/trunk/www/" withString: @""];
            NSString *arg = nil;
            NSArray *args = nil;

            if ([file length] != [url length]) {
                NSString *line = [params objectForKey:@"line"];
                if (line) {
                    arg = [NSString stringWithFormat:@"%@:%@", file, line];
                } else {
                    arg = [NSString stringWithFormat:@"%@", file];
                }
                args = [NSArray arrayWithObject:arg];
            } else {
                // TODO: support line numbers
                arg = [NSString stringWithFormat:@"box_open_filepath_directly {\"path\": \"%@\"}", limebox];
                args = [NSArray arrayWithObjects:@"--command", arg, nil];
            }
            
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:path];
            [task setArguments:args];
            [task launch];
            [task release];
            NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
            NSString *appPath = [sharedWorkspace fullPathForApplication:@"Sublime Text"];
            NSString *identifier = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
            NSArray *selectedApps =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];
            NSRunningApplication *runningApplcation = (NSRunningApplication*)[selectedApps objectAtIndex:0];
            [runningApplcation activateWithOptions: NSApplicationActivateAllWindows];
            [runningApplcation setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
        }
    }
    
    //    if (![prefPanel isVisible]) {
    //        [NSApp terminate:self];
    //    }
}

-(IBAction)showPrefPanel:(id)sender {
    // TODO: just have a radio, Sublime Text 2 vs Sublime Text 3, then we can build path from there.
    // Or maybe File browser to select the right Sublime app bundle.
    if (path) {
        [textField setStringValue:path];
    } else {
        [textField setStringValue:defaultPath];
    }
    [prefPanel makeKeyAndOrderFront:nil];
}

-(IBAction)applyChange:(id)sender {
    path = [textField stringValue];
    
    if (path) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setObject:path forKey:@"path"];
    }
    
    [prefPanel orderOut:nil];
}

@end
