# Progress

What has been built, the decisions behind it, and what comes next.
Stack, architecture, conventions and commands are in [`CLAUDE.md`](../CLAUDE.md).

**How to update:** keep **Next up** current, editing it in place. Append a new dated entry to the
**Log** at the end of each work session; don't rewrite old entries. Record rejected approaches
as well, so they aren't proposed again.

## Next up

- [ ] **Product detail page.** Product cards aren't tappable yet.
- [ ] **Cart.** Cart state, add-to-cart, and a badge on the cart tab. The cart page is a placeholder.
- [ ] **Profile.** Login, orders and addresses. Today the page only has the theme settings.
- [ ] **Backend.** Replace the in-memory `ProductRepository` / `PromoRepository` with API calls.
- [ ] **Images.** Persistent image caching, decoding at display size and precaching the first images.
      This would remove the small stutter on the very first scroll of Home.
- [ ] **Search.** Matching is only on name and category label, so "birra" doesn't find "Fusto IPA".
      Consider synonyms or tags.
- [ ] **Branding before release.**
  - Android app label is still `beverfood_mobile` and `applicationId` is `com.example.beverfood_mobile`.
  - Launcher icons (Android/iOS) and the web manifest icons (`Icon-192/512`) are still Flutter defaults.
- [ ] **Open asset questions.**
  - `logo.png` has transparent lettering, so the letters take the page color (dark in dark mode).
    Ask for a white-lettering variant if the letters should always be white.
  - `assets/images/placeholders/no_image.png` isn't bundled because it's a light image.
    Decide whether to use it (it would need a dark variant).

## Log

### 2026-10-29

**Done**
- Built the main UI from the user's references (`dashboard_example.jpg` and the `ui_structure.png` sketch):
  - **Home**
    - Search bar at the top.
    - Promo carousel: a `PageView` with `viewportFraction` 0.88, so the next banner peeks in, plus page dots.
    - "Novità" horizontal carousel.
    - "Più popolari" 2-column grid with working category chips.
  - **Bottom navigation:** Home, Prodotti, Carrello, Profilo.
  - **Prodotti:** search plus category chips. Carrello and Profilo are placeholders.
- Feature-based folder structure (`app/`, `core/`, `features/<name>/{data,models,presentation}`), following the
  user's `directory_structure.png`.
- Refined the product card over several rounds:
  - Removed the category/size line.
  - Made the images square.
  - Name on one line with the price right under it, styled after `product_example.jpg`:
    extra-bold 19 pt amount and a smaller "€", e.g. `12,90€`.
- Smaller corner radii (`AppRadii`), matching `dashboard_example_light/dark.jpg`.
- Dark mode for the whole app (`AppPalette` ThemeExtension):
  - Profile has "Segui impostazione del dispositivo" and "Modalità scura" switches,
    styled after `dark_mode_toogle.jpg`.
  - The choice is saved with `shared_preferences`.

**Decisions**
- **Domain:** food & beverages, to fit the Beverfood name. All UI copy is in Italian.
- **Grid:** 2 columns, like the example screenshot (the sketch showed 3).
- **Images:** loaded from Unsplash URLs, not bundled, picking photos without prominent brand logos.
  INTERNET permission was added to the main Android manifest.
- **Routing:** `go_router` with `StatefulShellRoute.indexedStack`, so each tab keeps its state.
- **State:** no state-management package. Mock repositories, and a `ChangeNotifier` only for the theme mode.
- **Colors:** brand bordeaux `#7B1E3A`. A lighter `#C94471` is used as primary in dark mode,
  because the bordeaux was unreadable on near-black.

### 2026-10-30

**Done**
- **Logo:** `logo.png` sits left of the Home search bar (48 pt, transparent background), and the profile avatar
  was removed.
- **Assets:** moved the contents of `img/` into the proper places:
  - `assets/images/branding/logo.png` (declared in pubspec).
  - `assets/images/placeholders/no_image.png` (not bundled).
  - Web favicons into `web/`, and `index.html` now points to the new apple-touch icon.
- **Header:** the Home header and the "Prodotti" title bar both scroll away. `SafeArea` keeps the status bar
  clear, and `AppShell` sets the status-bar icon brightness from the theme.
- **Spacing:** the promo banners moved lower; the gap from the search bar grew from about 20 to 36 pt.
- **Scroll performance:** measured with the performance overlay after removing the frosted header (see below).
  Once images are cached, Home and Prodotti have the same frame times.
- **Docs:** created `CLAUDE.md` and this file. Rewrote `README.md` with just the commands to run the app.
- **Profilo:** removed the "Accesso, ordini…" subtitle under "Area personale" and the description under
  "Segui impostazione del dispositivo". The setting rows are now just a title and a switch.

**Decisions / rejected approaches** (the user asked to revert each of these; don't propose them again)
- A colored background band behind the header and promos, fading out before "Novità".
  The user wants **one consistent background** across the app.
- A white tile behind the logo, which kept its lettering white. The user wants the logo as-is.
- A frosted, blurred, pinned header with a progressive-blur bottom edge.
  - The user wants the **original solid header that scrolls away**.
  - It was also the cause of Home's scroll jank: about 11 `BackdropFilter` layers redrawn every frame.
    Avoid stacked backdrop blurs on scrolling screens.

**Notes**
- During emulator testing the saved theme switched back to light twice between runs.
  Checked on device: the setting survives both a force-stop and a `flutter run` reinstall, and the stored value
  always matched what was shown. No code bug found.
