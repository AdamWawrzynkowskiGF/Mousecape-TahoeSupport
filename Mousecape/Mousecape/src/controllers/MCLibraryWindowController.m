//
//  MCLbraryWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryWindowController.h"

@interface MCLibraryWindowController ()
- (void)composeAccessory;
@end

@implementation MCLibraryWindowController

- (void)awakeFromNib {
    [self composeAccessory];
}

- (id)initWithWindow:(NSWindow *)window {
    if ((self = [super initWithWindow:window])) {
        
    }
    return self;
}

- (void)windowDidLoad {
    NSLog(@"window load");
    [super windowDidLoad];
    [self composeAccessory];
}

- (NSString *)windowNibName {
    return @"Library";
}

- (void)composeAccessory {
    // If we've already added it, avoid adding twice
    if (self.appliedAccessory.superview != nil) {
        [self.appliedAccessory removeFromSuperview];
    }

    // Make sure the accessory view opts into Auto Layout
    self.appliedAccessory.translatesAutoresizingMaskIntoConstraints = NO;

    NSTitlebarAccessoryViewController *accessoryVC = [[NSTitlebarAccessoryViewController alloc] init];
    accessoryVC.view = self.appliedAccessory;
    accessoryVC.layoutAttribute = NSLayoutAttributeRight; // Pin to the trailing side of the title bar

    // This API handles correct placement relative to the window title & traffic lights
    [self.window addTitlebarAccessoryViewController:accessoryVC];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.libraryViewController.libraryController.undoManager;
}

#pragma mark - Menu Actions

- (IBAction)applyCapeAction:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController.libraryController applyCape:cape];
}

- (IBAction)editCapeAction:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController editCape:cape];
}

- (IBAction)removeCapeAction:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    if (cape != self.libraryViewController.editingCape) {
        [self.libraryViewController.libraryController removeCape:cape];
    } else {
        [[NSSound soundNamed:@"Funk"] play];
        [self.libraryViewController editCape:self.libraryViewController.editingCape];
    }
}

- (IBAction)duplicateCapeAction:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController.libraryController importCape:cape.copy];
}

- (IBAction)checkCapeAction:(NSMenuItem *)sender {
    
}

- (IBAction)showCapeAction:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ cape.fileURL ]];
}

- (IBAction)dumpCapeAction:(NSMenuItem *)sender {
    [self.window beginSheet:self.progressBar.window completionHandler:nil];
    __weak MCLibraryWindowController *weakSelf = self;
    self.progressBar.doubleValue = 0.0;
    [self.progressBar setIndeterminate:NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [weakSelf.libraryViewController.libraryController dumpCursorsWithProgressBlock:^BOOL (NSUInteger current, NSUInteger total) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                weakSelf.progressField.stringValue = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)current, NSLocalizedString(@"of", @"Dump cursor progress separator (eg: 5 of 129)"), (unsigned long)total];
                weakSelf.progressBar.minValue = 0;
                weakSelf.progressBar.maxValue = total;
                weakSelf.progressBar.doubleValue = current;
            });
            return YES;
        }];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf.window endSheet:self.progressBar.window];
            [[NSCursor arrowCursor] set];
        });
    });

}

@end

@implementation MCAppliedCapeValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    return [
            NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape")
            stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Window Titlebar Accessory label for when no cape is applied")];
}

@end
