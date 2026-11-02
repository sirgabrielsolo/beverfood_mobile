# Progress

What has been built, the decisions behind it, and what comes next.
Stack, architecture, conventions and commands are in [`CLAUDE.md`](../CLAUDE.md).

**How to update:** keep **Next up** current, editing it in place. Append a new dated entry to the
**Log** at the end of each work session; don't rewrite old entries. Record rejected approaches
as well, so they aren't proposed again.

## Next up

- [ ] **Upload the promo images and deploy the API** (user). Upload the 14 PNGs in
      `beverfood_ops/assets/png_upload/promo/` to Cloudinary (`<id>.png` replaces each promo's product image,
      `promo_banner_<id>.png` is new), then push beverfood_web (`api.py`, `promos.py`, `app.py`) so production
      serves `/api/v1/promos`. Until then the app's banners show the "image missing" placeholder.
- [ ] **Client accounts.** The API exists in beverfood_web (uncommitted, see the log below). Next: the **app screens**
      (A1, B2, C2, D1+D2, E, as chosen), sending the token, then the **admin panel** (P2) with the approval page and
      the manager's split view. Then push notifications (Firebase) and the SMS/email provider.
      Privacy notice draft (the user will add the details): https://claude.ai/artifact/1B9653a9Ymaz1cbmbktART
- [ ] **User to set up:** an SMS (+ later WhatsApp) verification provider account (Twilio Verify recommended), an
      email sender on `beverfoodsrl.it` (DNS access needed; Brevo suggested), Meta WhatsApp Business verification.
- [ ] **Deploying beverfood_web:** `/api/v1` now requires a client login, so it can go to production. On Render set
      `APP_TEST_CODE` (the test account's code) and leave `OTP_SENDER` unset until a provider exists.
- [ ] **Checkout notes.** When the order is built: the client can write notes; the manager sees them followed by
      each promo's `PromoSelection.orderNote`. The client sees the mix in the cart, not the note.
- [ ] **Cart page** must list promo lines (with their mix) next to products; `CartController` already holds them.
- [ ] **Novità from the API**, then **Più popolari**, then the rest of the catalogue (the user's order). Product
      names in the DB are agent-style upper case ("LILIA NATURALE 500 ML 24 PZ"): decide how the app shows them.
- [ ] **Product detail page.** Product cards aren't tappable yet.
- [ ] **Cart.** `CartController` already holds quantities in memory and the cards' add button / stepper use it.
      Still to do: persistence, the cart page (a placeholder today), the cart-tab count badge, and showing
      `CartBar` ("Vai al carrello · N articoli", the agreed design) above the nav while the cart isn't empty.
      Scrolling pages then need about 170 pt of bottom padding so the last row clears the bar.
- [ ] **Favourites.** The heart on cards toggles in memory only (`FavouritesController`). Persist it and decide
      where the list is shown.
- [ ] **Profile.** Login, orders and addresses. Today the page only has the theme settings.
- [ ] **Backend.** Promos come from beverfood_web's API; `ProductRepository` is still in memory (see above).
      Decide whether `/api/v1` stays public (today: catalogue only, no auth) once client login exists.
- [ ] **Images.** Images are now decoded at display size. Still to do: persistent disk caching and precaching,
      for the slower first scroll while images download and decode. On the phone, Home's first pass had raster
      p90 9–18 ms depending on the run, against about 7 ms once the images were cached.
- [ ] **Performance on the phone.** Check the first scroll of each page (image download and decode) on the CPH2399
      after today's fixes. If the theme switch still feels slow, the `NavigationBar` is the next cost to cut.
- [ ] **Search.** Matching is only on name and category label, so "birra" doesn't find "Fusto IPA".
      Consider synonyms or tags.
- [ ] **Branding before release.**
  - Android app label is still `beverfood_mobile` and `applicationId` is `com.example.beverfood_mobile`.
  - Launcher icons (Android/iOS) and the web manifest icons (`Icon-192/512`) are still Flutter defaults.
- [ ] **Open asset questions.**
  - On Home the logo is tinted white in code (`Image.asset(color: …)`), so its transparent lettering shows the red header.
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

