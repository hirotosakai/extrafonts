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

#import "PreferencePaneBase.h"

@interface JpGrFanSakaiCaminoPreferenceExtraFonts : PreferencePaneBase 
{
  IBOutlet NSTabView*     mTabView;

  // colors tab stuff
  IBOutlet NSColorWell*   mTextColorWell;
  IBOutlet NSColorWell*   mBackgroundColorWell;
  IBOutlet NSColorWell*   mVisitedLinksColorWell;  
  IBOutlet NSColorWell*   mUnvisitedLinksColorWell;

  IBOutlet NSButton*      mUnderlineLinksCheckbox;
  IBOutlet NSButton*      mUseMyColorsCheckbox;

  // fonts tab stuff
  IBOutlet NSPopUpButton* mFontRegionPopup;

  IBOutlet NSMatrix*      mDefaultFontMatrix;

  IBOutlet NSTextField*   mSerifFontTextField;
  IBOutlet NSTextField*   mSansSerifFontTextField;

  IBOutlet NSTextField*   mVariableFontSizeTextField;
  IBOutlet NSTextField*   mFixedFontSizeTextField;
  IBOutlet NSTextField*   mMinimumFontSizeTextField;

  // advanced panel stuff
  IBOutlet NSPanel*       mAdvancedFontsDialog;
  IBOutlet NSTextField*   mAdvancedFontsLabel;

  IBOutlet NSButton*      mAdvancedOKButton;
  IBOutlet NSButton*      mAdvancedCancelButton;
  IBOutlet NSButton*      mSerifFontButton;
  IBOutlet NSButton*      mSansSerifFontButton;
  IBOutlet NSButton*      mCursiveFontButton;
  IBOutlet NSButton*      mFantasyFontButton;
  IBOutlet NSButton*      mMonospaceFontButton;

  // encoding tab stuff
  IBOutlet NSPopUpButton* mDefaultEncodingPopup;
  IBOutlet NSPopUpButton* mEncodingDetectorPopup;

  NSDictionary*           mCharsets;
  NSArray*                mCharsetDetectorTable;
  NSArray*                mRegionMappingTable;
  NSButton*               lastClicked;
}

// Colors tab
- (IBAction)buttonClicked:(id)sender; 
- (IBAction)colorChanged:(id)sender;
- (IBAction)resetColorsToDefaults:(id)sender;

// Fonts tab
- (IBAction)fontRegionPopupClicked:(id)sender;
- (IBAction)defaultFontMatrixChanged:(id)sender;
- (IBAction)fontSizeChanged:(id)sender;
- (IBAction)resetFontsToDefaults:(id)sender;

// Advanced panel
- (IBAction)fontSelectButtonClicked:(id)sender;
- (IBAction)showAdvancedFontsDialog:(id)sender;
- (IBAction)advancedFontsDone:(id)sender;

// Encoding tab
- (IBAction)defaultEncodingClicked:(id)sender;
- (IBAction)encodingDetectorChanged:(id)sender;
- (IBAction)resetEncodingsToDefaults:(id)sender;

@end
