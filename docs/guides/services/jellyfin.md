# Movies & TV (Jellyfin)

**Address:** <https://jellyfin.f9.casa>

**Works:** anywhere, at home or away.

Jellyfin is our own streaming service. It plays the films and TV shows stored on the server, on any device.

## Watching

1. Open the site and press the **Login with Home** button under the sign-in box. Confirm with your passkey. (On a TV or phone app, use [Quick Connect](#signing-in-on-the-apps) instead.)
2. Pick a library such as **Movies** or **Shows**.
3. Choose something and press play.

Jellyfin remembers where you stopped, so you can carry on from another device.

## Which app should I use?

The website works anywhere, but a dedicated app is nicer on a TV or phone. When an app asks for a server, enter `https://jellyfin.f9.casa`.

### Signing in on the apps

The apps can't open the F9 sign-in page, so they use **Quick Connect**:

1. In the app, choose **Quick Connect** on the sign-in screen. It shows a short code.
2. On the Jellyfin website, where you are already signed in, open the menu in the top corner, choose **Quick Connect** and type the code in.
3. The app signs in. The code only lasts a few minutes.

There is no password to type. See [Your account](../getting-started/your-account.md) for more.

!!! tip "A password, if an app needs one"
    Your Jellyfin account also has a password, the same one as your file server password. If a device can't use Quick Connect, sign in with your name and that password. You can set it at [reset.f9.casa](https://reset.f9.casa).

### Android TV, Google TV and Fire TV: Wholphin (recommended)

[Wholphin](https://github.com/damontecres/Wholphin) is a modern, fast TV app with a much nicer interface than the official Jellyfin TV app. It works well with a remote and has good subtitle and audio options.

<p class="store-badges">
<a href="https://play.google.com/store/apps/details?id=com.github.damontecres.wholphin"><img src="../../assets/badges/google-play.png" alt="Get it on Google Play"></a>
</p>

**Fire TV:** Wholphin is in the Amazon Appstore. You can also install it from the [GitHub releases](https://github.com/damontecres/Wholphin/releases).

!!! note
    The Amazon Appstore version of Wholphin can't show Seerr requests. Use the GitHub version if you want that.

### iPhone, iPad and Apple TV: Swiftfin

[Swiftfin](https://github.com/jellyfin/Swiftfin) is the Jellyfin app for iOS and Apple TV.

<p class="store-badges">
<a href="https://apps.apple.com/app/id1604098728"><img src="../../assets/badges/app-store.svg" alt="Download on the App Store"></a>
</p>

### Phones (Android and iPhone): Streamyfin

[Streamyfin](https://github.com/streamyfin/streamyfin) is a polished phone app with downloads for offline watching and built-in Seerr requests.

<p class="store-badges">
<a href="https://apps.apple.com/app/id6593660679"><img src="../../assets/badges/app-store.svg" alt="Download on the App Store"></a>
<a href="https://play.google.com/store/apps/details?id=com.fredrikburmester.streamyfin"><img src="../../assets/badges/google-play.png" alt="Get it on Google Play"></a>
</p>

### Anything else

Smart TVs and other devices can use the official Jellyfin app from their app store, or just open the website in a browser.

## Can't find something?

Request it with [Seerr](seerr.md). It usually appears within a few hours.

## Tips

- Use **Continue Watching** on the home screen to resume.
- Tap the speech-bubble icon during playback to change subtitles or language.
- If playback stutters on Wi-Fi, try lowering the quality (gear icon, **Quality**).
