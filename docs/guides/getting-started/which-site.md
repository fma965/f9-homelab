# Which site do I use?

Every service has its own address. All of them are also on the home page at <https://f9.casa>.

The **Works** column says where each one opens: **Anywhere** means at home or away, on any Wi-Fi or mobile data. **Home only** means only when you are connected to the house network.

| Service | Address | What it's for | Works | Sign in with |
| --- | --- | --- | --- | --- |
| Home page | <https://f9.casa> | Buttons for everything | Anywhere | F9 login |
| Jellyfin | <https://jellyfin.f9.casa> | Films and TV | Anywhere | F9 login |
| Seerr | <https://requests.f9.casa> | Request films and shows ("Requesting media") | Anywhere | Quick Connect (via Jellyfin) |
| Music Assistant | <https://music.f9.casa> | Music on the speakers | Anywhere | F9 login (via Home Assistant) |
| Games Manager | <https://games.f9.casa> | Compare games and find what you can play together | Anywhere | F9 login |
| Immich | <https://photos.f9.casa> | Photos and videos | Anywhere | F9 login |
| Zipline | <https://i.f9.casa> | Share files and images by link | Anywhere | F9 login |
| Paperless | <https://docs.f9.casa> | Scanned documents | Anywhere | F9 login |
| Home Assistant | <https://home.f9.casa> | Smart home | Anywhere | F9 login |
| Cameras (Frigate) | <https://cctv.f9.casa> | Live view and recorded clips | Anywhere | F9 login |
| Homebox | <https://inventory.f9.casa> | What we own and where it is | Home only | F9 login |
| Bambuddy | <https://bambuddy.f9.casa> | 3D printer control | Anywhere | F9 login |
| Open WebUI | <https://ai.f9.casa> | AI chat | Anywhere | F9 login |
| SABnzbd | <https://sabnzbd.f9.casa> | Usenet downloads (limited access) | Home only | F9 login |
| qBittorrent | <https://torrents.f9.casa> | Torrent downloads (limited access) | Home only | F9 login |
| Debt Manager | <https://debtmanager.f9.casa> | Money owed and payments | Anywhere | Discord |
| Your files | `smb://nas.main.internal/Home` | Your personal network folder | Home only | Its own password (see below) |
| Stream overlays | <https://overlays.f9.casa> | OBS overlays | Anywhere | None |
| Status page | <https://status.f9.casa> | Is everything up? | Anywhere | None |

!!! info "Home only sites"
    Cameras, Homebox, SABnzbd and qBittorrent only open when you are on the house Wi-Fi or plugged in at home. On mobile data or someone else's Wi-Fi they simply won't load, and that is on purpose. Away from home you can still see the cameras in the Home Assistant app. For anything else, ask Scott.

!!! note "F9 login"
    The **F9 login** is your one account, signed in with a passkey (no password). Jellyfin, Immich, Music Assistant, Home Assistant and the rest all use it, so there are no separate accounts to set up. See [Your account](your-account.md) for how passkeys work.

!!! info "Quick Connect"
    TV and phone apps, and Seerr, can't show a sign-in page. They sign in with **Quick Connect**: the app shows a code and you approve it from a device where you are already signed in. See [Your account](your-account.md#quick-connect-tv-apps-phone-apps-and-seerr).

!!! warning "The file server is separate"
    Your network folder (the house file server, TrueNAS) has **its own username and password**. It is not linked to the F9 login, and passkeys don't work there. You can set or reset it yourself at [reset.f9.casa](https://reset.f9.casa). See [Your files](../services/files.md#set-or-reset-your-password).
