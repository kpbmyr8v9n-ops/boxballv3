#!/usr/bin/env bash
# Run once after `npx cap add ios` (on a Mac). Locks iPhone to portrait and hides the status bar.
set -e
PL=ios/App/App/Info.plist
B=/usr/libexec/PlistBuddy
$B -c "Delete :UISupportedInterfaceOrientations" "$PL" 2>/dev/null || true
$B -c "Add :UISupportedInterfaceOrientations array" -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" "$PL"
$B -c "Add :UIStatusBarHidden bool true" "$PL" 2>/dev/null || true
$B -c "Add :UIViewControllerBasedStatusBarAppearance bool false" "$PL" 2>/dev/null || true
$B -c "Add :ITSAppUsesNonExemptEncryption bool false" "$PL" 2>/dev/null || true
echo "iOS patched (portrait, status bar hidden, export-compliance flag)."
