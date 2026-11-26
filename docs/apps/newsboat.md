<!-- Made from the newsboat catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# newsboat settings reference

Every setting `apps/newsboat.toml` takes, by table. Each one has a name you can read, and Malum writes what newsboat keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[shortcuts]`

The keys that run newsboat's actions.

### `down`

Goes to the next line.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"down"`

### `up`

Goes to the line before.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"up"`

### `first_item`

Goes to the first line.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"home"`

### `last_item`

Goes to the last line.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"end"`

### `next_feed`

Shows the articles of the next feed.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"next-feed articlelist"`

### `previous_feed`

Shows the articles of the feed before.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"prev-feed articlelist"`

### `open`

Opens the feed or article on the line.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"open"`

### `close`

Goes back to the list before, or quits from the list of feeds.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/newsboat/config`, a key per shortcut, set to `"quit"`

## `[browser]`

The app newsboat opens links in.

### `app`

The app's bundle ID.

- Value: an app's bundle ID, such as "net.librewolf.librewolf"
- Writes: `$HOME/.config/newsboat/config` `browser`

## `[reload]`

When and how newsboat fetches new articles.

### `on_startup`

Whether newsboat fetches every feed when it opens.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `refresh-on-startup`

### `auto_reload`

Whether newsboat fetches the feeds by itself, every interval_minutes.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `auto-reload`

### `interval_minutes`

How long newsboat waits between fetching the feeds by itself.

- Value: a whole number of minutes, 1 or more
- Writes: `$HOME/.config/newsboat/config` `reload-time`

### `parallel_feeds`

How many feeds newsboat fetches at once.

- Value: a whole number, 1 or more
- Writes: `$HOME/.config/newsboat/config` `reload-threads`

### `only_visible_feeds`

Whether newsboat fetches only the feeds the list shows.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `reload-only-visible-feeds`

## `[lists]`

What newsboat's lists of feeds and articles show, and in what order.

### `feed_columns`

The columns of the list of feeds, in order.

- Value: a list of at least one of "number", "unread_mark", "counts" or "title"
- Writes: `$HOME/.config/newsboat/config` `feedlist-format`

### `article_columns`

The columns of a list of articles, in order.

- Value: a list of at least one of "number", "flags", "date", "feed", "author" or "title"
- Writes: `$HOME/.config/newsboat/config` `articlelist-format`

### `date_parts`

The parts of an article's date, in order.

- Value: a list of at least one of "weekday", "day", "month", "month_number", "year" or "time"
- Writes: `$HOME/.config/newsboat/config` `datetime-format`

### `sort_feeds_by`

The order of the list of feeds.

- Value: "none", "title", "first_tag", "article_count", "unread_count" or "last_updated"
- Writes: `$HOME/.config/newsboat/config` `feed-sort-order`

### `show_read_feeds`

Whether the list of feeds shows feeds with no unread articles.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `show-read-feeds`

### `show_read_articles`

Whether a list of articles shows the ones you've read.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `show-read-articles`

## `[downloads]`

Where podboat, newsboat's downloader, saves podcasts.

### `folder`

The folder, which gets a folder for each feed, by the feed's name.

- Value: a path, starting with $HOME/ in your home folder or / outside it
- Writes: `$HOME/.config/newsboat/config` `download-path`

### `max_downloads`

How many files podboat downloads at once.

- Value: a whole number, 1 or more
- Writes: `$HOME/.config/newsboat/config` `max-downloads`

## `[notifications]`

Whether newsboat tells you about new articles.

### `when`

When newsboat shows a notification and sets the terminal's title: never, when a fetch finds new articles, or after every fetch.

- Value: "never", "new_articles" or "every_reload"
- Writes: `$HOME/.config/newsboat/config` `notify-program`, `$HOME/.config/newsboat/config` `notify-screen`, `$HOME/.config/newsboat/config` `notify-always`

## `[quit]`

What newsboat does when it quits.

### `confirm`

Whether newsboat asks before it quits.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `confirm-exit`

### `clean_up`

Whether newsboat removes deleted articles from its cache.

- Value: true or false
- Writes: `$HOME/.config/newsboat/config` `cleanup-on-quit`

## `[ignored_articles]`

Articles newsboat leaves out, by feed.

- Keys: a feed's address, or "*" for every feed
- Values: a filter in newsboat's filter language, or a list of them, such as 'link =~ "/shorts/"'

## `[feeds]`

The feeds newsboat follows, by title.

- Keys: a feed's title
- Values: the feed's address, or a table of its url and a list of tags
