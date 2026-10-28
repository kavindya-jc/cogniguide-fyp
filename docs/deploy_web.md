# The web version of CogniGuide (for iPhones and any browser)

An iPhone cannot install an APK. The web version is the same app as a website: it opens in
**Safari** (or any browser) and talks to the same Cloud Run server, with the same accounts and the same tutor agent.

```
iPhone Safari  →  the website (free host)  →  Cloud Run backend  →  Gemini + Supabase
```

**Status:** built and tested in a desktop browser at iPhone size (sign up, buddy, problem list, coach
chat, wrong-answer reply, reload keeps the login). **Not yet tested on a real iPhone.**

## Who does what

| Person | What |
|---|---|
| **App builder** (has Flutter) | Builds the web files (Step 1) and hosts them (Step 2) |
| **Cloud Run deployer** (has `gcloud`) | Allows the website's address on the server (Step 3), once |
| **Everyone with an iPhone** | Opens the link (Step 4) |

## Step 1: Build the web files (app builder)

In the `frontend` folder, one line:
```
$api = "https://cogniguide-backend-1056396913855.asia-south1.run.app"
flutter build web --release "--dart-define=API_BASE_URL=$api"
```
The files are in `frontend\build\web`. (The team pack also has them ready as `CogniGuide-web-build.zip`.)
There must be **no `/` at the end** of the address.

## Step 2: Put the files on a free host

Easiest: **Netlify Drop** (free, no card, no tools to install; check Netlify's current terms when you sign up).

1. Go to **app.netlify.com/drop**, sign up with your email or GitHub.
2. Open the folder `frontend\build\web` in Windows Explorer (or unzip `CogniGuide-web-build.zip`).
3. **Drag the folder** onto the Netlify Drop box.
4. Wait a few seconds. Netlify shows an address like `https://shiny-name-1234.netlify.app`.
   Optional: **Site configuration → Change site name** to something nicer, like `cogniguide`.
5. **Copy the address.** You need it for Step 3.

Other free hosts that also work: Firebase Hosting (same Google account as Cloud Run), Cloudflare Pages,
GitHub Pages. The files are plain static files.

## Step 3: Allow the website on the server (Cloud Run deployer, once)

The server currently refuses requests from websites (`CORS_ORIGINS=none`), so the web app would show
"coach is busy" or fail to sign up. Allow **your website's address only**:

```
gcloud run services update cogniguide-backend --region asia-south1 --update-env-vars CORS_ORIGINS=https://YOUR-SITE.netlify.app
```

- Use the exact address from Step 2: `https://`, no `/` at the end, no spaces.
- Only **one** address at a time with this command (commas separate settings in gcloud). If the site
  name changes later, run the command again with the new address.
- The phone APK is not affected: Android apps do not use CORS.

**Check it worked** (any computer, one line; replace the site address):
```
$api = "https://cogniguide-backend-1056396913855.asia-south1.run.app"
curl.exe -s -D - -o NUL -H "Origin: https://YOUR-SITE.netlify.app" "$api/problems"
```
(In PowerShell write `curl.exe`, not `curl`: plain `curl` is a different command there.) You should now see a line `access-control-allow-origin: https://YOUR-SITE.netlify.app`. Before the setting there is none.

## Step 4: Open it on an iPhone

1. Open the website address in **Safari**.
2. Create an account (a made-up username) and test: the checklist in `TEAM_SELF_SETUP.md`, Step 7, or
   the 14-step phone test (Algebra, Problem 1, `x = 2`, `just tell me the answer`, `x = 12`, "I worked it out!").
3. **Make it feel like an app:** Safari **Share** button → **Add to Home Screen** → **Add**. It then opens
   full screen with the Pip icon.

## Updating the website later

Build again (Step 1) and drag the new folder onto the same Netlify site (**Deploys → drag and drop**).
Browsers can keep the old version for a moment: close the page or the home-screen app and open it again.

## Known limits (please read)

- **Safari can forget the login after about 7 days** without a visit (Safari clears website storage). The
  student just logs in again; their progress is safe in Supabase. An app added to the Home Screen is not affected.
- **The web version keeps the login token in the browser's storage**, because a browser has no locked
  storage like a phone's Keystore. It runs out after 30 days and is deleted at log out. Use made-up usernames.
- **Anyone with the website address can open the app** and create an account, like with the APK. The
  coach still needs a login and each student is limited to 20 messages a minute.
- **Not tested on a real iPhone yet.** Things to look for: the blurred "glass" bars, the folding top bar,
  the maths keys, and typing. Send screenshots of anything odd to the team.
- Messages go to Google's Gemini and are stored in Supabase: put that in the consent notice.

## If something goes wrong

| What you see | What to do |
|---|---|
| The site opens, but sign up or the coach says it failed or is busy | Step 3 is missing or the address is wrong (not exactly the website's). Run the `gcloud ... update` command again with the exact address |
| A blank page | Wait a few seconds (first load downloads about 2 MB); then reload. If still blank, send a screenshot |
| Old version after an update | Close the page or home-screen app and reopen; or Safari: Settings → Safari → Clear History and Website Data |
| "Please log in again" after a week | Normal (see limits). Log in again |
| The first message takes about a minute | The server was asleep. Normal after a quiet period |
