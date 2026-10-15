# Your files (home folder)

**Address:** `\\nas.main.internal\Home` on Windows, or `smb://nas.main.internal/Home` on Mac, Linux and phones

**Works:** at home only, on the house Wi-Fi or plugged in at home.

Each of us has a personal folder on the house server, shown as a **network drive** on your computer. The folders are named after us: **scott**, **andrew** and **ash**. Keep anything you care about in yours: documents, projects, things you would hate to lose.

Your folder is yours. Everyone's folder name shows in the list, but you can only open your own.

## Open your folder

=== "Windows"
    1. Open **File Explorer**.
    2. Click the address bar, type `\\nas.main.internal\Home` and press Enter.
    3. Sign in when asked, then open the folder with your name.

    To keep it as a drive, right-click **This PC**, choose **Map network drive** and use the same address.

=== "Mac"
    1. In **Finder**, choose **Go**, then **Connect to Server** (or press ⌘K).
    2. Enter `smb://nas.main.internal/Home` and click **Connect**.
    3. Sign in when asked, then open the folder with your name.

=== "Linux"
    1. In your file manager, choose **Other Locations**.
    2. Under **Connect to Server**, enter `smb://nas.main.internal/Home`.
    3. Sign in when asked, then open the folder with your name.

=== "iPhone / iPad"
    1. Open the **Files** app, tap the **three dots**, then **Connect to Server**.
    2. Enter `smb://nas.main.internal/Home` and tap **Connect**.
    3. Sign in when asked, then open the folder with your name.

=== "Android"
    Android's built-in Files app can't connect to network drives. Use a file manager app that supports **network storage (SMB)**, and add the server `nas.main.internal` with the share name `Home`.

## Signing in

Use your own name (the same as your folder) and your own server password. This is **not** the house login used on the websites, so it has its own password. If you don't have one or you've forgotten it, ask Scott.

## Backups

Everything in the home folders is **backed up every night to Backblaze**, a cloud storage company, so it survives even if the server is lost.

- **Encrypted before it leaves the house.** The contents of your files are scrambled before they are uploaded, so Backblaze can't read them. The *names* of files and folders are not hidden.
- **It is a mirror, not a history.** The copy follows what is in the folder, so something you delete will disappear from the cloud copy the next night. If you delete something by accident, tell Scott as soon as you notice. The server also keeps weekly snapshots for a few weeks that may be able to bring it back.
- **Photos have their own backup.** See [Photos (Immich)](immich.md#backups).

## Please remember

- Only the house network can reach these folders, so they won't open on mobile data or someone else's Wi-Fi.
- This is a good home for important files. Files kept only on your own computer are not covered by these backups.
