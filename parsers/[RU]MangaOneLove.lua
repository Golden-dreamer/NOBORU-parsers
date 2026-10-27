MangaOneLove=Parser:new("MangaOneLove","https://mangaonelove.website","RUS","MANGAONELOVERU",5)
local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")
local nonce
local function searchPage()
 local html=U.request(MangaOneLove.Link.."/poisk/")
 nonce=html:match('var manga_search = [^\n]-"nonce":"([^"]+)"')
 assert(nonce,"MangaOneLove: search nonce not found")
 return html
end
local function post(action,body,raw)
 for attempt=1,2 do
  if not nonce then searchPage() end
  local content=U.request({Link=MangaOneLove.Link.."/wp-admin/admin-ajax.php",HttpMethod=POST_METHOD,
   PostData="action="..action.."&nonce="..nonce.."&"..body})
  if raw then
   if content:match('^%s*{%s*"success"%s*:%s*true') then return content end
  else
   local result=U.decodeJSON(content)
   if result.success then return result end
  end
  nonce=nil
 end
 error("MangaOneLove: search API rejected request")
end
function MangaOneLove:prepareFilters()
 local html=searchPage()
 local filters={}
 local genres={Name="Жанры",Type="check",Tags={},Values={},Field="genre[]"}
 local genreBlock=html:match('id="genresList"(.-)</div>') or ''
 for block in genreBlock:gmatch('<label[^>]*>(.-)</label>') do
  local slug=block:match('<input[^>]-value="([^"]+)"')
  local name=block:match('class="checkbox%-label">(.-)</span>')
  if slug and name then name=U.text(name);genres.Tags[#genres.Tags+1]=name;genres.Values[name]=slug end
 end
 assert(#genres.Tags>0,"MangaOneLove: genres not found")
 filters[#filters+1]=genres
 for _,spec in ipairs({{"Теги","tags","tag[]"},{"Авторы","authors","author[]"},{"Переводчики","translators","translator[]"}}) do
  local kind=spec[2]
  filters[#filters+1]={Name=spec[1],Type="check",Tags={},Values={},Field=spec[3],Search=function(query)
   local response=post('manga_get_filter_terms','type='..kind,true)
   return U.termOptions(response,query)
  end}
 end
 local radios={
  type={Name="Тип",Type="radio",Tags={},Values={},Field="type"},
  status={Name="Статус",Type="radio",Tags={},Values={},Field="status"},
  age_rating={Name="Возраст",Type="radio",Tags={},Values={},Field="age_rating"}
 }
 for block in html:gmatch('<label class="filter%-radio">(.-)</label>') do
  local input=block:match('<input[^>]+>')
  local f=input and radios[U.attr(input,'name')]
  local name=block:match('class="radio%-label">(.-)</span>')
  if f and name then
   name=U.text(name);f.Tags[#f.Tags+1]=name;f.Values[name]=U.attr(input,'value') or ''
   if input:find('checked',1,true) then f.Default=name end
  end
 end
 for _,key in ipairs({'type','status','age_rating'}) do
  assert(#radios[key].Tags>0,'MangaOneLove: filter missing: '..key)
  filters[#filters+1]=radios[key]
 end
 self.Filters=filters
end
local function catalogue(self,page,dt,order,search,tags)
 local form="q="..(search or '').."&post_type=wp-manga&orderby="..order
 if tags then
  for _,f in ipairs(self.Filters or {}) do
   local chosen=tags[f.Name]
   if f.Type=='radio' then chosen=chosen and {chosen} or {} end
   for _,label in ipairs(chosen or {}) do
    local value=f.Values[label]
    if value and value~='' then form=form..'&'..f.Field..'='..U.encode(value) end
   end
  end
  form=form..'&genre_relation=AND&tag_relation=AND&author_relation=OR&translator_relation=OR'
 end
 local result=post('manga_advanced_search_load',"paged="..page.."&form_data="..U.encode(form))
 assert(result.data and result.data.html,"MangaOneLove: search response missing")
 local html=result.data.html
 local seen={}
 for block in html:gmatch('class="manga%-search%-item (.-)</a>') do
  local link=block:match('<a[^>]-href="([^"]+)"')
  local name=block:match('class="manga%-search%-title">(.-)</div>')
  local image=block:match('<img[^>]-src="([^"]+)"')
  if link and name and not seen[link] then
   seen[link]=true
   local slug=link:match('/manga/([^/]+)/?')
   dt[#dt+1]=CreateManga(U.text(name),slug,U.absolute(self.Link.."/",image):gsub('^http:','https:'),self.ID,link)
   coroutine.yield(false)
  end
 end
 dt.NoPages=#dt==0 or not html:find('pagination',1,true)
end
function MangaOneLove:getPopularManga(page,dt) catalogue(self,page,dt,"rating") end
function MangaOneLove:getLatestManga(page,dt) catalogue(self,page,dt,"modified") end
function MangaOneLove:getAZManga(page,dt) catalogue(self,page,dt,"title") end
function MangaOneLove:searchManga(search,page,dt,tags) catalogue(self,page,dt,"relevance",search,tags) end
function MangaOneLove:getChapters(manga,dt)
 local url=self.Link.."/manga/"..manga.Link.."/"
 local html=U.request(url)
 dt.Description=U.text(html:match('class="summary__content[^>]*>(.-)</div>') or '')
 local chapters={};local seen={}
 for tag,body in html:gmatch('(<a[^>]+>)(.-)</a>') do
  if (U.attr(tag,"class") or ''):find('chapter%-item') then
   local link=U.attr(tag,"href")
   local name=body:match('class="chapter%-number">(.-)</span>') or body
   if link and not seen[link] then
    seen[link]=true
    chapters[#chapters+1]={Name=U.text(name),Link=U.path(link),Pages={},Manga=manga}
   end
  end
 end
 assert(#chapters>0,"MangaOneLove: chapter list not found")
 for i=#chapters,1,-1 do dt[#dt+1]=chapters[i] end
end
function MangaOneLove:prepareChapter(chapter,dt)
 local url=chapter.Link:find("/manga%-reader/") and U.absolute(self.Link.."/",chapter.Link) or self.Link.."/manga/"..chapter.Manga.Link.."/"..chapter.Link.."/"
 local html=U.request(url)
 local current=html:match('var mrpData = (%b{});')
 if current then
  local count=tonumber(current:match('totalPages:%s*(%d+)'))
  assert(count and count>0,"MangaOneLove: page count missing")
  local base=url:gsub('/stranica%-%d+/?$','/')
  for i=1,count do dt[#dt+1]=base.."stranica-"..i.."/" end
  return
 end
 local data=html:match('chapter_preloaded_images%s*=%s*(%b[])')
 if data then
  for _,link in ipairs(U.json.decode(data)) do dt[#dt+1]={Link=U.absolute(url,link),Header1="Referer: "..url} end
 else
  local seen={}
  for tag in html:gmatch('<img[^>]+>') do
   if (U.attr(tag,"class") or ''):find('wp%-manga%-chapter%-img') then
    local link=U.attr(tag,"data%-src") or U.attr(tag,"src")
    if link and not seen[link] then seen[link]=true;dt[#dt+1]={Link=U.absolute(url,link:gsub('^%s+',''):gsub('%s+$','')),Header1="Referer: "..url} end
   end
  end
 end
 assert(#dt>0,"MangaOneLove: chapter images not found")
end
function MangaOneLove:loadChapterPage(link,dt)
 if type(link)=="table" then dt.Link=link;return end
 local html=U.request(link)
 for tag in html:gmatch('<img[^>]+>') do
  if U.attr(tag,"id")=="manga-image" then
   dt.Link={Link=U.absolute(link,U.attr(tag,"src")):gsub('^http:','https:'),Header1="Referer: "..link}
   return
  end
 end
 error("MangaOneLove: reader image not found")
end
