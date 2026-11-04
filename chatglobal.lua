-- GLOBAL CHAT HUB V5.5.1 | REFERENCE NEON UI | FIREBASE AUTH + CREATOR
-- Canais separados: /global, /brasil, /usa. Salas por codigo em /rooms.
-- Script externo: nao substitui o filtro/privacidade do TextChatService Roblox.
-- Nao utilize para burlar restricoes de chat; ver README antes de publicar.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
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
    quiet = Color3.fromRGB(151, 142, 180), good = Color3.fromRGB(38, 241, 93),
    bad = Color3.fromRGB(244, 96, 145), gold = Color3.fromRGB(244, 195, 110),
    nav = Color3.fromRGB(32, 25, 61), violet = Color3.fromRGB(98, 42, 168),
    border = Color3.fromRGB(82, 63, 132), bubbleIn = Color3.fromRGB(52, 42, 87),
    bubbleOut = Color3.fromRGB(145, 48, 245)
}

local WORDS = {
    pt = {
        creatorTab="Criador", localTab="Local", globalTab="Global", brTab="Brasil", usTab="USA", privateTab="Privado", settingsTab="Ajustes", debugTab="Status",
        typeHere="Digite uma mensagem...", send="ENVIAR", translate="🌐 Traduzir", original="Original", noTranslation="Tradução não fornecida pelo Roblox para esta mensagem.",
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
    local shape=target:FindFirstChildOfClass("UICorner") or instance("UICorner",{},target)
    shape.CornerRadius=UDim.new(0,radius or 10)
    return shape
end
local function stroke(target, color, thickness)
    return instance("UIStroke", {Color=color or COLORS.accent, Thickness=thickness or 1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, target)
end
local function round(target)
    local shape=corner(target,1)
    shape.CornerRadius=UDim.new(1,0)
    return shape
end
local function animate(target, seconds, goals, style, direction)
    if not state.alive or not target or not target.Parent then return end
    local ok,tween=pcall(function()
        return TweenService:Create(target,TweenInfo.new(seconds or 0.2,
            style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),goals)
    end)
    if ok and tween then tween:Play() end
end
local function gradient(target, a, b, rotate)
    if target:IsA("GuiObject") then target.BackgroundColor3=Color3.new(1,1,1) end
    return instance("UIGradient",{Color=ColorSequence.new(a,b),Rotation=rotate or 0},target)
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
    local p = {Text=text, TextSize=18, Font=Enum.Font.GothamBold,
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


-- Design em coordenadas lógicas; UIScale preserva as proporções em qualquer tela.
local camera=workspace.CurrentCamera
local viewport=camera and camera.ViewportSize or Vector2.new(1280,900)
local touch=UserInputService.TouchEnabled
local compact=viewport.X<viewport.Y
local width=compact and 600 or 1020
local height=compact and 900 or 714
local headerH=compact and 94 or 112
local sideW=compact and 104 or 180
local footerH=46
local uiRadius=48
local ui={panels={},nav={},presence={},normalViewport=viewport}
ui.host=instance("Frame",{Name="ResponsiveCanvas",BackgroundTransparency=1,
    AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.53),Size=UDim2.fromOffset(width,height)},gui)
ui.scale=instance("UIScale",{Scale=1},ui.host)
local main=instance("Frame",{Name="Window",BackgroundColor3=COLORS.bg,BackgroundTransparency=.04,
    Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),
    BorderSizePixel=0,ClipsDescendants=false},ui.host)
ui.motion=instance("UIScale",{Scale=1},main)
corner(main,uiRadius)
local mainBorder=stroke(main,Color3.fromRGB(211,149,255),2.5)
function ui.glow(target,radius,color,alpha)
    -- Contornos suaves, sem depender de imagens externas.
    local root=instance("Frame",{Name="SoftGlow",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        ZIndex=target.ZIndex,BorderSizePixel=0},target)
    corner(root,radius)
    for i=1,4 do
        local layer=instance("Frame",{Size=UDim2.new(1,i*4,1,i*4),Position=UDim2.fromOffset(-i*2,-i*2),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=target.ZIndex},root)
        corner(layer,radius+i*2)
        local edge=stroke(layer,color,2+i)
        edge.Transparency=math.min(.98,(alpha or .78)+i*.04)
    end
    return root
end
ui.glow(main,uiRadius,Color3.fromRGB(165,61,255),.65)
ui.background=instance("Frame",{Name="Glass",Size=UDim2.fromScale(1,1),
    BackgroundColor3=Color3.fromRGB(26,19,55),BackgroundTransparency=.06,
    BorderSizePixel=0,ClipsDescendants=true,ZIndex=0},main)
corner(ui.background,uiRadius)
gradient(ui.background,Color3.fromRGB(17,16,37),Color3.fromRGB(38,23,80),30)
-- Arcos elípticos com gradiente reproduzem a onda luminosa da referência.
function ui.wave(parent,x,y,w,h,rotation)
    local arc=instance("Frame",{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),
        Rotation=rotation or 0,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},parent)
    round(arc)
    local edge=stroke(arc,Color3.fromRGB(177,55,255),2)
    local g=gradient(edge,Color3.fromRGB(87,24,150),Color3.fromRGB(218,115,255),15)
    g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.42,.92),
        NumberSequenceKeypoint.new(.65,.08),NumberSequenceKeypoint.new(.79,.65),NumberSequenceKeypoint.new(1,1)})
    ui.glow(arc,90,Color3.fromRGB(142,41,255),.9)
end
ui.wave(ui.background,-.4,.75,.7,.28,-20)
ui.wave(ui.background,.7,.87,.6,.24,-26)
local top=instance("Frame",{Name="TitleBar",Size=UDim2.new(1,0,0,headerH),
    BackgroundTransparency=1,BorderSizePixel=0,Active=true,ZIndex=2,ClipsDescendants=true},main)
corner(top,uiRadius)
ui.wave(top,.18,-1.95,.48,2.95,-8)
ui.divider=instance("Frame",{Position=UDim2.new(0,0,0,headerH),Size=UDim2.new(1,0,0,1),
    BackgroundColor3=COLORS.violet,BackgroundTransparency=.15,BorderSizePixel=0},main)
gradient(ui.divider,Color3.fromRGB(184,87,255),Color3.fromRGB(65,39,101),0)
function ui.icon(parent,kind,size,pos,color)
    local root=instance("Frame",{Name=kind.."Icon",Size=UDim2.fromOffset(size,size),Position=pos or UDim2.new(),
        BackgroundTransparency=1,BorderSizePixel=0},parent)
    color=color or COLORS.lilac
    if kind=="global" or kind=="globe" then
        local circle=instance("Frame",{Size=UDim2.fromScale(.88,.88),Position=UDim2.fromScale(.06,.06),
            BackgroundTransparency=1,BorderSizePixel=0},root)
        round(circle);stroke(circle,color,2)
        local meridian=instance("Frame",{Size=UDim2.fromScale(.42,.88),Position=UDim2.fromScale(.29,.06),
            BackgroundTransparency=1,BorderSizePixel=0},root)
        round(meridian);stroke(meridian,color,1.6)
        for _,v in ipairs({.33,.65}) do
            local latitude=instance("Frame",{Size=UDim2.fromScale(.82,.22),Position=UDim2.fromScale(.09,v-.1),
                BackgroundTransparency=1,BorderSizePixel=0},root)
            round(latitude);stroke(latitude,color,1.2)
        end
    elseif kind=="local" then
        local disk=instance("Frame",{Size=UDim2.fromScale(.83,.65),Position=UDim2.fromScale(.08,.1),
            BackgroundTransparency=1,BorderSizePixel=0},root)
        corner(disk,size*.27);stroke(disk,color,2)
        lbl(root,"•••",size*.38,color,{Size=UDim2.fromScale(1,.8),TextXAlignment=Enum.TextXAlignment.Center})
        lbl(root,"⌞",size*.5,color,{Position=UDim2.fromScale(.12,.35),Size=UDim2.fromScale(.3,.5),Rotation=-18})
    elseif kind=="brasil" then
        local disk=instance("Frame",{Size=UDim2.fromScale(.95,.74),Position=UDim2.fromScale(.025,.13),
            BackgroundColor3=Color3.fromRGB(0,162,75),BorderSizePixel=0,ClipsDescendants=true},root)
        corner(disk,6)
        local diamond=instance("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromScale(.58,.73),Rotation=45,BackgroundColor3=Color3.fromRGB(255,218,34),BorderSizePixel=0},disk)
        local blue=instance("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromOffset(size*.38,size*.38),BackgroundColor3=Color3.fromRGB(35,67,167),BorderSizePixel=0},disk)
        round(blue)
        local band=instance("Frame",{Size=UDim2.fromScale(.8,.12),Position=UDim2.fromScale(.1,.44),Rotation=15,
            BackgroundColor3=Color3.fromRGB(242,242,233),BorderSizePixel=0},blue)
    elseif kind=="usa" then
        local flag=instance("Frame",{Size=UDim2.fromScale(.95,.75),Position=UDim2.fromScale(.025,.125),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ClipsDescendants=true},root)
        corner(flag,7)
        for i=0,6 do
            instance("Frame",{Position=UDim2.fromScale(0,i*2/13),Size=UDim2.fromScale(1,1/13),
                BackgroundColor3=Color3.fromRGB(232,82,112),BorderSizePixel=0},flag)
        end
        local canton=instance("Frame",{Size=UDim2.fromScale(.43,.54),BackgroundColor3=Color3.fromRGB(68,62,146),BorderSizePixel=0},flag)
        lbl(canton,"···\n···",size*.18,COLORS.light,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center})
    else
        lbl(root,kind,size*.8,color,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center})
    end
    return root
end
ui.logo=instance("Frame",{Name="HubLogo",Size=UDim2.fromOffset(74,74),Position=UDim2.fromOffset(48,21),
    BackgroundColor3=COLORS.violet,BorderSizePixel=0},top)
round(ui.logo);stroke(ui.logo,Color3.fromRGB(172,97,255),2)
gradient(ui.logo,Color3.fromRGB(119,55,199),Color3.fromRGB(64,29,118),70)
ui.glow(ui.logo,38,Color3.fromRGB(160,79,255),.7)
ui.logoIcon=ui.icon(ui.logo,"globe",47,UDim2.fromOffset(13,13),Color3.fromRGB(222,170,255))
ui.logoDivider=instance("Frame",{Position=UDim2.fromOffset(142,30),Size=UDim2.fromOffset(1,55),
    BackgroundColor3=COLORS.border,BorderSizePixel=0},top)
local heading=lbl(top,"GLOBAL CHAT HUB",34,COLORS.light,{Name="Heading",Position=UDim2.fromOffset(164,20),
    Size=UDim2.new(1,-480,0,43),Font=Enum.Font.GothamBold,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
local sub=lbl(top,"V5.3 • Firebase Auth • Mobile",20,COLORS.lilac,{Position=UDim2.fromOffset(164,64),
    Size=UDim2.new(1,-480,0,29),TextWrapped=false})
local minBtn=btn(top,"-",{Name="Minimize",Size=UDim2.fromOffset(70,60),Position=UDim2.new(1,-185,0,28),
    BackgroundColor3=COLORS.accent,TextSize=36})
local closeBtn=btn(top,"X",{Name="Close",Size=UDim2.fromOffset(70,60),Position=UDim2.new(1,-100,0,28),
    BackgroundColor3=COLORS.bad,TextSize=36})
for _,b in ipairs({minBtn,closeBtn}) do
    corner(b,22);stroke(b,Color3.fromRGB(224,166,255),1.5)
    ui.glow(b,22,b.BackgroundColor3,.75)
end
gradient(minBtn,Color3.fromRGB(184,94,255),Color3.fromRGB(110,43,233),90)
gradient(closeBtn,Color3.fromRGB(255,135,172),Color3.fromRGB(222,64,113),90)
ui.avatar=instance("ImageLabel",{Name="MyAvatar",Position=UDim2.new(1,-306,0,24),Size=UDim2.fromOffset(72,72),
    BackgroundColor3=COLORS.nav,BorderSizePixel=0,Image="",ScaleType=Enum.ScaleType.Crop},top)
round(ui.avatar);stroke(ui.avatar,Color3.fromRGB(214,147,255),2)
ui.avatarDot=instance("Frame",{Name="OnlineDot",Position=UDim2.new(1,-16,1,-17),Size=UDim2.fromOffset(17,17),
    BackgroundColor3=COLORS.good,BorderSizePixel=0},ui.avatar)
round(ui.avatarDot);stroke(ui.avatarDot,COLORS.bg,3)
ui.avatarDot.Visible=false
ui.avatarDivider=instance("Frame",{Position=UDim2.new(1,-211,0,31),Size=UDim2.fromOffset(1,54),
    BackgroundColor3=COLORS.border,BorderSizePixel=0},top)
task.spawn(function()
    local ok,url=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
    if ok and state.alive and ui.avatar.Parent then ui.avatar.Image=url end
end)
local bar=instance("Frame",{Name="Sidebar",Position=UDim2.fromOffset(0,headerH),
    Size=UDim2.new(0,sideW,1,-headerH-footerH),BackgroundColor3=COLORS.nav,BackgroundTransparency=.64,BorderSizePixel=0},main)
local buttonsHolder=instance("ScrollingFrame",{Name="SidebarTabs",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,AutomaticCanvasSize=Enum.AutomaticSize.Y,BorderSizePixel=0,
    ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(0,0)},bar)
ui.navLayout=makeList(buttonsHolder,15)
ui.navPad=instance("UIPadding",{PaddingLeft=UDim.new(0,19),PaddingRight=UDim.new(0,16),
    PaddingTop=UDim.new(0,28),PaddingBottom=UDim.new(0,8)},buttonsHolder)
ui.sideDivider=instance("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.fromScale(0,1),
    BackgroundColor3=COLORS.border,BackgroundTransparency=.55,BorderSizePixel=0},bar)
ui.sideDivider.Size=UDim2.new(0,1,1,0)
local content=instance("Frame",{Name="Content",Position=UDim2.fromOffset(sideW+18,headerH+14),
    Size=UDim2.new(1,-sideW-40,1,-headerH-footerH-18),BackgroundTransparency=1,ClipsDescendants=true},main)
ui.statusDot=instance("Frame",{Name="StatusDot",Position=UDim2.new(0,48,1,-42),Size=UDim2.fromOffset(24,24),
    BackgroundColor3=COLORS.good,BorderSizePixel=0},main)
round(ui.statusDot);ui.glow(ui.statusDot,12,COLORS.good,.85)
ui.statusCheck=lbl(ui.statusDot,"✓",17,COLORS.light,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center})
local statusBar=lbl(main,"Conectando ao Firebase...",17,COLORS.lilac,{Position=UDim2.new(0,83,1,-43),
    Size=UDim2.new(1,-112,0,26),TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
local bubble=btn(gui,"",{Name="MiniBubble",Size=UDim2.fromOffset(55,55),Position=UDim2.new(0,12,.46,0),
    BackgroundColor3=COLORS.violet,Visible=false,ZIndex=10})
round(bubble);stroke(bubble,COLORS.lilac,2);ui.icon(bubble,"globe",33,UDim2.fromOffset(11,11))
local badge=lbl(bubble,"",10,COLORS.light,{Position=UDim2.new(1,-19,0,-7),Size=UDim2.fromOffset(22,20),
    BackgroundColor3=COLORS.bad,BackgroundTransparency=0,TextXAlignment=Enum.TextXAlignment.Center,Visible=false,ZIndex=11})
round(badge)
function ui.fit()
    local cam=workspace.CurrentCamera
    local actualViewport=cam and cam.ViewportSize or viewport
    local keyboardVisible=false
    local keyboardY=actualViewport.Y
    pcall(function()
        keyboardVisible=UserInputService.OnScreenKeyboardVisible
        if keyboardVisible and UserInputService.OnScreenKeyboardPosition.Y>0 then
            keyboardY=UserInputService.OnScreenKeyboardPosition.Y
        end
    end)
    -- O teclado não redimensiona a janela inteira: só a barra de digitação sobe.
    if not keyboardVisible then ui.normalViewport=actualViewport end
    viewport=keyboardVisible and ui.normalViewport or actualViewport
    compact=viewport.X<viewport.Y
    width=compact and 600 or 1020
    height=compact and math.min(1080,math.max(820,math.floor(viewport.Y/viewport.X*570))) or 714
    headerH=compact and 94 or 112;sideW=compact and 104 or 180
    ui.host.Size=UDim2.fromOffset(width,height)
    ui.scale.Scale=math.max(.1,math.min((viewport.X-24)/width,(viewport.Y-32)/height,1))
    ui.host.Position=UDim2.new(.5,0,0,viewport.Y*.5)
    main.Position=UDim2.fromScale(.5,.5)
    top.Size=UDim2.new(1,0,0,headerH)
    ui.divider.Position=UDim2.fromOffset(0,headerH)
    bar.Position=UDim2.fromOffset(0,headerH);bar.Size=UDim2.new(0,sideW,1,-headerH-footerH)
    ui.logo.Size=UDim2.fromOffset(compact and 52 or 74,compact and 52 or 74)
    ui.logo.Position=UDim2.fromOffset(compact and 20 or 48,21)
    ui.logoIcon.Size=UDim2.fromOffset(compact and 34 or 47,compact and 34 or 47)
    ui.logoIcon.Position=UDim2.fromOffset(compact and 9 or 13,compact and 9 or 13)
    ui.logoDivider.Visible=not compact
    heading.Position=UDim2.fromOffset(compact and 86 or 164,compact and 24 or 20)
    heading.Size=UDim2.new(1,compact and -275 or -480,0,compact and 28 or 43)
    heading.TextSize=compact and 22 or 34
    sub.Position=UDim2.fromOffset(compact and 86 or 164,compact and 55 or 64)
    sub.Size=UDim2.new(1,compact and -275 or -480,0,26);sub.TextSize=compact and 13 or 20
    minBtn.Size=UDim2.fromOffset(compact and 44 or 70,compact and 48 or 60)
    closeBtn.Size=minBtn.Size
    minBtn.Position=UDim2.new(1,compact and -112 or -185,0,compact and 24 or 28)
    closeBtn.Position=UDim2.new(1,compact and -59 or -100,0,compact and 24 or 28)
    ui.avatar.Size=UDim2.fromOffset(compact and 45 or 72,compact and 45 or 72)
    ui.avatar.Position=UDim2.new(1,compact and -174 or -306,0,24)
    ui.avatarDivider.Visible=not compact
    ui.navLayout.Padding=UDim.new(0,compact and 13 or 15)
    ui.navPad.PaddingLeft=UDim.new(0,compact and 9 or 19)
    ui.navPad.PaddingRight=UDim.new(0,compact and 9 or 16)
    content.Position=UDim2.fromOffset(sideW+(compact and 10 or 18),headerH+10)
    content.Size=UDim2.new(1,-sideW-(compact and 22 or 40),1,-headerH-footerH-18)
    for _,nav in pairs(ui.nav) do
        nav.button.Size=UDim2.new(1,-2,0,compact and 94 or 104)
        nav.icon.Position=UDim2.new(.5,-17,0,compact and 15 or 21)
        nav.label.TextSize=compact and 17 or 21
    end
    for _,panel in pairs(ui.panels) do
        if panel.composer and panel.composer.Parent~=panel.frame then
            panel.composer.Parent=panel.frame
            panel.composer.Position=UDim2.new(0,0,1,-84)
            panel.composer.Size=UDim2.new(1,-2,0,84)
        end
        panel.reflow()
    end
    if ui.keyboardDock then
        local tab=ui.panels[state.active]
        local docked=keyboardVisible and not state.minimized and tab and ui.focusedInput==tab.input
        ui.keyboardDock.Visible=docked and true or false
        if docked then
            ui.dockScale.Scale=ui.scale.Scale
            ui.keyboardDock.Size=UDim2.fromOffset(width-sideW-(compact and 22 or 40)-2,84)
            ui.keyboardDock.Position=UDim2.new(.5,0,0,math.max(90,math.min(keyboardY,actualViewport.Y))-10)
            tab.composer.Parent=ui.keyboardDock
            tab.composer.Position=UDim2.new()
            tab.composer.Size=UDim2.fromScale(1,1)
            tab.quick.Visible=false;tab.emojiPanel.Visible=false
        end
    end
end
ui.keyboardDock=instance("Frame",{Name="KeyboardComposer",BackgroundTransparency=1,
    AnchorPoint=Vector2.new(.5,1),Size=UDim2.fromOffset(800,84),Visible=false,ZIndex=30},gui)
ui.dockScale=instance("UIScale",{Scale=1},ui.keyboardDock)
ui.fit()
for _,property in ipairs({"OnScreenKeyboardVisible","OnScreenKeyboardPosition","OnScreenKeyboardSize"}) do
    pcall(function() connect(UserInputService:GetPropertyChangedSignal(property),ui.fit) end)
end
connect(workspace:GetPropertyChangedSignal("CurrentCamera"),function()
    if ui.cameraConnection then ui.cameraConnection:Disconnect() end
    if workspace.CurrentCamera then
        ui.cameraConnection=connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),ui.fit)
    end
    ui.fit()
end)
if camera then ui.cameraConnection=connect(camera:GetPropertyChangedSignal("ViewportSize"),ui.fit) end

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
    statusBar.Text=tostring(message)
    ui.statusDot.BackgroundColor3=positive and COLORS.good or COLORS.gold
    ui.statusCheck.Text=positive and "✓" or "!"
    statusBar.TextColor3=positive and COLORS.good or COLORS.gold
    if not positive then state.lastError=tostring(message):sub(1,100) end
end


local function newMessagePanel(key)
    local frame=instance("Frame",{Name=key,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ClipsDescendants=true},content)
    local channelHead=instance("Frame",{Name="ChannelHeader",Size=UDim2.new(1,-2,0,96),BackgroundColor3=COLORS.deep,
        BackgroundTransparency=.12,BorderSizePixel=0},frame)
    corner(channelHead,24)
    local border=stroke(channelHead,COLORS.border,1);border.Transparency=.5
    local channelIcon=ui.icon(channelHead,key=="local" and "local" or "globe",34,UDim2.fromOffset(4,8))
    local title=lbl(channelHead,"",28,COLORS.light,{Position=UDim2.fromOffset(49,5),
        Size=UDim2.fromOffset(108,38),Font=Enum.Font.GothamBold})
    local onlinePill=lbl(channelHead,"Online: ...",16,COLORS.lilac,{Position=UDim2.fromOffset(162,8),
        Size=UDim2.fromOffset(158,34),BackgroundColor3=COLORS.violet,BackgroundTransparency=.5,
        TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
    corner(onlinePill,17)
    local onlineDot=instance("Frame",{Name="PresenceDot",Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(10,10),
        BackgroundColor3=COLORS.good,BorderSizePixel=0,Visible=key=="local"},onlinePill)
    round(onlineDot)
    local hint=lbl(channelHead,"",18,COLORS.quiet,{Position=UDim2.fromOffset(49,44),Size=UDim2.new(1,-95,0,47),
        TextYAlignment=Enum.TextYAlignment.Top})
    local bars=instance("Frame",{Name="Signal",Position=UDim2.new(1,-48,0,24),Size=UDim2.fromOffset(38,32),BackgroundTransparency=1},channelHead)
    for i=1,4 do
        local line=instance("Frame",{Position=UDim2.new(0,(i-1)*9,1,-i*7),Size=UDim2.fromOffset(4,i*7),
            BackgroundColor3=Color3.fromRGB(178,93,246),BorderSizePixel=0},bars)
        corner(line,2)
    end
    local scrollTop=105
    local scroll=instance("ScrollingFrame",{Name="Messages",Position=UDim2.fromOffset(0,scrollTop),Size=UDim2.new(1,-2,1,-scrollTop-92),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=7,
        ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=true,
        ScrollBarImageColor3=Color3.fromRGB(189,100,255),CanvasSize=UDim2.fromOffset(0,0)},frame)
    local layout=makeList(scroll,18);addPad(scroll,9)
    local previousHeight=0
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
        if not state.alive then return end
        local scale=ui.scale.Scale
        local h=layout.AbsoluteContentSize.Y/scale+20
        local wasNear=scroll.CanvasPosition.Y+scroll.AbsoluteSize.Y/scale>=previousHeight-80
        scroll.CanvasSize=UDim2.fromOffset(0,h)
        if wasNear then scroll.CanvasPosition=Vector2.new(0,math.max(0,h-scroll.AbsoluteSize.Y/scale)) end
        previousHeight=h
    end)
    local inputBar=instance("Frame",{Name="Composer",Position=UDim2.new(0,0,1,-84),Size=UDim2.new(1,-2,0,84),
        BackgroundColor3=COLORS.panel,BackgroundTransparency=.25,BorderSizePixel=0},frame)
    corner(inputBar,30);stroke(inputBar,COLORS.border,1.3)
    local plusBtn=btn(inputBar,"+",{Name="Options",Position=UDim2.fromOffset(16,14),Size=UDim2.fromOffset(54,56),
        BackgroundColor3=COLORS.nav,TextSize=40})
    corner(plusBtn,22);stroke(plusBtn,COLORS.border,1.5)
    gradient(plusBtn,Color3.fromRGB(78,58,121),Color3.fromRGB(35,27,66),90)
    local inputWell=instance("Frame",{Name="InputWell",Position=UDim2.fromOffset(84,14),Size=UDim2.new(1,-198,0,56),
        BackgroundColor3=Color3.fromRGB(54,43,88),BorderSizePixel=0},inputBar)
    corner(inputWell,27);stroke(inputWell,Color3.fromRGB(111,86,156),1.5)
    gradient(inputWell,Color3.fromRGB(66,52,105),Color3.fromRGB(37,31,65),80)
    local send=btn(inputBar,"",{Name="Send",Position=UDim2.new(1,-98,0,14),Size=UDim2.fromOffset(82,56),
        BackgroundColor3=COLORS.accent,TextSize=36})
    local arrow=instance("Frame",{Name="SendArrow",Size=UDim2.fromOffset(30,30),
        Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1},send)
    for _,line in ipairs({{4,24,30,-45},{14,5,17,0},{27,5,17,90}}) do
        local segment=instance("Frame",{Position=UDim2.fromOffset(line[1],line[2]),Size=UDim2.fromOffset(line[3],3),
            AnchorPoint=Vector2.new(0,.5),Rotation=line[4],BackgroundColor3=COLORS.light,BorderSizePixel=0},arrow)
        corner(segment,2)
    end
    corner(send,23);stroke(send,Color3.fromRGB(218,155,255),1.6)
    gradient(send,Color3.fromRGB(196,114,255),Color3.fromRGB(126,32,234),90)
    ui.glow(send,23,Color3.fromRGB(178,65,255),.72)
    local emoji=btn(inputWell,"☺",{Name="Emoji",Position=UDim2.new(1,-53,0,2),Size=UDim2.fromOffset(48,52),
        BackgroundTransparency=1,TextSize=38,TextColor3=COLORS.lilac})
    local input=instance("TextBox",{Name="Input",Position=UDim2.fromOffset(20,0),Size=UDim2.new(1,-75,1,0),
        BackgroundTransparency=1,BorderSizePixel=0,TextColor3=COLORS.light,PlaceholderColor3=COLORS.quiet,
        Text="",TextSize=20,Font=Enum.Font.Gotham,ClearTextOnFocus=false,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,MultiLine=false},inputWell)
    local quick=instance("Frame",{Name="QuickActions",Position=UDim2.new(0,5,1,-230),Size=UDim2.new(1,-12,0,138),
        BackgroundColor3=COLORS.deep,Visible=false,BorderSizePixel=0,ZIndex=5},frame)
    corner(quick,20);stroke(quick,COLORS.border,1.2)
    local quickDefs={{"⚙ Ajustes","ajustes"},{"🔒 Privado","privado"},{"◉ Status","debug"},{"♛ Criador","criador"}}
    for i,def in ipairs(quickDefs) do
        local action=btn(quick,def[1],{Position=UDim2.new((i-1)%2*.5,8,0,8+math.floor((i-1)/2)*62),
            Size=UDim2.new(.5,-16,0,54),BackgroundColor3=COLORS.panel,TextSize=17,ZIndex=6})
        corner(action,16)
        connect(action.MouseButton1Click,function() quick.Visible=false;selected(def[2]) end)
    end
    connect(plusBtn.MouseButton1Click,function() quick.Visible=not quick.Visible end)
    local emojiPanel=instance("Frame",{Name="Emojis",Position=UDim2.new(0,0,1,-148),Size=UDim2.new(1,-2,0,56),
        BackgroundColor3=COLORS.deep,Visible=false,BorderSizePixel=0,ZIndex=5},frame)
    corner(emojiPanel,18);stroke(emojiPanel,COLORS.border,1)
    connect(emoji.MouseButton1Click,function() emojiPanel.Visible=not emojiPanel.Visible;quick.Visible=false end)
    local commonEmojis={"💜","😂","🔥","😍","👍","🎮"}
    for i,glyph in ipairs(commonEmojis) do
        local b=btn(emojiPanel,glyph,{Position=UDim2.new((i-1)/6,0,0,1),Size=UDim2.new(1/6,-2,1,-2),
            TextSize=26,BackgroundTransparency=1,ZIndex=6})
        connect(b.MouseButton1Click,function() input.Text=input.Text..glyph;emojiPanel.Visible=false;input:CaptureFocus() end)
    end
    local tab={frame=frame,title=title,hint=hint,scroll=scroll,layout=layout,input=input,send=send,
        count=0,entries={},channel=key,quick=quick,emojiPanel=emojiPanel,head=channelHead,online=onlinePill,onlineDot=onlineDot,composer=inputBar}
    if key=="privado" then
        local control=instance("Frame",{Name="RoomControls",Position=UDim2.fromOffset(0,scrollTop),Size=UDim2.new(1,-2,0,132),
            BackgroundColor3=COLORS.deep,BorderSizePixel=0},frame)
        corner(control,16)
        tab.controls=control
        tab.createBtn=btn(control,"CRIAR SALA",{Position=UDim2.fromOffset(6,5),Size=UDim2.new(.36,-8,0,40),BackgroundColor3=COLORS.accent})
        tab.roomCode=instance("TextBox",{Position=UDim2.new(.36,3,0,5),Size=UDim2.new(.37,-6,0,40),
            BackgroundColor3=COLORS.panel,TextColor3=COLORS.light,PlaceholderText="Código",Text="",TextSize=18,
            ClearTextOnFocus=false,Font=Enum.Font.Gotham},control)
        corner(tab.roomCode,10)
        tab.joinBtn=btn(control,"ENTRAR",{Position=UDim2.new(.73,2,0,5),Size=UDim2.new(.27,-8,0,40),BackgroundColor3=COLORS.violet})
        tab.recipient=instance("TextBox",{Position=UDim2.fromOffset(6,52),Size=UDim2.new(1,-166,0,40),
            BackgroundColor3=COLORS.panel,TextColor3=COLORS.light,PlaceholderColor3=COLORS.quiet,
            PlaceholderText="Nome para convidar",Text="",TextSize=18,Font=Enum.Font.Gotham,ClearTextOnFocus=false},control)
        corner(tab.recipient,10)
        tab.inviteBtn=btn(control,"CONVIDAR",{Position=UDim2.new(1,-154,0,52),Size=UDim2.fromOffset(148,40),BackgroundColor3=COLORS.accent})
        tab.roomStatus=lbl(control,"Nenhuma sala ativa",17,COLORS.quiet,{Position=UDim2.fromOffset(6,97),Size=UDim2.new(1,-12,0,25)})
    end
    tab.reflow=function()
        local headH=compact and 112 or 96
        channelHead.Size=UDim2.new(1,-2,0,headH)
        title.TextSize=compact and 23 or 28
        title.Size=UDim2.fromOffset(compact and 88 or 108,38)
        onlinePill.Position=UDim2.fromOffset(compact and 139 or 162,8)
        onlinePill.Size=UDim2.fromOffset(compact and 148 or 158,34)
        onlinePill.TextSize=compact and 14 or 16
        hint.TextSize=compact and 15 or 18
        hint.Size=UDim2.new(1,compact and -65 or -95,0,compact and 64 or 47)
        scrollTop=headH+9
        if tab.controls then tab.controls.Position=UDim2.fromOffset(0,scrollTop) end
        local extra=tab.controls and 139 or 0
        scroll.Position=UDim2.fromOffset(0,scrollTop+extra)
        scroll.Size=UDim2.new(1,-2,1,-scrollTop-extra-96)
        input.TextSize=compact and 17 or 20
        inputWell.Position=UDim2.fromOffset(compact and 68 or 84,14)
        inputWell.Size=UDim2.new(1,compact and -154 or -198,0,56)
        plusBtn.Position=UDim2.fromOffset(compact and 8 or 16,14)
        plusBtn.Size=UDim2.fromOffset(compact and 50 or 54,56)
        send.Position=UDim2.new(1,compact and -76 or -98,0,14)
        send.Size=UDim2.fromOffset(compact and 66 or 82,56)
        if tab.prompt then tab.prompt.Position=UDim2.new(0,0,1,-134) end
    end
    connect(input.Focused,function() ui.focusedInput=input;ui.fit() end)
    connect(input.FocusLost,function() if ui.focusedInput==input then ui.focusedInput=nil end;ui.fit() end)
    state.tabs[key]=tab;ui.panels[key]=tab
    tab.reflow()
    return tab
end
for _,d in ipairs(tabDefs) do
    if messageTabs[d.key] then newMessagePanel(d.key) end
end

local function plainMessage(key, message)
    local p=state.tabs[key]
    if not p then return end
    p.count=p.count+1
    local row=instance("Frame",{Name="SystemNote",Size=UDim2.new(1,-5,0,34),
        LayoutOrder=p.count,BackgroundTransparency=1},p.scroll)
    local line=lbl(row,tostring(message),17,COLORS.quiet,{
        Position=UDim2.fromOffset(3,2),Size=UDim2.new(1,-6,0,30),
        TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
    table.insert(p.entries,row)
    if #p.entries>MAX_MESSAGES then
        local old=table.remove(p.entries,1);if old then old:Destroy() end
    end
end

local avatarCache={}
local function loadAvatar(robloxUid,imageLabel)
    robloxUid=tonumber(robloxUid)
    if not robloxUid or robloxUid<1 then return end
    if avatarCache[robloxUid] then imageLabel.Image=avatarCache[robloxUid];return end
    task.spawn(function()
        local ok,url=pcall(function()
            return Players:GetUserThumbnailAsync(robloxUid,Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100)
        end)
        if ok and url and url~="" then
            avatarCache[robloxUid]=url
            if state.alive and imageLabel.Parent then imageLabel.Image=url end
        end
    end)
end
local function boundTextHeight(value,fontSize,maxWidth)
    local ok,rect=pcall(function()
        return TextService:GetTextSize(tostring(value),fontSize,Enum.Font.Gotham,
            Vector2.new(math.max(75,maxWidth),2000))
    end)
    if ok and rect then return math.max(fontSize+4,rect.Y) end
    return fontSize+8
end
local function addMessage(key, uid, username, text, translated, messageId, sourceLang, gameTitle, placeId, authorAuthUid, sentTimestamp)
    if not state.alive or text=="" or state.blocked[uid] then return end
    local p=state.tabs[key];if not p then return end
    if messageId and messageId~="" then
        local mark=key.."/"..tostring(messageId)
        if state.seen[mark] then return end
        state.seen[mark]=true;table.insert(state.seenOrder,mark)
        if #state.seenOrder>400 then state.seen[table.remove(state.seenOrder,1)]=nil end
    end
    state.messages=state.messages+1;p.count=p.count+1
    local outgoing=tonumber(uid)==tonumber(player.UserId)
    local available=math.max(180,p.scroll.AbsoluteSize.X/ui.scale.Scale-24)
    local avatarSize=compact and 44 or 66
    local leftIndent=outgoing and 5 or (avatarSize+13)
    local maxBubbleWidth=math.max(100,math.floor((available-leftIndent)*(compact and .85 or .50)))
    local bubbleHeight=38
    local headerY=0
    local bubbleY=outgoing and 10 or (compact and 25 or 31)
    local actionsY=0
    local reasonsHeight=0
    local showReasons=false
    local reported=false
    local translating=false
    local originalText=tostring(text)
    local actualTranslation=translated and tostring(translated) or ""
    local showingTranslation=false
    local textFont=compact and 18 or 23
    local row=instance("Frame",{Name="Message",BackgroundTransparency=1,
        BorderSizePixel=0,LayoutOrder=p.count,Size=UDim2.new(1,-5,0,70)},p.scroll)
    local avatar
    if not outgoing then
        avatar=instance("ImageLabel",{Name="Avatar",Position=UDim2.fromOffset(0,bubbleY-1),
            Size=UDim2.fromOffset(avatarSize,avatarSize),Image="",ScaleType=Enum.ScaleType.Crop,
            BackgroundColor3=COLORS.nav,BorderSizePixel=0},row)
        round(avatar);stroke(avatar,Color3.fromRGB(183,116,251),1.4)
        loadAvatar(uid,avatar)
        local dot=instance("Frame",{Name="AvatarOnline",Size=UDim2.fromOffset(13,13),Position=UDim2.new(1,-13,1,-14),
            BackgroundColor3=COLORS.good,BorderSizePixel=0,Visible=Players:GetPlayerByUserId(tonumber(uid) or 0)~=nil or ui.presence[tonumber(uid)]==true},avatar)
        round(dot);stroke(dot,COLORS.bg,3)
    end
    local header=lbl(row,"",compact and 15 or 19,COLORS.light,{
        Position=UDim2.fromOffset(leftIndent,headerY),
        Size=UDim2.fromOffset(maxBubbleWidth-52,compact and 22 or 25),
        Visible=not outgoing,Font=Enum.Font.GothamBold,TextXAlignment=outgoing and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd})
    local displayGame=type(gameTitle)=="string" and gameTitle~="" and gameTitle or "Jogo..."
    local function updateHeader()
        local label=(outgoing and "Você" or tostring(username)).."  |  "..tostring(displayGame)
        header.Text=label:sub(1,100)
    end
    updateHeader()
    local targetPlace=tonumber(placeId or gameTitle)
    if targetPlace and targetPlace>0 then
        resolveGameName(targetPlace,function(label)
            displayGame=label
            if header.Parent then updateHeader() end
        end)
    end
    local bubbleWidth=outgoing and math.min(maxBubbleWidth,math.max(compact and 150 or 210,
        TextService:GetTextSize(originalText,textFont,Enum.Font.Gotham,Vector2.new(maxBubbleWidth,2000)).X+74)) or maxBubbleWidth
    local timeLabel=lbl(row,os.date("%H:%M",tonumber(sentTimestamp) or os.time()),compact and 12 or 15,COLORS.quiet,{
        Size=UDim2.fromOffset(52,24),TextXAlignment=Enum.TextXAlignment.Right,
        Position=outgoing and UDim2.new(1,-bubbleWidth-64,0,bubbleY+12)
            or UDim2.fromOffset(leftIndent+maxBubbleWidth-52,0)})
    local bubble=instance("Frame",{Name=outgoing and "SentBubble" or "ReceivedBubble",
        Position=outgoing and UDim2.new(1,12,0,bubbleY) or UDim2.fromOffset(leftIndent+12,bubbleY),
        AnchorPoint=outgoing and Vector2.new(1,0) or Vector2.new(0,0),
        Size=UDim2.fromOffset(bubbleWidth,35),BackgroundColor3=outgoing and COLORS.bubbleOut or COLORS.bubbleIn,
        BorderSizePixel=0,BackgroundTransparency=.72,ClipsDescendants=false},row)
    corner(bubble,compact and 19 or 25)
    stroke(bubble,outgoing and Color3.fromRGB(207,132,255) or Color3.fromRGB(93,75,151),1)
    if outgoing then gradient(bubble,Color3.fromRGB(155,63,251),Color3.fromRGB(89,41,183),90)
    else gradient(bubble,Color3.fromRGB(55,45,99),Color3.fromRGB(36,31,70),90) end
    if outgoing then
        ui.glow(bubble,24,Color3.fromRGB(177,67,255),.82)
        lbl(bubble,"✓",28,COLORS.light,{Position=UDim2.new(1,-43,0,0),Size=UDim2.new(0,34,1,0),
            TextXAlignment=Enum.TextXAlignment.Center})
    end
    local messageLabel=lbl(bubble,originalText,textFont,COLORS.light,{
        Position=UDim2.fromOffset(22,7),Size=UDim2.new(1,outgoing and -68 or -44,1,-14),
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center})
    local actions={}
    if not outgoing then
        local rowActions=instance("Frame",{Name="Actions",Position=UDim2.fromOffset(leftIndent+8,0),
            Size=UDim2.fromOffset(compact and maxBubbleWidth+4 or math.min(280,maxBubbleWidth+4),compact and 30 or 35),BackgroundTransparency=1},row)
        actions.root=rowActions
        local translateBtn=btn(rowActions,tr("translate"),{
            Position=UDim2.fromOffset(0,1),Size=UDim2.new(.47,-3,1,-2),
            BackgroundColor3=COLORS.violet,TextSize=compact and 12 or 15,
            TextColor3=COLORS.light})
        corner(translateBtn,20)
        actions.translate=translateBtn
        if key~="local" and tonumber(uid)>0 and messageId then
            local reportBtn=btn(rowActions,"⚑ Denunciar",{
                Position=UDim2.new(.49,2,0,1),Size=UDim2.new(.51,-4,1,-2),
                BackgroundColor3=COLORS.nav,TextSize=compact and 12 or 15,
                TextColor3=COLORS.lilac})
            corner(reportBtn,20);stroke(reportBtn,COLORS.border,1)
            actions.report=reportBtn
        end
        if outgoing==false and tonumber(uid)>0 then
            -- Toque prolongado no avatar para ocultar o usuario localmente.
            if avatar then
                local holding=false
                connect(avatar.InputBegan,function(input)
                    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                        holding=true
                        task.delay(.85,function()
                            if holding and state.alive and row.Parent then
                                state.blocked[uid]=true
                                toast(tostring(username).." ocultado nesta interface",true)
                            end
                        end)
                    end
                end)
                connect(avatar.InputEnded,function()holding=false end)
            end
        end
    end
    if actions.report==nil and not outgoing and key=="local" then
        local reportBtn=btn(actions.root,"⚑ Denunciar",{Position=UDim2.new(.49,2,0,1),
            Size=UDim2.new(.51,-4,1,-2),BackgroundColor3=COLORS.nav,TextSize=compact and 12 or 15})
        corner(reportBtn,20);stroke(reportBtn,COLORS.border,1)
        connect(reportBtn.MouseButton1Click,function()
            openedNative();toast(tr("report"),false)
        end)
    end
    local reasonPanel=nil
    local function recalc()
        local str=showingTranslation and actualTranslation or originalText
        local y=boundTextHeight(str,textFont,bubbleWidth-(outgoing and 68 or 44))
        bubbleHeight=math.max(compact and 44 or 49,y+20)
        bubble.Size=UDim2.fromOffset(bubbleWidth,bubbleHeight)
        actionsY=bubbleY+bubbleHeight+4
        if actions.root then actions.root.Position=UDim2.fromOffset(leftIndent+8,actionsY) end
        if reasonPanel then reasonPanel.Position=UDim2.fromOffset(leftIndent,actionsY+(compact and 32 or 39)) end
        local total=actionsY+(actions.root and (compact and 35 or 43) or 5)+reasonsHeight+2
        row.Size=UDim2.new(1,-5,0,total)
    end
    if actions.translate and actualTranslation~="" and state.autoTranslate then
        showingTranslation=true;state.translationHits=state.translationHits+1
        actions.translate.Text=tr("original")
        messageLabel.Text=actualTranslation
    end
    row:SetAttribute("MessageUID",tonumber(uid) or 0)
    local function resizeMessage()
        available=math.max(180,p.scroll.AbsoluteSize.X/ui.scale.Scale-24)
        avatarSize=compact and 44 or 66
        leftIndent=outgoing and 5 or (avatarSize+13)
        maxBubbleWidth=math.max(100,math.floor((available-leftIndent)*(compact and .85 or .50)))
        textFont=compact and 18 or 23
        bubbleWidth=outgoing and math.min(maxBubbleWidth,math.max(compact and 150 or 210,
            TextService:GetTextSize(originalText,textFont,Enum.Font.Gotham,Vector2.new(maxBubbleWidth,2000)).X+74)) or maxBubbleWidth
        messageLabel.TextSize=textFont
        bubbleY=outgoing and 10 or (compact and 25 or 31)
        header.Size=UDim2.fromOffset(math.max(40,maxBubbleWidth-52),compact and 22 or 25)
        header.Position=UDim2.fromOffset(leftIndent,0)
        header.TextSize=compact and 15 or 19
        timeLabel.TextSize=compact and 12 or 15
        if avatar then
            avatar.Size=UDim2.fromOffset(avatarSize,avatarSize)
            avatar.Position=UDim2.fromOffset(0,bubbleY-1)
        end
        if actions.root then actions.root.Size=UDim2.fromOffset(compact and maxBubbleWidth+4 or math.min(280,maxBubbleWidth+4),compact and 30 or 35) end
        if reasonPanel then reasonPanel.Size=UDim2.fromOffset(maxBubbleWidth+4,30) end
        timeLabel.Position=outgoing and UDim2.new(1,-bubbleWidth-64,0,bubbleY+12)
            or UDim2.fromOffset(leftIndent+maxBubbleWidth-52,0)
        bubble.Position=outgoing and UDim2.new(1,-2,0,bubbleY) or UDim2.fromOffset(leftIndent,bubbleY)
        recalc()
    end
    local resizeConnection=p.scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeMessage)
    row.Destroying:Once(function() resizeConnection:Disconnect() end)
    resizeMessage()
    if actions.translate then
        connect(actions.translate.MouseButton1Click,function()
            if actualTranslation~="" then
                showingTranslation=not showingTranslation
                messageLabel.Text=showingTranslation and actualTranslation or originalText
                actions.translate.Text=showingTranslation and tr("original") or tr("translate")
                recalc();return
            end
            if key=="local" then toast(tr("noTranslation"),false);return end
            if translating then return end
            local target=state.language
            local source=sourceLang
            if source~="pt" and source~="en" and source~="es" then
                source=key=="brasil" and "pt" or key=="usa" and "en" or (target=="en" and "pt" or "en")
            end
            if source==target then toast("Mensagem ja esta no idioma selecionado",true);return end
            translating=true;actions.translate.Text="⏳ ..."
            task.spawn(function()
                local result,err=translateExternal(originalText,source,target)
                translating=false
                if not state.alive or not actions.translate.Parent then return end
                if result then
                    actualTranslation=result;showingTranslation=true
                    messageLabel.Text=result;actions.translate.Text=tr("original")
                    state.translationHits=state.translationHits+1;recalc()
                else
                    actions.translate.Text=tr("translate")
                    toast("Tradução indisponível: "..tostring(err),false)
                end
            end)
        end)
    end
    if actions.report then
        reasonPanel=instance("Frame",{Name="ReportReasons",Size=UDim2.fromOffset(maxBubbleWidth+4,30),
            BackgroundTransparency=1,Visible=false},row)
        local reasons={"Ofensa","Spam","Assedio","Outro"}
        local reasonButtons={}
        for i,reason in ipairs(reasons) do
            local rb=btn(reasonPanel,reason,{Position=UDim2.new((i-1)/4,0,0,0),
                Size=UDim2.new(.25,-2,1,0),BackgroundColor3=COLORS.nav,
                TextColor3=COLORS.gold,TextSize=compact and 8 or 10})
            corner(rb,11);reasonButtons[#reasonButtons+1]=rb
            connect(rb.MouseButton1Click,function()
                if reported then return end
                reported=true;actions.report.Text="⏳ Enviando"
                task.spawn(function()
                    local result,err=fbPost("/reports.json",{
                        reporter=player.Name,reporterUid=player.UserId,
                        reporterAuthUid=state.auth.uid or "",reported=username,
                        reportedUid=tonumber(uid) or 0,
                        reportedAuthUid=tostring(authorAuthUid or ""),
                        channel=key,ts=os.time(),messageId=tostring(messageId or ""),
                        message=originalText:sub(1,400),reason=reason,
                        game=tostring(gameTitle or ""):sub(1,72),placeId=tonumber(placeId) or 0,
                        roomCode=key=="privado" and tostring(state.privateCode or "") or "",
                        status="pending"
                    })
                    if not state.alive or not actions.report.Parent then return end
                    if result then
                        actions.report.Text="✓ Denunciado";reasonPanel.Visible=false
                        reasonsHeight=0;recalc();toast("Denúncia registrada",true)
                    else
                        reported=false;actions.report.Text="⚑ Denunciar"
                        toast("Erro ao denunciar: "..tostring(err),false)
                    end
                end)
            end)
        end
        connect(actions.report.MouseButton1Click,function()
            if reported then return end
            showReasons=not showReasons
            reasonPanel.Visible=showReasons
            reasonsHeight=showReasons and 34 or 0
            recalc()
        end)
    end
    -- Transicao de entrada sutil, sem centenas de tweens em loop.
    task.defer(function()
        if not state.alive or not bubble.Parent then return end
        animate(bubble,.25,{Position=outgoing and UDim2.new(1,-2,0,bubbleY)
            or UDim2.fromOffset(leftIndent,bubbleY),BackgroundTransparency=0})
    end)
    table.insert(p.entries,row)
    if #p.entries>MAX_MESSAGES then
        local old=table.remove(p.entries,1);if old then old:Destroy() end
    end
    if state.active~=key or state.minimized then
        state.unread=state.unread+1;badge.Visible=true
        badge.Text=state.unread>9 and "9+" or tostring(state.unread)
    end
end

local settings=instance("ScrollingFrame",{Name="Settings",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
addPad(settings,8);makeList(settings,10)
local settingsTitle=lbl(settings,"⚙️ AJUSTES",22,COLORS.light,{Font=Enum.Font.GothamBold})
local languageButton=btn(settings,"🌐 PT / EN / ES",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local transButton=btn(settings,"🌐 Mostrar tradução: OFF",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local translationNote=lbl(settings,"",17,COLORS.quiet,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y})
local creatorEntry=btn(settings,"👑 ENTRAR NA AREA DO CRIADOR",{
    Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local soundsButton=btn(settings,"🔕 Sons: OFF",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local nativeButton=btn(settings,"ABRIR CHAT ROBLOX",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local clearButton=btn(settings,"LIMPAR MENSAGENS",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.panel})
local settingsNotice=lbl(settings,"⚠️ Firebase é externo: mensagens NÃO passam automaticamente pelo filtro Roblox. Não compartilhe dados pessoais.",17,COLORS.good,
    {Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y})

local debugPanel=instance("ScrollingFrame",{Name="Debug",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
addPad(debugPanel,8); makeList(debugPanel,11)
local debugTitle=lbl(debugPanel,"🔍 DIAGNÓSTICO",22,COLORS.lilac,{Font=Enum.Font.GothamBold})
local info=lbl(debugPanel,"",17,COLORS.light,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y})
local copyButton=btn(debugPanel,"COPIAR DIAGNÓSTICO",{Size=UDim2.new(1,-2,0,40),BackgroundColor3=COLORS.accent})
local reportInfo=lbl(debugPanel,"",17,COLORS.quiet,{AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-8,0,0)})

-- Painel do criador: a interface nao concede permissao. Regras Firebase autorizam cada operacao.
local creator=instance("Frame",{Name="Creator",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},content)
local creatorHead=lbl(creator,"👑 PAINEL DO CRIADOR",24,COLORS.lilac,
    {Size=UDim2.new(1,0,0,34),Font=Enum.Font.GothamBold})
local creatorHint=lbl(creator,"Entre com a conta Firebase Auth autorizada nas regras.",17,COLORS.quiet,
    {Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,0,38)})
local creatorLogin=instance("Frame",{Name="Login",Position=UDim2.fromOffset(0,90),
    Size=UDim2.new(1,0,0,190),BackgroundTransparency=1},creator)
local creatorEmail=instance("TextBox",{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,48),
    Text="",PlaceholderText="Email do administrador Firebase",ClearTextOnFocus=false,
    TextSize=18,Font=Enum.Font.Gotham,TextColor3=COLORS.light,
    BackgroundColor3=COLORS.panel},creatorLogin)
corner(creatorEmail,8)
local creatorPassword=instance("TextBox",{Position=UDim2.fromOffset(0,58),Size=UDim2.new(1,0,0,48),
    Text="",PlaceholderText="Senha (nao salva)",ClearTextOnFocus=false,
    TextSize=18,Font=Enum.Font.Gotham,TextColor3=COLORS.light,
    BackgroundColor3=COLORS.panel},creatorLogin)
corner(creatorPassword,8)
creatorPassword.TextTransparency=1 -- evita exibir senha em texto legivel
local creatorMask=lbl(creatorLogin,"",17,COLORS.light,{
    Position=UDim2.fromOffset(12,69),Size=UDim2.new(1,-18,0,24)})
connect(creatorPassword:GetPropertyChangedSignal("Text"),function()
    local length=#creatorPassword.Text
    creatorMask.Text=length>0 and string.rep("•",math.min(length,28)) or ""
end)
local creatorLoginBtn=btn(creatorLogin,"🔐 LOGIN SEGURO",{Position=UDim2.fromOffset(0,120),
    Size=UDim2.new(1,0,0,48),BackgroundColor3=COLORS.accent,TextSize=18})
local creatorDashboard=instance("Frame",{Name="ModDashboard",Position=UDim2.fromOffset(0,88),
    Size=UDim2.new(1,0,1,-90),BackgroundTransparency=1,Visible=false},creator)
local creatorRefresh=btn(creatorDashboard,"🔄 ATUALIZAR",{Position=UDim2.fromOffset(0,0),
    Size=UDim2.new(.65,-3,0,46),BackgroundColor3=COLORS.accent,TextSize=18})
local creatorLogout=btn(creatorDashboard,"SAIR",{Position=UDim2.new(.65,3,0,0),
    Size=UDim2.new(.35,-3,0,46),BackgroundColor3=COLORS.bad,TextSize=18})
local creatorReportScroll=instance("ScrollingFrame",{Position=UDim2.fromOffset(0,56),
    Size=UDim2.new(1,0,1,-58),CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,
    BackgroundColor3=COLORS.deep,BorderSizePixel=0},creatorDashboard)
corner(creatorReportScroll,9)
makeList(creatorReportScroll,8);addPad(creatorReportScroll,7)


local tabButtons={}
for i,def in ipairs(tabDefs) do
    local primary=i<=4
    local tab=btn(buttonsHolder,"",{Name=def.key,Size=UDim2.new(1,-2,0,compact and 94 or 104),
        BackgroundColor3=COLORS.nav,TextWrapped=true,AutoButtonColor=false,Visible=primary,LayoutOrder=i})
    corner(tab,28)
    local fill=gradient(tab,Color3.fromRGB(55,42,91),Color3.fromRGB(30,25,56),90)
    local edge=stroke(tab,Color3.fromRGB(89,65,143),1.4)
    local glow=ui.glow(tab,28,Color3.fromRGB(191,89,255),.6);glow.Visible=false
    local icon=ui.icon(tab,primary and def.key or def.icon,34,UDim2.new(.5,-17,0,compact and 15 or 21))
    local label=lbl(tab,tr(def.label),compact and 17 or 21,COLORS.light,{Position=UDim2.new(0,0,1,-42),
        Size=UDim2.new(1,0,0,32),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold})
    local selectedDot=instance("Frame",{Name="ActiveDot",Size=UDim2.fromOffset(12,12),Position=UDim2.new(1,-21,0,11),
        Visible=false,BorderSizePixel=0,BackgroundColor3=COLORS.good},tab)
    round(selectedDot);ui.glow(selectedDot,6,COLORS.good,.75)
    tabButtons[def.key]={button=tab,definition=def,edge=edge,dot=selectedDot,fill=fill,glow=glow,label=label,icon=icon}
    ui.nav[def.key]=tabButtons[def.key]
    connect(tab.MouseButton1Click,function() selected(def.key) end)
end
-- Hover e pressão sem alterar tamanhos calculados pelo layout.
function ui.bindButton(b)
    if not b:IsA("TextButton") then return end
    local scale=instance("UIScale",{Scale=1},b)
    connect(b.MouseEnter,function() animate(scale,.13,{Scale=1.025}) end)
    connect(b.MouseLeave,function() animate(scale,.16,{Scale=1}) end)
    connect(b.MouseButton1Down,function() animate(scale,.08,{Scale=.96}) end)
    connect(b.MouseButton1Up,function() animate(scale,.15,{Scale=1}) end)
end
for _,object in ipairs(main:GetDescendants()) do ui.bindButton(object) end
connect(main.DescendantAdded,function(object) ui.bindButton(object) end)
ui.fit()

local function updateLabels()
    for _,p in pairs(tabButtons) do
        p.label.Text=tr(p.definition.label)
    end
    for k,tab in pairs(state.tabs) do
        local word={["local"]="localTab",global="globalTab",brasil="brTab",usa="usTab",privado="privateTab"}
        tab.title.Text=tr(word[k])
        tab.hint.Text=k=="global" and tr("globalInfo") or (k=="local" and tr("localOnly") or
            (k=="privado" and (state.privateCode and ("Sala "..state.privateCode.." • Firebase") or "Sala privada por código • Firebase") or
                (k=="brasil" and "🇧🇷 Chat brasileiro entre todos os jogos" or "🇺🇸 English chat across all games")))
        tab.input.PlaceholderText=tr("typeHere")
        tab.send.Text=""
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
        local active=(key==k)
        animate(p.button,.19,{BackgroundColor3=Color3.new(1,1,1)})
        animate(p.edge,.2,{Color=active and Color3.fromRGB(218,127,255) or Color3.fromRGB(77,55,139),
            Thickness=active and 1.9 or 1})
        p.dot.Visible=active
        p.glow.Visible=active
        p.fill.Color=active and ColorSequence.new(Color3.fromRGB(190,90,255),Color3.fromRGB(104,25,225))
            or ColorSequence.new(Color3.fromRGB(55,42,91),Color3.fromRGB(30,25,56))
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
    local panel=state.tabs[key]
    if panel then
        panel.head.BackgroundTransparency=.5
        animate(panel.head,.22,{BackgroundTransparency=.12})
    end
    ui.fit()
    refreshStatus()
end

refreshStatus=function()
    local lines={
        "GlobalChatHub V5.5.1 | NEON UI + FIREBASE AUTH",
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
            if state.tabs[key] and state.tabs[key].input.Text==text then state.tabs[key].input.Text="" end
            toast("Mensagem enviada ao chat local",true)
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
            toast("Mensagem enviada ao Firebase",true)
            local sentPanel=state.tabs[key]
            if sentPanel then
                animate(sentPanel.send,.1,{BackgroundColor3=COLORS.good})
                task.delay(.22,function() if state.alive then animate(sentPanel.send,.25,{BackgroundColor3=Color3.new(1,1,1)}) end end)
            end
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
            currentGameName,currentPlaceId, nil, message.Timestamp and message.Timestamp.UnixTimestamp or os.time())
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
        local panel=instance("Frame",{Position=UDim2.new(0,0,1,-134),
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
            lbl(creatorReportScroll,"📭 Nenhuma denuncia recebida",17,COLORS.quiet,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
        end
        for _,entry in ipairs(list) do
            local r=entry.m
            local line=instance("Frame",{Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=COLORS.panel,BorderSizePixel=0},creatorReportScroll)
            corner(line,9);addPad(line,7);makeList(line,5)
            lbl(line,"🚨 "..tostring(r.reported or "Jogador").." • "..tostring(r.reason or "Sem motivo")..
                (r.status=="resolved" and "  ✔ RESOLVIDA" or "  • PENDENTE"),17,COLORS.gold,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            lbl(line,"📣 «"..tostring(r.message or "Mensagem nao preservada (versao antiga)"):sub(1,400).."»",17,COLORS.light,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            lbl(line,"Por "..tostring(r.reporter or "?").." • "..tostring(r.channel or "?")..
                " • 🎮 "..tostring(r.game or "Jogo nao registrado")..
                " • UID "..tostring(r.reportedUid or "?"),16,COLORS.quiet,
                {AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-10,0,0)})
            local target=tostring(r.reportedAuthUid or "")
            local actions=instance("Frame",{Size=UDim2.new(1,-12,0,62),BackgroundTransparency=1},line)
            local specs={
                {"🔇 10 MIN","mute10",0,.0},{"🔇 1 H","mute60",0,.51},
                {"🔊 TIRAR MUTE","unmute",1,.0},{"🚫 BANIR","ban",1,.51},
            }
            for _,spec in ipairs(specs) do
                local b=btn(actions,spec[1],{Size=UDim2.new(.49,-2,0,28),
                    Position=UDim2.new(spec[4],0,0,spec[3]*33),TextSize=17,
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
            local unban=btn(last,"✅ DESBANIR",{Size=UDim2.new(.49,-2,1,0),TextSize=17,
                BackgroundColor3=COLORS.good})
            local resolve=btn(last,"✔ RESOLVER",{Position=UDim2.new(.51,0,0,0),
                Size=UDim2.new(.49,-2,1,0),TextSize=17,BackgroundColor3=COLORS.deep})
            unban.MouseButton1Click:Connect(function() moderateAuthUid(target,"unban",entry.id) end)
            local deleteBtn=btn(line,"🗑️ APAGAR MENSAGEM DO FIREBASE",{
                Size=UDim2.new(1,-12,0,28),TextSize=17,BackgroundColor3=COLORS.bad})
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
        tabButtons.criador.button.Visible=false
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
                        m.pid or m.g,m.authUid,m.ts)
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
                        m.pid or m.g,m.authUid,m.ts)
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

-- Contador verificado: nenhuma contagem ficticia como no mockup.
task.spawn(function()
    while state.alive do
        local data=fbGet("/presence.json")
        if not state.alive then break end
        local onlineCount=nil
        ui.presence={}
        if type(data)=="table" then
            local current=os.time();onlineCount=0
            for _,record in pairs(data) do
                if type(record)=="table" and type(record.ts)=="number" and
                   record.ts<=current+15 and current-record.ts<=45 then
                    onlineCount=onlineCount+1
                    if tonumber(record.uid) then ui.presence[tonumber(record.uid)]=true end
                end
            end
        end
        ui.avatarDot.Visible=ui.presence[player.UserId]==true
        for _,tab in pairs(state.tabs) do
            for _,entry in ipairs(tab.entries) do
                local avatar=entry:FindFirstChild("Avatar")
                if avatar then
                    local dot=avatar:FindFirstChild("AvatarOnline")
                    if dot then dot.Visible=ui.presence[entry:GetAttribute("MessageUID")]==true end
                end
            end
        end
        for _,key in ipairs({"global","brasil","usa","privado"}) do
            local tab=state.tabs[key]
            if tab and tab.online and tab.online.Parent then
                tab.online.Text=onlineCount and ("Online: "..tostring(onlineCount))
                    or "Indisponível"
                tab.onlineDot.Visible=onlineCount~=nil and onlineCount>0
            end
        end
        task.wait(24)
    end
end)
-- Presence usa a identidade Firebase do remetente, nao uma chave de nick sobrescrita.
task.spawn(function()
    while state.alive do
        local token=playerToken()
        if token and state.auth.uid then
            local present=fbPut('/presence/'..state.auth.uid..'.json',{
                authUid=state.auth.uid,n=player.Name,uid=player.UserId,ts=os.time(),
                gn=tostring(currentGameName):sub(1,72)
            },token)
            if state.alive then ui.avatarDot.Visible=present~=nil end
        end
        task.wait(PRESENCE_SECONDS)
    end
end)

function ui.localPresence()
    local tab=state.tabs["local"]
    if tab then tab.online.Text="Online: "..tostring(#Players:GetPlayers()) end
end
connect(Players.PlayerAdded,function() task.defer(ui.localPresence) end)
connect(Players.PlayerRemoving,function() task.defer(ui.localPresence) end)
ui.localPresence()

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
        local factor=target==main and ui.scale.Scale or 1
        local offsetX=original.X.Offset+delta.X/factor
        local offsetY=original.Y.Offset+delta.Y/factor
        if target==main then
            local marginX=math.max(0,(viewport.X-width*factor)/2/factor-6)
            local marginY=math.max(0,(viewport.Y-height*factor)/2/factor-6)
            offsetX=math.max(-marginX,math.min(marginX,offsetX))
            offsetY=math.max(-marginY,math.min(marginY,offsetY))
        end
        target.Position=UDim2.new(original.X.Scale,offsetX,original.Y.Scale,offsetY)
    end)
end
moveOnDrag(top,main)
moveOnDrag(bubble,bubble)

local animatingWindow=false
local function minimize()
    if animatingWindow or state.minimized then return end
    animatingWindow=true;state.minimized=true
    if ui.focusedInput then ui.focusedInput:ReleaseFocus() end
    ui.fit()
    animate(ui.motion,.18,{Scale=.94},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
    task.delay(.19,function()
        if not state.alive then return end
        main.Visible=false;bubble.Visible=true
        bubble.Size=UDim2.fromOffset(40,40)
        animate(bubble,.25,{Size=UDim2.fromOffset(55,55)},Enum.EasingStyle.Back)
        animatingWindow=false
    end)
end
local function restore()
    if bubbleMoved then bubbleMoved=false;return end
    if animatingWindow or not state.minimized then return end
    state.minimized=false;main.Visible=true;bubble.Visible=false
    ui.motion.Scale=.94;animate(ui.motion,.25,{Scale=1},Enum.EasingStyle.Quart)
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
ui.motion.Scale=.96
animate(ui.motion,.35,{Scale=1},Enum.EasingStyle.Quart)
refreshStatus()
plainMessage("global","💜 Bem-vindo! Chat mundial; Brasil e USA são canais separados.")
plainMessage("brasil","🇧🇷 Canal da comunidade brasileira, disponível em qualquer servidor.")
plainMessage("usa","🇺🇸 English-only community room; shared across all games.")
plainMessage("privado","🔒 Crie uma sala, compartilhe o código ou convide outro jogador pelo nome.")
plainMessage("local","💬 Chat local usa TextChatService do Roblox.")
-- O painel Debug mostra o status em tempo real e os erros do backend.


print("[GlobalChatHub V5.5.1] Neon Chat UI + Firebase REST | canais preservados")
