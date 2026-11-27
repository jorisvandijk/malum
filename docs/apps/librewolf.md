<!-- Made from the librewolf catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# librewolf settings reference

Every setting `apps/librewolf.toml` takes, by table. Each one has a name you can read, and Malum writes what librewolf keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

Malum always writes these, which have no setting:

- `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `extensions.autoDisableScopes`: `0`
- `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `toolkit.legacyUserProfileCustomizations.stylesheets`: `true`
- `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `accessibility.typeaheadfind.flashBar`: `0`

## `[appearance]`

How LibreWolf looks.

### `mode`

Light, dark, or following macOS, for LibreWolf's own look and for the sites that have both. Malum sets LibreWolf's compact theme to match.

- Value: "dark", "light" or "system"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `layout.css.prefers-color-scheme.content-override`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `ui.systemUsesDarkTheme`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `extensions.activeThemeID`

### `nova_design`

Whether LibreWolf uses the Nova redesign of its interface.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.nova.enabled`

## `[window]`

Closing and quitting LibreWolf.

### `close_with_last_tab`

Whether closing the last tab closes its window.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.tabs.closeWindowWithLastTab`

### `quit_shortcut`

What cmd+q does: quits at once, asks first, or nothing.

- Value: "quit", "ask" or "off"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.warnOnQuitShortcut`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.quitShortcut.disabled`

## `[startup]`

What LibreWolf opens when it starts.

### `open`

The tabs of last time, the home page, or a blank page.

- Value: "last_session", "home_page" or "blank_page"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.startup.page`

## `[privacy]`

What LibreWolf hides from sites and clears.

### `fingerprinting`

How LibreWolf hides what makes this Mac stand out to sites: "resist" is LibreWolf's strict default, which also hides dark mode and the time zone; "protect" is every other protection, so sites still see light or dark mode; "off" is none.

- Value: "resist", "protect" or "off"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `privacy.resistFingerprinting`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `privacy.fingerprintingProtection`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `privacy.fingerprintingProtection.overrides`

### `clear_on_quit`

Whether LibreWolf clears cookies, history and the rest when it quits, as it does by default. Off keeps the tabs of last time.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `privacy.sanitize.sanitizeOnShutdown`

## `[extensions]`

The add-ons LibreWolf installs and keeps, from addons.mozilla.org.

- Keys: the add-on's name in its addons.mozilla.org address, such as ublock-origin
- Values: the add-on's ID, which about:support lists, such as "uBlock0@raymondhill.net"

## `[tabs]`

Where LibreWolf shows its tabs.

### `vertical`

Whether the tabs are in the sidebar, down the side of the window, not along the top.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `sidebar.revamp`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `sidebar.verticalTabs`

## `[sidebar]`

The sidebar's tools.

### `tools`

The tools the sidebar shows buttons for, in order, or none.

- Value: a list of any of "chatbot", "synced_tabs", "history" or "bookmarks"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `sidebar.main.tools`

## `[toolbar]`

The toolbar with the address bar.

### `buttons`

The toolbar's buttons, in order, with "space" for room that grows. Malum puts the add-ons' buttons in the extensions menu.

- Value: a list of at least one of "back", "forward", "reload", "home", "space", "address_bar", "downloads", "library", "sidebar", "bookmarks", "history", "new_tab", "new_window", "print", "fullscreen", "developer", "account", "extensions" or "menu", each as often as you like
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.uiCustomization.state`

## `[bookmarks_toolbar]`

The toolbar of bookmarks under the address bar.

### `show`

When it shows: never, always, or only on a new tab.

- Value: "never", "always" or "on_new_tab"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.toolbars.bookmarks.visibility`

## `[address_bar]`

The buttons and suggestions under the address bar while you type.

### `show_tabs_button`

Whether there's a button to search the open tabs.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.urlbar.shortcuts.tabs`

### `show_actions_button`

Whether there's a button to search LibreWolf's actions.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.urlbar.shortcuts.actions`

### `suggest_search_engines`

Whether it suggests searching with another engine.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.urlbar.suggest.engines`

### `suggest_quick_actions`

Whether it suggests actions, such as clearing history.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.urlbar.suggest.quickactions`

### `suggest_top_sites`

Whether it suggests the sites you visit most.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.urlbar.suggest.topsites`

## `[search]`

Which search engine the address bar uses.

### `default_engine`

The search engine's name, one of [search_engines] or one LibreWolf has, such as "DuckDuckGo".

- Value: text that isn't empty
- Writes: `/Library/Preferences/net.librewolf.librewolf` `SearchEngines.Default`

## `[translations]`

Which languages LibreWolf offers to translate.

### `never_translate`

The languages LibreWolf never offers to translate a page from.

- Value: a list of at least one of "arabic", "bulgarian", "catalan", "chinese", "croatian", "czech", "danish", "dutch", "english", "estonian", "finnish", "french", "german", "greek", "hindi", "hungarian", "indonesian", "italian", "japanese", "korean", "latvian", "lithuanian", "persian", "polish", "portuguese", "romanian", "russian", "serbian", "slovak", "slovenian", "spanish", "swedish", "turkish", "ukrainian" or "vietnamese"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.translations.neverTranslateLanguages`

## `[navigation]`

What the keys that move around a page do.

### `backspace`

What backspace does outside a text field: goes back, scrolls up a page, or nothing.

- Value: "back", "page_up" or "nothing"
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `browser.backspace_action`

## `[video]`

Video on pages.

### `picture_in_picture`

Whether a video can play in a small window of its own, and shows the button for it.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `media.videocontrols.picture-in-picture.enabled`, `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `media.videocontrols.picture-in-picture.video-toggle.enabled`

## `[websites]`

What sites may use.

### `serial_ports`

Whether a site may ask to use a serial port, such as a tool that flashes a board.

- Value: true or false
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/user.js` `dom.webserial.enabled`

## `[ublock_origin]`

uBlock Origin's settings.

### `trust_my_filters`

Whether the filters in [ublock_origin.filters] may use what uBlock Origin allows only trusted filters, such as scriptlets.

- Value: true or false
- Writes: `/Library/Preferences/net.librewolf.librewolf` `3rdparty.Extensions.uBlock0@raymondhill.net.userSettings`

## `[css]`

CSS that changes LibreWolf's own interface, such as hiding a button.

### `text`

The CSS, as it is.

- Value: text that isn't empty
- Writes: `$HOME/Library/Application Support/LibreWolf/Profiles/default/chrome/userChrome.css` `text`

## `[bookmarks]`

LibreWolf's bookmarks, in the parts below.

## `[bookmarks.menu]`

The bookmarks in the Bookmarks menu, by title.

- Keys: a bookmark's title
- Values: its address

## `[bookmarks.toolbar]`

The bookmarks on the bookmarks toolbar, by title.

- Keys: a bookmark's title
- Values: its address

## `[search_engines]`

Search engines LibreWolf adds to its own, by name.

- Keys: the engine's name
- Values: its search address with %s for what you search, or a table of that address and a keyword that searches with it from the address bar, such as { address = "https://www.startpage.com/search?q=%s", keyword = "@sp" }. Malum takes the icon from the site's favicon.ico

## `[ublock_origin.filters]`

uBlock Origin's own filters, by what they're for.

- Keys: what the filters are for, which uBlock Origin shows as a comment above them
- Values: a filter in uBlock Origin's syntax, or a list of them, such as "www.youtube.com##ytd-merch-shelf-renderer"
