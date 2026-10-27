MangaHubRU = Parser:new("MangaHub (Русский)", "https://mangahub.ru", "RUS", "MANGAHUBRU", 3)

local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")

local function stringify(string)
	if u8c then
		return string:gsub(
			"&#([^;]-);",
			function(a)
				local number = tonumber("0" .. a) or tonumber(a)
				return number and u8c(number) or "&#" .. a .. ";"
			end
		):gsub(
			"&([^;]-);",
			function(a)
				return HTML_entities and HTML_entities[a] and u8c(HTML_entities[a]) or "&" .. a .. ";"
			end
		)
	else
		return string
	end
end

local function downloadContent(link)
	local file = {}
	Threads.insertTask(
		file,
		{
			Type = "StringRequest",
			Link = link,
			Table = file,
			Index = "string",
			Header1 = "Referer: " .. MangaHubRU.Link,
			Header2 = "Accept-Encoding: identity",
			Cookie = Settings.NSFW and "confirm_age=1" or ""
		}
	)
	while Threads.check(file) do
		coroutine.yield(false)
	end
	return file.string or ""
end

function MangaHubRU:getManga(link, dt)
	local content = downloadContent(link)
	dt.NoPages = true
	local seen={}
	for block in content:gmatch('<div class="item%-grid"[^>]*>(.-)</a>') do
		local link=block:match('href="/(title/[^"]+)"')
		local imageTag=block:match('<img[^>]+>')
		local image=imageTag and U.attr(imageTag,'src')
		local name=imageTag and U.attr(imageTag,'alt')
		if link and image and name and not seen[link] then
			seen[link]=true
			dt[#dt+1]=CreateManga(U.text(name),link,U.absolute(self.Link..'/',image),self.ID,self.Link..'/'..link)
			dt.NoPages=false
			coroutine.yield(false)
		end
	end
end

function MangaHubRU:getPopularManga(page, dt)
	self:getManga(self.Link .. "/explore?filter%5Bsort%5D=rating&filter%5Btypes%5D%5Bexcludes%5D=&filter%5Bgenres%5D%5Bexcludes%5D=&filter%5Bstatus%5D%5Bexcludes%5D=&filter%5Bcountry%5D%5Bexcludes%5D=&page=" .. page, dt)
end

function MangaHubRU:getLatestManga(page, dt)
	self:getManga(self.Link .. "/explore?filter%5Bsort%5D=update&filter%5Btypes%5D%5Bexcludes%5D=&filter%5Bgenres%5D%5Bexcludes%5D=&filter%5Bstatus%5D%5Bexcludes%5D=&filter%5Bcountry%5D%5Bexcludes%5D=&page=" .. page, dt)
end

function MangaHubRU:searchManga(search, page, dt)
	self:getManga(self.Link .. "/search/title?query=" .. search .. "&page=" .. page, dt)
end

function MangaHubRU:getChapters(manga, dt)
	local content = downloadContent(self.Link .. "/" .. manga.Link:gsub("^/", "") .. "/chapters") or ""
	local t = {}
	for Link, Name in content:gmatch('href="/read/([^"]-)"[^>]*>%s*<span class="text%-truncate">%s*(.-)%s*</span>') do
		t[#t + 1] = {
			Name = U.text(Name):gsub("[\t\n ]+", " "),
			Link = Link,
			Pages = {},
			Manga = manga
		}
	end
	for i = #t, 1, -1 do
		dt[#dt + 1] = t[i]
	end
end

function MangaHubRU:prepareChapter(chapter, dt)
	local content = downloadContent(self.Link .. "/read/" .. chapter.Link)
	assert(not content:find("confirm_age__token",1,true), "MangaHub: reader requires age confirmation in a browser session")
	for tag in content:gmatch('<img[^>]+>') do
		if U.attr(tag,'data%-target')=='reader-scan.image' then
			local link=U.attr(tag,'data%-src') or U.attr(tag,'src')
			if link then dt[#dt+1]={Link=U.absolute(self.Link..'/',link),Header1='Referer: '..self.Link..'/',Header2='Accept-Encoding: identity'} end
		end
	end
	assert(#dt>0,'MangaHub: reader images not found')
end

function MangaHubRU:loadChapterPage(link, dt)
	dt.Link = link
end
