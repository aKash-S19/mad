# Libora - Personal Digital Reading Ecosystem

> **Discover → Read → Interact → Save → Remember**

Libora is a personal digital reading ecosystem built in Flutter. Instead of being just another PDF/EPUB reader, Libora combines a **personal library, Kindle-like reading experience, book discovery, highlights, notes, quotes, reading statistics, collections, global search, and Letterboxd-style book ratings and reviews** into a unified, distraction-free application.

---

## Key Features

### 1. Personal Library (Bookshelf)
- **Local File Import**: Import PDF and EPUB files directly from device storage.
- **URL Import**: Add supported books through URLs.
- **Automatic Metadata Extraction**: Reads titles, authors, page counts, chapters, and generates beautiful cover cards.
- **Reading Statuses**: Mark books as *Currently Reading*, *Want to Read*, *Completed*, or *Favorite*.
- **Organization**: Custom shelves/collections, search, filter, and sort (Title, Author, Date, Progress).
- **View Modes**: Switch between Grid and List views.
- **Progress Tracking**: Automatically remembers the exact reading location and page.

### 2. Kindle-Like Reader
- **Dual Reading Engine**: Immersive Syncfusion PDF viewer and reflowable EPUB renderer.
- **Immersive Mode**: Clean, distraction-free interface with controls that autohide during reading and reveal on tap.
- **Customizable Appearance**:
  - Themes: *Light*, *Sepia*, *Dark*, and *AMOLED Black*.
  - Typography: Font size slider, font family (*Serif*, *Sans*, *Mono*), line height, margins, and text alignment.
- **Navigation**: Table of Contents, page slider, bookmarks, and in-book search.

### 3. Text Selection & Interaction (Core Differentiator)
When selecting text inside any document:
- **Highlight**: Color picker (Yellow, Green, Blue, Pink, Orange) with persistent highlight storage.
- **Note**: Attach personal thoughts and annotations to exact passages. Tap any note later to jump directly to that page in the reader.
- **Quote**: Save passages to your personal quote collection.
- **Copy & Share**: Copy to clipboard or share via native system sheet.

### 4. Letterboxd for Books
- **Ratings & Reviews**: Rate books (1 to 5 stars) and write personal reviews.
- **Reading Diary**: Chronological history of completed reads.
- **Social Profile**: Username, reading streak (e.g. 5-day streak 🔥), reading goal progress (e.g. 12 books/year).
- **Reading Buddies**: Connect with friends by username.
- **Share Profile**: Letterboxd-style profile summary card to share with friends.

### 5. Quote Card Generator
- Turn any saved quote into a shareable card.
- Modern visual styling with author, book title, page, and `READ ON LIBORA` branding.
- Multiple card themes: *Midnight Navy*, *Vintage Sepia*, *Crimson Passion*, and *Minimalist Ivory*.
- One-tap sharing via native Android sharing sheet.

### 6. Free Book Discovery (Browse & Offline Reading)
- Discover thousands of free, public-domain books from **Project Gutenberg (Gutendex API)** and **Open Library**.
- Popular categories: *Philosophy*, *Classic Literature*, *Science Fiction*, *History*, *Psychology*, *Poetry*, *Adventure*.
- Real-time download progress indicator.
- Automatically imports downloaded books into your personal offline library with a direct **Read Now** action.

### 7. Global Search
Unified search across:
- Books
- Authors
- Highlights
- Quotes
- Notes
- Collections

Tapping any highlight, quote, or note immediately opens the reader at that exact page location.

### 8. 100% Local-First Offline Architecture
- Built on SQLite (`sqflite`) for lightning-fast, persistent offline access.
- Reading, importing, highlighting, note-taking, and stats work **completely offline** without requiring an account.
- Optional Firebase Auth and Cloud Firestore synchronization for cloud backup and social features.

---

## Remote GitHub Actions APK Build

Because Flutter is not installed locally on your laptop, the repository includes an automated GitHub Actions CI/CD workflow (`.github/workflows/build_apk.yml`).

### How to Build & Download the APK

1. **Push to GitHub**:
   ```bash
   git remote add origin <YOUR_GITHUB_REPO_URL>
   git branch -M main
   git push -u origin main
   ```

2. **Automated Build**:
   - Go to your repository on GitHub.
   - Click the **Actions** tab.
   - The workflow `Build Libora Android APK` will trigger automatically on push. You can also trigger it manually by clicking **Run workflow**.

3. **Download APK**:
   - Once the build succeeds, click on the workflow run.
   - Under the **Artifacts** section at the bottom, click **`libora-debug-apk`** to download `app-debug.apk`.
   - Transfer or open the `.apk` file on your Android device to install and test!

---

## Project Structure

```text
lib/
├── app.dart                       # Main app shell & bottom navigation
├── main.dart                      # App entry point & provider setup
├── core/
│   ├── constants/                 # App constants & defaults
│   ├── router/app_router.dart     # Route generation & deep-linking
│   ├── theme/                     # AppTheme and ReaderTheme
│   └── utils/                     # Formatters, file utils, validators
├── data/
│   ├── database/database_helper.dart # SQLite database & CRUD operations
│   └── models/                    # Book, Highlight, Note, Quote, Review, etc.
├── features/
│   ├── auth/                      # Login & Signup screens
│   ├── book_details/              # Book Details & Review screen
│   ├── browse/                    # Free books discovery screen
│   ├── collections/               # Custom shelves & shelf details
│   ├── download_manager/          # Active downloads screen
│   ├── highlights/                # Highlights archive screen
│   ├── home/                      # Home screen (Continue reading hero)
│   ├── library/                   # Bookshelf (grid/list, filters, import)
│   ├── notes/                     # Personal notes archive
│   ├── profile/                   # Social profile, stats, friends
│   ├── quotes/                    # Quotes archive & Quote Card generator
│   ├── reader/                    # Kindle-like PDF/EPUB reader
│   ├── search/                    # Global search screen
│   ├── settings/                  # Appearance & storage settings
│   ├── splash/                    # Animated splash screen
│   └── statistics/                # Reading analytics screen
├── providers/                     # ChangeNotifier state providers
└── services/                      # EPUB parser, import, downloads, quote card
```
