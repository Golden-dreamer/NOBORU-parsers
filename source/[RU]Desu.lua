Desu = Parser:new("Desu", "https://desu.uno", "RUS", "DESURU", 11)

Desu.Filters = {
	{
		Name = "Сортировка",
		Type = "radio",
		Tags = {
			"По алфавиту",
			"По популярности",
			"По обновлению"
		},
		Default = "По популярности"
	},
	{
		Name = "Тип манги",
		Type = "check",
		Tags = {
			"Манга",
			"Манхва",
			"Маньхуа",
			"Ваншот",
			"Комикс"
		}
	},
	{
		Name = "Жанры",
		Type = "check",
		Tags = {
			"Безумие",
			"Боевые искусства",
			"Вампиры",
			"Военное",
			"Гарем",
			"Демоны",
			"Детектив",
			"Детское",
			"Дзёсей",
			"Додзинси",
			"Драма",
			"Игры",
			"Исторический",
			"Комедия",
			"Космос",
			"Магия",
			"Машины",
			"Меха",
			"Музыка",
			"Пародия",
			"Повседневность",
			"Полиция",
			"Приключения",
			"Психологическое",
			"Романтика",
			"Самураи",
			"Сверхъестественное",
			"Сёдзе",
			"Сёдзе Ай",
			"Сейнен",
			"Сёнен",
			"Сёнен Ай",
			"Смена пола",
			"Спорт",
			"Супер сила",
			"Триллер",
			"Ужасы",
			"Фантастика",
			"Фэнтези",
			"Хентай",
			"Школа",
			"Экшен",
			"Этти",
			"Юри",
			"Яой"
		}
	}
}

Desu.Keys = {
	["По алфавиту"] = "name",
	["По популярности"] = "popular",
	["По обновлению"] = "updated",
	["Манга"] = "manga",
	["Манхва"] = "manhwa",
	["Маньхуа"] = "manhua",
	["Ваншот"] = "one_shot",
	["Комикс"] = "comics",
	["Безумие"] = "Dementia",
	["Боевые искусства"] = "Martial Arts",
	["Вампиры"] = "Vampire",
	["Военное"] = "Military",
	["Гарем"] = "Harem",
	["Демоны"] = "Demons",
	["Детектив"] = "Mystery",
	["Детское"] = "Kids",
	["Дзёсей"] = "Josei",
	["Додзинси"] = "Doujinshi",
	["Драма"] = "Drama",
	["Игры"] = "Game",
	["Исторический"] = "Historical",
	["Комедия"] = "Comedy",
	["Космос"] = "Space",
	["Магия"] = "Magic",
	["Машины"] = "Cars",
	["Меха"] = "Mecha",
	["Музыка"] = "Music",
	["Пародия"] = "Parody",
	["Повседневность"] = "Slice of Life",
	["Полиция"] = "Police",
	["Приключения"] = "Adventure",
	["Психологическое"] = "Psychological",
	["Романтика"] = "Romance",
	["Самураи"] = "Samurai",
	["Сверхъестественное"] = "Supernatural",
	["Сёдзе"] = "Shoujo",
	["Сёдзе Ай"] = "Shoujo Ai",
	["Сейнен"] = "Seinen",
	["Сёнен"] = "Shounen",
	["Сёнен Ай"] = "Shounen Ai",
	["Смена пола"] = "Gender Bender",
	["Спорт"] = "Sports",
	["Супер сила"] = "Super Power",
	["Триллер"] = "Thriller",
	["Ужасы"] = "Horror",
	["Фантастика"] = "Sci-Fi",
	["Фэнтези"] = "Fantasy",
	["Хентай"] = "Hentai",
	["Школа"] = "School",
	["Экшен"] = "Action",
	["Этти"] = "Ecchi",
	["Юри"] = "Yuri",
	["Яой"] = "Yaoi"
}

local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")
local api=Desu.Link.."/api/manga/"
local function coverLink(url)
 if not url or url=='' then return '' end
 return {Link=url..(url:find('?',1,true) and '&' or '?')..'noboru_identity=1',Header1='Accept-Encoding: identity',Header2='Referer: https://desu.uno/'}
end
function Desu:prepareFilters()
 local html=U.request(self.Link..'/manga/')
 local genres,keys={},{}
 for tag in html:gmatch('<input[^>]+>') do
  local slug=U.attr(tag,'data%-genre%-slug')
  local name=U.attr(tag,'data%-genre%-name')
  if slug and name then name=U.text(name);genres[#genres+1]=name;keys[name]=slug end
 end
 assert(#genres>0,'Desu: genre list not found')
 table.sort(genres)
 local filters=table.clone(self.Filters)
 filters[3].Tags=genres
 self.Filters=filters
 for name,slug in pairs(keys) do self.Keys[name]=slug end
end

local function mangaID(link)
 return tostring(link):match("[./](%d+)/?$") or tostring(link):match("^(%d+)$") or error("Desu: unknown saved manga URL")
end
function Desu:getManga(link,dt)
 local result=U.requestJSON(link)
 assert(type(result.mangas)=="table","Desu: catalogue response changed")
 for _,m in ipairs(result.mangas) do
  local name=m.name or m.russian or ""
  if m.russian and m.russian~="" and m.russian~=name then name=name.." ("..m.russian..")" end
  local raw=m.view_url or self.Link.."/manga/"..m.id.."/"
  dt[#dt+1]=CreateManga(name,U.path(raw),coverLink((m.cover or {}).preview),self.ID,raw)
  coroutine.yield(false)
 end
 local nav=result.pagination or {}
 dt.NoPages=#result.mangas==0 or (nav.last_page and nav.current_page and nav.current_page>=nav.last_page) or false
end
function Desu:getPopularManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=popular&page="..page,dt) end
function Desu:getLatestManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=updated&page="..page,dt) end
function Desu:getAZManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=name&page="..page,dt) end
-- The catalogue JSON endpoint ignores search/genre/sort parameters.
-- Use the site's catalogue for filters and its search endpoint for titles.
local searchDetails = {}
local lastSearch
local function addEntry(self,dt,path,name,cover)
 local raw=U.absolute(self.Link..'/',path)
 dt[#dt+1]=CreateManga(U.text(name),U.path(raw),coverLink(cover),self.ID,raw)
 coroutine.yield(false)
end
function Desu:searchManga(search,page,dt,tags)
 local kinds=tags and (tags['Тип манги'] or tags[2]) or {}
 local genres=tags and (tags['Жанры'] or tags[3]) or {}
 local order=self.Keys[tags and (tags['Сортировка'] or tags[1])] or 'popular'
 if search:gsub('[+%s]','')=='' then
  local query='?page='..page..'&order_by='..order
  for _,spec in ipairs({{'kinds',kinds},{'genres',genres}}) do
   local slugs={}
   for _,name in ipairs(spec[2]) do if self.Keys[name] then slugs[#slugs+1]=self.Keys[name] end end
   if #slugs>0 then query=query..'&'..spec[1]..'='..U.encode(table.concat(slugs,',')) end
  end
  local html=U.request(self.Link..'/manga/'..query)
  for block in html:gmatch('<li class="primaryContent memberListItem"[^>]*>(.-)</li>') do
   local path=block:match('<a[^>]-href="([^"]+)"')
   local title=block:match('<h3>.-<a([^>]+)>')
   local name=title and U.attr(title,'title')
   local cover=block:match("background%-image:%s*url%('([^']+)'%)")
   if path and name and cover then addEntry(self,dt,path,name,cover) end
  end
  assert(#dt>0 or not html:find('memberListItem',1,true),'Desu: catalogue markup changed')
  dt.NoPages=not html:gsub('&amp;','&'):find('[?&]page='..(page+1)..'[^%d]')
  return
 end
 if page>1 then dt.NoPages=true;return end
 if lastSearch~=search then searchDetails={};lastSearch=search end
 local html=U.request(self.Link..'/manga/search/?q='..search..'&type=manga')
 local entries={}
 for block in html:gmatch('<li class="AniMangaSearchCard"[^>]*>(.-)</li>') do
  local path=block:match('<a[^>]-href="([^"]+)"')
  local img=block:match('<img[^>]+>')
  if path and img then
   local id=mangaID(path)
   local m=searchDetails[id]
   if not m then m=U.requestJSON(api..id..'/').manga;assert(m,'Desu: search details missing');searchDetails[id]=m end
   local matches=#kinds==0
   for _,name in ipairs(kinds) do if self.Keys[name]==m.kind then matches=true end end
   local available={}
   for _,genre in ipairs(m.genres or {}) do available[genre.slug]=true end
   for _,name in ipairs(genres) do if not available[self.Keys[name] or name] then matches=false end end
   if matches then entries[#entries+1]=m end
  end
 end
 table.sort(entries,function(a,b)
  if order=='name' then return U.fold(a.name or '')<U.fold(b.name or '') end
  local field=order=='updated' and 'updated_date' or 'views'
  if (a[field] or 0)==(b[field] or 0) then return a.id<b.id end
  return (a[field] or 0)>(b[field] or 0)
 end)
 for _,m in ipairs(entries) do
  addEntry(self,dt,m.view_url,m.russian and m.russian~='' and m.russian or m.name,(m.cover or {}).preview or '')
 end
 dt.NoPages=true
end

function Desu:getChapters(manga,dt)
 local id=mangaID(manga.Link)
 local details=U.requestJSON(api..id.."/").manga or {}
 dt.Description=U.text(details.description)
 local chapters=U.requestJSON(api..id.."/chapters").chapters or {}
 local ordered={}
 for _,c in ipairs(chapters) do
  if c.is_readable~=false then
   ordered[#ordered+1]={Name="Том "..tostring(c.volume or "").." Глава "..tostring(c.number or "").." "..(c.title or ""),Link=tostring(c.id),Pages={},Manga=manga,Data={MangaID=id}}
  end
 end
 table.sort(ordered,function(a,b)
  local an=tonumber(a.Name:match("Глава ([%d.]+)")) or 0
  local bn=tonumber(b.Name:match("Глава ([%d.]+)")) or 0
  if an==bn then return tonumber(a.Link)<tonumber(b.Link) end
  return an<bn
 end)
 for _,c in ipairs(ordered) do dt[#dt+1]=c end
end
function Desu:prepareChapter(chapter,dt)
 local id=mangaID(chapter.Manga.Link)
 local cid=tostring(chapter.Link):match("(%d+)/?$") or error("Desu: refresh saved chapter list")
 local c=U.requestJSON(api..id.."/chapters/"..cid).chapter or {}
 for _,p in ipairs(c.pages or {}) do dt[#dt+1]=U.absolute(self.Link.."/",p.url) end
end
function Desu:loadChapterPage(link,dt) dt.Link=coverLink(link) end
