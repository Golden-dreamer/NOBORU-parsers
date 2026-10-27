nhentai = Parser:new("nhentai", "https://nhentai.to", "DIF", "NHENTAI", 6)

nhentai.NSFW = true
local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")

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

function nhentai:getManga(link, dt)
	local content = downloadContent(link)
	dt.NoPages = true
	for Link, ImageLink, Name in content:gmatch('class="gallery".-href="(%S-)".-data%-src="(%S-)".->([^<]-)</div>') do
		if ImageLink:match("^http") == nil then
			ImageLink = "https://cdn.nload.xyz" .. ImageLink
		end
		dt[#dt + 1] = CreateManga(stringify(Name), Link, U.image(ImageLink), self.ID, self.Link .. Link)
		dt.NoPages = false
		coroutine.yield(false)
	end
end

function nhentai:getPopularManga(page, dt)
	self:getManga(self.Link .. "/go?page=" .. page, dt)
end

function nhentai:searchManga(search, page, dt, tags)
	local selected=tags and tags['Теги']
	local slug=selected and self.Filters[1].Values[selected]
	if slug and slug~='' then
		assert(search:gsub('[+%s]','')=='','nhentai: clear text search to browse the selected tag')
		self:getManga(self.Link..'/tag/'..slug..'/?page='..page,dt)
	else
		self:getManga(self.Link .. "/search/?q=" .. search .. "&page=" .. page, dt)
	end
end

function nhentai:getChapters(manga, dt)
	dt[#dt + 1] = {
		Name = "Read chapter",
		Link = manga.Link,
		Pages = {},
		Manga = manga
	}
end

function nhentai:prepareChapter(chapter, dt)
	local content = downloadContent(self.Link .. chapter.Link)
	for link in content:gmatch('class="gallerythumb".-href="(%S-)"') do
		dt[#dt + 1] = self.Link .. link
	end
end

function nhentai:loadChapterPage(link, dt)
	local image = downloadContent(link):match('image%-container".-src="(%S-)"')
	assert(image, "nhentai: page image not found")
	dt.Link = U.image(U.absolute(link, image))
end

local function directoryEntries(html)
 local entries={}
 for slug,name in html:gmatch('href="/tag/([^"/]+)/"[^>]*>.-class="name">(.-)</span>') do
  entries[#entries+1]={Name=U.text(name),Value=slug}
 end
 return entries
end
function nhentai:prepareFilters()
 local first=U.request(self.Link..'/tags/')
 local index={}
 local last=1
 for page,letter in first:gmatch('href="%?page=(%d+)#([^"]+)"') do
  index[letter:lower()]=tonumber(page);last=math.max(last,tonumber(page))
 end
 local function search(query)
  query=U.fold(query):match('^%s*(.-)%s*$')
  local function page(number)
   if number==1 then return directoryEntries(first) end
   return directoryEntries(U.request(nhentai.Link..'/tags/?page='..number))
  end
  if query=='' then return page(1) end
  local letter=query:sub(1,1)
  local low,high=index[letter] or 1,last
  for other,start in pairs(index) do if other>letter and start>=low then high=math.min(high,start) end end
  while low<high do
   local mid=math.floor((low+high)/2)
   local entries=page(mid)
   if #entries>0 and U.fold(entries[#entries].Name)<query then low=mid+1 else high=mid end
  end
  local result={}
  for number=low,math.min(last,low+2) do
   local entries=page(number)
   for _,entry in ipairs(entries) do
    if U.fold(entry.Name):find(query,1,true)==1 then result[#result+1]=entry end
    if #result>=101 then return result end
   end
   local final=entries[#entries]
   if final and U.fold(final.Name)>query and U.fold(final.Name):find(query,1,true)~=1 then break end
  end
  return result
 end
 self.Filters={{Name='Теги',Type='radio',Tags={'Любой тег'},Values={['Любой тег']=''},Default='Любой тег',EmptyOption='Любой тег',Search=search,Prefix=true}}
end
function nhentai:getRandomManga(page,dt)
 if page>1 then dt.NoPages=true;return end
 local html=U.request(self.Link..'/random/')
 local link=html:match('<link[^>]-rel="canonical"[^>]-href="([^"]+)"')
 local name=html:match('<h1[^>]*>(.-)</h1>')
 local cover=html:match('id="cover".-<img[^>]-src="([^"]+)"')
 assert(link and name and cover,'nhentai: random gallery not found')
 dt[#dt+1]=CreateManga(U.text(name),U.path(link),U.image(U.absolute(self.Link..'/',cover)),self.ID,link)
 dt.NoPages=true
end
