MangaOneLove=Parser:new("MangaOneLove","https://mangaonelove.website","RUS","MANGAONELOVERU",4)
local U=NoboruSupport or dofile("ux0:data/noboru/parsers/00_NoboruSupport.lua")
local nonce
local function catalogue(self,page,dt,order,search)
 if not nonce then
  local html=U.request(self.Link.."/poisk/")
  local config=html:match('var manga_search = ([^\n]+)') or ''
  nonce=config:match('"nonce":"([^"]+)"')
  assert(nonce,"MangaOneLove: search nonce not found")
 end
 local form="q="..(search or '').."&post_type=wp-manga&orderby="..order
 local result=U.requestJSON({Link=self.Link.."/wp-admin/admin-ajax.php",HttpMethod=POST_METHOD,
  PostData="action=manga_advanced_search_load&nonce="..nonce.."&paged="..page.."&form_data="..U.encode(form)})
 assert(result.success and result.data and result.data.html,"MangaOneLove: search API rejected request")
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
function MangaOneLove:searchManga(search,page,dt) catalogue(self,page,dt,"relevance",search) end
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
