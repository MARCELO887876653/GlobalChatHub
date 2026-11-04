-- GLOBAL CHAT HUB V5.3 | FIREBASE AUTH + CREATOR DASHBOARD | Mobile-first
-- Canais separados: /global, /brasil, /usa. Salas por codigo em /rooms.
-- Script externo: nao substitui o filtro/privacidade do TextChatService Roblox.
-- Nao utilize para burlar restricoes de chat; ver README antes de publicar.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
if not player then return end

local store = _G
pcall(function()
    if type(getgenv) == "function" then store = getgenv() end
end)
if type(store.GCH_V5_Shutdown) == "function" then
    pcall(store.GCH_V5_Shutdown)
end

local state = {
    alive = true, active = "local", minimized = false,
    language = "pt", autoTranslate = false, sounds = false,
    sentAt = -100, messages = 0, errors = 0, unread = 0,
    lastError = "", privateChannel = nil, connections = {},
    blocked = {}, seen = {}, seenOrder = {}, tabs = {},
    currentInvite = nil, translationHits = 0, privateCode=nil,
    firebaseTransport="none", firebaseStatus="not_checked", firebaseError="",
    auth={idToken=nil,refreshToken=nil,uid=nil,expireAt=0,loading=false,status="aguardando"},
    roomGeneration=0, sentByTab={}, pendingSend={}, inviteLast=0,
    moderation={banned=false,muteUntil=0}, admin={token=nil,refreshToken=nil,uid=nil,expireAt=0,loginPending=false,reportSeen={},reports={},loading=false},
}
local MAX_MESSAGES = 50
local COLORS = {
    bg = Color3.fromRGB(12, 11, 29), panel = Color3.fromRGB(22, 20, 45),
    deep = Color3.fromRGB(16, 15, 34), accent = Color3.fromRGB(140, 91, 255),
    lilac = Color3.fromRGB(202, 180, 255), light = Color3.fromRGB(241, 236, 255),
    quiet = Color3.fromRGB(151, 142, 180), good = Color3.fromRGB(76, 194, 147),
    bad = Color3.fromRGB(232, 109, 119), gold = Color3.fromRGB(244, 195, 110)
}

local WORDS = {
    pt = {
        creatorTab="Criador", localTab="Local", globalTab="Global", brTab="Brasil", usTab="USA", privateTab="Privado", settingsTab="Ajustes", debugTab="Status",
        typeHere="Escreva sua mensagem...", send="ENVIAR", translate="🌐 Traduzir", original="Original", noTranslation="Tradução não fornecida pelo Roblox para esta mensagem.",
        enableTranslation="Mostrar tradução automática", sound="Sons de notificações", language="Idioma do menu", status="Estado do chat", channelMissing="Canal indisponível neste jogo.",
        localOnly="Mensagens filtradas pelo chat Roblox.", globalInfo="Chat mundial via Firebase: funciona entre jogos e servidores. Canal separado do Brasil e USA.",
        openNative="ABRIR CHAT ROBLOX", invite="Convidar jogador da partida", inviteButton="ENVIAR CONVITE", inviteWait="Aguardando convite ou canal privado...",
        accept="ACEITAR", refuse="RECUSAR", clear="LIMPAR MENSAGENS", copy="COPIAR DIAGNÓSTICO", mute="Ocultar", unmute="Mostrar",
        report="Denunciar: abra o menu do Roblox e use Denunciar.", noDirect="Crie uma sala por código e convide pelo nome do jogador, inclusive de outro jogo.",
        nativeMode="Chat integrado: a plataforma controla o conteúdo e a tradução das mensagens.", boot="Global Chat Hub V5 iniciado.",
        noSend="Não foi possível enviar. Confira as permissões de chat.", wait="Aguarde antes de enviar outra mensagem.",
        translationHint="Local: tradução do Roblox quando disponível. Firebase: tradução sob demanda usando serviço externo.",
    },
    en = {
        creatorTab="Creator", localTab="Local", globalTab="Global", brTab="Brazil", usTab="USA", privateTab="Private", settingsTab="Settings", debugTab="Status",
        typeHere="Type your message...", send="SEND", translate="🌐 Translate", original="Original", noTranslation="Roblox has not provided a translation for this message.",
        enableTranslation="Show translation automatically", sound="Notification sounds", language="Menu language", status="Chat status", channelMissing="Channel unavailable in this game.",
        localOnly="Messages filtered by Roblox chat.", globalInfo="Worldwide Firebase channel, across experiences and servers; separate from Brazil and USA.",
        openNative="OPEN ROBLOX CHAT", invite="Invite player in this server", inviteButton="SEND INVITE", inviteWait="Waiting for invite or private channel...",
        accept="ACCEPT", refuse="DECLINE", clear="CLEAR MESSAGES", copy="COPY DIAGNOSTICS", mute="Hide", unmute="Show",
        report="Report: open the Roblox menu and select Report.", noDirect="Create a code-based room and invite by username, even across different games.",
        nativeMode="Integrated chat: Roblox controls message content and translation.", boot="Global Chat Hub V5 started.",
        noSend="Message not sent. Check your chat permissions.", wait="Please wait before sending another message.",
        translationHint="Local: Roblox translation when available. Firebase: on-demand third-party translation.",
    },
    es = {
        creatorTab="Creador", localTab="Local", globalTab="Global", brTab="Brasil", usTab="EE.UU.", privateTab="Privado", settingsTab="Ajustes", debugTab="Estado",
        typeHere="Escribe tu mensaje...", send="ENVIAR", translate="🌐 Traducir", original="Original", noTranslation="Roblox no ha proporcionado una traducción de este mensaje.",
        enableTranslation="Mostrar traducción automáticamente", sound="Sonidos de notificación", language="Idioma del menú", status="Estado del chat", channelMissing="Canal no disponible en este juego.",
        localOnly="Mensajes filtrados por el chat de Roblox.", globalInfo="Canal mundial vía Firebase: entre juegos y servidores; separado de Brasil y USA.",
        openNative="ABRIR CHAT ROBLOX", invite="Invitar jugador de la partida", inviteButton="ENVIAR INVITACIÓN", inviteWait="Esperando invitación o canal privado...",
        accept="ACEPTAR", refuse="RECHAZAR", clear="BORRAR MENSAJES", copy="COPIAR DIAGNÓSTICO", mute="Ocultar", unmute="Mostrar",
        report="Denunciar: abre el menú de Roblox y elige Denunciar.", noDirect="Crea una sala con código e invita por nombre, incluso desde otros juegos.",
        nativeMode="Chat integrado: Roblox controla el contenido y las traducciones.", boot="Global Chat Hub V5 iniciado.",
        noSend="Mensaje no enviado. Revisa permisos de chat.", wait="Espera antes de enviar otro mensaje.",
        translationHint="Local: traducción Roblox disponible. Firebase: traducción externa a pedido.",
    },
}
local function tr(key)
    return (WORDS[state.language] or WORDS.pt)[key] or WORDS.pt[key] or key
end
local function connect(signal, handler)
    local c = signal:Connect(handler)
    table.insert(state.connections, c)
    return c
end
local function errorState(msg)
    state.errors = state.errors + 1
    state.lastError = tostring(msg):sub(1, 160)
    warn("[GCH V5] " .. state.lastError)
end
local function instance(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do obj[key] = value end
    if parent then obj.Parent = parent end
    return obj
end
local function corner(target, radius)
    instance("UICorner", {CornerRadius=UDim.new(0, radius or 10)}, target)
end
local function stroke(target, color, thickness)
    instance("UIStroke", {Color=color or COLORS.accent, Thickness=thickness or 1}, target)
end
local function lbl(parent, text, size, color, props)
    local p = {Text=text, TextSize=size or 13, TextColor3=color or COLORS.light,
        BackgroundTransparency=1, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        RichText=false, Size=UDim2.new(1, 0, 0, size and (size+12) or 25)}
    for k,v in pairs(props or {}) do p[k]=v end
    return instance("TextLabel", p, parent)
end
local function btn(parent, text, props)
    local p = {Text=text, TextSize=12, Font=Enum.Font.GothamBold,
        BackgroundColor3=COLORS.panel, TextColor3=COLORS.light, BorderSizePixel=0,
        AutoButtonColor=true, Size=UDim2.fromOffset(120, 34)}
    for k,v in pairs(props or {}) do p[k]=v end
    local b = instance("TextButton", p, parent)
    corner(b, 9)
    return b
end
local function makeList(parent, padding)
    return instance("UIListLayout", {Padding=UDim.new(0, padding or 7),
        SortOrder=Enum.SortOrder.LayoutOrder}, parent)
end
local function addPad(parent, n)
    instance("UIPadding", {PaddingLeft=UDim.new(0,n), PaddingRight=UDim.new(0,n),
        PaddingTop=UDim.new(0,n), PaddingBottom=UDim.new(0,n)}, parent)
end
-- O chat da partida usa o TextChatService. As demais abas usam Firebase.
local FIREBASE_URL = "https://globalchathub-2bd33-default-rtdb.firebaseio.com"
-- Chave WEB publica do projeto Firebase (nao e uma chave secreta). Configure no arquivo privado.
-- O PAINEL CRIADOR so opera apos login Firebase Auth E autorizacao pelas regras de seguranca.
-- Chave publica do aplicativo WEB mostrada no Firebase Console.
-- Caso a API responda API_KEY_INVALID, copie novamente em Configuracoes do projeto > Seus aplicativos.
local FIREBASE_WEB_API_KEY = "AIzaSyCS4CB6kebNufXTs5IJeOmvgA--Shs8rAc"
local function hasFirebaseAuthConfig()
    return FIREBASE_WEB_API_KEY:match("^AIza[%w_%-]+$") ~= nil and #FIREBASE_WEB_API_KEY >= 30
end
local currentGameName = tostring(game.Name or "Jogo")
local currentPlaceId = tonumber(game.PlaceId) or 0
local gameNames = {}
local gameWaiters = {}
local function resolveGameName(placeId, callback)
    placeId = tonumber(placeId)
    if not placeId or placeId < 1 then callback("Jogo nao identificado"); return end
    if gameNames[placeId] then callback(gameNames[placeId]); return end
    if gameWaiters[placeId] then
        table.insert(gameWaiters[placeId],callback)
        return
    end
    gameWaiters[placeId] = {callback}
    task.spawn(function()
        local label = "Jogo #"..tostring(placeId)
        local ok, details = pcall(function()
            return MarketplaceService:GetProductInfoAsync(placeId, Enum.InfoType.Asset)
        end)
        if ok and type(details)=="table" and type(details.Name)=="string" and details.Name~="" then
            label = details.Name:sub(1,72)
        end
        gameNames[placeId]=label
        local waiters=gameWaiters[placeId] or {}
        gameWaiters[placeId]=nil
        for _,cb in ipairs(waiters) do pcall(cb,label) end
    end)
end
gameNames[currentPlaceId]=currentGameName
if currentPlaceId>0 then
    task.spawn(function()
        local ok,d=pcall(function() return MarketplaceService:GetProductInfoAsync(currentPlaceId,Enum.InfoType.Asset) end)
        if ok and type(d)=="table" and type(d.Name)=="string" and d.Name~="" then
            currentGameName=d.Name:sub(1,72)
            gameNames[currentPlaceId]=currentGameName
        end
    end)
end
local POLL_SECONDS = 3
local PRESENCE_SECONDS = 15
local CHANNEL_PATHS = { global="global", brasil="brasil", usa="usa" }
local function findChannel(name)
    local found = TextChatService:FindFirstChild(name, true)
    if found and found:IsA("TextChannel") then return found end
end
local function getChannel(key)
    if key=="local" then return findChannel("RBXGeneral") end
    return nil
end

local function httpRequest(options)
    local methods = {
        {"request", function() return request end},
        {"syn.request", function() return syn and syn.request end},
        {"http_request", function() return http_request end},
        {"http.request", function() return http and http.request end},
        {"fluxus.request", function() return fluxus and fluxus.request end},
    }
    local lastError="HTTP request unavailable"
    for _,item in ipairs(methods) do
        local ok,fn=pcall(item[2])
        if ok and type(fn)=="function" then
            local success,res=pcall(fn,options)
            if success and type(res)=="table" then
                local status=tonumber(res.StatusCode or res.status_code or res.Status) or 0
                state.firebaseTransport=item[1]
                -- Nunca adivinhar status 200 quando executor nao devolve codigo.
                return {status=status,body=tostring(res.Body or res.body or ""),
                    success=status>=200 and status<300}
            elseif not success then
                lastError=tostring(res)
            end
        end
    end
    local success,res=pcall(function()
        return Http:RequestAsync(options)
    end)
    if success and type(res)=="table" then
        local status=tonumber(res.StatusCode) or 0
        state.firebaseTransport="HttpService.RequestAsync"
        return {status=status,body=tostring(res.Body or ""),
            success=status>=200 and status<300}
    end
    if not success then lastError=tostring(res) end
    return nil,lastError
end
-- Autenticacao individual, persistindo apenas o refresh token se o executor permitir.
-- O UID Firebase e o identificador verificavel nas regras; o Roblox UID e apenas declarativo.
local AUTH_FILE = "GlobalChatHub_V53_anon_auth.json"
local function decodeJson(raw)
    local ok, data = pcall(function() return Http:JSONDecode(raw) end)
    return ok and type(data)=="table" and data or nil
end
local function storeRefresh(uid,refresh)
    if type(writefile) ~= "function" then return end
    pcall(function() writefile(AUTH_FILE,Http:JSONEncode({uid=uid,refresh=refresh})) end)
end
local function readRefresh()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok,exists=pcall(isfile,AUTH_FILE)
    if not ok or not exists then return nil end
    local readOK,data=pcall(readfile,AUTH_FILE)
    if not readOK then return nil end
    local parsed=decodeJson(data)
    return parsed and type(parsed.refresh)=="string" and parsed.refresh or nil
end
local function refreshAnonymous(oldRefresh)
    local url="https://securetoken.googleapis.com/v1/token?key="..Http:UrlEncode(FIREBASE_WEB_API_KEY)
    local data="grant_type=refresh_token&refresh_token="..Http:UrlEncode(oldRefresh)
    local response,err=httpRequest({Url=url,Method="POST",Headers={
        ["Content-Type"]="application/x-www-form-urlencoded"},Body=data})
    if not response then return nil,err end
    if not response.success then return nil,"Refresh HTTP "..tostring(response.status).." "..response.body:sub(1,110) end
    local parsed=decodeJson(response.body)
    if not parsed or type(parsed.id_token)~="string" or type(parsed.user_id)~="string" then
        return nil,"Refresh invalido" end
    return {idToken=parsed.id_token,refreshToken=parsed.refresh_token or oldRefresh,
        localId=parsed.user_id,expiresIn=parsed.expires_in},nil
end
local function newAnonymous()
    local url="https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="..Http:UrlEncode(FIREBASE_WEB_API_KEY)
    local response,err=httpRequest({Url=url,Method="POST",Headers={
        ["Content-Type"]="application/json"},Body='{"returnSecureToken":true}'})
    if not response then return nil,err end
    if not response.success then return nil,"Login anonimo HTTP "..tostring(response.status).." "..response.body:sub(1,120) end
    local parsed=decodeJson(response.body)
    if not parsed or type(parsed.idToken)~="string" or type(parsed.localId)~="string"
        or type(parsed.refreshToken)~="string" then return nil,"Login anonimo sem token" end
    return parsed,nil
end
local function playerToken()
    local a=state.auth
    if a.idToken and os.time()<a.expireAt-120 then return a.idToken end
    if not hasFirebaseAuthConfig() then return nil,"Web API Key invalida" end
    if a.loading then
        for _=1,100 do
            if not a.loading then break end
            task.wait(0.15)
        end
        if a.idToken and os.time()<a.expireAt-60 then return a.idToken end
        if a.loading then return nil,"Autenticacao em andamento" end
    end
    a.loading=true
    a.status="autenticando"
    local refresh = a.refreshToken or readRefresh()
    local data,err
    if refresh then data,err=refreshAnonymous(refresh) end
    if not data then data,err=newAnonymous() end
    a.loading=false
    if not data then
        a.status="falhou: "..tostring(err):sub(1,90)
        return nil,a.status
    end
    a.idToken=data.idToken;a.refreshToken=data.refreshToken;a.uid=data.localId
    a.expireAt=os.time()+(tonumber(data.expiresIn) or 3600)
    a.status="autenticado"
    storeRefresh(a.uid,a.refreshToken)
    return a.idToken
end
local function fbRequest(method,path,payload,authToken)
    if not authToken then
        local err
        authToken,err=playerToken()
        if not authToken then return nil,err end
    end
    local options={
        Url=FIREBASE_URL..path..((path:find("?",1,true) and "&" or "?").."auth="..Http:UrlEncode(authToken)),
        Method=method,
        Headers={ ["Content-Type"]="application/json" },
    }
    if payload~=nil then
        local ok,json=pcall(function() return Http:JSONEncode(payload) end)
        if not ok then return nil,"JSON encode failed" end
        options.Body=json
    end
    local r,networkErr=httpRequest(options)
    if not r then
        state.firebaseStatus="offline"
        state.firebaseError=tostring(networkErr):sub(1,160)
        return nil,state.firebaseError
    end
    state.firebaseStatus=tostring(r.status)
    if not r.success then
        local reason="HTTP "..tostring(r.status).." "..r.body:sub(1,130)
        state.firebaseError=reason
        return nil,reason
    end
    state.firebaseError=""
    if r.body=="" or r.body=="null" then return {},nil end
    local ok,decoded=pcall(function() return Http:JSONDecode(r.body) end)
    if not ok then return nil,"Resposta JSON invalida" end
    return decoded,nil
end
local function fbGet(path,token) return fbRequest("GET",path,nil,token) end
local function fbPost(path,data,token) return fbRequest("POST",path,data,token) end
local function fbPut(path,data,token) return fbRequest("PUT",path,data,token) end
local function fbPatch(path,data,token) return fbRequest("PATCH",path,data,token) end
local function fbDel(path,token) return fbRequest("DELETE",path,nil,token) end
local function fbList(channel)
    -- Consultas por chave sao ordenadas pelo Firebase.
    return fbGet("/"..channel..'.json?orderBy="$key"&limitToLast='..tostring(MAX_MESSAGES))
end
local function cleanUser(s)
    return tostring(s or ""):gsub("[^%w%-_]","_")
end
local function codeValid(code)
    return type(code)=="string" and #code>=4 and #code<=12 and code:match("^[A-Z0-9]+$")~=nil
end
local function randomCode()
    local alphabet="ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local out={}
    for i=1,8 do
        local k=math.random(1,#alphabet)
        out[i]=alphabet:sub(k,k)
    end
    return table.concat(out)
end
local function trimText(s)
    if type(s)~="string" then return "" end
    return (s:match("^%s*(.-)%s*$") or "")
end
local function translateExternal(text,source,target)
    -- Somente apos acao explicita no botao Traduzir.
    if not ({pt=true,en=true,es=true})[source] then return nil,"Idioma de origem desconhecido" end
    if not ({pt=true,en=true,es=true})[target] then return nil,"Idioma de destino invalido" end
    if source==target then return text,nil end
    local query=text:sub(1,490)
    local url="https://api.mymemory.translated.net/get?q="..Http:UrlEncode(query)
       .."&langpair="..source.."%7C"..target
    local response,err=httpRequest({Url=url,Method="GET"})
    if not response then return nil,err end
    if not response.success then return nil,"Tradutor HTTP "..tostring(response.status) end
    local ok,json=pcall(function() return Http:JSONDecode(response.body) end)
    if not ok or type(json)~="table" then return nil,"Traducao indisponivel" end
    local result=json.responseData and json.responseData.translatedText
    if type(result)~="string" or result=="" then return nil,"Sem traducao" end
    return result,nil
end


local function firebaseAuthEmail(email,password)
    if not hasFirebaseAuthConfig() then return nil,"Configure FIREBASE_WEB_API_KEY no arquivo Lua" end
    local url="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="..Http:UrlEncode(FIREBASE_WEB_API_KEY)
    local json=Http:JSONEncode({email=email,password=password,returnSecureToken=true})
    local res,err=httpRequest({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json})
    if not res then return nil,err end
    if not res.success then return nil,"Login recusado (HTTP "..tostring(res.status)..")" end
    local ok,data=pcall(function() return Http:JSONDecode(res.body) end)
    if not ok or type(data)~="table" or type(data.idToken)~="string" then return nil,"Resposta de login invalida" end
    return data,nil
end
local function refreshAdminAuth()
    local a=state.admin
    if not a.refreshToken or not hasFirebaseAuthConfig() then return false end
    local payload="grant_type=refresh_token&refresh_token="..Http:UrlEncode(a.refreshToken)
    local url="https://securetoken.googleapis.com/v1/token?key="..Http:UrlEncode(FIREBASE_WEB_API_KEY)
    local res=httpRequest({Url=url,Method="POST",Headers={["Content-Type"]="application/x-www-form-urlencoded"},Body=payload})
    if not res or not res.success then a.token=nil;return false end
    local ok,data=pcall(function() return Http:JSONDecode(res.body) end)
    if not ok or type(data)~="table" or type(data.id_token)~="string" then a.token=nil;return false end
    a.token=data.id_token
    a.refreshToken=data.refresh_token or a.refreshToken
    a.expireAt=os.time()+(tonumber(data.expires_in) or 3600)
    return true
end
local function adminToken()
    if not state.admin.token then return nil end
    if os.time() >= state.admin.expireAt-120 then
        if not refreshAdminAuth() then return nil end
    end
    return state.admin.token
end
local function openedNative()
    local ok=pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,true)
    end)
    if not ok then warn("[GCH V5] Abra o chat nativo pela interface do Roblox") end
end

pcall(function()
    local old=game:GetService("CoreGui"):FindFirstChild("GlobalChatHubV5")
    if old then old:Destroy() end
end)
local oldGui=player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("GlobalChatHub")
if oldGui then pcall(function() oldGui:Destroy() end) end
local gui = instance("ScreenGui", {Name="GlobalChatHubV5", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=900, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local attachOK=pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not attachOK then gui.Parent=player:WaitForChild("PlayerGui") end

local camera=workspace.CurrentCamera
local viewport=camera and camera.ViewportSize or Vector2.new(390,800)
local touch=UserInputService.TouchEnabled
local width = math.floor(math.min((touch and viewport.X*0.92 or 460), 470))
local height = math.floor(math.min((touch and viewport.Y*0.76 or 520), 550))
width=math.max(250,width); height=math.max(310,height)
local main=instance("Frame",{Name="Window", BackgroundColor3=COLORS.bg, BorderSizePixel=0,
    Size=UDim2.fromOffset(width,height), AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5), ClipsDescendants=true},gui)
corner(main,16); stroke(main, COLORS.accent,1.5)
local top=instance("Frame", {Size=UDim2.new(1,0,0,51), BackgroundColor3=COLORS.panel,BorderSizePixel=0},main)
instance("UIGradient", {Color=ColorSequence.new(COLORS.accent, COLORS.panel),Rotation=5},top)
local heading=lbl(top,"💬 GLOBAL CHAT HUB",15,COLORS.light,{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-125,0,24),Font=Enum.Font.GothamBold})
local sub=lbl(top,"V5.3  •  Firebase Auth  •  Mobile",10,COLORS.lilac,{Position=UDim2.fromOffset(12,29),Size=UDim2.new(1,-125,0,17)})
local minBtn=btn(top,"−",{Size=UDim2.fromOffset(34,30),Position=UDim2.new(1,-78,0,10),BackgroundColor3=COLORS.accent,TextSize=19})
local closeBtn=btn(top,"×",{Size=UDim2.fromOffset(34,30),Position=UDim2.new(1,-39,0,10),BackgroundColor3=COLORS.bad,TextSize=18})
local bar=instance("Frame",{Position=UDim2.fromOffset(0,51),Size=UDim2.new(0,72,1,-77),BackgroundColor3=COLORS.deep,BorderSizePixel=0},main)
local buttonsHolder=instance("ScrollingFrame",{Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(0,0)},bar)
makeList(buttonsHolder,5); addPad(buttonsHolder,6)
local content=instance("Frame",{Position=UDim2.fromOffset(76,57),Size=UDim2.new(1,-83,1,-89),BackgroundTransparency=1,ClipsDescendants=true},main)
local statusBar=lbl(main,"🟣  Firebase • três canais independentes",10,COLORS.good,
    {Position=UDim2.new(0,13,1,-23),Size=UDim2.new(1,-24,0,19)})
local bubble=btn(gui,"💬",{Size=UDim2.fromOffset(53,53),Position=UDim2.new(0,12,.46,0),
    BackgroundColor3=COLORS.accent,TextSize=22,Visible=false})
corner(bubble,25); stroke(bubble,COLORS.lilac,2)
local badge=lbl(bubble,"",10,COLORS.light,{Position=UDim2.new(1,-19,0,-7),Size=UDim2.fromOffset(22,20),
    BackgroundColor3=COLORS.bad,BackgroundTransparency=0,TextXAlignment=Enum.TextXAlignment.Center,Visible=false})
corner(badge,10)

local tabDefs={
    {key="local",icon="💬",label="localTab"},
    {key="global",icon="🌍",label="globalTab"},
    {key="brasil",icon="🇧🇷",label="brTab"},
    {key="usa",icon="🇺🇸",label="usTab"},
    {key="privado",icon="🔒",label="privateTab"},
    {key="ajustes",icon="⚙️",label="settingsTab"},
    {key="debug",icon="🔍",label="debugTab"},
    {key="criador",icon="👑",label="creatorTab"},
}
local messageTabs={["local"]=true, global=true, brasil=true, usa=true, privado=true}
local retranslateUI=function() end
local refreshStatus=function() end
local selected=function() end

local function toast(message, positive)
    if not state.alive then return end
    statusBar.Text=(positive and "✅  " or "⚠️  ") .. tostring(message)
    statusBar.TextColor3=positive and COLORS.good or COLORS.gold
    if not positive then state.lastError=tostring(message):sub(1,100) end
end

local function newMessagePanel(key)
    local frame=instance("Frame",{Name=key,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},content)
    local title=lbl(frame,"",14,COLORS.light,{Size=UDim2.new(1,-3,0,22),Font=Enum.Font.GothamBold})
    local hint=lbl(frame,"",10,COLORS.quiet,{Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,-2,0,28)})
    local scroll=instance("ScrollingFrame",{Name="Messages",Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-114),
        BackgroundColor3=COLORS.deep,BorderSizePixel=0,ScrollBarThickness=2,
        ScrollBarImageColor3=COLORS.accent,CanvasSize=UDim2.fromOffset(0,0)},frame)
    corner(scroll,10)
    local layout=makeList(scroll,7); addPad(scroll,7)
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
        if not state.alive then return end
        local h=layout.AbsoluteContentSize.Y+18
        scroll.CanvasSize=UDim2.fromOffset(0,h)
        scroll.CanvasPosition=Vector2.new(0,math.max(0,h-scroll.AbsoluteSize.Y))
    end)
    local input=instance("TextBox",{Name="Input",Position=UDim2.new(0,0,1,-47),
        Size=UDim2.new(1,-75,0,40),BackgroundColor3=COLORS.panel,BorderSizePixel=0,
        TextColor3=COLORS.light,PlaceholderColor3=COLORS.quiet,
        Text="",TextSize=12,Font=Enum.Font.Gotham,
        ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,MultiLine=false},frame)
    corner(input,9)
    local send=btn(frame,"ENVIAR",{Position=UDim2.new(1,-70,1,-47),Size=UDim2.fromOffset(70,40),BackgroundColor3=COLORS.accent})
    local tab={frame=frame,title=title,hint=hint,scroll=scroll,layout=layout,input=input,send=send,
        count=0,entries={},channel=key}
    if key=="privado" then
        title.Text="🔒 Privado (Firebase)"
        local control=instance("Frame",{Name="RoomControls",Position=UDim2.fromOffset(0,50),
            Size=UDim2.new(1,0,0,105),BackgroundTransparency=1},frame)
        local createBtn=btn(control,"✨ CRIAR SALA",{Size=UDim2.new(.48,-3,0,30),
            BackgroundColor3=COLORS.accent,TextSize=10})
        local roomCode=instance("TextBox",{Position=UDim2.new(.49,0,0,0),
            Size=UDim2.new(.30,-3,0,30),BackgroundColor3=COLORS.panel,BorderSizePixel=0,
            TextColor3=COLORS.light,PlaceholderText="Código",Text="",TextSize=11,
            ClearTextOnFocus=false,Font=Enum.Font.Gotham},control)
        corner(roomCode,8)
        local joinBtn=btn(control,"ENTRAR",{Position=UDim2.new(.79,0,0,0),
            Size=UDim2.new(.21,0,0,30),BackgroundColor3=COLORS.good,TextSize=10})
        local recipient=instance("TextBox",{Position=UDim2.fromOffset(0,36),
            Size=UDim2.new(1,-92,0,31),BackgroundColor3=COLORS.panel,
            TextColor3=COLORS.light,PlaceholderColor3=COLORS.quiet,
            PlaceholderText="Usuário a convidar (qualquer jogo)",
            Text="",TextSize=10,Font=Enum.Font.Gotham,ClearTextOnFocus=false},control)
        corner(recipient,8)
        local inviteBtn=btn(control,"CONVIDAR",{Position=UDim2.new(1,-88,0,36),
            Size=UDim2.fromOffset(88,31),BackgroundColor3=COLORS.accent,TextSize=10})
        local roomStatus=lbl(control,"🔒 Nenhuma sala ativa",10,COLORS.quiet,
            {Position=UDim2.fromOffset(0,71),Size=UDim2.new(1,0,0,25)})
        tab.recipient=recipient;tab.inviteBtn=inviteBtn;tab.createBtn=createBtn
        tab.joinBtn=joinBtn;tab.roomCode=roomCode;tab.roomStatus=roomStatus
        scroll.Position=UDim2.fromOffset(0,159)
        scroll.Size=UDim2.new(1,0,1,-215)
    end


    state.tabs[key]=tab
    return tab
end
for _,d in ipairs(tabDefs) do
    if messageTabs[d.key] then newMessagePanel(d.key) end
end

local function plainMessage(key, message)
    local p=state.tabs[key]
    if not p then return end
    p.count=p.count+1
    local line=lbl(p.scroll,message,11,COLORS.gold,{AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,-10,0,0),LayoutOrder=p.count,TextWrapped=true})
    table.insert(p.entries,line)
    if #p.entries>MAX_MESSAGES then
        local old=table.remove(p.entries,1); if old then old:Destroy() end
    end
end

local function addMessage(key, uid, username, text, translated, messageId, sourceLang, gameTitle, placeId, authorAuthUid)
    if not state.alive or text=="" or state.blocked[uid] then return end
    local p=state.tabs[key]; if not p then return end
    if messageId and messageId~="" then
        local mark=key.."/"..tostring(messageId)
        if state.seen[mark] then return end
        state.seen[mark]=true
        table.insert(state.seenOrder,mark)
        if #state.seenOrder>400 then
            state.seen[table.remove(state.seenOrder,1)]=nil
        end
    end
    state.messages=state.messages+1
    p.count=p.count+1
    local row=instance("Frame",{Name="Message",BackgroundColor3=(uid==player.UserId and COLORS.panel or COLORS.deep),
        BorderSizePixel=0,Size=UDim2.new(1,-9,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=p.count},p.scroll)
    corner(row,9); addPad(row,7)
    local column=makeList(row,3)
    local namelabel=lbl(row,(uid==player.UserId and "★ " or "")..username,11,
        uid==player.UserId and COLORS.gold or COLORS.lilac,{Size=UDim2.new(1,-12,0,16),Font=Enum.Font.GothamBold})
    local gameLabel=lbl(row,"🎮 Jogando: "..(gameTitle and tostring(gameTitle)~="" and tostring(gameTitle) or "Identificando..."),10,COLORS.quiet,
        {Size=UDim2.new(1,-12,0,16),TextTruncate=Enum.TextTruncate.AtEnd})
    local targetPlace=tonumber(placeId or gameTitle)
    if targetPlace and targetPlace>0 then
        resolveGameName(targetPlace,function(label)
            if gameLabel.Parent then gameLabel.Text="🎮 Jogando: "..label end
        end)
    elseif not gameTitle or tostring(gameTitle)=="" then
        gameLabel.Text="🎮 Jogo nao informado"
    end
    local messageLabel=lbl(row,text,12,COLORS.light,{Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
    local actualTranslation=translated and tostring(translated) or ""
    local showingTranslation=false
    local translationButton=btn(row,tr("translate"),{Size=UDim2.new(1,-10,0,25),BackgroundColor3=COLORS.panel,
        TextColor3=COLORS.lilac,TextSize=10})
    if state.autoTranslate and actualTranslation~="" then
        messageLabel.Text=actualTranslation;showingTranslation=true;translationButton.Text=tr("original")
        state.translationHits=state.translationHits+1
    end
    local translating=false
    translationButton.MouseButton1Click:Connect(function()
        if actualTranslation~="" then
            showingTranslation=not showingTranslation
            messageLabel.Text=showingTranslation and actualTranslation or text
            translationButton.Text=showingTranslation and tr("original") or tr("translate")
            return
        end
        if key=="local" then toast(tr("noTranslation"),false);return end
        if translating then return end
        local target=state.language
        local source=sourceLang
        if source~="pt" and source~="en" and source~="es" then
            source=key=="brasil" and "pt" or key=="usa" and "en" or (target=="en" and "pt" or "en")
        end
        if target==source then toast("Mensagem ja esta no idioma selecionado",true);return end
        translating=true;translationButton.Text="⏳ Traduzindo..."
        task.spawn(function()
            local result,err=translateExternal(text,source,target)
            translating=false
            if not state.alive or not translationButton.Parent then return end
            if result then
                actualTranslation=result;showingTranslation=true
                messageLabel.Text=result;translationButton.Text=tr("original")
                state.translationHits=state.translationHits+1
            else
                translationButton.Text=tr("translate")
                toast("Tradução indisponível: "..tostring(err),false)
            end
        end)
    end)
    if uid~=player.UserId and uid>0 then
        if key~="local" then
            local reportButton=btn(row,"🚨 Registrar denúncia",{
                Size=UDim2.new(1,-10,0,24),BackgroundColor3=COLORS.panel,
                TextColor3=COLORS.gold,TextSize=10})
            local reasonIndex=1
            local reasons={"Ofensa", "Spam", "Assedio", "Outro"}
            local reasonButton=btn(row,"Motivo: "..reasons[reasonIndex].."  • toque para mudar",{
                Size=UDim2.new(1,-10,0,22),BackgroundColor3=COLORS.panel,
                TextColor3=COLORS.quiet,TextSize=10})
            reasonButton.MouseButton1Click:Connect(function()
                reasonIndex=(reasonIndex%#reasons)+1
                reasonButton.Text="Motivo: "..reasons[reasonIndex].."  • toque para mudar"
            end)
            local reported=false
            reportButton.MouseButton1Click:Connect(function()
                if reported then return end
                reported=true
                reportButton.Text="⏳ Registrando..."
                task.spawn(function()
                    local result,err=fbPost("/reports.json",{
                        reporter=player.Name,reporterUid=player.UserId,
                        reporterAuthUid=state.auth.uid or "",
                        reported=username,reportedUid=uid,
                        reportedAuthUid=tostring(authorAuthUid or ""),
                        channel=key,ts=os.time(),messageId=tostring(messageId or ""),
                        message=tostring(text):sub(1,400),reason=reasons[reasonIndex],
                        game=tostring(gameTitle or ""):sub(1,72),placeId=tonumber(placeId) or 0,
                        roomCode=key=="privado" and tostring(state.privateCode or "") or "",
                        status="pending"
                    })
                    if not state.alive or not reportButton.Parent then return end
                    if result then
                        reportButton.Text="✔ Denúncia registrada"
                    else
                        reported=false;reportButton.Text="🚨 Registrar denúncia"
                        toast("Erro no registro: "..tostring(err),false)
                    end
                end)
            end)
        end
        local hideButton=btn(row,tr("mute").." • "..username,{Size=UDim2.new(1,-10,0,24),
            BackgroundColor3=COLORS.panel,TextColor3=COLORS.quiet,TextSize=10})
        hideButton.MouseButton1Click:Connect(function()
            state.blocked[uid]=true
            toast(username..": oculto nesta interface",true)
            -- UI-only mute, not a platform-level block.
        end)
    end
    table.insert(p.entries,row)
    if #p.entries>MAX_MESSAGES then
        local old=table.remove(p.entries,1); if old then old:Destroy() end
    end
    if state.active~=key or state.minimized then
        state.unread=state.unread+1
        badge.Visible=true;badge.Text=state.unread>9 and "9+" or tostring(state.unread)
    end
end

local settings=instance("ScrollingFrame",{Name="Settings",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
addPad(settings,8);makeList(settings,10)
local settingsTitle=lbl(settings,"⚙️ AJUSTES",16,COLORS.light,{Font=Enum.Font.GothamBold})
local languageButton=btn(settings,"🌐 PT / EN / ES",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local transButton=btn(settings,"🌐 Mostrar tradução: OFF",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local translationNote=lbl(settings,"",11,COLORS.quiet,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y})
local creatorEntry=btn(settings,"👑 ENTRAR NA AREA DO CRIADOR",{
    Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local soundsButton=btn(settings,"🔕 Sons: OFF",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local nativeButton=btn(settings,"ABRIR CHAT ROBLOX",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local clearButton=btn(settings,"LIMPAR MENSAGENS",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local settingsNotice=lbl(settings,"⚠️ Firebase é externo: mensagens NÃO passam automaticamente pelo filtro Roblox. Não compartilhe dados pessoais.",11,COLORS.good,
    {Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y})

local debugPanel=instance("ScrollingFrame",{Name="Debug",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
addPad(debugPanel,8); makeList(debugPanel,11)
local debugTitle=lbl(debugPanel,"🔍 DIAGNÓSTICO",15,COLORS.lilac,{Font=Enum.Font.GothamBold})
local info=lbl(debugPanel,"",11,COLORS.light,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y})
local copyButton=btn(debugPanel,"COPIAR DIAGNÓSTICO",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local reportInfo=lbl(debugPanel,"",11,COLORS.quiet,{AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-8,0,0)})

-- Painel do criador: a interface nao concede permissao. Regras Firebase autorizam cada operacao.
local creator=instance("Frame",{Name="Creator",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},content)
local creatorHead=lbl(creator,"👑 PAINEL DO CRIADOR",14,COLORS.lilac,
    {Size=UDim2.new(1,0,0,23),Font=Enum.Font.GothamBold})
local creatorHint=lbl(creator,"Entre com a conta Firebase Auth autorizada nas regras.",10,COLORS.quiet,
    {Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,0,0,38)})
local creatorLogin=instance("Frame",{Name="Login",Position=UDim2.fromOffset(0,65),
    Size=UDim2.new(1,0,0,150),BackgroundTransparency=1},creator)
local creatorEmail=instance("TextBox",{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,36),
    Text="",PlaceholderText="Email do administrador Firebase",ClearTextOnFocus=false,
    TextSize=11,Font=Enum.Font.Gotham,TextColor3=COLORS.light,
    BackgroundColor3=COLORS.panel},creatorLogin)
corner(creatorEmail,8)
local creatorPassword=instance("TextBox",{Position=UDim2.fromOffset(0,43),Size=UDim2.new(1,0,0,36),
    Text="",PlaceholderText="Senha (nao salva)",ClearTextOnFocus=false,
    TextSize=11,Font=Enum.Font.Gotham,TextColor3=COLORS.light,
    BackgroundColor3=COLORS.panel},creatorLogin)
corner(creatorPassword,8)
creatorPassword.TextTransparency=1 -- evita exibir senha em texto legivel
local creatorMask=lbl(creatorLogin,"",12,COLORS.light,{
    Position=UDim2.fromOffset(9,49),Size=UDim2.new(1,-18,0,24)})
connect(creatorPassword:GetPropertyChangedSignal("Text"),function()
    local length=#creatorPassword.Text
    creatorMask.Text=length>0 and string.rep("•",math.min(length,28)) or ""
end)
local creatorLoginBtn=btn(creatorLogin,"🔐 LOGIN SEGURO",{Position=UDim2.fromOffset(0,87),
    Size=UDim2.new(1,0,0,37),BackgroundColor3=COLORS.accent,TextSize=11})
local creatorDashboard=instance("Frame",{Name="ModDashboard",Position=UDim2.fromOffset(0,63),
    Size=UDim2.new(1,0,1,-65),BackgroundTransparency=1,Visible=false},creator)
local creatorRefresh=btn(creatorDashboard,"🔄 ATUALIZAR",{Position=UDim2.fromOffset(0,0),
    Size=UDim2.new(.65,-3,0,33),BackgroundColor3=COLORS.accent,TextSize=10})
local creatorLogout=btn(creatorDashboard,"SAIR",{Position=UDim2.new(.65,3,0,0),
    Size=UDim2.new(.35,-3,0,33),BackgroundColor3=COLORS.bad,TextSize=10})
local creatorReportScroll=instance("ScrollingFrame",{Position=UDim2.fromOffset(0,42),
    Size=UDim2.new(1,0,1,-43),CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,
    BackgroundColor3=COLORS.deep,BorderSizePixel=0},creatorDashboard)
corner(creatorReportScroll,9)
makeList(creatorReportScroll,8);addPad(creatorReportScroll,7)

local tabButtons={}
for _,def in ipairs(tabDefs) do
    local tab=btn(buttonsHolder,def.icon.."\n"..tr(def.label),{Name=def.key,Size=UDim2.new(1,-4,0,52),
        BackgroundColor3=COLORS.panel,TextSize=10,TextWrapped=true})
    tabButtons[def.key]={button=tab,definition=def}
    if def.key=="criador" then tab.Visible=false end
    connect(tab.MouseButton1Click,function() selected(def.key) end)
end

local function updateLabels()
    for _,p in pairs(tabButtons) do
        p.button.Text=p.definition.icon.."\n"..tr(p.definition.label)
    end
    for k,tab in pairs(state.tabs) do
        local word={["local"]="localTab",global="globalTab",brasil="brTab",usa="usTab",privado="privateTab"}
        tab.title.Text=(k=="local" and "💬 " or "🌐 ")..tr(word[k])
        tab.hint.Text=k=="global" and tr("globalInfo") or (k=="local" and tr("localOnly") or
            (k=="privado" and (state.privateCode and ("Sala "..state.privateCode.." • Firebase") or "Sala privada por código • Firebase") or
                (k=="brasil" and "🇧🇷 Chat brasileiro entre todos os jogos" or "🇺🇸 English chat across all games")))
        tab.input.PlaceholderText=tr("typeHere")
        tab.send.Text=tr("send")
        if tab.inviteBtn then tab.inviteBtn.Text=tr("inviteButton") end
    end
    settingsTitle.Text="⚙️ "..tr("settingsTab")
    creatorEntry.Text=state.admin.token and "👑 ABRIR PAINEL DO CRIADOR" or "👑 ENTRAR NA AREA DO CRIADOR"
    languageButton.Text="🌐 "..tr("language").." : "..string.upper(state.language)
    transButton.Text=(state.autoTranslate and "✅  " or "⬜  ")..tr("enableTranslation")
    soundsButton.Text=(state.sounds and "🔔  " or "🔕  ")..tr("sound")
    translationNote.Text=tr("translationHint")
    nativeButton.Text="📡 TESTAR CONEXÃO FIREBASE"
    clearButton.Text=tr("clear")
    debugTitle.Text="🔍 "..tr("debugTab")
    copyButton.Text=tr("copy")
    reportInfo.Text="⚠️ Firebase nao filtra automaticamente mensagens como o Roblox.\n"..tr("report")
end
retranslateUI=updateLabels

selected=function(key)
    state.active=key
    state.unread=0;badge.Visible=false
    for k,p in pairs(state.tabs) do p.frame.Visible=(k==key) end
    settings.Visible=(key=="ajustes");debugPanel.Visible=(key=="debug");creator.Visible=(key=="criador")
    for k,p in pairs(tabButtons) do
        p.button.BackgroundColor3=(key==k) and COLORS.accent or COLORS.panel
    end
    if messageTabs[key] then
        if key=="local" then
            toast(tr("localOnly"),true)
        elseif key=="privado" then
            toast(state.privateCode and ("🔒 Sala "..state.privateCode) or "Crie ou entre em uma sala privada",true)
        else
            toast("🌎 Firebase /"..tostring(CHANNEL_PATHS[key]),true)
        end
    end
    refreshStatus()
end

refreshStatus=function()
    local lines={
        "GlobalChatHub V5.3 | FIREBASE AUTH REST + CREATOR",
        "PlaceId="..tostring(game.PlaceId),
        "Transport="..state.firebaseTransport,
        "FirebaseHTTP="..state.firebaseStatus,
        "AuthStatus="..state.auth.status,
        "AuthReady="..tostring(state.auth.uid~=nil),
        "FirebaseError="..state.firebaseError,
        "Channels=global,brasil,usa (independentes)",
        "ActiveTab="..state.active,
        "PrivateRoom="..tostring(state.privateCode or "none"),
        "Messages="..state.messages,
        "Translations="..state.translationHits,
        "Errors="..state.errors,
        "LastError="..state.lastError,
        "LocalNative="..tostring(getChannel("local")~=nil),
        "CreatorConfigured="..tostring(hasFirebaseAuthConfig()),
        "AdminLogged="..tostring(state.admin.token~=nil),
        "Moderation="..(state.moderation.banned and "BANNED" or "active").." / muteUntil="..tostring(state.moderation.muteUntil),
        "Aviso: Firebase nao aplica filtros nem permissoes Roblox automaticamente.",
    }
    info.Text=table.concat(lines,"\n")
    return info.Text
end



connect(creatorEntry.MouseButton1Click,function()
    selected("criador")
end)
connect(languageButton.MouseButton1Click,function()
    state.language=(state.language=="pt" and "en" or state.language=="en" and "es" or "pt")
    retranslateUI();refreshStatus()
end)
connect(transButton.MouseButton1Click,function()
    state.autoTranslate=not state.autoTranslate
    retranslateUI();toast(tr("translationHint"),true)
end)
connect(soundsButton.MouseButton1Click,function()
    state.sounds=not state.sounds;retranslateUI()
end)
connect(nativeButton.MouseButton1Click,function()
    toast("Testando Firebase...",true)
    task.spawn(function()
        local data,err=fbGet("/ping.json")
        if not state.alive then return end
        if data~=nil then toast("✅ Firebase respondeu HTTP "..state.firebaseStatus,true)
        else toast("❌ Firebase: "..tostring(err),false) end
        refreshStatus()
    end)
end)
connect(clearButton.MouseButton1Click,function()
    for _,tab in pairs(state.tabs) do
        for _,entry in ipairs(tab.entries) do pcall(function() entry:Destroy() end) end
        tab.entries={}
    end
    toast("Histórico local limpo",true)
end)
connect(copyButton.MouseButton1Click,function()
    local value=refreshStatus()
    if type(setclipboard)=="function" then
        local ok=pcall(setclipboard,value)
        toast(ok and "Diagnóstico copiado" or "Não foi possível copiar",ok)
    else
        print(value);toast("Diagnóstico no console",true)
    end
end)

local function checkMyModeration()
    local token,authErr=playerToken()
    if not token or not state.auth.uid then return false,authErr end
    local value,err=fbGet("/moderationAuth/"..state.auth.uid..".json",token)
    if type(value)=="table" then
        state.moderation.banned=value.banned==true
        state.moderation.muteUntil=tonumber(value.muteUntil) or 0
        return true
    end
    return false,err
end
local function isModerated()
    if state.moderation.banned then return true,"Voce esta banido do Global Chat Hub" end
    local left=state.moderation.muteUntil-os.time()
    if left>0 then return true,"Voce esta mutado por mais "..tostring(math.ceil(left/60)).." min" end
    return false
end
local function sendMessage(key,text)
    if not state.alive then return end
    text=trimText(text)
    if text=="" then return end
    if #text>400 then toast("Mensagem muito grande (400 bytes)",false);return end
    local when=state.sentByTab[key] or -100
    if os.clock()-when<2.0 then toast(tr("wait"),false);return end
    if state.pendingSend[key] then toast("Envio anterior em andamento",false);return end
    if key~="local" then
        local denied,why=isModerated()
        if denied then toast("⛔ "..why,false);return end
    end
    if key=="local" then
        local native=getChannel("local")
        if not native then toast(tr("channelMissing"),false);return end
        state.sentByTab[key]=os.clock()
        task.spawn(function()
            local ok,result=pcall(function() return native:SendAsync(text) end)
            if not state.alive then return end
            if not ok then errorState(result);toast(tr("noSend"),false);return end
            if state.tabs[key] and state.tabs[key].input then state.tabs[key].input.Text="" end
        end)
        return
    end
    local path=nil
    if CHANNEL_PATHS[key] then path="/"..CHANNEL_PATHS[key]..".json"
    elseif key=="privado" and state.privateCode then
        path="/rooms/"..state.privateCode.."/msgs.json"
    end
    if not path then toast("Entre em uma sala privada primeiro",false);return end
    state.pendingSend[key]=true
    state.sentByTab[key]=os.clock()
    local currentText=text
    task.spawn(function()
        -- A verificacao local e uma protecao de interface; enforcement real exige backend autenticado.
        checkMyModeration()
        local denied,why=isModerated()
        if denied then
            state.pendingSend[key]=nil
            toast("⛔ "..why,false)
            return
        end
        local token,authErr=playerToken()
        if not token then
            state.pendingSend[key]=nil
            toast("❌ Login Firebase: "..tostring(authErr),false)
            return
        end
        local result,err=fbPost(path,{
            authUid=state.auth.uid,
            u=player.Name,uid=player.UserId,t=currentText,
            ts=os.time(),lg=state.language,g=tostring(game.PlaceId),
            pid=currentPlaceId,gn=tostring(currentGameName):sub(1,72),v="5.3"
        },token)
        state.pendingSend[key]=nil
        if not state.alive then return end
        if result then
            local input=state.tabs[key] and state.tabs[key].input
            if input and input.Text==currentText then input.Text="" end
            toast("✅ Mensagem enviada ao Firebase",true)
        else
            errorState(err)
            toast("❌ Falha de envio: "..tostring(err),false)
        end
        refreshStatus()
    end)
end
for key,p in pairs(state.tabs) do
    connect(p.send.MouseButton1Click,function() sendMessage(key,p.input.Text) end)
    connect(p.input.FocusLost,function(enter)
        if enter then sendMessage(key,p.input.Text) end
    end)
end

-- Local: mensagens nativas e filtradas pelo Roblox.
local function receiveLocal(message)
    if not state.alive then return end
    local ok,err=pcall(function()
        local channel=message.TextChannel
        if not channel or (channel.Name~="RBXGeneral" and channel.Name~="RBXSystem") then return end
        local msg=tostring(message.Text or "")
        if msg=="" then return end
        local uid=message.TextSource and message.TextSource.UserId or 0
        local sender=uid>0 and Players:GetPlayerByUserId(uid) or nil
        local name=sender and sender.DisplayName or "Sistema"
        local trans=""
        pcall(function() trans=tostring(message.Translation or "") end)
        addMessage("local",uid,name,msg,trans,tostring(message.MessageId or ""),nil,
            currentGameName,currentPlaceId)
    end)
    if not ok then errorState(err) end
end
connect(TextChatService.MessageReceived,receiveLocal)

local function getRoomInfo(code)
    if not codeValid(code) then return nil,"Código inválido" end
    local info,err=fbGet("/rooms/"..code.."/info.json")
    if not info then return nil,err end
    if type(info)~="table" or not info.c then return nil,"Sala não encontrada" end
    return info,nil
end
local function joinRoom(code,fromCreation)
    code=tostring(code or ""):upper():gsub("%s+","")
    if not codeValid(code) then toast("Código inválido",false);return end
    task.spawn(function()
        local info,err=getRoomInfo(code)
        if not state.alive then return end
        if not info then toast("❌ "..tostring(err),false);return end
        state.roomGeneration=state.roomGeneration+1
        state.privateCode=code
        local tab=state.tabs.privado
        tab.roomStatus.Text="🔒 SALA "..code.." • "..(fromCreation and "Criada" or "Conectada")
        tab.roomCode.Text=code
        for _,row in ipairs(tab.entries) do pcall(function() row:Destroy() end) end
        tab.entries={};tab.count=0
        plainMessage("privado","🔐 Entrou na sala "..code..". Compartilhe o código com quem deseja convidar.")
        selected("privado")
    end)
end
local function createRoom()
    local p=state.tabs.privado
    p.createBtn.Text="⏳ Criando"
    task.spawn(function()
        local chosen=nil
        for attempt=1,5 do
            local code=randomCode()
            local found,err=fbGet("/rooms/"..code.."/info.json")
            if found and type(found)=="table" and not found.c then
                chosen=code;break
            elseif not found then
                toast("Erro ao verificar sala: "..tostring(err),false)
                break
            end
        end
        if chosen then
            local token,authErr=playerToken()
            if not token then toast("Login Firebase: "..tostring(authErr),false);return end
            local created,err=fbPut("/rooms/"..chosen.."/info.json",{
                c=player.Name,uid=player.UserId,creatorAuthUid=state.auth.uid,
                ts=os.time(),v="5.3"
            },token)
            if created then joinRoom(chosen,true)
            else toast("Erro ao criar: "..tostring(err),false) end
        else
            toast("Não foi possível reservar um código de sala",false)
        end
        if p.createBtn and p.createBtn.Parent then p.createBtn.Text="✨ CRIAR SALA" end
    end)
end
local pPrivate=state.tabs.privado
connect(pPrivate.createBtn.MouseButton1Click,createRoom)
connect(pPrivate.joinBtn.MouseButton1Click,function() joinRoom(pPrivate.roomCode.Text,false) end)
connect(pPrivate.roomCode.FocusLost,function(enter)
    if enter then joinRoom(pPrivate.roomCode.Text,false) end
end)
connect(pPrivate.inviteBtn.MouseButton1Click,function()
    if not state.privateCode then toast("Crie ou entre numa sala primeiro",false);return end
    local target=trimText(pPrivate.recipient.Text)
    if not target:match("^[%w_]+$") or #target<3 or #target>20 then
        toast("Digite o nome de usuário exato, sem espaços",false);return
    end
    if target:lower()==player.Name:lower() then toast("Não pode convidar a si mesmo",false);return end
    if os.clock()-state.inviteLast<8 then toast("Aguarde 8s para outro convite",false);return end
    state.inviteLast=os.clock()
    task.spawn(function()
        local token,authErr=playerToken()
        if not token then toast("Login Firebase: "..tostring(authErr),false);return end
        local result,err=fbPost("/invites/"..cleanUser(target)..".json",{
            from=player.Name,fromUid=player.UserId,fromAuthUid=state.auth.uid,
            code=state.privateCode,ts=os.time(),to=target
        },token)
        if not state.alive then return end
        toast(result and "Convite enviado!" or ("Falha no convite: "..tostring(err)),result~=nil)
    end)
end)

-- Convites Firebase sao indexados por username, compatíveis com a versao 4.1.
local function showInvite(from,code)
    if state.currentInvite then return end
    state.currentInvite={from=from,code=code}
    local p=state.tabs.privado
    plainMessage("privado","🔔 "..from.." convidou você para a sala "..code)
    if not p.prompt then
        local panel=instance("Frame",{Position=UDim2.new(0,0,1,-88),
            Size=UDim2.new(1,0,0,35),BackgroundColor3=COLORS.deep,BorderSizePixel=0},p.frame)
        corner(panel,8)
        p.prompt=panel
        p.accept=btn(panel,"✔ ENTRAR",{Size=UDim2.new(.5,-3,1,0),BackgroundColor3=COLORS.good})
        p.decline=btn(panel,"✖ RECUSAR",{Position=UDim2.new(.5,3,0,0),Size=UDim2.new(.5,-3,1,0),BackgroundColor3=COLORS.bad})
        connect(p.accept.MouseButton1Click,function()
            local inv=state.currentInvite
            state.currentInvite=nil;p.prompt.Visible=false
            if inv then joinRoom(inv.code,false) end
        end)
        connect(p.decline.MouseButton1Click,function()
            state.currentInvite=nil;p.prompt.Visible=false
        end)
    end
    p.prompt.Visible=true
    selected("privado")
end
-- ADMIN: o cliente nao recebe nenhum segredo de administracao.
-- As Rules verificam o Firebase Auth UID do criador em cada leitura/escrita sensivel.
local function clearCreatorReports()
    for _,c in ipairs(creatorReportScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
end
local loadCreatorReports
-- Moderacao Firebase por UID de Auth, verificado na escrita da mensagem.
-- NAO usar Roblox UserId como controle de acesso: cliente Delta pode falsifica-lo.
local function moderateAuthUid(targetAuthUid,action,reportKey)
    targetAuthUid=tostring(targetAuthUid or "")
    if not targetAuthUid:match("^[%w_%-]+$") or #targetAuthUid<8 or #targetAuthUid>128 then
        toast("Denuncia sem UID Firebase verificado",false);return
    end
    task.spawn(function()
        local token=adminToken()
        if not token then toast("Login do criador expirado",false);return end
        local path="/moderationAuth/"..targetAuthUid..".json"
        local current,err=fbGet(path,token)
        if not current then toast("Falha ao buscar moderacao: "..tostring(err),false);return end
        if type(current)~="table" then current={} end
        local newValue={
            banned=current.banned==true,
            muteUntil=tonumber(current.muteUntil) or 0,
            updatedAt=os.time(),updatedBy=state.admin.uid,
            reason="report:"..tostring(reportKey or ""),
        }
        if action=="mute10" then newValue.muteUntil=os.time()+10*60
        elseif action=="mute60" then newValue.muteUntil=os.time()+60*60
        elseif action=="unmute" then newValue.muteUntil=0
        elseif action=="ban" then newValue.banned=true
        elseif action=="unban" then newValue.banned=false
        else return end
        local written,writeErr=fbPut(path,newValue,token)
        if not state.alive then return end
        if written then toast("✅ Moderacao Firebase: "..action,true)
        else toast("❌ Firebase negou acao: "..tostring(writeErr),false) end
    end)
end
loadCreatorReports=function()
    if state.admin.loading then return end
    if not adminToken() then toast("Faca login no painel do criador",false);return end
    state.admin.loading=true
    creatorRefresh.Text="⏳ CARREGANDO..."
    task.spawn(function()
        local token=adminToken()
        local reports,err=fbGet('/reports.json?orderBy="$key"&limitToLast=40',token)
        state.admin.loading=false
        if not state.alive or not creatorReportScroll.Parent then return end
        creatorRefresh.Text="🔄 ATUALIZAR"
        if type(reports)~="table" then toast("❌ Denuncias indisponiveis: "..tostring(err),false);return end
        local list={}
        for key,r in pairs(reports) do
            if type(r)=="table" then list[#list+1]={id=tostring(key),m=r} end
        end
        table.sort(list,function(a,b)
            local at=tonumber(a.m.ts) or 0;local bt=tonumber(b.m.ts) or 0
            return at==bt and a.id>b.id or at>bt
        end)
        local unseen=0
        for _,entry in ipairs(list) do
            if not state.admin.reportSeen[entry.id] and entry.m.status~="resolved" then unseen=unseen+1 end
            state.admin.reportSeen[entry.id]=true
        end
        clearCreatorReports()
        if #list==0 then
            lbl(creatorReportScroll,"📭 Nenhuma denuncia recebida",11,COLORS.quiet,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
        end
        for _,entry in ipairs(list) do
            local r=entry.m
            local line=instance("Frame",{Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=COLORS.panel,BorderSizePixel=0},creatorReportScroll)
            corner(line,9);addPad(line,7);makeList(line,5)
            lbl(line,"🚨 "..tostring(r.reported or "Jogador").." • "..tostring(r.reason or "Sem motivo")..
                (r.status=="resolved" and "  ✔ RESOLVIDA" or "  • PENDENTE"),11,COLORS.gold,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            lbl(line,"📣 «"..tostring(r.message or "Mensagem nao preservada (versao antiga)"):sub(1,400).."»",11,COLORS.light,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            lbl(line,"Por "..tostring(r.reporter or "?").." • "..tostring(r.channel or "?")..
                " • 🎮 "..tostring(r.game or "Jogo nao registrado")..
                " • UID "..tostring(r.reportedUid or "?"),10,COLORS.quiet,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            local target=tostring(r.reportedAuthUid or "")
            local actions=instance("Frame",{Size=UDim2.new(1,-12,0,62),BackgroundTransparency=1},line)
            local specs={
                {"🔇 10 MIN","mute10",0,.0},{"🔇 1 H","mute60",0,.51},
                {"🔊 TIRAR MUTE","unmute",1,.0},{"🚫 BANIR","ban",1,.51},
            }
            for _,spec in ipairs(specs) do
                local b=btn(actions,spec[1],{Size=UDim2.new(.49,-2,0,28),
                    Position=UDim2.new(spec[4],0,0,spec[3]*33),TextSize=9,
                    BackgroundColor3=spec[2]=="ban" and COLORS.bad or COLORS.accent})
                local banConfirmed=false
                b.MouseButton1Click:Connect(function()
                    if spec[2]=="ban" and not banConfirmed then
                        banConfirmed=true
                        b.Text="CONFIRMAR BAN?"
                        task.delay(7,function()
                            if b.Parent then banConfirmed=false;b.Text=spec[1] end
                        end)
                        return
                    end
                    banConfirmed=false;b.Text=spec[1]
                    moderateAuthUid(target,spec[2],entry.id)
                end)
            end
            local last=instance("Frame",{Size=UDim2.new(1,-12,0,28),BackgroundTransparency=1},line)
            local unban=btn(last,"✅ DESBANIR",{Size=UDim2.new(.49,-2,1,0),TextSize=9,
                BackgroundColor3=COLORS.good})
            local resolve=btn(last,"✔ RESOLVER",{Position=UDim2.new(.51,0,0,0),
                Size=UDim2.new(.49,-2,1,0),TextSize=9,BackgroundColor3=COLORS.deep})
            unban.MouseButton1Click:Connect(function() moderateAuthUid(target,"unban",entry.id) end)
            local deleteBtn=btn(line,"🗑️ APAGAR MENSAGEM DO FIREBASE",{
                Size=UDim2.new(1,-12,0,28),TextSize=9,BackgroundColor3=COLORS.bad})
            local deleteConfirmed=false
            deleteBtn.MouseButton1Click:Connect(function()
                local id=tostring(r.messageId or "")
                local channel=tostring(r.channel or "")
                local rootPath=nil
                if CHANNEL_PATHS[channel] then rootPath=CHANNEL_PATHS[channel]
                elseif channel=="privado" and codeValid(tostring(r.roomCode or "")) then
                    rootPath="rooms/"..r.roomCode.."/msgs"
                end
                if not rootPath or not id:match("^[%w%-%_]+$") then
                    toast("Mensagem antiga sem caminho valido para exclusao",false);return
                end
                if not deleteConfirmed then
                    deleteConfirmed=true;deleteBtn.Text="CONFIRMAR EXCLUSAO? TOQUE NOVAMENTE"
                    task.delay(8,function()
                        if deleteBtn.Parent then
                            deleteConfirmed=false;deleteBtn.Text="🗑️ APAGAR MENSAGEM DO FIREBASE"
                        end
                    end)
                    return
                end
                deleteConfirmed=false
                task.spawn(function()
                    local token=adminToken()
                    if not token then toast("Login expirado",false);return end
                    local removed,why=fbDel("/"..rootPath.."/"..id..".json",token)
                    if removed then
                        toast("Mensagem apagada do banco; clientes podem precisar atualizar a tela",true)
                        loadCreatorReports()
                    else
                        toast("Exclusao negada: "..tostring(why),false)
                    end
                end)
            end)
            resolve.MouseButton1Click:Connect(function()
                task.spawn(function()
                    local t=adminToken()
                    if not t then toast("Sessao expirada",false);return end
                    local done,why=fbPatch("/reports/"..entry.id..".json",{
                        status="resolved",resolvedAt=os.time(),resolvedBy=state.admin.uid
                    },t)
                    if done then loadCreatorReports() else toast("Falha ao resolver: "..tostring(why),false) end
                end)
            end)
        end
        if unseen>0 then toast("👑 "..tostring(unseen).." novas denuncias",true) end
    end)
end
connect(creatorLoginBtn.MouseButton1Click,function()
    if state.admin.loginPending then return end
    local email=trimText(creatorEmail.Text)
    local password=creatorPassword.Text
    creatorPassword.Text="" -- nao manter senha no TextBox
    if not email:find("@",1,true) or #password<6 then
        toast("Informe email e senha Firebase Auth validos",false);return
    end
    state.admin.loginPending=true
    creatorLoginBtn.Text="⏳ VALIDANDO..."
    task.spawn(function()
        local result,err=firebaseAuthEmail(email,password)
        password=nil
        if not state.alive then return end
        state.admin.loginPending=false
        creatorLoginBtn.Text="🔐 LOGIN SEGURO"
        if not result then toast("Login falhou: "..tostring(err),false);return end
        -- Mesmo que a UI leia um papel falso, /reports e /moderation continuam protegidos nas Rules.
        local role,roleErr=fbGet("/admins/"..tostring(result.localId)..".json",result.idToken)
        if role~=true then toast("Conta sem permissao de criador: "..tostring(roleErr or "nao autorizada"),false);return end
        local a=state.admin
        a.token=result.idToken;a.refreshToken=result.refreshToken
        a.uid=result.localId;a.expireAt=os.time()+(tonumber(result.expiresIn) or 3600)
        creatorLogin.Visible=false;creatorDashboard.Visible=true
        tabButtons.criador.button.Visible=true
        toast("👑 Criador autenticado",true)
        loadCreatorReports()
    end)
end)
connect(creatorRefresh.MouseButton1Click,loadCreatorReports)
connect(creatorLogout.MouseButton1Click,function()
    local a=state.admin
    a.token=nil;a.refreshToken=nil;a.uid=nil;a.expireAt=0;a.reportSeen={}
    creatorDashboard.Visible=false;creatorLogin.Visible=true
    tabButtons.criador.button.Visible=false
    selected("ajustes");toast("Conta criador desconectada",true)
end)
-- Checar punicoes periodicamente; a protecao contra clientes modificados exige backend.
task.spawn(function()
    while state.alive do
        checkMyModeration()
        task.wait(10)
    end
end)
-- Notificacao de denuncia para o criador, sem ler reports se nao houver autenticacao.
task.spawn(function()
    while state.alive do
        task.wait(22)
        if state.admin.token and not state.admin.loading then
            loadCreatorReports()
        end
    end
end)
local function startChannelPoll(key,path)
    task.spawn(function()
        local first=true
        local seen={}
        while state.alive do
            local data,err=fbList(path)
            if not state.alive then break end
            if type(data)=="table" then
                local messages={}
                for id,entry in pairs(data) do
                    if type(entry)=="table" and not seen[id] then
                        seen[id]=true
                        table.insert(messages,{id=id,m=entry})
                    end
                end
                table.sort(messages,function(a,b)
                    local ta=tonumber(a.m.ts) or 0
                    local tb=tonumber(b.m.ts) or 0
                    if ta==tb then return tostring(a.id)<tostring(b.id) end
                    return ta<tb
                end)
                if first then
                    plainMessage(key,#messages==0 and "📭 Nenhuma mensagem ainda" or "✅ Conectado ao Firebase")
                    first=false
                end
                for _,it in ipairs(messages) do
                    local m=it.m
                    local content=tostring(m.t or ""):sub(1,400)
                    addMessage(key,tonumber(m.uid) or 0,tostring(m.u or "?"),content,
                        nil,tostring(it.id),m.lg,
                        m.gn or (type(m.g)=="string" and not tonumber(m.g) and m.g or nil),
                        m.pid or m.g,m.authUid)
                end
            elseif first then
                plainMessage(key,"⚠️ Erro de conexão: "..tostring(err))
            end
            if state.active=="debug" then refreshStatus() end
            task.wait(POLL_SECONDS)
        end
    end)
end
for key,path in pairs(CHANNEL_PATHS) do startChannelPoll(key,path) end

-- Poll da sala e isolado por geracao; alternar de sala nao reaproveita historico.
task.spawn(function()
    local activeGeneration=-1
    local seen={}
    local first=true
    while state.alive do
        local code=state.privateCode
        if code then
            if activeGeneration~=state.roomGeneration then
                seen={};first=true;activeGeneration=state.roomGeneration
            end
            local data,err=fbList("rooms/"..code.."/msgs")
            if not state.alive then break end
            if type(data)=="table" and state.privateCode==code and activeGeneration==state.roomGeneration then
                local messages={}
                for id,entry in pairs(data) do
                    if type(entry)=="table" and not seen[id] then
                        seen[id]=true
                        messages[#messages+1]={id=id,m=entry}
                    end
                end
                table.sort(messages,function(a,b)
                    local ta=tonumber(a.m.ts) or 0
                    local tb=tonumber(b.m.ts) or 0
                    if ta==tb then return tostring(a.id)<tostring(b.id) end
                    return ta<tb
                end)
                if first and #messages==0 then plainMessage("privado","📭 Sala vazia. Compartilhe o código!") end
                first=false
                for _,it in ipairs(messages) do
                    local m=it.m
                    addMessage("privado",tonumber(m.uid) or 0,tostring(m.u or "?"),
                        tostring(m.t or ""):sub(1,400),nil,tostring(it.id),m.lg,
                        m.gn or (type(m.g)=="string" and not tonumber(m.g) and m.g or nil),
                        m.pid or m.g,m.authUid)
                end
            elseif first then
                plainMessage("privado","⚠️ "..tostring(err))
                first=false
            end
        end
        task.wait(POLL_SECONDS)
    end
end)

-- Convites por username sao convites de cortesia, nao autenticacao Roblox.
-- Somente contas Firebase autenticadas podem criar convites.
local myInviteKey=cleanUser(player.Name)
task.spawn(function()
    local seenInvites={}
    local openedAt=os.time()
    task.wait(2)
    while state.alive do
        local list=fbGet('/invites/'..myInviteKey..'.json?orderBy="$key"&limitToLast=15')
        if type(list)=="table" then
            local candidates={}
            for id,v in pairs(list) do
                if type(v)=="table" and v.code and v.ts and not seenInvites[id] then
                    seenInvites[id]=true
                    local ts=tonumber(v.ts) or 0
                    if ts>=openedAt-20 and math.abs(os.time()-ts)<90 and codeValid(tostring(v.code)) then
                        table.insert(candidates,v)
                    end
                end
            end
            table.sort(candidates,function(a,b) return (a.ts or 0)<(b.ts or 0) end)
            for _,v in ipairs(candidates) do
                if not state.currentInvite then showInvite(tostring(v.from or "Jogador"),tostring(v.code)) end
            end
        end
        task.wait(4)
    end
end)

-- Presence usa a identidade Firebase do remetente, nao uma chave de nick sobrescrita.
task.spawn(function()
    while state.alive do
        local token=playerToken()
        if token and state.auth.uid then
            fbPut('/presence/'..state.auth.uid..'.json',{
                authUid=state.auth.uid,n=player.Name,uid=player.UserId,ts=os.time(),
                gn=tostring(currentGameName):sub(1,72)
            },token)
        end
        task.wait(PRESENCE_SECONDS)
    end
end)

local bubbleMoved=false
local function moveOnDrag(surface, target)
    local started=nil
    local original=nil
    local currentInput=nil
    connect(surface.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            started=input.Position;original=target.Position;currentInput=input
            if target==bubble then bubbleMoved=false end
        end
    end)
    connect(surface.InputEnded,function(input)
        if input==currentInput then currentInput=nil;started=nil end
    end)
    connect(UserInputService.InputChanged,function(input)
        if not state.alive or not started then return end
        local touchMatch=(input==currentInput and input.UserInputType==Enum.UserInputType.Touch)
        local mouseMatch=(currentInput and currentInput.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseMovement)
        if not touchMatch and not mouseMatch then return end
        local delta=input.Position-started
        if target==bubble and (math.abs(delta.X)+math.abs(delta.Y)>10) then bubbleMoved=true end
        target.Position=UDim2.new(original.X.Scale,original.X.Offset+delta.X,original.Y.Scale,original.Y.Offset+delta.Y)
    end)
end
moveOnDrag(top,main)
moveOnDrag(bubble,bubble)

local function minimize()
    state.minimized=true;main.Visible=false;bubble.Visible=true
end
local function restore()
    if bubbleMoved then bubbleMoved=false;return end
    state.minimized=false;main.Visible=true;bubble.Visible=false
    state.unread=0;badge.Visible=false
end
connect(minBtn.MouseButton1Click,minimize)
connect(bubble.MouseButton1Click,restore)
local function shutdown()
    if not state.alive then return end
    state.alive=false
    task.spawn(function()
        pcall(function()
            if state.auth.uid then fbDel("/presence/"..state.auth.uid..".json",state.auth.idToken) end
        end)
    end)
    for _,conn in ipairs(state.connections) do pcall(function() conn:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    if store.GCH_V5_Shutdown==shutdown then store.GCH_V5_Shutdown=nil end
end
store.GCH_V5_Shutdown=shutdown
connect(closeBtn.MouseButton1Click,shutdown)

retranslateUI()
selected("global")
refreshStatus()
plainMessage("global","💜 Global Chat Hub V5.3 • canal mundial Firebase autenticado. BR/USA independentes!")
plainMessage("brasil","🇧🇷 Canal da comunidade brasileira, disponível em qualquer servidor.")
plainMessage("usa","🇺🇸 English-only community room; shared across all games.")
plainMessage("privado","🔒 Crie uma sala, compartilhe o código ou convide outro jogador pelo nome.")
plainMessage("local","💬 Chat local usa TextChatService do Roblox.")
-- O painel Debug mostra o status em tempo real e os erros do backend.


print("[GlobalChatHub V5.3] Firebase REST ativo: global/brasil/usa independentes | Local nativo")
