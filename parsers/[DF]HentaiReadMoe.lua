HentaiReadMoe=Parser:new('HentaiRead.moe','https://hentairead.moe','DIF','HENTAIREADMOE',2)
HentaiReadMoe.NSFW=true
HentaiReadMoe.RandomBatchSize=1
local P=HentaiReadMoe
local U=NoboruSupport or dofile('ux0:data/noboru/parsers/00_NoboruSupport.lua')
local clock=Timer.new()
-- Cache gallery metadata to avoid repeated requests while browsing.
local cache,order={},{}
local ttl=5*60*1000
local cacheLimit=96

local function request(url)
    return U.request({Link=url,Header1='Accept-Encoding: identity',Header2='Referer: '..P.Link..'/'})
end

local function absolute(url)
    return U.absolute(P.Link..'/',url)
end

local function galleryURL(url)
    assert(type(url)=='string','HentaiRead: missing gallery address')
    url=absolute(url):gsub('[?#].*$',''):gsub('/+$','')
    assert(url:match('^https://hentairead%.moe/hentai/[^/]+$'),'HentaiRead: invalid gallery address')
    return url
end

local function primary(html)
    assert(html:find('</html>',1,true),'HentaiRead: incomplete page response')
    -- Related-gallery cards must not contribute tags to the current gallery.
    return html:match('^(.-)<article[%s>]') or html
end

local function parseMetadata(html,url)
    local main=primary(html)
    local book
    for tag,body in main:gmatch('(<script[^>]*>)(.-)</script>') do
        if U.attr(tag,'type')=='application/ld+json' then
            local ok,value=pcall(U.decodeJSON,body)
            if ok and type(value)=='table' and value['@type']=='Book' then book=value;break end
        end
    end
    assert(book and galleryURL(book.url)==url,'HentaiRead: gallery metadata unavailable')
    local variants,links={},{}
    for tag in main:gmatch('<a%s[^>]*>') do
        local href=absolute(U.attr(tag,'href') or '')
        local base,kind=href:match('^(.-)/([%w%-]+)/p/1$')
        if base==url and not links[kind] then
            variants[#variants+1]={Name=kind,Link=href};links[kind]=true
        end
    end
    local image=absolute(book.image or '')
    local metadata={name=U.text(book.name),url=url,image=image,variants=variants}
    assert(metadata.name~='' and image:match('^https://readimg%.site/galleries/'),'HentaiRead: incomplete gallery metadata')
    return metadata
end

local function galleryMetadata(url,refresh)
    url=galleryURL(url)
    local saved=cache[url]
    if refresh or not saved or Timer.getTime(clock)-saved.Time>ttl then
        local data=parseMetadata(request(url),url)
        cache[url]={Data=data,Time=Timer.getTime(clock)}
        for i=#order,1,-1 do if order[i]==url then table.remove(order,i) end end
        order[#order+1]=url
        if #order>cacheLimit then cache[table.remove(order,1)]=nil end
        return data
    end
    return saved.Data
end

local function imageLink(url)
    assert(type(url)=='string' and url:match('^https://readimg%.site/galleries/'),'HentaiRead: unexpected image host')
    if url:lower():match('%.webp[?]?') or url:lower():match('%.avif[?]?') then return U.image(url) end
    return {Link=url,Header1='Referer: '..P.Link..'/',Header2='Accept-Encoding: identity'}
end

local function appendGallery(dest,url,seen)
    url=galleryURL(url)
    if seen[url] then return false end
    seen[url]=true
    local data=galleryMetadata(url)
    dest[#dest+1]=CreateManga(data.name,U.path(data.url),imageLink(data.image),P.ID,data.url)
    return true
end

local function cards(html,dest,latest)
    local content=html
    if latest then
        -- The index also contains popularity carousels before the actual Latest section.
        content=html:match('<section>%s*(.-)</section>')
        assert(content,'HentaiRead: latest catalogue section unavailable')
    end
    local seen,count={},0
    for _,manga in ipairs(dest) do seen[absolute(manga.Link)]=true end
    for block in content:gmatch('<article[%s>](.-)</article>') do
        count=count+1
        local href=block:match('<a[^>]-href="(https://hentairead%.moe/hentai/[^"/?]+)"')
        if href then
            appendGallery(dest,href,seen)
        end
    end
    assert(count>0 or html:lower():find('no results',1,true) or html:lower():find('no manga',1,true) or html:lower():find('no hentai',1,true),
        'HentaiRead: catalogue markup or response changed')
    local nextPage=false
    for tag in content:gmatch('<a%s[^>]*>') do if U.attr(tag,'rel')=='next' then nextPage=true;break end end
    return nextPage
end

local function catalogue(url,dest,latest)
    local nextPage=cards(request(url),dest,latest)
    dest.NoPages=not nextPage
end

function P:getLatestManga(page,dest)
    catalogue(self.Link..(page==1 and '/index' or '/index/page/'..page),dest,true)
end

function P:getPopularManga(page,dest)
    catalogue(self.Link..'/top-hentai?range=all&page='..page,dest)
end

local function radio(name,options,default)
    local tags,values={},{}
    for _,pair in ipairs(options) do tags[#tags+1]=pair[1];values[pair[1]]=pair[2] end
    return {Name=name,Type='radio',Tags=tags,Values=values,Default=default or tags[1]}
end

local function options(kind,query)
    local result,seen={},{}
    local folded=U.fold(query)
    for page=1,3 do
        local data=U.decodeJSON(request(P.Link..'/terms?type='..kind..'&q='..U.encode(query)..'&page='..page))
        assert(type(data.terms)=='table','HentaiRead: filter dictionary unavailable')
        for _,term in ipairs(data.terms) do
            local name=type(term.name)=='string' and U.text(term.name) or ''
            if name~='' and term.id and not seen[name]
                and (folded=='' or U.fold(name):find(folded,1,true)==1) then
                result[#result+1]={Name=name,Value=tostring(term.id)};seen[name]=true
                if #result>=101 then return result end
            end
        end
        if not data.has_more then break end
    end
    return result
end

local function remote(name,kind,mode)
    return {Name=name,Type=mode or 'check',Tags={},Values={},Search=function(query) return options(kind,query) end}
end

function P:prepareFilters()
    local html=request(self.Link..'/search?q=&advanced=1')
    local categories,seen={},{}
    for input in html:gmatch('<input%s[^>]*>') do
        if U.attr(input,'name')=='categories[]' then
            local value=U.attr(input,'value')
            if value and not seen[value] then categories[#categories+1]=value;seen[value]=true end
        end
    end
    assert(#categories>0,'HentaiRead: advanced search form unavailable')
    self.Filters={
        radio('Sort order',{{'Latest','latest'},{'Popular today','day'},{'Popular this week','week'},
            {'Popular this month','month'},{'Popular this year','year'},{'Popular all time','all'}}),
        radio('Title match',{{'Contains','contains'},{'Starts with','start-with'},{'Ends with','end-with'}}),
        radio('Search mode',{{'All conditions','AND'},{'Any condition','OR'}}),
        {Name='Categories',Type='check',Tags=categories},
        remote('Tags','tag','checkcross'),remote('Parodies','parody','checkcross'),
        remote('Artists','artist'),remote('Characters','character'),remote('Scanlators','scanlator'),
        remote('Circles','circle'),remote('Collections','collection'),remote('Conventions','convention'),
        radio('Year condition',{{'In year','in'},{'Before year','before'},{'After year','after'}}),
        {Name='Year',Type='radio',Tags={'Any'},Values={['Any']=''},Default='Any',EmptyOption='Any',
            Search=function(query)
                if query=='' then return {} end
                assert(query:match('^%d%d%d%d$'),'HentaiRead: enter a four-digit year')
                return {{Name=query,Value=query}}
            end}
    }
end

local function filterValue(tags,name,default)
    for _,filter in ipairs(P.Filters or {}) do
        if filter.Name==name then return (filter.Values or {})[(tags or {})[name] or filter.Default] or default end
    end
    return default
end

local function values(tags,name,names)
    for _,filter in ipairs(P.Filters or {}) do
        if filter.Name==name then
            local result={}
            for _,name in ipairs(names or (tags or {})[name] or {}) do
                local value=(filter.Values or {})[name] or (filter.Name=='Categories' and name)
                assert(value,'HentaiRead: filter value unavailable; select it again')
                result[#result+1]=value
            end
            return result
        end
    end
    return {}
end

function P:searchManga(search,page,dest,tags)
    local decoded=search:gsub('%%%%','%%'):gsub('%+',' '):gsub('%%(%x%x)',function(n)return string.char(tonumber(n,16))end)
    local params={'q='..U.encode(decoded),'advanced=1','page='..page}
    local constrained=decoded:gsub('%s','')~=''
    local function add(key,value)
        params[#params+1]=U.encode(key)..'='..U.encode(value);constrained=true
    end
    for _,pair in ipairs({{'Categories','categories'},{'Artists','artists'},{'Characters','characters'},
        {'Scanlators','scanlators'},{'Circles','circles'},{'Collections','collections'},{'Conventions','conventions'}}) do
        for _,value in ipairs(values(tags,pair[1])) do add(pair[2]..'[]',value) end
    end
    for _,name in ipairs({'Tags','Parodies'}) do
        local selected=(tags or {})[name] or {}
        for _,value in ipairs(values(tags,name,selected.include or {})) do add('tags[]',value) end
        for _,value in ipairs(values(tags,name,selected.exclude or {})) do add('exclude[]',value) end
    end
    local year=filterValue(tags,'Year','')
    if year~='' then add('release',year) end
    params[#params+1]='title-type='..filterValue(tags,'Title match','contains')
    params[#params+1]='search-mode='..filterValue(tags,'Search mode','AND')
    params[#params+1]='release-type='..filterValue(tags,'Year condition','in')
    local sort=filterValue(tags,'Sort order','latest')
    if not constrained then
        if sort=='latest' then self:getLatestManga(page,dest)
        else catalogue(self.Link..'/top-hentai?range='..sort..'&page='..page,dest) end
        return
    end
    assert(sort=='latest','HentaiRead: popularity periods apply to the unfiltered catalogue; choose Latest for advanced search')
    catalogue(self.Link..'/search?'..table.concat(params,'&'),dest)
end

function P:getRandomManga(page,dest)
    dest.NoPages=true
    if page>1 then return end
    local seen,stale={},0
    for attempt=1,36 do
        if #dest>=24 or stale>=5 then break end
        local html=request(self.Link..'/random')
        local canonical
        for tag in html:gmatch('<link%s[^>]*>') do
            if U.attr(tag,'rel')=='canonical' then canonical=U.attr(tag,'href');break end
        end
        local url=galleryURL(canonical)
        if not cache[url] then
            local ok,data=pcall(parseMetadata,html,url)
            if ok then
                cache[url]={Data=data,Time=Timer.getTime(clock)};order[#order+1]=url
                if #order>cacheLimit then cache[table.remove(order,1)]=nil end
            end
        end
        if appendGallery(dest,url,seen) then stale=0 else stale=stale+1 end
        coroutine.yield(true)
    end
end

function P:getChapters(manga,dest)
    local data=galleryMetadata(manga.Link,true)
    assert(#data.variants>0,'HentaiRead: reader links unavailable')
    for _,variant in ipairs(data.variants) do
        dest[#dest+1]={Name=variant.Name,Link=variant.Link,Manga=manga}
    end
end

function P:prepareChapter(chapter,dest)
    local data=galleryMetadata(chapter.Manga.Link,true)
    local allowed=false
    for _,variant in ipairs(data.variants) do if variant.Link==chapter.Link then allowed=true;break end end
    assert(allowed,'HentaiRead: chapter does not belong to the gallery')
    local html=request(chapter.Link)
    local total=tonumber(html:match('reader%(%{%s*total:%s*(%d+)'))
    assert(total and total>0 and total<=5000,'HentaiRead: reader metadata unavailable')
    local images,seen={},{}
    for tag in html:gmatch('<img%s[^>]*>') do
        local class=U.attr(tag,'class') or ''
        local src=U.attr(tag,'src')
        if class=='mx-auto' and src and src:match('^https://readimg%.site/galleries/') and not seen[src] then
            images[#images+1]=src;seen[src]=true
        end
    end
    assert(#images==total,'HentaiRead: incomplete reader page list')
    for _,url in ipairs(images) do dest[#dest+1]={URL=url} end
end

function P:loadChapterPage(page,dest)
    assert(type(page)=='table','HentaiRead: invalid page metadata')
    dest.Link=imageLink(page.URL)
end
