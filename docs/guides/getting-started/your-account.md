# Your account

Almost every site uses the **F9 login**: one account, created by Scott, that works on all of them. It has **no password**. You sign in with a **passkey** instead.

## What's a passkey?

A passkey replaces your password. It lives on your phone, laptop or password manager and unlocks with the same fingerprint, face or PIN you already use to open the device.

- There is nothing to remember and nothing to type.
- It can't be guessed, and it can't be tricked out of you by a fake website.
- Each passkey only works on the device (or password manager) that holds it, so set one up on more than one.

## Set up your first passkey

1. Scott sends you a **one-time link**. It stops working after an hour, so open it soon.
2. On the page, choose to add a passkey and confirm with your fingerprint, face or PIN.
3. Add a **second passkey** on another device, or in your password manager, so you are never locked out if you lose one. Open <https://id.f9.casa>, go to your account settings and add another.

## Signing in

1. Open the site you want. If it needs you to sign in, you are sent to the F9 sign-in page.
2. Confirm with your passkey.
3. You are sent straight back to the site.

You stay signed in for a while, so you won't be asked every time. If a site asks again after a long gap, that is normal.

## Quick Connect (TV apps, phone apps and Seerr)

Some apps can't show a sign-in page: the Jellyfin apps on your TV and phone ([Wholphin](../services/jellyfin.md), Swiftfin, Streamyfin and the official app) and [Seerr](../services/seerr.md). They use **Quick Connect** instead. It lets a device where you are already signed in approve the new one.

1. In the app (or on Seerr's sign-in page), choose **Quick Connect**. It shows a short code.
2. On a device where you are already signed in to Jellyfin (the website is fine), open the menu in the top corner, choose **Quick Connect** and type the code in.
3. The app signs you in. The code only lasts a few minutes, so do this straight away.

You only need to do this once for each app on each device.

## The file server has its own password

Your network folder on the house file server (TrueNAS, see [Your files](../services/files.md)) is **separate**. It has its own username and its own password. It is not connected to the F9 login:

- A passkey does not work there.
- Changing your F9 login never changes the file server password.
- To set or reset the file server password, use [Reset Password](https://reset.f9.casa) (see [Your files](../services/files.md#set-or-reset-your-password)). It sets the same password for your Jellyfin and Seerr accounts too.

## Lost your phone or passkey?

If you added a second passkey, use that. If not, ask Scott for a new one-time link and set up a fresh passkey.

## Add a shortcut to your phone

=== "iPhone"
    Open the site in Safari, tap **Share**, then **Add to Home Screen**.

=== "Android"
    Open the site in Chrome, tap the **three dots**, then **Add to Home screen** (or **Install app**).

## Why can't I open something?

Access depends on the group your account is in. Day-to-day sites such as photos, documents, the smart home and AI chat are open to everyone in the house. Some admin tools, such as the download managers, are only for Scott. If you get an "access denied" page for something you need, ask.
