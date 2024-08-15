/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Camino code.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 2002
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */
 
#import "MVCarbonFontPanelController.h"
#import <Carbon/Carbon.h>

static MVCarbonFontPanelController *gSharedInstance = nil;

int sortByEncoding(NSDictionary *a, NSDictionary *b, void *context)
{
  NSComparisonResult ret;
  NSNumber *enc = [a objectForKey:@"encoding"];
  NSString *name = [a objectForKey:@"fontname"];

  ret = [enc compare:[b objectForKey:@"encoding"]];
  if (ret == NSOrderedSame) {
    ret = [name compare:[b objectForKey:@"fontname"]];
  }

  return ret;
}

@interface MVCarbonFontPanelController (Private)
- (id)initWithWindowNib;
- (NSArray *)carbonFontnames;
- (void)filterFonts;
@end

@implementation MVCarbonFontPanelController

+ (MVCarbonFontPanelController *)sharedInstance
{
  if (!gSharedInstance) {
    gSharedInstance = [[MVCarbonFontPanelController allocWithZone:NULL] initWithWindowNib];
  }

  return gSharedInstance;
}

- (id)initWithWindowNib
{
  self = [super initWithWindowNibName:@"CarbonFontPanel"];
  if (self) {
    mFontnamesBase = [[NSArray arrayWithArray:[self carbonFontnames]] retain];
    mFontnames = [[NSMutableArray arrayWithArray:mFontnamesBase] retain];
    mLastFontnameForSort = [[NSString stringWithString:@""] retain];
    mLastEncodingForSort = [[NSNumber numberWithInt:0] retain];
  }
  return self;
}

- (void)dealloc
{
  [mLastEncodingForSort release];
  mLastEncodingForSort = nil;
  [mLastFontnameForSort release];
  mLastFontnameForSort = nil;
  [mFontnames release];
  mFontnames = nil;
  [mFontnamesBase release];
  mFontnamesBase = nil;

  [super dealloc];
}

- (void)windowDidLoad
{
  [self setWindowFrameAutosaveName:@"CarbonFontPanel"];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  if (!mFontnames) return 0;
  return [mFontnames count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  id identifier = [aTableColumn identifier];

  if ([identifier isEqualToString:@"font"]) {
    return [mFontnames objectAtIndex:rowIndex];
  }
  
  return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  int rowIndex = [mFontTableView selectedRow];

  if (rowIndex >= 0) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MVCarbonFontnameSelected"
                                                        object:[self selectedFontname]];
  }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
  if ([textView isEqual:mFilterTextField])
    return NO;

  if (command == @selector(insertNewline:)) { // "return" key was typed
    [self filterFonts];
    return YES;
  }

  return NO;
}

- (void)showPanel:(id)sender
{
  [self showAllClicked:sender];
  [self showWindow:sender];
}

- (void)filterFonts
{
  NSString *filter = [mFilterTextField stringValue];
  NSMutableArray *newFontnames;

  if ([filter length] == 0) {
    newFontnames = [NSMutableArray arrayWithArray:mFontnamesBase];
  } else {
    newFontnames = [NSMutableArray array];
    for (unsigned int i=0; i<[mFontnamesBase count]; i++) {
      NSString *name = [mFontnamesBase objectAtIndex:i];
      NSRange result = [name rangeOfString:filter options:NSCaseInsensitiveSearch];
      if (result.location == NSNotFound && result.length == 0) // not matched
        continue;
      [newFontnames addObject:name];
    }
  }

  // replace mFontnames
  id oldFonts = mFontnames;
  [oldFonts release];
  oldFonts = nil;
  mFontnames = [newFontnames retain];

  [mFontTableView reloadData];
}

- (IBAction)showAllClicked:(id)sender
{
  [mFilterTextField setStringValue:@""];
  [self filterFonts];
}

- (void)setSelectedFontname:(NSString *)fontname
{
  [mFontTableView deselectAll:self];
  [mFontTableView scrollRowToVisible:0];

  for (unsigned int i=0; i<[mFontnames count]; i++) {
    if ([[mFontnames objectAtIndex:i] isEqualToString:fontname]) {
      [mFontTableView selectRow:i byExtendingSelection:NO];
      [mFontTableView scrollRowToVisible:i];
      return;
    }
  }
}

- (NSArray *)carbonFontnames
{
  // we should enumerate QuickDraw fontname while Gecko use QuickDraw API
  // reference is "nsDeviceContextMac :: InitFontInfoList() at mozilla/gfx/src/mac/nsDeviceContextMac.cpp"
  // patch of #2137027 uses ATS instead of FM APIs
  // Enumerating fonts with ATS (ADC Technical QA1471)
  // http://developer.apple.com/qa/qa2006/qa1471.html
  OSStatus err;
  ATSFontFamilyIterator iter = NULL;
  err = ::ATSFontFamilyIteratorCreate(kATSFontContextLocal,
        NULL, NULL, // filter and its refcon
        kATSOptionFlagsUnRestrictedScope, // QA1471
        &iter);
  if (err != noErr)
    return [NSMutableArray array];

  // enumerate all fonts.
  NSMutableArray *tmpArray = [NSMutableArray array];
  ATSFontFamilyRef fontFamily = 0;
  while (::ATSFontFamilyIteratorNext(iter, &fontFamily) == noErr) {
    // we'd like to use ATSFontFamilyGetName here, but it's ignorant of the
    // font encodings, resulting in garbage names for non-western fonts.
    Str255 fontName;
    err = ::ATSFontFamilyGetQuickDrawName(fontFamily, fontName);
    if (err != noErr || fontName[0] == 0 || fontName[1] == '.' || fontName[1] == '%')
      continue;
    TextEncoding fontEncoding;
    fontEncoding = ::ATSFontFamilyGetEncoding(fontFamily);
    CFStringRef strRef;
    strRef = CFStringCreateWithPascalString(kCFAllocatorDefault, fontName, fontEncoding);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          (NSString *)strRef, @"fontname",
                          [NSNumber numberWithInt:fontEncoding], @"encoding", nil];
    [tmpArray addObject:dict];
    CFRelease(strRef);
  }
  err = ::ATSFontFamilyIteratorRelease(&iter);

  // sort by encoding > fontname
  NSArray *sortedArray = [tmpArray sortedArrayUsingFunction:sortByEncoding context:nil];
  NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[sortedArray count]];
  for (unsigned int i=0; i<[sortedArray count]; i++) {
    [outArray addObject:[[sortedArray objectAtIndex:i] objectForKey:@"fontname"]];
  }
  return [outArray copy];
}

- (NSString *)selectedFontname
{
  int rowIndex = [mFontTableView selectedRow];

  if (rowIndex >= 0) {
    return [mFontnames objectAtIndex:rowIndex];
  } else {
    return @"";
  }
}

@end
