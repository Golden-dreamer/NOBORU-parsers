MangaPoisk = Parser:new("МангаПоиск", "https://mangapoisk.me", "RUS", "MANGAPOISK", 4)

local function stringify(string)
	return string:gsub(
		"&#([^;]-);",
		function(a)
			local number = tonumber("0" .. a) or tonumber(a)
			return number and u8c(number) or "&#" .. a .. ";"
		end
	):gsub(
		"&(.-);",
		function(a)
			return HTML_entities and HTML_entities[a] and u8c(HTML_entities[a]) or "&" .. a .. ";"
		end
	)
end

local function downloadContent(link)
	local f = {}
	Threads.insertTask(
		f,
		{
			Type = "StringRequest",
			Link = link,
			Table = f,
			Index = "text"
		}
	)
	while Threads.check(f) do
		coroutine.yield(false)
	end
	return f.text or ""
end

local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")
function MangaPoisk:getManga(link,dt)
 local content=U.request(link)
 local payload=content:match('data%-page="([^"]+)"')
 if payload then
  local props=U.json.decode(U.text(payload)).props or {}
  local list=props.mangaList or {}
  for _,m in ipairs(list.data or {}) do
   dt[#dt+1]=CreateManga(m.title,m.link,(m.poster or {}).link_mini or (m.poster or {}).link or "",self.ID,self.Link..m.link)
   coroutine.yield(false)
  end
  local meta=list.meta or {}
  dt.NoPages=#dt==0 or (meta.current_page and meta.last_page and meta.current_page>=meta.last_page) or false
 else
  dt.NoPages=true
  local seen={}
  for link,rest in content:gmatch('<a[^>]-href="(/manga/[^"]+)"([^>]*>.-)</a>') do
   local image=rest:match('<img[^>]-src="([^"]+)"')
   local name=rest:match('<h%d[^>]*>(.-)</h%d>') or rest:match('alt="([^"]+)"')
   if image and name and not seen[link] then
    seen[link]=true;dt[#dt+1]=CreateManga(U.text(name),link,U.absolute(self.Link.."/",image),self.ID,self.Link..link);dt.NoPages=false
   end
  end
 end
end

function MangaPoisk:getPopularManga(page, dest_table)
	self:getManga(self.Link .. "/manga?page=" .. page, dest_table)
end

function MangaPoisk:getLatestManga(page, dest_table)
	self:getManga(self.Link .. "/manga?sortBy=-last_chapter_at&page=" .. page, dest_table)
end

function MangaPoisk:searchManga(search, page, dest_table)
	self:getManga(self.Link .. "/search?q=" .. search .. "&page=" .. page, dest_table)
end

function MangaPoisk:getChapters(manga, dt)
	local description = (downloadContent(self.Link .. manga.Link):match('class="manga%-description.->(.-)</div>') or ""):gsub("<br>","\n"):gsub("<.->",""):gsub("\n+","\n"):gsub("^%s+",""):gsub("%s+$","")
	dt.Description = stringify(description)
	local page = 1
	local res = 0
	local t = {}
	local seen = {}
	while page <= 1000 do
		local content = downloadContent(self.Link .. manga.Link .. "/chaptersList?infinite=1&page="..page)
		for Link, Name, subName in content:gmatch('href="(%S-)"[^>]->%s+<span class="chapter%-title">%s*(.-)%s*</span>%s*(.-)%s*</a>') do
			local sub_n = stringify(subName:gsub("%s+", " "):gsub("<[^>]->",""))
			t[#t + 1] = {
				Name = stringify(Name:gsub("%s+", " ")) .. (sub_n ~= "" and (": " .. sub_n) or ""),
				Link = Link,
				Pages = {},
				Manga = manga
			}
			assert(not seen[Link], "MangaPoisk: repeated chapter page")
			seen[Link] = true
			res = res + 1
		end
		if res == 0 then
			break
		else
			page = page + 1
			res = 0
		end
	end
	for i = #t, 1, -1 do
		dt[#dt + 1] = t[i]
	end
end

function MangaPoisk:prepareChapter(chapter,dt)
 local url=self.Link..chapter.Link
 local content=U.request(url)
 for tag in content:gmatch('<img[^>]+>') do
  if (U.attr(tag,"class") or ''):find('page%-image') then
   local image=U.attr(tag,"data%-src") or U.attr(tag,"src")
   if image then dt[#dt+1]={Link=U.absolute(url,image),Header1="Referer: "..self.Link.."/"} end
  end
 end
 assert(#dt>0,"MangaPoisk: reader images not found")
end

function MangaPoisk:loadChapterPage(link, dt)
	dt.Link = link
end
