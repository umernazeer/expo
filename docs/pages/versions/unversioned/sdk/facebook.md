---
title: Facebook
---

Provides Facebook integration for Expo apps. Expo exposes a minimal native API since you can access Facebook's [Graph API](https://developers.facebook.com/docs/graph-api) directly through HTTP (using [fetch](https://facebook.github.io/react-native/docs/network.html#fetch), for example).

## Installation

For [managed](../../introduction/managed-vs-bare/#managed-workflow) apps, you'll need to run `expo install expo-facebook`. To use it in a [bare](../../introduction/managed-vs-bare/#bare-workflow) React Native app, follow its [installation instructions](https://github.com/expo/expo/tree/master/packages/expo-facebook).

For ejected (see: [ExpoKit](../../expokit/overview)) apps, here are links to the [iOS Installation Walkthrough](https://developers.facebook.com/docs/ios/getting-started/) and the [Android Installation Walkthrough](https://developers.facebook.com/docs/android/getting-started).

> **Note**: Not compatible with web.

## Configuration

### Registering your app with Facebook

Follow [Facebook's developer documentation](https://developers.facebook.com/docs/apps/register) to register an application with Facebook's API and get an application ID. Take note of this application ID because it will be used as the `appId` option in your [`Facebook.logInWithReadPermissionsAsync`](#expofacebookloginwithreadpermissionsasync 'Facebook.logInWithReadPermissionsAsync') call. Then follow these steps based on the platforms you're targetting. This will need to be done from the [Facebook developer site](https://developers.facebook.com/):

- **The Expo client app**

  - Add `host.exp.Exponent` as an iOS _Bundle ID_. Add `rRW++LUjmZZ+58EbN5DVhGAnkX4=` as an Android _key hash_. Your app's settings should end up including the following under "Settings > Basic":

![](/static/images/facebook-app-settings.png)

- **iOS standalone app**

  - Add your app's Bundle ID as a _Bundle ID_ in app's settings page pictured above.
  - In your [app.json](../../workflow/configuration/), add a field `facebookScheme` with your Facebook login redirect URL scheme found [here](https://developers.facebook.com/docs/facebook-login/ios) under _4. Configure Your info.plist_. It should look like `"fb123456"`.
  - Also in your [app.json](../../workflow/configuration/), add your [Facebook App ID and Facebook Display Name](https://developers.facebook.com/docs/facebook-login/ios) under the `facebookAppId` and `facebookDisplayName` keys.

- **Android standalone app**

  - [Build your standalone app](../../distribution/building-standalone-apps/#building-standalone-apps) for Android.
  - Run `expo fetch:android:hashes`.
  - Copy `Facebook Key Hash` and paste it as an additional key hash in your Facebook developer page pictured above.

You may have to switch the app from 'development mode' to 'public mode' on the Facebook developer page before other users can log in.

## API

```js
import * as Facebook from 'expo-facebook';
```

### `Facebook.initializeAsync(appId: string | undefined, appName: string | undefined): Promise<void>`

Calling this method ensures that the SDK is initialized. You have to call this method before calling `logInWithReadPermissionsAsync` to ensure that Facebook support is initialized properly.

The Facebook SDK requires your Facebook application ID. [Facebook's developer documentation](https://developers.facebook.com/docs/apps/register) describes how to get one. This method accepts `appId: string` as an optional argument.
- If you don't provide the Facebook application ID explicitly, Facebook SDK will try to read it from the native app binary (e.g., from `Info.plist` on iOS and `AndroidManifest.xml` on Android). In the **managed workflow**, you can define your Facebook application ID via the `facebookAppId` field in `app.json` and it will be embedded in standalone apps. During development in the Expo client, the `expo-facebook` module will read your application ID from `app.json` since it is not possible to modify the Expo client's binary. In the **bare workflow**, follow Facebook's setup documentation for [iOS](https://developers.facebook.com/docs/facebook-login/ios#4--configure-your-project) and [Android](https://developers.facebook.com/docs/facebook-login/android#manifest)).
- If you specify the `appId` argument, it will override any other source.
- If this method fails to find an application ID, the returned promise will be rejected.

The same resolution mechanism works for your Facebook application name. You can pass in the `appName` argument, define `facebookDisplayName` in `app.json`, or modify your native configuration files directly depending on the workflow you are using.

### `Facebook.setAutoInitEnabledAsync(enabled: boolean): Promise<void>`

Sets whether the Facebook SDK should autoinitialize itself. SDK initialization involves eg. fetching app settings from Facebook or a profile of the logged in user. In some cases, you may want to disable or delay the SDK initialization, such as to obtain user consent or fulfill legal obligations. This corresponds to [this iOS SDK method](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#disable-sdk-initialization) and [this Android SDK method](https://developers.facebook.com/docs/app-events/getting-started-app-events-android/#disable-sdk-initialization). Even though calling this method with `enabled == true` initializes the Facebook SDK on iOS, it does not on Android and we recommend always calling `initializeAsync` before performing any actions with effects that should be visible to the user (like `loginWithPermissions`).

In Expo, autoinitialization of the Facebook SDK is disabled by default. You may change this value at runtime by calling this method, or customize this feature at buildtime by setting the appropriate `app.json` fields. The set value persists across runs, and the value set with this method overriddes the value set in `app.json`.

### `Facebook.setAutoLogAppEventsEnabledAsync(enabled: boolean): Promise<void>`

Sets whether Facebook SDK should log app events. App events involve e.g. app installs and launches (more info [here](https://developers.facebook.com/docs/app-events/getting-started-app-events-android/#auto-events) and [here](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#auto-events)). In some cases, you may want to disable or delay the collection of automatically logged events, such as to obtain user consent or fulfill legal obligations. This method corresponds to [this](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#disable-auto-events) and [this](https://developers.facebook.com/docs/app-events/getting-started-app-events-android/#disable-auto-events) native SDK methods.

In Expo, automatic logging of app events is disabled by default. You may change this at runtime by calling this method, or customize this feature at buildtime by setting the appropriate `app.json` fields. The set value persists across runs, and the value set with this method overriddes the value set in `app.json`.

### `Facebook.setAdvertiserIDCollectionEnabledAsync(enabled: boolean): Promise<void>`

Sets whether the Facebook SDK should collect and attach `advertiser-id` to sent events. `advertiser-id` lets you identify and target specific customers. To learn more visit [Facebook's documentation](https://developers.facebook.com/docs/app-ads/targeting/mobile-advertiser-ids) describing this topic. In some cases, you may want to disable or delay the collection of `advertiser-id`, such as to obtain user consent or fulfill legal obligations. This method corresponds to [this iOS SDK method](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#disable-advertiser-id) and [this Android SDK method](https://developers.facebook.com/docs/app-events/getting-started-app-events-android/#disable-advertiser-id).

In Expo, collecting those IDs is disabled by default. You may change this at runtime by calling this method, or customize this feature at buildtime by setting the appropriate `app.json` fields. The set value persists across runs, and the value set with this method overriddes the value set in `app.json`.

### `Facebook.logInWithReadPermissionsAsync(options)`

Prompts the user to log into Facebook and grants your app permission
to access their Facebook data.

#### param object options

A map of options:

- **permissions (_array_)** -- An array specifying the permissions to ask for from Facebook for this login. The permissions are strings as specified in the [Facebook API documentation](https://developers.facebook.com/docs/facebook-login/permissions). The default permissions are `['public_profile', 'email']`.

#### Returns

If the user or Facebook cancelled the login, returns `{ type: 'cancel' }`.

Otherwise, returns `{ type: 'success', token, expires, permissions, declinedPermissions }`. `token` is a string giving the access token to use with Facebook HTTP API requests. `expires` is the time at which this token will expire, as seconds since epoch. You can save the access token using, say, `AsyncStorage`, and use it till the expiration time. `permissions` is a list of all the approved permissions, whereas `declinedPermissions` is a list of the permissions that the user has rejected.

#### Example

```javascript
async function logIn() {
  try {
    await Facebook.initializeAsync('<APP_ID>');
    const {
      type,
      token,
      expires,
      permissions,
      declinedPermissions,
    } = await Facebook.logInWithReadPermissionsAsync({
      permissions: ['public_profile'],
    });
    if (type === 'success') {
      // Get the user's name using Facebook's Graph API
      const response = await fetch(`https://graph.facebook.com/me?access_token=${token}`);
      Alert.alert('Logged in!', `Hi ${(await response.json()).name}!`);
    } else {
      // type === 'cancel'
    }
  } catch ({ message }) {
    alert(`Facebook Login Error: ${message}`);
  }
}
```

Given a valid Facebook application ID in place of `<APP_ID>`, the code above will prompt the user to log into Facebook then display the user's name. This uses React Native's [fetch](https://facebook.github.io/react-native/docs/network.html#fetch) to query Facebook's [Graph API](https://developers.facebook.com/docs/graph-api).
