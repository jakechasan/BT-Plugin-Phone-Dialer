The Phone Dialer plugin allows the developer to customize how the native phone application is launched. Either an AlertView Action Sheet is presented prompting the user to place the phone call. After the phone call, the developer can configure the device to return to their app, or to the phone app. For best results, use the "fade" transition when loading this plugin.

Version History:
v1.0-Initial Release of Plugin
v1.1-Compatibility with BT4.0 and iOS 10

iOS Project
------------------------
-JC_PhoneDialer.h
-JC_PhoneDialer.m

Android Project
------------------------
This plugin is not compatible with Android.

JSON Data
------------------------
{
 "itemId": "11223344",
 "itemType": "JC_PhoneDialer",
 "itemNickname": "Place Call",
 "callType": "advanced",
 "alertOrActionSheet": "alert",
 "promptTitle": "Title",
 "promptMessage": "Message",
 "callButtonTitle": "Call",
 "cancelButtonTitle": "Cancel"
}