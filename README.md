# NOBORU - Parsers
This repo is created to store parsers for NOBORU app on PS vita
## Supported Parsers: 
|     Different     |         Russian         |      English      |     Japan     |      Spanish       |    Portuguese    |      French       |     Turkish     |    Italian    | Vietnamese  |    Polish     |   German   |  Brazil   | Indonesian  |     Korean     |      Thai      | Arab  |
| :---------------: | :---------------------: | :---------------: | :-----------: | :----------------: | :--------------: | :---------------: | :-------------: | :-----------: | :---------: | :-----------: | :--------: | :-------: | :---------: | :------------: | :------------: | :---: |
|     MangaDex      |      ~~ReadManga~~      |   ~~MangaHub~~    |   SenManga    |    ~~LeoManga~~    |  ~~Animaregia~~  |   ~~LelScanVF~~   | ~~Mabushimajo~~ | ~~MangaEden~~ |  TruyenQQ   | Phoenix-Scans | NineManga  | NineManga | ~~Komikid~~ | ~~manatoki95~~ |   NiceOppai    | Onma  |
|   ~~Bato.to*~~    |       МангаПоиск        |  ~~MangaReader~~  | ~~Manga1000~~ |      InManga       |   UnionMangas    |      ScanFR       |   ~~Puzzmos~~   |   NineManga   | TruyengiHot |               | Wie Manga! |           |             |                |    Oremanga    |       |
| ~~LoveHug (RAW)~~ |      ~~MintManga~~      |  ~~MangaPanda~~   |               |    ~~Submanga~~    | ~~GoldenMangas~~ |     NineManga     |   ~~MangaTR~~   |               |             |               |            |           |             |                | CartoonClub-TH |       |
|  RawDevArt (RAW)  |      ~~SelfManga~~      |     MangaTown     |               |     NineManga      |   ~~BRMangas~~   |                   |    SeriManga    |               |             |               |            |           |             |                |                |       |
|                   | Desu (broken covers :C) |   ~~MangaOwl~~    |               |    HeavenManga     |                  |                   |   MangaDenizi   |               |             |               |            |           |             |                |                |       |
|                   |        NineManga        | ReadComicsOnline  |               | ~~TumangaOnline~~  |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |      MangaOneLove       |   MangaKakalot    |               |   ~~MangaDoor~~    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |       Манга-Тян!        |     MangaNelo     |               |    MangaLibros     |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |       MangaHubRu        |    ~~VLComic~~    |               |   ~~LeoMangas~~    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |   ~~MangaEden~~   |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |     NineManga     |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |   ~~MangaSee~~    |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |    XoXoComics     |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         | ReadComicOnlineTo |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |   ~~Mangafast~~   |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         | ~~Reaper Scans~~  |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|                   |                         |    ReadM (50%)    |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|     **NSFW**      |        **NSFW**         |     **NSFW**      |   **NSFW**    |      **NSFW**      |     **NSFW**     |     **NSFW**      |    **NSFW**     |   **NSFW**    |  **NSFW**   |   **NSFW**    |  **NSFW**  | **NSFW**  |  **NSFW**   |    **NSFW**    |    **NSFW**    |       |
|      nhentai      |        Nude-Moon        |     PervEden      |               |    DoujinHentai    |                  | Histoire d'Hentai |                 |   PervEden    |             |               |            |           |             |                |                |       |
|    HentaiRead     |      ~~AllHentai~~      |  ~~HentaiCafe~~   |               | VerComicsPorno.xxx |                  |                   |                 |               |             |               |            |           |             |                |                |       |
|      9hentai      |        Яой-Тян!         |  MyHentaiGallery  |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |
| ~~Hentai Shark~~  |       Хентай-Тян!       |     Hentai20      |               |                    |                  |                   |                 |               |             |               |            |           |             |                |                |       |

**Catalog works with option Preferred Language and deletes extra manga from it*<br>
*strikethrough parsers don't work*

## Requirements
  For better experience better to update SSL certificates see [iTLS-enso by SKGleba](https://github.com/SKGleba/iTLS-Enso)
  
  *be careful before installing*

## Cloudflare-sites
  Parsers in this folder will work if there is the way to bypass cloudflare with cURL or with sites that avoid cloudflare thing (that will never happen).

## Manual Installation
  Throw `*.lua` file to `ux0:data/noboru/parsers/` and launch app

## Creating parsers
  Edit `parsers/*.lua` directly. Keep useful comments and formatting; this is the only parser directory. Publish the changes to `master`, then update catalogues in NOBORU. Parser-only edits do not require a new VPK.

  For understanding how to create parser you can check `parsers/[JP]RawDevArt.lua`, there all functions described and you can see how it all works.

## Tables
  ```Lua
  ---@param Name string
  ---@param Link string
  ---@param ImageLink string
  ---@param ParserID string
  ---@param RawLink string
  ---@return Manga table
  ---This function gives Manga table(see info about Manga table below)
  function CreateManga(Name, Link, ImageLink, ParserID, RawLink)

  Manga = {
	Name,      -- string Manga name
	Link,      -- string Link to the manga format isn't important (variable for parser)
	ImageLink, -- string Link to jpeg/png/bmp cover of manga
	ParserID,  -- string Parser's Unique key (used in saves)
	RawLink,   -- string Link for App (not important)
	Data       -- table to store manga data (for parser or other) 
  }
  
  Chapter = {
	Name,       -- string Chapter name
	Link,       -- var Link to the chapter format isn't important (variable for parser)
	Pages = {}, -- table (don't touch)
	Manga       -- table to Manga
  }
  ```
## Parser structure
  ```Lua
  ---@param name string
  ---@param link string
  ---@param language string
  ---@param uniqueID string
  ---@param version number
  ---@return Parser
  ---Creates parser
  function Parser:new(name, link, language, uniqueID, version)
  
  ---@param page integer
  ---@param dest_table table
  ---Adds popular manga(see Manga Table) to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  function Parser:getPopularManga(page, dest_table)
  
  ---@param page integer
  ---@param dest_table table
  ---Adds latest manga(see Manga Table) to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  function Parser:getLatestManga(page, dest_table)
  
  ---@param page integer
  ---@param dest_table table
  ---Adds manga(see Manga Table) in alphabet order to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  function Parser:getAZManga(page, dest_table)

  ---@param page integer
  ---@param dest_table table
  ---@param letter string
  ---Adds manga(see Manga Table) started with selected `letter` to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  ---ParserVar.Letters should be initialized
  ---example: LelScanVF.Letters = {"#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
  function Parser:getLetterManga(page, dest_table, letter)

  ---@param page integer
  ---@param dest_table table
  ---@param tag string
  ---Adds manga(see Manga Table) in alphabet order to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  ---ParserVar.Tags should be initialized
  ---example: MangaDoor.Tags = {"Acción", "Aventura", "Comedia", "Drama", "Ecchi", "Fantasía", "Gender Bender", "Harem", "Histórico", "Horror", "Josei", "Artes Marciales", "Maduro", "Mecha", "Misterio", "One Shot", "Psicológico", "Romance", "Escolar", "Ciencia Ficción", "Seinen", "Shoujo", "Shoujo Ai", "Shounen", "Shounen Ai", "Recuentos de la vida", "Deportes", "Supernatural", "Tragedia", "Yaoi", "Yuri", "Demonios", "Juegos", "Policial", "Militar", "Thriller", "Autos", "Música", "Vampiros", "Magia", "Samurai", "Boys love", "Hentai"}
  function Parser:getTagManga(page, dest_table, tag)

  ---@param search string
  ---@param page integer
  ---@param dest_table table
  ---@param filter? table
  ---Adds searched manga(see Manga Table) with `search` string to `dest_table`
  ---If page was last sets dest_table.NoPages to `true`
  ---For `filter` example search for `/parsers/[RAW]RawDevArt.lua` file
  function Parser:searchManga(search, page, dest_table, filter)
  
  ---@param manga table
  ---@param dest_table table
  ---Adds chapters(see Chapter Table) to dest_table in relese order (from 1st chapter to nth)
  function Parser:getChapters(manga, dest_table)
  
  ---@param chapter table
  ---@param dest_table table
  ---Adds links to all pages to dest_table
  function Parser:prepareChapter(chapter, dest_table)
  
  ---@param link string
  ---@param dest_table table
  ---Converts `link` in image_link(jpeg/png/bmp) and saves into dest_table.Link
  function Parser:loadChapterPage(link, dest_table)
 
  ```

## Fork runtime extensions

The existing parser methods above still apply. Keep the single readable version of each parser in `parsers/`. The app downloads these same Lua files directly from `parsers/` on `master`; no minification, compilation or copy to another directory is needed. Preserve parser IDs and increment the parser version when changing its behavior.

### Dynamic filters and large option lists

An optional `Parser:prepareFilters()` runs in a parser coroutine before catalogue loading. The app caches successful preparation for 30 minutes per session. Fetch dictionaries here, not while the parser file is being loaded. Build a new `Filters` table and assign it only after successful parsing; do not mutate the old filter/tag arrays in place.

A filter has `Name`, `Type` (`check`, `checkcross`, or `radio`), `Tags` (display names), and optional `Default`. `searchManga(search, page, dest_table, filter)` receives selections both by filter name and by position: arrays for checkboxes, `{include={}, exclude={}}` for checkcross, and a name for radio buttons.

For a large or remotely searched dictionary:

```lua
{
    Name = "Authors",
    Type = "check",
    Tags = {},
    Values = {},
    Search = function(query)
        return { { Name = "Display name", Value = "site-id-or-slug" } }
    end
}
```

`Search` is a plain function, not a method; it may yield and use the shared request helpers. Return up to 101 matches: the panel shows at most 100 new options, with the extra match indicating that the query should be refined. Already selected options and their `Values[name]` are retained. Read those values when building the site's actual query; do not assume that different sites share a tag-search syntax. Radio filters can use `EmptyOption` for a neutral choice. Option searches match the beginning of the name, ignoring ASCII and Russian letter case. Active options remain above the search row regardless of the query; recently disabled options follow them so they can be restored. Selecting an active radio option clears it when the filter defines `EmptyOption`.

All expanded filters have an in-list search row. Local filtering retains original option indexes. For large dictionaries, `NoboruSupport.termOptions(content, query)` scans a JSON `terms` array of `{name, slug, ...}` records without materializing the whole dictionary as Lua tables.

### Random and shared helpers

Optional `Parser:getRandomManga(page, dest_table)` enables the Random mode. Return ordinary manga entries and set `dest_table.NoPages=true` when there is no next page. Re-selecting Random requests a new result. If the first Random request returns exactly one entry, the app collects up to 24 distinct entries using fresh page-1 calls. Collection stops after 36 calls, five consecutive duplicate-only responses, an empty response or an error. Partial results remain visible and automatic pagination is disabled for that collection. A parser may lower the target with `RandomBatchSize`. Multi-entry Random responses retain their original pagination; other catalogue modes are unaffected.

`00_NoboruSupport.lua` provides `request`, `requestJSON`, `decodeJSON`, text/URL helpers and the option-search helpers. Requests accept a URL or a task link table with headers, cookies and POST data. Returned page/image links can also be tables such as `{Link=url, Header1="Referer: ..."}`. Attribute names passed to `U.attr` are Lua patterns: escape hyphens, e.g. `data%-src`.

Use Lua 5.3 for syntax checks. Respect the shared helpers' URL/POST length limits. JSON may arrive with a trailing NUL; the shared decoder handles this and uses byte offsets despite NOBORU's UTF-8 `string.sub` override.

Image bytes must be supported by the existing runtime (e.g. JPEG/PNG). `U.image` is a URL for the separate server-side WebP-to-JPEG gateway, not an on-device decoder. Check magic bytes and content encoding: a `.jpg` response can still contain gzip or HTML.
