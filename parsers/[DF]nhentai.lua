nhentai = Parser:new("nhentai", "https://nhentai.to", "DIF", "NHENTAI", 8)

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
 local content = U.request(link)
 dt.NoPages = true
 for block in content:gmatch('<div[^>]-class="gallery"(.-)</a>') do
  local path=block:match('<a[^>]-href="([^"]+)"')
  local image=block:match('<img[^>]+>')
  local name=block:match('class="caption"[^>]*>(.-)</div>')
  if image then
   name=name or U.attr(image,'alt')
   local cover=U.attr(image,'data%-src') or U.attr(image,'src')
   if path and name and cover and not cover:find('^data:') then
    local raw=U.absolute(self.Link..'/',path)
    dt[#dt+1]=CreateManga(U.text(name),U.path(raw),U.image(U.absolute(link,cover)),self.ID,raw)
    dt.NoPages=false
    coroutine.yield(false)
   end
  end
 end
 local pagination=content:match('<section class="pagination">(.-)</section>') or ''
 dt.NoPages=not (pagination:find('rel="next"',1,true) or pagination:find('class="next"',1,true))
end

function nhentai:getPopularManga(page, dt)
	self:getManga(self.Link .. "/go?page=" .. page, dt)
end

local function filterValue(self,tags,name)
 for _,filter in ipairs(self.Filters or {}) do
  if filter.Name==name then
   return (filter.Values or {})[(tags or {})[name] or filter.Default] or ''
  end
 end
 return ''
end

local function pageCount(value)
 if value=='' then return '' end
 assert(value:match('^%d+$') and #value<=6,'nhentai: enter a page count from 0 to 999999')
 return tostring(tonumber(value))
end

function nhentai:searchManga(search,page,dt,tags)
 local tag=filterValue(self,tags,'Теги')
 local group=filterValue(self,tags,'Группы')
 local language=filterValue(self,tags,'Язык')
 local sort=filterValue(self,tags,'Сортировка')
 if sort=='' then sort='relevance' end
 local minimum=pageCount(filterValue(self,tags,'Мин. страниц'))
 local maximum=pageCount(filterValue(self,tags,'Макс. страниц'))
 assert(minimum=='' or maximum=='' or tonumber(minimum)<=tonumber(maximum),'nhentai: minimum pages exceeds maximum pages')
 local excluded={}
 for _,filter in ipairs(self.Filters or {}) do
  if filter.Name=='Исключить теги' then
   for _,name in ipairs(tags and tags[filter.Name] or {}) do
    local value=filter.Values[name]
    if value and value~='' then excluded[#excluded+1]=value end
   end
  end
 end
 local blank=search:gsub('[+%s]','')==''
 assert(tag=='' or group=='','nhentai: choose either a tag or a group')
 if tag~='' or group~='' then
  assert(blank,'nhentai: clear text search to browse a tag or group')
  assert(language=='' and minimum=='' and maximum=='' and #excluded==0 and sort=='relevance',
   'nhentai: site ignores advanced filters on tag/group pages; clear them or use text search')
  local kind=tag~='' and 'tag' or 'group'
  self:getManga(self.Link..'/'..kind..'/'..(tag~='' and tag or group)..'/?page='..page,dt)
 elseif blank then
  assert(minimum=='' and maximum=='' and #excluded==0 and sort=='relevance',
   'nhentai: enter search text to use page, exclusion or sorting filters')
  if language~='' then self:getManga(self.Link..'/language/'..language..'/?page='..page,dt)
  else self:getPopularManga(page,dt) end
 else
  local link=self.Link..'/search?q='..search..'&sort='..U.encode(sort)..'&lang='..U.encode(language)
  link=link..'&min_pages='..minimum..'&max_pages='..maximum..'&exclude='..U.encode(table.concat(excluded,','))..'&page='..page
  self:getManga(link,dt)
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
	local content = U.request(U.absolute(self.Link.."/", chapter.Link))
	for link in content:gmatch('class="gallerythumb".-href="(%S-)"') do
		dt[#dt + 1] = U.absolute(self.Link.."/", link)
	end
end

function nhentai:loadChapterPage(link, dt)
	local image = U.request(link):match('image%-container".-src="(%S-)"')
	assert(image, "nhentai: page image not found")
	dt.Link = U.image(U.absolute(link, image))
end

local function directorySearch(self,directory,kind)
 local first,index,last
 local cache,order={},{}
 local function entries(html)
  local result={}
  for slug,name in html:gmatch('href="/'..kind..'/([^"/]+)/"[^>]*>.-class="name">(.-)</span>') do
   name=U.text(name)
   result[#result+1]={Name=name,Value=slug}
  end
  return result
 end
 local function load(number)
  if cache[number] then return cache[number] end
  local html=number==1 and first or U.request(self.Link..'/'..directory..'/?page='..number)
  local result=entries(html)
  cache[number]=result;order[#order+1]=number
  if #order>6 then cache[table.remove(order,1)]=nil end
  return result
 end
 return function(query)
  if not first then
   first=U.request(self.Link..'/'..directory..'/')
   index={};last=1
   for number,letter in first:gmatch('href="%?page=(%d+)#([^"]+)"') do index[U.fold(letter)]=tonumber(number) end
   for number in first:gmatch('[?&]page=(%d+)') do last=math.max(last,tonumber(number)) end
   assert(next(index),'nhentai: directory alphabet not found')
  end
  query=U.fold(query):match('^%s*(.-)%s*$')
  if query=='' then
   local result={}
   for i,entry in ipairs(load(1)) do if i>101 then break end;result[#result+1]=entry end
   return result
  end
  local letter=query:sub(1,1)
  local low,high=index[letter] or 1,last
  if letter:match('%d') then
   low=index.num or 1;high=index.a or last
  else
   for other,start in pairs(index) do
    if other~='num' and other>letter and start>=low then high=math.min(high,start) end
   end
  end
  while low<high do
   local mid=math.floor((low+high)/2)
   local result=load(mid)
   if #result>0 and U.fold(result[#result].Name)<query then low=mid+1 else high=mid end
  end
  local result={}
  for number=low,math.min(last,low+2) do
   local page=load(number)
   for _,entry in ipairs(page) do
    if U.fold(entry.Name):find(query,1,true)==1 then result[#result+1]=entry end
    if #result>=101 then return result end
   end
   local final=page[#page]
   if final and U.fold(final.Name)>query and U.fold(final.Name):find(query,1,true)~=1 then break end
  end
  return result
 end
end

local function directoryFilter(name,neutral,search,kind)
 return {Name=name,Type=kind or 'radio',Tags=neutral and {neutral} or {},Values=neutral and {[neutral]=''} or {},
  Default=neutral,EmptyOption=neutral,Search=search}
end

local function numericFilter(name)
 return directoryFilter(name,'Без ограничения',function(query)
  local result,seen={},{}
  if query~='' then
   local value=pageCount(query)
   result[#result+1]={Name=query,Value=value};seen[query]=true
  end
  for _,value in ipairs({'0','10','20','30','50','100','200','500','1000'}) do
   if not seen[value] and value:find(query,1,true)==1 then result[#result+1]={Name=value,Value=value} end
  end
  return result
 end)
end

local function selectFilter(html,field,name,labels)
 local result={Name=name,Type='radio',Tags={},Values={}}
 for tag,body in html:gmatch('(<select[^>]*>)(.-)</select>') do
  if U.attr(tag,'name')==field then
   for option,text in body:gmatch('(<option[^>]*>)(.-)</option>') do
    local value=U.attr(option,'value') or ''
    local label=labels[value] or U.text(text)
    result.Tags[#result.Tags+1]=label;result.Values[label]=value
    if value=='' then result.EmptyOption=label end
    if option:find('%sselected[%s=>]') then result.Default=label end
   end
  end
 end
 assert(#result.Tags>0,'nhentai: missing search filter: '..field)
 result.Default=result.Default or result.Tags[1]
 return result
end

function nhentai:prepareFilters()
 local html=U.request(self.Link..'/search?q=')
 local tags=directorySearch(self,'tags','tag')
 local function excluded(query)
  local result={}
  for _,entry in ipairs(tags(query)) do result[#result+1]={Name=entry.Name,Value=entry.Name} end
  return result
 end
 local groups=directorySearch(self,'groups','group')
 self.Filters={
  directoryFilter('Теги','Любой тег',tags),
  directoryFilter('Группы','Любая группа',groups),
  selectFilter(html,'lang','Язык',{['']='Любой язык',japanese='Японский',english='Английский',chinese='Китайский',korean='Корейский'}),
  selectFilter(html,'sort','Сортировка',{relevance='По соответствию',newest='Сначала новые',['most-favorited']='По избранному',['most-liked']='По лайкам'}),
  numericFilter('Мин. страниц'),numericFilter('Макс. страниц'),
  directoryFilter('Исключить теги',nil,excluded,'check')
 }
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
