--[[
Covers Are Unavailable due GZIP encoding
]]
Desu = Parser:new("Desu", "https://desu.uno", "RUS", "DESURU", 9)

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
  dt[#dt+1]=CreateManga(name,U.path(raw),(m.cover or {}).preview or "",self.ID,raw)
  coroutine.yield(false)
 end
 local nav=result.pagination or {}
 dt.NoPages=#result.mangas==0 or (nav.last_page and nav.current_page and nav.current_page>=nav.last_page) or false
end
function Desu:getPopularManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=popular&page="..page,dt) end
function Desu:getLatestManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=updated&page="..page,dt) end
function Desu:getAZManga(page,dt) self:getManga(api.."catalog/?limit=20&order_by=name&page="..page,dt) end
function Desu:searchManga(search,page,dt,tags)
 local query="&search="..search
 if tags then
  query=query.."&order_by="..(self.Keys[tags["Сортировка"] or tags[1]] or "popular")
  for i,key in ipairs({"kinds","genres"}) do
   local values={}
   for _,v in ipairs(tags[i==1 and "Тип манги" or "Жанры"] or tags[i+1] or {}) do
    if self.Keys[v] then values[#values+1]=self.Keys[v] end
   end
   if #values>0 then query=query.."&"..key.."="..U.encode(table.concat(values,",")) end
  end
 end
 self:getManga(api.."catalog/?limit=20&page="..page..query,dt)
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
function Desu:loadChapterPage(link,dt) dt.Link={Link=link,Header1="Referer: "..self.Link.."/"} end
