# Check Your Danish

A spelling game for English speakers practising Danish nouns (Blazor WebAssembly, .NET 10).

An English noun is shown with one box per letter of the Danish word, the first letter already
filled in. Type the rest from left to right on the built-in keyboard (or your own), then choose
the gender: **en** or **et**.

- A wrong letter plays a short error sound; keep going until it's right.
- `?` reveals the next letter, which you then still have to type.
- A word spelled and gendered without any mistakes counts as **correct** and plays a success
  sound. A wrong letter, a wrong gender or using `?` counts it as **missed**.
- The score, accuracy and streak are kept in the browser; ↺ resets them.

Keyboard shortcuts: letters (Æ, Ø, Å included), `?` for a hint, `1`/`2` for en/et, and `Enter`
to start or go to the next word.

## The word list

The nouns live in `CheckYourDanish/wwwroot/danish_nouns.json`:

```json
[
  { "danish": "mand", "gender": "en", "english": ["man", "husband"] },
  { "danish": "barn", "gender": "et", "english": ["child"] }
]
```

| Field     | Meaning |
|-----------|---------|
| `danish`  | The Danish word. Letters A–Z, Æ, Ø and Å are typed; É is typed as E, and other characters (like the hyphen in `t-shirt`) are filled in automatically. |
| `gender`  | `en` or `et`. Entries with anything else are skipped. |
| `english` | One or more translations. The first is shown as the prompt, the rest as "also: …". |

Words come in random order, and every word is shown once before any repeats.

## Run

```bash
dotnet run --project CheckYourDanish
```

The app then runs at http://localhost:5147.

## Icons

The app icon (iOS home screen, Windows/Android install via the web app manifest, and the browser
favicon) is drawn by a script into `CheckYourDanish/wwwroot/icons` and `wwwroot/favicon.ico`:

```powershell
powershell -File tools\make-icons.ps1
```

## Version

`Directory.Build.props` sets the version: Major.Minor by hand, and the patch is the GitHub Actions
run number (0 for local builds). The footer shows the version, build time and git commit.

## Deploy to FTP

`.github/workflows/deploy.yml` publishes and uploads to FTP on every push to `main` (or manually
from the Actions tab). It uses these repository secrets:

| Secret         | Example |
|----------------|---------|
| `FTP_HOST`     | `ftp.example.com` |
| `FTP_USERNAME` | |
| `FTP_PASSWORD` | |
| `FTP_FOLDER`   | `webroots/www/danish` (no trailing `/`) |

The page uses a relative `<base href="./">`, so it works in any folder.
