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
 
#import "ExtraFonts.h"
#import "MVCarbonFontPanelController.h"
#import "PreferencePaneBaseAdditions.h"

@interface JpGrFanSakaiCaminoPreferenceExtraFonts(Private)

- (void)setupColorTab;
- (void)setupFontTab;
- (void)setupEncodingTab;
- (NSString*)regionCodeForCurrentRegion;
- (void)setupFontRegionPopup;
- (NSString*)getRegionToSelect;
- (void)selectEncodingPopup;
- (void)setupChardetPopup;
- (void)updateFontTabForRegion;
- (void)saveFontSettings;

@end

@implementation JpGrFanSakaiCaminoPreferenceExtraFonts

// tag of mDefaultFontMatrix
const int kDefaultFontSerifTag = 0;
const int kDefaultFontSansSerifTag = 1;

- (void)dealloc
{
  [mRegionMappingTable release];
  [mCharsetDetectorTable release];
  [mCharsets release];
  [super dealloc];
}

- (id)initWithBundle:(NSBundle *)bundle
{
  self = [super initWithBundle:bundle];
  return self;
}

- (void)mainViewDidLoad
{
  NSBundle* prefBundle = [NSBundle bundleForClass:[self class]];

  mRegionMappingTable = [[NSArray arrayWithContentsOfFile:[prefBundle pathForResource:@"RegionMapping" ofType:@"plist"]] retain];
  mCharsetDetectorTable = [[NSArray arrayWithContentsOfFile:[prefBundle pathForResource:@"CharsetDetector" ofType:@"plist"]] retain];
  mCharsets = [[NSDictionary dictionaryWithContentsOfFile:[NSBundle pathForResource:@"Charset" ofType:@"dict" inDirectory:[[NSBundle mainBundle] bundlePath]]] retain];

  // should save and restore this
  [[NSColorPanel sharedColorPanel] setContinuous:NO];

  [self setupColorTab];
  [self setupFontTab];
  [self setupEncodingTab];
}

- (void)setupColorTab
{
  BOOL gotPref;
  [mUnderlineLinksCheckbox setState:
    [self getBooleanPref:"browser.underline_anchors" withSuccess:&gotPref]];
  [mUseMyColorsCheckbox setState:
    ![self getBooleanPref:"browser.display.use_document_colors" withSuccess:&gotPref]];
  
  [mBackgroundColorWell     setColor:[self getColorPref:"browser.display.background_color"  withSuccess:&gotPref]];
  [mTextColorWell           setColor:[self getColorPref:"browser.display.foreground_color"  withSuccess:&gotPref]];
  [mUnvisitedLinksColorWell setColor:[self getColorPref:"browser.anchor_color"              withSuccess:&gotPref]];
  [mVisitedLinksColorWell   setColor:[self getColorPref:"browser.visited_color"             withSuccess:&gotPref]];
}

- (void)setupFontTab
{
  [self setupFontRegionPopup];
  [self updateFontTabForRegion];
}

- (void)setupEncodingTab
{
  [self selectEncodingPopup];
  [self setupChardetPopup];
}

- (void)setupFontRegionPopup
{
  NSBundle* prefBundle = [NSBundle bundleForClass:[self class]];
  NSString* lang = [self getRegionToSelect];

  [mFontRegionPopup removeAllItems];
  for (unsigned int i = 0; i < [mRegionMappingTable count]; i++) {
    NSDictionary* regionDict = [mRegionMappingTable objectAtIndex:i];
	NSString* region = [regionDict objectForKey:@"code"];
    [mFontRegionPopup addItemWithTitle:NSLocalizedStringFromTableInBundle(region, @"RegionNames", prefBundle, @"")];

    if ([region isEqualToString:lang])
	  [mFontRegionPopup selectItemAtIndex:i];
  }
}

- (NSString*)getRegionToSelect
{
  BOOL gotPref;
  NSString* lang = [self getStringPref:"font.language.group" withSuccess:&gotPref];
  NSString* nsDefault = [self getDefaultStringPref:"font.language.group" withSuccess:&gotPref];
  NSString* myDefault = [self getLocalizedString:@"DefaultRegionCode"];

  // default "font.language.group" is stored in "chrome://global/locale/intl.properties".
  // but L10N Camino don't have localized version of embed.jar, so I stored it in Localizable.strings.

  if (![lang isEqualToString:nsDefault]) // user-defined value found
    return lang;
  else
    return myDefault;
}

- (void)selectEncodingPopup
{
  BOOL gotPref;
  NSString* encoding = [self getStringPref:"intl.charset.default" withSuccess:&gotPref];

  for (int i = 0; i < [mDefaultEncodingPopup numberOfItems]; i++) {
    int tag = [[mDefaultEncodingPopup itemAtIndex:i] tag];
    NSArray* charsetList = [mCharsets allKeysForObject:[NSNumber numberWithInt:tag]];
    if ([charsetList count] == 0)
	  continue;
	if ([[charsetList objectAtIndex:0] caseInsensitiveCompare:encoding] == NSOrderedSame) {
      [mDefaultEncodingPopup selectItemAtIndex:i];
	  break;
	}
  }
}

- (void)setupChardetPopup
{
  NSBundle* prefBundle = [NSBundle bundleForClass:[self class]];
  BOOL gotPref;
  NSString* myChardet = [self getStringPref:"intl.charset.detector" withSuccess:&gotPref];

  [mEncodingDetectorPopup removeAllItems];
  for (unsigned int i = 0; i < [mCharsetDetectorTable count]; i++) {
    NSDictionary* chardetDict = [mCharsetDetectorTable objectAtIndex:i];
	NSString* chardet = [chardetDict objectForKey:@"detector"];
    [mEncodingDetectorPopup addItemWithTitle:NSLocalizedStringFromTableInBundle(chardet, @"CharsetDetectorNames", prefBundle, @"")];

    if ([chardet isEqualToString:myChardet])
	  [mEncodingDetectorPopup selectItemAtIndex:i];
  }
}

- (IBAction)colorChanged:(id)sender
{
  const char* prefName = NULL;
  
  if (sender == mBackgroundColorWell)
    prefName = "browser.display.background_color";
  else if (sender == mTextColorWell)
    prefName = "browser.display.foreground_color";
  else if (sender == mUnvisitedLinksColorWell)
    prefName = "browser.anchor_color";
  else if (sender == mVisitedLinksColorWell)
    prefName = "browser.visited_color";

  if (prefName)
    [self setPref:prefName toColor:[sender color]];
}

- (IBAction)buttonClicked:(id)sender
{
  if (sender == mUnderlineLinksCheckbox)
    [self setPref:"browser.underline_anchors" toBoolean:[sender state]];
  else if (sender == mUseMyColorsCheckbox)
    [self setPref:"browser.display.use_document_colors" toBoolean:![sender state]];
}

- (IBAction)resetColorsToDefaults:(id)sender
{
  [self clearPref:"browser.underline_anchors"];
  [self clearPref:"browser.display.use_document_colors"];
  [self clearPref:"browser.display.background_color"];
  [self clearPref:"browser.display.foreground_color"];
  [self clearPref:"browser.anchor_color"];
  [self clearPref:"browser.visited_color"];

  // update the UI of the Appearance pane
  [self setupColorTab];
}

// Return current selected region code (ex. "en")
- (NSString*)regionCodeForCurrentRegion
{
  int index = [mFontRegionPopup indexOfSelectedItem];
  NSDictionary* regionDict = [mRegionMappingTable objectAtIndex:index];

  return [regionDict objectForKey:@"code"];
}

- (IBAction)fontRegionPopupClicked:(id)sender
{
  [self updateFontTabForRegion];
  [self setPref:"font.language.group" toString:[self regionCodeForCurrentRegion]];
}

- (void)updateFontTabForRegion
{
  BOOL gotPref = NO;
  NSString *region = [self regionCodeForCurrentRegion];
  NSString *key, *sValue;
  int iValue;

  key = [NSString stringWithFormat:@"font.default.%@", region];
  sValue = [self getStringPref:[key cString] withSuccess:&gotPref];
  if ([sValue isEqualToString:@"sans-serif"]) {
    [mDefaultFontMatrix selectCellWithTag:kDefaultFontSansSerifTag];
  } else {
    [mDefaultFontMatrix selectCellWithTag:kDefaultFontSerifTag];
  }

  key = [NSString stringWithFormat:@"font.name.serif.%@", region];
  sValue = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mSerifFontTextField setStringValue:sValue];
  key = [NSString stringWithFormat:@"font.name.sans-serif.%@", region];
  sValue = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mSansSerifFontTextField setStringValue:sValue];

  key = [NSString stringWithFormat:@"font.size.variable.%@", region];
  iValue = [self getIntPref:[key cString] withSuccess:&gotPref];
  if (iValue > 0)
    [mVariableFontSizeTextField setIntValue:iValue];
  else
    [mVariableFontSizeTextField setStringValue:@""];
  key = [NSString stringWithFormat:@"font.size.fixed.%@", region];
  iValue = [self getIntPref:[key cString] withSuccess:&gotPref];
  if (iValue > 0)
    [mFixedFontSizeTextField setIntValue:iValue];
  else
    [mFixedFontSizeTextField setStringValue:@""];
  key = [NSString stringWithFormat:@"font.minimum-size.%@", region];
  iValue = [self getIntPref:[key cString] withSuccess:&gotPref];
  if (iValue > 0)
    [mMinimumFontSizeTextField setIntValue:iValue];
  else
    [mMinimumFontSizeTextField setStringValue:@""];
}

- (IBAction)defaultFontMatrixChanged:(id)sender
{
  NSString *key;

  key = [NSString stringWithFormat:@"font.default.%@", [self regionCodeForCurrentRegion]];

  if ([sender selectedTag] == kDefaultFontSerifTag) {
    [self setPref:[key cString] toString:@"serif"];
  } else if ([sender selectedTag] == kDefaultFontSansSerifTag) {
    [self setPref:[key cString] toString:@"sans-serif"];
  }
}

- (IBAction)fontSizeChanged:(id)sender
{
  NSString *key;
  int value = [sender intValue];
  NSString *region = [self regionCodeForCurrentRegion];

  if (sender == mVariableFontSizeTextField) {
    key = [NSString stringWithFormat:@"font.size.variable.%@", region];
  } else if (sender == mFixedFontSizeTextField) {
    key = [NSString stringWithFormat:@"font.size.fixed.%@", region];
  } else if (sender == mMinimumFontSizeTextField) {
    key = [NSString stringWithFormat:@"font.minimum-size.%@", region];
  } else {
    return;
  }

  if (value > 0) {
    [self setPref:[key cString] toInt:value];
  } else {
    [self clearPref:[key cString]];
  }
}

- (IBAction)resetFontsToDefaults:(id)sender
{
  for (unsigned int i=0; i<[mRegionMappingTable count]; i++) {
    NSString *region = [[mRegionMappingTable objectAtIndex:i] objectForKey:@"code"];

    [self clearPref:[[NSString stringWithFormat:@"font.name.serif.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.name.sans-serif.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.name.cursive.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.name.fantasy.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.name.monospace.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.default.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.size.variable.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.size.fixed.%@", region] cString]];
    [self clearPref:[[NSString stringWithFormat:@"font.minimum-size.%@", region] cString]];
  }

  // Update the UI of the Appearance pane
  [self updateFontTabForRegion];
}

- (IBAction)showAdvancedFontsDialog:(id)sender
{
  NSString* advancedLabel = [NSString stringWithFormat:[self getLocalizedString:@"AdditionalFontsLabelFormat"], [mFontRegionPopup titleOfSelectedItem]];
  [mAdvancedFontsLabel setStringValue:advancedLabel];

  NSString *region = [self regionCodeForCurrentRegion];
  NSString *key, *value;
  BOOL gotPref = NO;
  key = [NSString stringWithFormat:@"font.name.serif.%@", region];
  value = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mSerifFontButton setTitle:value];
  key = [NSString stringWithFormat:@"font.name.sans-serif.%@", region];
  value = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mSansSerifFontButton setTitle:value];
  key = [NSString stringWithFormat:@"font.name.cursive.%@", region];
  value = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mCursiveFontButton setTitle:value];
  key = [NSString stringWithFormat:@"font.name.fantasy.%@", region];
  value = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mFantasyFontButton setTitle:value];
  key = [NSString stringWithFormat:@"font.name.monospace.%@", region];
  value = [self getStringPref:[key cString] withSuccess:&gotPref];
  [mMonospaceFontButton setTitle:value];
  
  [mSerifFontButton setState:NSOffState];
  [mSansSerifFontButton setState:NSOffState];
  [mCursiveFontButton setState:NSOffState];
  [mFantasyFontButton setState:NSOffState];
  [mMonospaceFontButton setState:NSOffState];

  [NSApp beginSheet:mAdvancedFontsDialog
      modalForWindow:[mTabView window] // any old window accessor
	   modalDelegate:self
	  didEndSelector:@selector(advancedFontsSheetDidEnd:returnCode:contextInfo:)
	     contextInfo:NULL];

  [[NSNotificationCenter defaultCenter] addObserver:self
      selector:@selector(fontSelected:)
          name:@"MVCarbonFontnameSelected"
        object:nil];
}

- (void)advancedFontsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
  if (returnCode != YES)
    return;

  // update font name of main window
  [self saveFontSettings];
  [self updateFontTabForRegion];
}

- (IBAction)advancedFontsDone:(id)sender
{
  // close fontpanel (if opened)
  [[MVCarbonFontPanelController sharedInstance] close];
  [[NSNotificationCenter defaultCenter] removeObserver:self
      name:@"MVCarbonFontnameSelected"
    object:nil];

  [mAdvancedFontsDialog orderOut:self];
  if ([sender isEqual:mAdvancedOKButton]) {
    [NSApp endSheet:mAdvancedFontsDialog returnCode:YES];
  } else {
    [NSApp endSheet:mAdvancedFontsDialog returnCode:NO];
  }
}

- (void)saveFontSettings
{
  NSString *key;
  NSString *region = [self regionCodeForCurrentRegion];

  key = [NSString stringWithFormat:@"font.name.serif.%@", region];
  [self setPref:[key cString] toString:[mSerifFontButton title]];
  key = [NSString stringWithFormat:@"font.name.sans-serif.%@", region];
  [self setPref:[key cString] toString:[mSansSerifFontButton title]];
  key = [NSString stringWithFormat:@"font.name.cursive.%@", region];
  [self setPref:[key cString] toString:[mCursiveFontButton title]];
  key = [NSString stringWithFormat:@"font.name.fantasy.%@", region];
  [self setPref:[key cString] toString:[mFantasyFontButton title]];
  key = [NSString stringWithFormat:@"font.name.monospace.%@", region];
  [self setPref:[key cString] toString:[mMonospaceFontButton title]];
}

- (IBAction)fontSelectButtonClicked:(id)sender
{
  lastClicked = sender;
  
  // activate or deactivate state of buttons
  NSArray *buttons = [NSArray arrayWithObjects:mSerifFontButton, mSansSerifFontButton, mCursiveFontButton, mFantasyFontButton, mMonospaceFontButton, nil];
  for (unsigned int i=0; i<[buttons count]; i++) {
    NSButton *button = [buttons objectAtIndex:i];
    if ([sender isEqualTo:button]) {
      [button setState:NSOnState];
    } else {
      [button setState:NSOffState];
    }
  }

  MVCarbonFontPanelController *fontPanel = [MVCarbonFontPanelController sharedInstance];
  [fontPanel showPanel:sender];
  [fontPanel setSelectedFontname:[sender title]];
}

- (void)fontSelected:(NSNotification *)notification
{
  // set selected fontname to clicked button
  [lastClicked setTitle:[notification object]];
}

- (IBAction)defaultEncodingClicked:(id)sender
{
  NSArray* charsetList = [mCharsets allKeysForObject:[NSNumber numberWithInt:[sender selectedTag]]];
  [self setPref:"intl.charset.default" toString:[charsetList objectAtIndex:0]];
}

- (IBAction)encodingDetectorChanged:(id)sender
{
  int index = [mEncodingDetectorPopup indexOfSelectedItem];
  NSDictionary* chardetDict = [mCharsetDetectorTable objectAtIndex:index];
  NSString* chardet = [chardetDict objectForKey:@"detector"];

  if ([chardet isEqualToString:@"_off_"])
    [self clearPref:"intl.charset.detector"];
  else
    [self setPref:"intl.charset.detector" toString:chardet];
}

- (IBAction)resetEncodingsToDefaults:(id)sender
{
  [self clearPref:"intl.charset.default"];
  [self clearPref:"intl.charset.detector"];

  [self setupEncodingTab];
}

@end

