# Setting up your Mac for the app

Building an iPhone app needs Apple's free Xcode, which only runs on a Mac, so the app is built in a Claude Code session running on your Mac. This is your part, in three steps. Nothing here pays for or registers anything with Apple.

Checked against Apple's and Anthropic's pages on October 23, 2026.

## 1. Check your Mac and install Xcode

1. **Check your Mac.** Click the Apple menu () at the top left › **About This Mac**.
   - **Chip** should say **Apple M1** or later (M2, M3, M4…). If it says **Processor … Intel**, stop here and tell Claude: the current Xcode doesn't run on Intel Macs.
   - **macOS** should say **Tahoe 26.6** or later. If it's older: Apple menu › **System Settings** › **General** › **Software Update**, install the update, then come back.
   - **Free space:** in the same window, **More Info…** › **Storage**. You need about **30 GB** free (Xcode is about 3 GB to download, the iPhone Simulator 8–10 GB, and both unpack bigger).
2. **Install Xcode.** Open the **App Store** app, search for **Xcode** (by Apple), click **Get**, then **Install**. It's free; the App Store may ask for your Apple Account password, as for any free app. The download takes a while.
3. **Open Xcode once.** Open it from Applications. Agree to the license if it asks, and enter your Mac's password if it asks to install extra parts.
4. **Install the iPhone Simulator.** When Xcode asks which platforms to download, tick **iOS** and click **Download**. If it doesn't ask: in the menu bar, **Xcode** › **Settings…** › **Components**, and click **Get** next to iOS. Wait until it finishes. Then you can quit Xcode; Claude runs it from now on.

## 2. Run Claude Code on your Mac

The session you had in the Claude app ran in the cloud, which can't reach Xcode. This one runs on your Mac.

**In the Claude desktop app** (simplest):

1. Make sure it's up to date: in the menu bar, **Claude** › **Check for Updates…** (the newest version also shows the iPhone Simulator inside the app).
2. Click the **Code** tab at the top of the sidebar.
3. In the row under the message box, click the first control (where the session runs) and choose the top entry under **Local**.
4. Click the folder control beside it › **Open folder…** and pick the app's folder.
5. To answer fewer "may I run this?" questions, pick **Auto** in the mode selector.

**Or in Terminal:** press ⌘ Space, type **Terminal**, press Enter, and paste `curl -fsSL https://claude.ai/install.sh | bash`. Open a new Terminal window, then type `cd ` (with a space), drag the app's folder onto the window, press Enter, then type `claude` and log in when asked.

**From your iPhone:** in that session type `/remote-control`. The session then shows in the Claude app on your iPhone under **Code** (a computer icon with a green dot), so you can follow it and answer from your phone while it runs on the Mac. The Mac has to stay on.

**What to type first:**

> Continue the SOS Closet iOS app. The repo is samosherman-byte/sos-closet-ios33: clone it into this folder if it isn't here. Read CLAUDE.md and APP-SPEC.md, then start at "Where we are › Next".

(If the repo isn't on GitHub yet, save the files Claude sent you into the folder first, and leave out the second sentence.)

## 3. Put the app on your iPhone (once phase 1 runs)

Claude walks you through this when it's time and asks first. What it involves, so it isn't a surprise:

1. Plug the iPhone into the Mac with a cable and tap **Trust This Computer** on the phone.
2. On the iPhone: **Settings** › **Privacy & Security** › **Developer Mode** › on, then **Restart**, and after the restart tap **Enable** and enter your passcode. (The switch only shows up after the phone has been connected to the Mac.)
3. In Xcode: **Xcode** › **Settings…** › **Apple Accounts** › sign in with your usual Apple Account. It shows as "(Personal Team)". It's free and doesn't join anything.
4. Claude builds the app onto your phone under a test ID, `com.soscloset.app.dev`, so the real ID, `com.soscloset.app`, stays free for the App Store later.
5. The first time, the iPhone may ask you to trust the developer: **Settings** › **General** › **VPN & Device Management** › your Apple Account › **Trust**.

With a free account the app stops opening after 7 days; Claude reinstalls it from the Mac in a minute. TestFlight (sharing it with others) and the App Store need Apple's paid Developer Program, which Claude will never sign up for without asking you.
