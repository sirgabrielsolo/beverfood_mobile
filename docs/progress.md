# Progress

What has been built, the decisions behind it, and what comes next.
Stack, architecture, conventions and commands are in [`CLAUDE.md`](../CLAUDE.md).

**How to update:** keep **Start here** and **Next up** current, editing them in place. Append a new dated entry to the
**Log** at the end of each work session; don't rewrite old entries. Record rejected approaches
as well, so they aren't proposed again.

## Start here (next session)

State at the end of 2026-11-03:
- **Built and passing:**
  - **App:** sign-in (A1/B2), profile completion (C2), notices (D1/D2), Profilo (E), promos with banners and the
    detail page, the whole catalogue from the database (Novità, Più popolari, categories, search, sort), and now the
    **cart and orders**: Carrello (K1 + notes N1, saved on the phone), Riepilogo ordine (C2), "Ordine inviato",
    Profilo → I miei ordini and the order page with Riordina (O1). Runs at 90 Hz on the CPH2399.
  - **beverfood_web:** the `/api/v1` API (now with `/orders`), the admin panel (P2), and the managers' two areas:
    Ordini agenti (light) and **Ordini clienti** (dark: the same four order tabs for app orders, plus Clienti).
  - **Tests:** 29 widget + 22 unit tests in the app; the web checks are scratch scripts (see beverfood_web's
    CLAUDE.md, "Checking changes").
- **Not committed yet** (the user handles git): run `git status` first, in both repos.
- **Not tried on the phone yet:** the cart and orders. Test them against the local server, not with plain
  `flutter run` (production has no `/orders` until the user deploys). Locally, run
  `flask --app app ensure-columns` once first, inside the virtualenv (`python app.py` adds missing tables, never
  columns): it adds the new `orders`/`order_item` columns. Render runs it before each deploy.
- **The user planned to set `OTP_SENDER=log` on Render** (codes in Render's logs, so co-workers can register on
  production until an SMS provider exists). Remove it before public launch.
- **Next task:** the user's test of the cart and orders on the phone and in Ordini clienti, then Next up step 4.
- **Local testing:**
  - Start the server: `cd ~/projects/beverfood_web && source .venv/bin/activate && python app.py`. The `flask`
    command also needs the virtualenv active (or `.venv/bin/flask`), else "command not found".
  - Run the app: `flutter run -d <id> --dart-define=API_BASE_URL=http://172.16.25.128:5000` (the PC's LAN IP, which changes with the network; the
    emulator uses `10.0.2.2`). Sign-in codes print in the server terminal.
  - Approve clients at http://127.0.0.1:5000 → Admin Panel → Clienti app; managers see app orders in Ordini clienti.
  - The local `app_*` tables were emptied once by mistake, so local test accounts may need registering again.
- **Production test account:** `+39 300 000 0000` or `admin@beverfoodsrl.it`, code = Render's `APP_TEST_CODE`
  (the user knows it; don't write it into files). Its orders reach the managers like any other: the user deletes them
  by hand (admin's Ordini, bin).

## Next up

In order. "(user)" marks what only the user can do.

1. [ ] **(user) Commit, push, deploy, upload.**
   - Commit and push both repos (beverfood_web: admin panel, Clienti app, `/products/new`).
   - Optionally set `OTP_SENDER=log` on Render.
   - Upload the 14 promo PNGs in `beverfood_ops/assets/png_upload/promo/` to Cloudinary, if not done yet, then open
     Immagini mancanti so the web picks them up.
2. [x] **Catalogue from the API** (done 2026-11-02): Novità, Più popolari, all products and categories. Still open:
       the product-name format (stopgap `splitProductName`), and a check on the phone (Start here).
3. [x] **Cart page and orders from the app** (done 2026-11-03; see the Log). Still open:
   - (user) test on the phone, and in Ordini clienti as a manager.
   - Later, by the user's choice: a transport charge depending on the delivery area (Q2), order emails (F7) and
     status notifications (F8), payments (Q4).
4. [ ] **Approval notice** to the client: a push notification (Firebase) and an email.
5. [ ] **(user) Providers:** SMS (Twilio Verify recommended, WhatsApp later after Meta's business verification), and
       email on `beverfoodsrl.it` (DNS access; Brevo suggested). Then connect them in `client_auth.send_code`. Until
       then only the test account (or `OTP_SENDER=log`) can sign in on production.
6. [ ] **(user) Privacy notice:** fill in Beverfood's details on https://claude.ai/artifact/1B9653a9Ymaz1cbmbktART and
       have it reviewed. It's needed before the stores.
7. [ ] **Product detail page** (cards aren't tappable) and **favourites** (in memory only: persist them, decide where the
       list is).
8. [ ] **Release preparation:**
   - App label and `applicationId` (still `com.example.beverfood_mobile`).
   - Launcher and web icons.
   - Store listings, with the test account as the review account.
   - A phone performance pass.
   - Search synonyms ("birra" doesn't find "Fusto IPA").
   - Open asset questions: the white-tinted Home logo, and `no_image.png` (no dark variant).

**Design pages** (the user's choices are recorded in the Log; rejected options shouldn't come back):
- Cart and orders (K1, N1, C2, O1, M as a copy of Ordini agenti; extras F1–F5): https://claude.ai/artifact/34gcgRRH4mLHMqvC8kdjyb
- Categories and catalogue: https://claude.ai/artifact/HK4w7qZGNx8wWPHYM7jKsd
- Promo banners: https://claude.ai/artifact/VMge2md1CKKvRYTuU5PyLJ
- Promo page and prices: https://claude.ai/artifact/9BYuZ1Gk5yLB5ycY3jzhX3
- App sign-in: https://claude.ai/artifact/J3o7na5R2aKkGkzp8nsSk7
- Admin panel: https://claude.ai/artifact/FFVYxNrYywkXfeBVzTyXpP
- Earlier header and add-to-cart options: https://claude.ai/artifact/Ak4aapAPkCsJw64f171T19

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

### 2026-10-31

**Done**
- New Home and Prodotti UI from the user's handoff (`beverfood-ui-handoff.zip`, kept out of git via `.gitignore`).
  - **Home**
    - Red header: the logo (tinted white, so the cut-out lettering shows the red) and "Beverfood", then the
      search bar. The logo row scrolls away; the search bar stays pinned at the top.
    - Promo cards: 300×124, yellow first then dark, text left and photo right, no page dots.
    - "Novità" and "Più popolari" are now horizontal rails of the new product card ("NUOVO" badge on Novità).
    - Category tiles (image card plus label, one per category) between "Novità" and "Più popolari", under a
      "Categorie" title. A tile opens Prodotti on that category's tab.
  - **Prodotti:** "Prodotti" title with a "Filtra e ordina" button (bottom sheet: Consigliati, Più popolari,
    Prezzo crescente/decrescente, Nome), the search bar, then pinned scrollable category tabs with an underline
    indicator, then a 2-column grid.
  - **Product card** (shared): surface card, square image, heart, two-line name, price, and an add button that
    turns into a −/1/+ stepper. Quantities and favourites are in memory and shared across screens.
  - **Nav bar:** handoff styling (surface background, top hairline, labels always visible, pink indicator),
    keeping the existing icons.
- New tokens from the handoff: brand red `#C8174A` (replaces bordeaux), yellow accent `#FFC93C`, warmer
  greys, and a pink `brandText` for text/icons in dark mode. Nunito Sans is bundled as the app font.
- Built `CartBar` but it isn't shown yet. `CartController` / `FavouritesController` are in memory.
- Tests: category tile opens the tab, cart state shared between Home and Prodotti, sorting, and no overflow at
  360 dp with 1.3× text.
- Fixed: Home category tiles kept their light background after switching to dark mode (the color was read
  through the list builder's context).

**Decisions**
- **Kept from the current app, not taken from the handoff:**
  - The small corner radii (`AppRadii`); the Home header's bottom corners use 10 too.
  - The bottom-nav icons.
  - Search is still a real text field: Home opens Prodotti filtered, and Prodotti filters live. The handoff
    had a button that opens a separate search screen.
- **Home header is red in dark mode too** (the handoff had a dark maroon), so the logo always sits on the same red.
- **No tagline** ("Vini, birre, caffè e altro") under the name.
- **Category tiles are a horizontal list**, not the handoff's 4-column grid, because there are 6 categories.
- **"Vai al carrello" bar:** the design is approved for later and kept as `CartBar`, but it stays hidden until
  the real cart exists.
- **Card buttons work in memory** (user's choice), rather than being hidden or inert until the cart exists.
- The theme change also restyles Carrello and Profilo (colors and font); their page files weren't touched.

### 2026-10-31 (afternoon)

**Done**
- Home: "Più popolari" now comes before "Categorie".
- **Scroll performance**, measured with a new `integration_test/scroll_performance_test.dart` (profile mode on the
  emulator; command in `CLAUDE.md`). Second pass over each page, average raster time:
  - Home: about 15 ms with roughly 255 of 306 frames over budget, down to 3.7–10 ms (0–143 over budget; the emulator
    is noisy).
  - Prodotti: 7.7 ms with 135 over budget, down to about 2.7 ms with 0–2 over budget.
  - Fixes: removed unneeded clips (header, promo cards, card buttons, horizontal lists), faded the logo by color instead
    of `Opacity`, decoded images at display size (square Unsplash crops), and replaced Home's search text field.
- Home's search bar is now a button styled as the field. It opens Prodotti with the search field focused and the
  keyboard up, and results filter as you type. Bisecting showed the real text field in the pinned header alone cost
  about 10 ms of raster per frame.
- Published an options page for the user: dark-mode header and search colors (5 variants with contrast figures) and
  three add-to-cart alternatives with live demos, based on Baymard Institute research.

**Decisions**
- The user handles all git commits and branches; don't commit or create branches.
- Search from Home moved to Prodotti (the handoff's original behavior) for scroll performance.
- The first-scroll cost of image download and decode remains. Experiments showed it disappears without network images.

### 2026-10-31 (evening)

**Done**
- **Dark-mode Home header:** the user picked "Dark header" from the options page
  (https://claude.ai/artifact/Ak4aapAPkCsJw64f171T19). In dark mode the header is `#241E21`, the search field
  `#362D31` with `#ABA1A5` icon and hint, the name `#F7F2F3`, and the logo keeps its own red. Light mode is unchanged
  (red header, white field). New palette tokens: `header`, `onHeader`, `headerLogoTint`, `headerField`, `onHeaderField`.
  The logo now fades through `Image.opacity`, which also works untinted and doesn't add a layer.
- **Add to cart:** the user picked the full-width "Aggiungi". The card now has the price on its own line and a 38 pt
  red bar with a cart icon and "Aggiungi". After the first tap the label slides up and a stepper of the same size slides
  in: bin at quantity 1 (semantics "Rimuovi dal carrello"), minus above 1, the quantity (it briefly grows when it
  changes), plus. Cards are about 28 pt taller; `ProductCard.textHeight` was updated.
- Tests: the cart test covers the bin at quantity 1; the dark-mode test checks the header color; the category tile
  test scrolls further because the taller cards pushed the tile behind the nav bar.
- Scroll performance after the change (6 emulator runs, second pass): typically about 4 ms raster on Home and
  3 ms on Prodotti with 0–3 frames over budget, as before. Some runs were slow on every frame (emulator noise).

**Decisions**
- Rejected alternatives on the options page (not to propose again unless asked): "Tonal red", "White field" and
  "Handoff original" headers; "+" on the photo corner; filled "+" that stretches into the stepper; the old outlined "+".
- The add bar's slide animation clips only while it runs, so cards at rest have no clip while scrolling.

### 2026-11-01

**Done**
- Tested on the user's phone (CPH2399, Dimensity 1200, 90 Hz display, so about 11 ms per frame). Home felt smooth;
  Prodotti and the light/dark switch didn't. Measured with the performance test in profile mode on the phone, which now
  also times four theme switches from Profilo.
- **Prodotti scrolling.** `ProductSliverGrid` sized its cells with a `SliverLayoutBuilder`. That builder runs again
  whenever the sliver constraints change, and those include the scroll offset, so every visible card rebuilt on every
  scroll frame. A custom `SliverGridDelegate` now sizes the cells at layout time.
  - Build time (second pass): avg 4.5 → 1.5 ms, p90 8.7 → 2.3 ms, p99 13–17 → 6–8 ms. Raster was already fine at about
    5.4 ms. Traced afterwards, no UI-thread frame was over budget.
- **Theme switch.** Before: 200 ms of frames at up to 65 ms each. After: one frame of about 30 ms at the moment of the
  tap (about 26 ms without the accessibility pass the test turns on).
  - The theme is set by a `Theme` in `MaterialApp.router(builder:)`, so a switch no longer rebuilds the MaterialApp,
    the router and every page. It applies instantly, without the 200 ms interpolation.
  - New `BranchStack` (`lib/app/shell/`) replaces `StatefulShellRoute.indexedStack`'s container. Tabs not on screen keep
    their last theme until they're opened, so a switch from Profilo doesn't rebuild Home's and Prodotti's cards.
    `Theme` creates a new Cupertino theme each time it builds, and `Theme.of` depends on it, so `BranchStack` provides a
    stable one; without that every card still rebuilt.
  - The "Filtra e ordina" button is its own widget, so a theme change doesn't rebuild all of Prodotti.
- New test: "a theme switch rebuilds only the tab on screen" (no `ProductCard` rebuilds in background tabs, and the
  cards are dark once Prodotti is opened).

**Decisions / trade-offs**
- No theme cross-fade. The switch is instant, which is what makes it cheap.
- After a switch, opening Home or Prodotti for the first time rebuilds that tab with the new theme. That costs one
  frame when the tab opens, rather than on the switch.
- What's left in the switch frame is mostly the `NavigationBar` (its four destinations), Profilo and the repaint.
  A lighter custom nav bar would cut it further if it still feels slow.

### 2026-11-02

**Done**
- **Connected to beverfood_web** (the agents' Flask app on Render, same product DB). Read its structure and data:
  the PROMO category (99) has 7 active promos (91, 92, 93, 95, 98, 99, 901; 94 Ceres is inactive).
- **Promo images.** The old ones had white text on transparency, invisible on the web's light card. Published an
  options page (https://claude.ai/artifact/VMge2md1CKKvRYTuU5PyLJ) with the real Cloudinary cut-outs: three image
  styles (A Formula, B Vetrina, C Locandina), three app banner layouts and two tints.
  - User's choice: **C · Locandina**, **layout 3 · image only**, **one tint per promo**, banner order
    **92, 93, 95, 99, 91, 98, 901**, a single bottle for Alix (901).
  - Rendered 7 square `<id>.png` (800×800, for Cloudinary/web) and 7 `promo_banner_<id>.png` (900×372 = 3× the
    300×124 pt banner) into `beverfood_ops/assets/png_upload/promo/`. The generator (HTML + cut-outs) and
    `render.sh` are in `beverfood_ops/scripts/promo_banners/`.
- **API in beverfood_web** (not committed; the user handles git): `api.py` (`GET /api/v1/promos`, public,
  read-only) and `promos.py` (banner texts, order, banner version and each promo's rule). Registered in `app.py`;
  its CLAUDE.md documents it.
- **App:** `ApiClient` (`package:http`, `API_BASE_URL` dart-define, production by default), API-backed
  `PromoRepository` with `PromoRepositoryScope`, new `Promo` model (rule groups), `PromoSection` (placeholders while
  loading, "Promozioni non disponibili · Riprova" on failure), `PromoBanner` (image-only banner). Checked end to end
  with a web build against the local server. Tests: promos from a `MockClient` (an image banner plus the text
  fallback), and retry after a failed load.
- Published proposals for the **promo detail page** and **price + IVA** display
  (https://claude.ai/artifact/9BYuZ1Gk5yLB5ycY3jzhX3).

**Decisions**
- Promo data confirmed by the user: Estathè 4+1 is 5181, 5182, 51831, **51841** → 5041 free; 51777 is Basil Lemon
  (its photo shows Touch of Lime; kept until there's a better one); the Pepsi gift 51711 is **Pepsi Zero** (its
  photo shows a Pepsi Max); Foscaro's highlight is "Esclusiva"; Lilia is 92.
- **Banner texts live on the server** (`promos.py`, later a DB column), not in the app. With image-only banners the
  texts are baked into the PNG; the API's copy is used for accessibility and the detail page.
- **Prices:** shown like the agents' app, net + IVA. The user will pick the UI.
- **Orders:** a promo stays one line in the order/CSV, as for agents; the client's mixed choices will be a
  front-end option.
- Rejected on the options page: styles A Formula and B Vetrina, layouts 1 (text + image) and 2 (full-bleed image),
  the single Beverfood tint.

### 2026-11-02 (afternoon)

**Done**
- **Promo page** (`PromoPage`, route `/promo/:id`, full screen): the user combined the proposals: **D2's banner on
  top, D1's content below**, without repeating the title (it's in the banner), starting from the price and
  "Risparmi". Groups as cards: fixed products "× n", mixed groups with counter, progress bar and steppers, gifts with
  an "OMAGGIO" badge. 38 pt bottom bar: "Scegli ancora N [in omaggio]" → "Aggiungi · price + IVA" → "Nel carrello" with
  a bin → "Aggiorna il carrello" if the mix changes. Home banners now open it.
- `PromoSelection` model (mix, missing items, list value, savings, order note) and promo lines in `CartController`.
- **Prices "+ IVA"** (`NetPriceText`, choice "P2 · Suffisso") on the product card and the promo page.
- `splitProductName` for the database names, `palette.cutoutBackground` for cut-outs, `AppNetworkImage(fit:)`.
- Tests: unit tests for names and selections (Lilia, Alix), a widget test of the whole promo flow (pick, add, change,
  update, remove, back). 18 passing. Checked the page in a web build against the local API (Lilia and Coca).

**Decisions**
- **One of each promo per order** (several different promos are fine): no bundle quantity on the page.
- The client's mix is kept with the cart line and shown to the client in the cart; at checkout it's **appended to
  the order notes** (after the client's own notes) for the manager, as agents do today.
- **Show "Risparmi"** (list value of paid + free items − promo price). **No promo descriptions** in the app (they're
  written for agents).
- The bottom bar is 38 pt like the cards' "Aggiungi" bar (the user asked for it as tall as the quantity stepper, which
  went away with "one per order").
- Rejected from the proposals: D3 Passi, D2's receipt content, D1's square image and title; prices P1, P3, P4.

### 2026-11-02 (evening)

**Decisions: client accounts** (the user's answers; design pages above)
- **Nothing without an account:** the app shows only the login screen until the user signs in.
- **Sign-in without passwords:** the client signs in or registers with a **phone** (SMS or WhatsApp code) or an
  **email** (code by email); the same flow logs in later. A verified account sees the catalogue with prices.
- **To order:** the client completes the profile (Nome, Cognome, the other contact, Ragione sociale, Partita IVA,
  delivery address chosen from a list for the **province of Torino only**), then **any manager or admin** approves it
  in the web app and assigns the client's ERP **ID**.
  - Someone who signed up with an email must also verify the phone with a code.
  - The email is optional when the phone is verified.
- **Who can be a client:** existing and new businesses; private people only with a Partita IVA.
- **Separate from the agents' clients:** app clients have their own table. The agents' client import never touches it.
  A business can exist in both places, and an ID that's already used only shows a warning.
- **Against fake accounts:** a disposable-email blocklist, Italian mobile numbers only (optionally a VoIP lookup), and
  the Partita IVA checked on VIES and shown at approval.
- **Test account** for co-workers and the store reviews: fixed email and phone, a fixed code, no SMS sent, approved
  from the start, and "Elimina account" greyed out.
- **"Elimina account"** is in Profilo (both stores require it).
- **Admin panel:** to be redesigned. It holds Clienti app, Utenti, Catalogo (Importa CSV and Immagini mancanti move
  there) and Impostazioni. Managers get a "Clienti app" tab.
- **Email:** sent from `@beverfoodsrl.it`; the user will provide DNS access later. There's no provider yet, for SMS
  or for email.
- **Order of work:** design pages → DB + API → approval page → app screens → the real provider.

### 2026-11-02 (night)

**Decisions (from the design pages)**
- **App:** **A1** with the logo in its own red, large, filling the space above "Benvenuto su Beverfood"; **B2**
  (single code field); **C2** (three steps).
- **D1 + D2:** a red notice on Home while the profile isn't sent, then a yellow one: "Potrai inviare ordini una volta
  verificati i tuoi dati". The same notice goes in the cart above a disabled "Invia ordine".
- **E:** the theme settings go under an "Aspetto" section header, in a standard settings-list layout.
- **Buttons:** 46 pt on these screens.
- **Test account:** `admin@beverfoodsrl.it` / `+39 300 000 0000`. Its orders go to the web user admin@beverfoodsrl.it
  (the user will create it).
- **Approval notice to the client:** a push notification and an email.
- **After approval only the address can change.** Rejected clients see the reason and can resend. Clients can be
  suspended.
- **Admin panel: P2** (sidebar).
  - **Approval page:** the ID warning stops at the address, with no explanation after it. **The P.IVA is checked by
    hand**: a "Partita IVA verificata" checkbox, and "Approva" is enabled only with that ticked and the client ID
    filled. So no VIES in the app or the API.
- **Managers:** after login they choose between the agents' orders (light theme) and **Clienti app** (dark theme),
  which are separate. So there's no "APP" badge.
- **Privacy notice:** kept as drafted; the user will provide the details.

**Done**
- **beverfood_web:**
  - Tables `app_client`, `app_session` and `app_code`. `ensure-columns` now creates new tables too, for Render's
    pre-deploy.
  - `client_auth.py`: Italian mobile and disposable-email checks, P.IVA check digit, 6-digit codes (hashed, limited),
    bearer sessions, and the test account.
  - `places.py` + `data/places_torino.json.gz`: 312 comuni and about 20,600 OSM streets; Torino's streets have their
    CAPs.
  - `api.py`: auth, me, profile, address, second contact, delete, places, and promos behind login.
  - 33 end-to-end checks passed against the local database (a scratch script, then cleaned up).
- **beverfood_ops:** `scripts/places/build_places.py` (+ Overpass queries) rebuilds the address data.
- The local `.env` got `OTP_SENDER=log` and `APP_TEST_CODE=000000` (development only).

**Notes**
- **Address data:** OSM house numbers rarely carry the comune (79% don't), so streets come from each comune's
  boundary. Ingria, Massello, Pramollo and Ribordone have no named streets; the app offers "La via non è in elenco".
- **Mistake:** the first Overpass request carried the user's email in its User-Agent; later requests carry none.

### 2026-11-02 (late night)

**Done: app sign-in (phase 6)**
- **Sign-in screens:**
  - Start screen.
  - **A1** welcome: the logo, large and in its own red.
  - Phone or email entry, then **B2** code entry: one wide field, resend after 45 s, "Ricevilo su WhatsApp".
  - With no account the router allows only these.
- **C2** profile completion in three steps:
  - Verifying the phone (if signed up by email) or adding an email.
  - P.IVA check digit tested before sending.
  - Address with comune search, street search, CAP filled in, "La via non è in elenco", "© OpenStreetMap".
- **D1/D2:** the notice on Home and in the cart, red while it's up to the client, yellow "Profilo in verifica".
- **E Profilo:** status card, "Account" and "Aspetto" sections, Esci, and Elimina account (with a confirmation;
  disabled for the test account). Address changes after approval go through `/account/address`.
- **Plumbing:** `AuthController` + `SecureTokenStore` (flutter_secure_storage); `ApiClient` sends the token and signs
  out on 401; the account reloads on resume; the cart empties on sign-out.
- **Palette:** new `warning`/`onWarning` and `success`/`onSuccess` tokens.
- **Tests:** 22 widget tests + 8 unit tests. New ones cover the sign-in with a wrong then the right code, the 3-step
  profile with the exact payload sent, the pending notices, and the test account.
- **Checks:** the screens were rendered and looked over (light and dark), and an Android debug APK builds.

**Fixed**
- **Android debug builds** failed to compile since the previous push: the comment added to
  `android/app/src/debug/AndroidManifest.xml` contained `--`, which XML forbids.
- **The profile page** didn't close after sending: the step-by-step back button blocked it.

**Notes**
- **Headless Chromium** stalls on the web build's start screen; the app itself reaches /welcome. For visual checks,
  render screens through the Flutter test renderer with the real fonts loaded.
- **Not done yet:** push notifications for approval, real SMS/email delivery, the admin approval page.

### 2026-11-02 (tweaks)

**Done** (from the user's test)
- **Profilo card:**
  - No "ACCOUNT DI PROVA" badge.
  - The status badge ("APPROVATO") sits at the far right of the name's line, so the card is shorter.
  - The client number moved to the line below ("… · Cliente 40217"), so the name isn't cut off.
  - No line under the greyed "Elimina account".
- **Test account:** its company is now "Beverfood srl testing account". beverfood_web resets the test account's data at
  every test sign-in, so production updates on the next deploy without a database change.
- **Promo page:** tapping the number in a stepper opens a scroll wheel (`CupertinoPicker`, like iPhone's) with every
  allowed quantity, then "Conferma". Its numbers set the app font explicitly (the wheel defaults to Apple's system font).
  Covered by a new widget test (23 widget tests).

**Mistake**
- Re-running the web API checks wiped the local `app_*` tables, including any accounts the user may have created
  while testing locally. Production wasn't affected. Next time, run those checks on a separate database.

### 2026-11-02 (admin panel)

**Done (beverfood_web)**
- **Admin panel P2:**
  - A sidebar with Clienti app, Utenti, Importa CSV, Immagini mancanti and Impostazioni.
  - `/admin` opens Clienti app.
  - The CSV import moved off the agents' catalogue toolbar to Admin Panel → Importa CSV; dark mode moved to
    Impostazioni.
- **Clienti app (`app_clients.py`):**
  - Status chips, live search, and a page per client.
  - **Approva** needs the "Partita IVA verificata" tick and the ERP id. The id is checked live against the agents'
    clients, and a match only warns, the text ending at the address.
  - **Rifiuta… / Sospendi…** need a reason (the app shows it); **Riattiva** undoes a suspension. The test account is
    protected.
- **Managers:**
  - After login they choose **Ordini agenti** (light) or **Clienti app** (dark, without the sidebar).
  - A top-bar switch moves between them, and the count of waiting requests shows in the top bar.
- **Checks:** 37 end-to-end checks run against a **copy** of the local tables in a temporary `scratch` schema (the
  local role can't create databases), then removed. Pages were screenshotted in a browser; that caught the manager's
  Clienti app rendering empty (wrong layout), now fixed.

**Decisions**
- **Approve only `pending` requests.** A rejected client resends from the app (it becomes pending again); a suspended
  one uses Riattiva.
- **The client ID is warned about, never blocked,** as in the agents' "Nuovo cliente" flow.
- **No automatic VIES check** (the user verifies by hand); a VIES link sits next to the box.

### 2026-11-02 (Novità and cart bar)

**Done**
- **Novità from the database:**
  - beverfood_web has a new `GET /api/v1/products/new` (login required): the products flagged new, newest first. That's
    17 locally, all added on 1 November (Nordes gin, ODK syrups, Fabbri…).
  - In the app, `CatalogRepository` and `NewArrivalsSection`: placeholders while loading, retry on failure, and the
    section is hidden if nothing is new. Cut-out photos are drawn whole on the light backdrop. Names go through
    `splitProductName` ("GIN NORDES 3 LT" → "Gin Nordes 3 l"; `LATT` now reads "lattina").
- **"Vai al carrello" bar:** shown above the navigation bar while the cart has items (not on the Carrello tab). The
  count is on a second line so the total "+ IVA" fits at 360 pt, and the shadow is small enough not to be cut.
- **Profilo:** a much smaller status badge at the top right; the name wraps instead of being cut.
- **Shared retry row:** `LoadErrorRow` in `core/widgets`, used by promos and Novità.
- **Tests:** 26 widget tests, including Novità, its retry, and the cart bar. The cart-sharing test now searches
  Prodotti for its product and scopes its finders to Prodotti: Home, alive behind it, was matching first.

**Notes**
- Loading real network photos inside the Flutter test renderer hangs, so visual checks use placeholders.
- Product names are still the stopgap formatter; the user hasn't decided how names should look.

### 2026-11-02 (Più popolari)

**Done**
- **beverfood_web:** `GET /api/v1/products/popular?limit=` (login required; 20 by default, clamped to 1–50). It
  returns the active products in `popularity.py`'s order (the agents' "Più popolari" sort), **without the PROMO
  category**, in the same JSON as Novità. Locally the top 20 run from Beck's, Ceres and Coca Cola lattina to Red Bull;
  the promos 92 and 93, ranked 26th and 65th, are left out. Checked on a copy of the local tables in a `scratch`
  schema (20 products, no promos, the limit's bounds, 401 without a token), then dropped.
- **App:** `CatalogRepository.popularProducts()`. `NewArrivalsSection` became the shared `CatalogRailSection`
  (title, loader, error text), used by Novità and Più popolari. The sample `getPopular()` is gone.
- **Tests:** Più popolari from the database (names, no "NUOVO" badge, `limit=20` asked), its retry, and a rewritten
  cart-sharing test. Home's sample popular cards no longer exist in Prodotti, so it now checks one product (the gin)
  in both Home rails. 20 widget + 8 unit tests pass.

**Decisions**
- **The app reads the database only through beverfood_web's API**, never Postgres directly: a database password
  can't be shipped inside an app. The user asked about this.
- **20 products, promos left out** (the user's request). The ranking is still the static snapshot of 2026-09-29;
  dynamic popularity (beverfood_web's CLAUDE.md, "Decided future work") isn't started.
- **Names:** kept the stopgap formatter for now.

### 2026-11-02 (catalogue and categories)

**Decisions** (options page https://claude.ai/artifact/HK4w7qZGNx8wWPHYM7jKsd)
- **H3:** Home shows every category in a grid, four per row, **with Novità and Promozioni** as the first two tiles.
- **P1:** Prodotti keeps the category tabs ("Tutti" first). The sort starts on **Più popolari**; **"Consigliati" is
  gone**. "Vedi tutti" under Più popolari opens Prodotti on Tutti sorted by Più popolari (even if the client changed
  the sort there); under Novità it opens the Novità tab.
- **L1:** the whole catalogue in one request, searched, filtered and sorted on the phone.
- **Empty categories are hidden** (Specialità, Kebab and Caffè today); they come back once they have products.
- **Category names:** sentence case, as Italian shops write them ("Vini e spumanti", "Caffè"); PROMO is shown as
  "Promozioni".
- **Category photos are bundled in the app**, not on Cloudinary.
- Rejected on the page: H1 (one row), H2 (two rows), P2 (categories first), P3 (groups), L2 (server paging).

**Done**
- **beverfood_web:** `GET /api/v1/catalog` (products with `category_id`, categories with counts, popular and new
  orders) replaces `/products/new` and `/products/popular`. API answers over 1 KB are gzipped (263 KB → 32 KB).
  Checked on a scratch copy: 1222 products + 7 promos = 1229, 39 categories, ~40 ms.
- **beverfood_ops:** `scripts/category_images/build.sh` turns `static/img/categories/*.png` (9.1 MB) into 256 px
  WebP in the app's `assets/images/categories/` (445 KB, 41 files).
- **App:**
  - `Catalog` + `CatalogController` (loaded once signed in, refreshed on resume after 5 minutes, pull-to-refresh on
    Prodotti, cleared on sign-out).
  - Home: the Novità and Più popolari rails read it; `CategoryGrid` (H3).
  - Prodotti: a tab per category, the Promozioni tab lists the promo banners.
  - Search ignores accents and needs every word, and matches the ERP name too ("coca lat").
  - Sort: Più popolari, price, name.
  - Removed `ProductRepository`, the sample products and categories, and Unsplash.
- **Lighter product photos:** Cloudinary thumbnails (`w_400,f_webp`; Beck's 7.6 KB instead of 76.6 KB), kept on disk
  with `cached_network_image` (set in `main()`, so tests keep `NetworkImage`).
- **Fixed:** the category tabs used the system font: `TabBar` replaces the inherited text style, so its label styles
  now name Nunito Sans.
- **Tests:** 23 widget + 14 unit. New ones cover the category grid's order, a tile opening its tab, Vedi tutti
  re-applying Più popolari, the Promozioni tab, nothing new, catalogue retry, and unit tests for search, sort, names
  and thumbnail URLs. A debug APK builds.

**Notes**
- The Promozioni tab's search matches the promo's name and banner texts.
- `integration_test/scroll_performance_test.dart` builds the app with the device's saved token and the production
  API, so it measures the catalogue only when that device is signed in and production has `/catalog`; otherwise it
  stops at the welcome screen. Not run this session.

### 2026-11-02 (categories H2 and the phone)

**Decisions**
- **Home's categories are H2** (two rows that scroll sideways together), replacing H3. **Novità and Promozioni are not
  in Home's Categorie**: they have their own sections. They stay tabs in Prodotti.

**Done**
- `CategoryGrid` is now the two-row rail: columns of two 84 pt tiles, read down then across; 6 pt between the rows (a
  one-line name already leaves a blank line). Tile labels say "1 prodotto" / "N prodotti" to screen readers.
- **Tested on the user's phone** (CPH2399) against a local beverfood_web on a scratch copy of the local database
  (the real tables untouched; the copy dropped afterwards):
  - The integration test now signs in as the test account itself (`PERF_SIGN_IN_CODE`), waits for the real catalogue,
    uses the disk cache like the app, and also times the category rail, long Prodotti flings over 1222 products, tab
    switches and typing a search.
  - **The app ran at 60 Hz** on the 90 Hz screen (ColorOS keeps apps at 60 unless they ask). `MainActivity` now asks
    for the fastest display mode: 90 Hz confirmed.
  - **Real flings** (`tool/fling_stats.sh`, adb touch events timed by SurfaceFlinger) at 90 Hz: Prodotti 0.1–0.3%
    dropped frames, Home about 1%. Switching a Prodotti tab drops one frame.
  - The synthetic test showed ~25 ms build spikes in Prodotti (one per row of cards entering). Traced, they come from
    building and laying out a row of new cards, and they mostly vanish with real touches (touch boost). The test also
    ran *faster* with the accessibility tree on, so its numbers depend on how busy the cores are; compare like with
    like.
- **Lighter product card:** a `DecoratedBox` instead of a `Material` for the card, and the cart bar builds only its
  visible layer at rest. Measurably cheaper per card in traces, though the synthetic test's totals didn't move.
- **Names:** Italian small words lower case after the first word ("Succo di Limone"), DOC/DOCG/IGT… in capitals.
- **Tests:** 23 widget + 15 unit, all passing.

**Mistake**
- The first `flutter drive` run uninstalled the app from the user's phone when it finished (flutter drive does that
  without `--keep-app-running`), which also deleted its saved sign-in. Every later run used `--keep-app-running`, and
  CLAUDE.md's command now includes it.

**Notes**
- The theme switch still costs one frame of about 30–40 ms at the tap (as on 2026-11-01).
- A locked or sleeping phone stalls `flutter drive` (no frames without a display); Developer options → Stay awake.

### 2026-11-02 (Aggiungi email)

- **Bug the user hit:** Profilo → Email "Aggiungi" opened a Material `AlertDialog` with a text field; "Annulla" threw
  `'_dependents.isEmpty': is not true` (red error screen), every time. Cause: the dialog's `TextEditingController` was
  made in a method and disposed as soon as `showDialog` returned, while the dialog's closing animation still had the
  `TextField` on screen. Lesson: a controller belongs to a `State` and is disposed in its `dispose()`.
- **The user also disliked the dialog** (not like the rest of the app). It's now a page, `/account/email`
  (`AppRoutes.addEmail`): `ContactEntryPage(channel: email, addToAccount: true)`, the sign-in screen's look ("Aggiungi la
  tua email", the bordered field, "Ricevi il codice"), then the same code bottom sheet as C2; once verified it closes
  with "Email verificata." The dialog is gone.
- `contact_verification.dart` now has `askContactCode(context, sent)` (the sheet alone) besides `verifyContact` (send +
  sheet), so the page's button stops its spinner once the code is sent instead of spinning behind the sheet.
- The page pops on the next frame: the account update refreshes go_router (`refreshListenable`), which undid a pop made
  in the same frame (C2's page already did this).
- Test "an email is added from Profilo on its own page" (back without sending, then the whole flow); `_FakeServer`
  answers `/me/contact/code` and `/me/contact/verify`.

### 2026-11-03 (cart and orders)

**Decisions** (options page https://claude.ai/artifact/34gcgRRH4mLHMqvC8kdjyb)
- **K1** compact cart list, with a **"Rimuovi"** text link on each row (the user didn't like the page's emoji bin).
  Removing shows "Annulla" in a message; **no swipe**: the big shops (Amazon "Elimina", Zalando "Rimuovi") use a
  visible button, and the user found it clearer. The stepper is the cards' (Material bin at 1). "Svuota carrello"
  in the ⋮ menu, with a confirmation.
- **N1** notes field in the cart (500 characters), kept with the cart until the order is sent.
- **C2** review page "Riepilogo ordine", whose product list is a **compact read-only cart without photos**; the same
  list is used on the order page (**O1**, I miei ordini in Profilo). "Riordina" has no description underneath.
- **Manager (M):** an exact copy of Ordini agenti (same tabs, cards, CSV, live search, dark), for app orders, plus a
  fifth tab **"Clienti"** (the former Clienti app list). The area is called **"Ordini clienti"** (choose page and
  top-bar switch). Only managers process app orders; **admins see them in Ordini**, like agents' orders.
- **F1** cart saved on the phone; **F3** type a quantity (tap the stepper's number, on cards too); **F4** a product
  no longer sold is marked "Non più disponibile" (cart) / "Non disponibile" (old order) and left out, **but price
  changes are applied silently, no notice**; **F5** Riordina; **F6** clients can't cancel orders; F7/F8 later.
- **Minimum order 150 € net of IVA** (asked: net, not with IVA). No transport charge for now (later, by delivery
  area); notes only for delivery times; no payment in the app.
- **Status for clients:** "Inviato" from sending until the manager marks it Evaso, then "Evaso" (In lavorazione
  isn't shown to clients).
- **Test-account orders:** not marked; the user deletes them by hand. They carry the web user with the test email
  (admin@beverfoodsrl.it) as `id_user` when that user exists.

**Done (beverfood_web)**
- `orders` gains `from_app`, `app_client_id` (SET NULL on account deletion), `app_client_name`,
  `app_erp_client_id`, `delivery_address`, `app_request_id` (unique, against double sends), `fulfilled_at`;
  `order_item` gains `price`/`iva` (prices on the day, app orders only) and `promo_note`/`promo_mix`.
  `ensure_columns()` adds them.
- `app_orders.py` + `POST/GET /api/v1/orders`, `GET /orders/<id>`: checks approval, active products, quantities
  1–999, promos once with their mix checked against `promos.py`, the 150 € minimum; `/me` carries `order_minimum`.
- Manager: `_manager_page(area)` serves both areas; `/manager/clienti` (+ `/results`); fulfil sets `fulfilled_at` and
  returns to the right area; the CSV takes the app client's ERP id. Cards show the contact line, "(ID …)",
  "Consegna: …" and each promo's mix under its line; notes keep their line breaks.
- Admin Ordini shows app orders with a purple "DALL'APP" badge; its search matches the company name.
- **Checks:** 35 end-to-end checks on a scratch copy of the local tables (refusals, a promo order, idempotency,
  other clients' orders, both manager areas, CSV, Evaso seen by the client, admin view, account deletion keeping the
  order), plus screenshots of Ordini clienti and admin Ordini. Scratch schema dropped.

**Done (app)**
- `CartController` rewritten: product ids + quantities, promos with their mix, notes; saved through `CartStorage`
  (shared preferences) and restored at launch; `syncCatalog`/`syncPromos` bring it up to date (current prices,
  unavailable lines, promos whose rule changed must be chosen again). Totals with each product's IVA.
- Pages: `CartPage` (K1/N1), `CheckoutPage` (`/checkout`), `OrderSentPage` (`/order-sent/:id`), `OrdersPage` and
  `OrderPage` (`/profile/orders[/:id]`), the quantity sheet; `features/orders/` (model, repository, widgets).
- **Tests:** 5 new widget tests (send an order end to end, Rimuovi + Annulla, a saved cart with an unavailable
  product, Riordina, typing a quantity on a card) and 7 unit tests for the cart and promo mixes. Screens rendered and
  checked in light and dark; that caught the pack shown twice in cart rows and a TextButton losing the app font.

