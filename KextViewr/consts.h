//
//  Consts.h
//  DHS
//
//  Created by Patrick Wardle on 2/4/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#ifndef KK_Consts_h
#define KK_Consts_h

//success
#define STATUS_SUCCESS 0

//keys for signing stuff
#define KEY_SIGNATURE_STATUS @"signatureStatus"
#define KEY_SIGNING_AUTHORITIES @"signingAuthorities"
#define KEY_SIGNING_IS_APPLE @"signedByApple"

//patreon url
#define PATREON_URL @"https://www.patreon.com/bePatron?c=701171"

//product url
#define PRODUCT_URL @"https://objective-see.org/products/kextviewr.html"

//OS version x
#define OS_MAJOR_VERSION_X 10

//OS minor version lion
#define OS_MINOR_VERSION_LION 8

//OS minor version mavericks
#define OS_MINOR_VERSION_MAVERICKS 9

//OS minor version yosemite
#define OS_MINOR_VERSION_YOSEMITE 10

//OS minor version el capitan
#define OS_MINOR_VERSION_EL_CAPITAN 11

//path to kmutil
#define KM_UTIL @"/usr/bin/kmutil"

//hash key, SHA1
#define KEY_HASH_SHA1 @"sha1"

//hash key, MD5
#define KEY_HASH_MD5 @"md5"

//refresh button
#define REFRESH_BUTTON_TAG 10001

//logo button
#define SAVE_BUTTON_TAG 10003

//logo button
#define LOGO_BUTTON_TAG 10004

//id (tag) for detailed text in category table
#define TABLE_ROW_NAME_TAG 100

//id (tag) for detailed text in category table
#define TABLE_ROW_SUB_TEXT_TAG 101

//id (tag) for signed icon
#define TABLE_ROW_SIGNATURE_ICON 100

//id (tag) for path
#define TABLE_ROW_PATH_LABEL 101

//id (tag) for plist
#define TABLE_ROW_PID_LABEL 102

//id (tag) for 'virus total' button
#define TABLE_ROW_VT_BUTTON 103

//id (tag) for 'info' button
#define TABLE_ROW_INFO_BUTTON 105

//id (tag) for 'show' button
#define TABLE_ROW_SHOW_BUTTON 107

//scanner option key
// ->filter apple signed/known items
#define KEY_SCANNER_FILTER @"filterItems"

//name key
#define KEY_RESULT_NAME @"name"

//path key
#define KEY_RESULT_PATH @"path"

//extension id key
#define KEY_EXTENSION_ID @"id"

/* VIRUS TOTAL */

//query url
#define VT_QUERY_URL @"https://www.virustotal.com/partners/sysinternals/file-reports?apikey="

//requery url
#define VT_REQUERY_URL @"https://www.virustotal.com/vtapi/v2/file/report"

//rescan url
#define VT_RESCAN_URL @"https://www.virustotal.com/vtapi/v2/file/rescan"

//submit url
#define VT_SUBMIT_URL @"https://www.virustotal.com/vtapi/v2/file/scan"

//api key
#define VT_API_KEY @"233f22e200ca5822bd91103043ccac138b910db79f29af5616a9afe8b6f215ad"

//user agent
#define VT_USER_AGENT @"VirusTotal"

//query count
#define VT_MAX_QUERY_COUNT 25

//results
#define VT_RESULTS @"data"

//results response code
#define VT_RESULTS_RESPONSE @"response_code"

//result url
#define VT_RESULTS_URL @"permalink"

//result hash
#define VT_RESULT_HASH @"hash"

//results positives
#define VT_RESULTS_POSITIVES @"positives"

//results total
#define VT_RESULTS_TOTAL @"total"

//results scan id
#define VT_RESULTS_SCANID @"scan_id"

//button state off
#define STATE_OFF 0x0

//button state on
#define STATE_ON 0x1

//hotkey 's'
#define KEYCODE_S 0x1

//hotkey 'f'
#define KEYCODE_F 0x3

//hotkey 'w'
#define KEYCODE_W 0xD

//hotkey 'r'
#define KEYCODE_R 0xF


#endif
