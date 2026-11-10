-- GLOBAL CHAT HUB V5.8.0 | NEON UI | FIREBASE AUTH + CREATOR
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
local Localization = game:GetService("LocalizationService")
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
    language = "en", autoTranslate = false,
    sentAt = -100, messages = 0, errors = 0, unread = {}, mentions = {},
    lastError = "", privateChannel = nil, connections = {},
    blocked = {}, seen = {}, seenOrder = {}, tabs = {},
    currentInvite = nil, translationHits = 0, privateCode=nil,
    firebaseTransport="none", firebaseStatus="not_checked", firebaseError="",
    auth={idToken=nil,refreshToken=nil,uid=nil,expireAt=0,loading=false,status="aguardando"},
    roomGeneration=0, sentByTab={}, pendingSend={}, inviteLast=0,
    moderation={banned=false,muteUntil=0}, admin={token=nil,refreshToken=nil,uid=nil,expireAt=0,loginPending=false,reportSeen={},reports={},loading=false},
}
local prefs = {
    file = "GlobalChatHub_UI_Settings.json",
    language = "auto", motion = true, glow = true, badge = true, startup = "global",
    mentionsOnly=false, mutedChannels={},
}
do
    local saved = store.GCH_V5_UISettings
    if type(saved) ~= "table" and type(readfile) == "function" then
        local ok, data = pcall(function() return Http:JSONDecode(readfile(prefs.file)) end)
        if ok then saved = data end
    end
    if type(saved) == "table" then
        if saved.language == "pt" or saved.language == "en" or saved.language == "es" then
            prefs.language = saved.language
        end
        if saved.startup == "local" or saved.startup == "brasil" or saved.startup == "usa" then
            prefs.startup = saved.startup
        end
        for _, key in ipairs({"motion", "glow", "badge", "autoTranslate", "mentionsOnly"}) do
            if type(saved[key]) == "boolean" then prefs[key] = saved[key] end
        end
        if type(saved.mutedChannels)=="table" then
            for _,key in ipairs({"local","global","brasil","usa","privado"}) do
                prefs.mutedChannels[key]=saved.mutedChannels[key]==true or nil
            end
        end
        if type(saved.blocked)=="table" then
            for id,enabled in pairs(saved.blocked) do
                if type(id)=="string" and id:match("^%d+$") and enabled==true then state.blocked[id]=true end
            end
        end
    end
    state.autoTranslate = prefs.autoTranslate == true
end
function prefs.save()
    local data = {
        language = prefs.language, motion = prefs.motion, glow = prefs.glow,
        badge = prefs.badge, startup = prefs.startup, autoTranslate = state.autoTranslate,
        mentionsOnly=prefs.mentionsOnly, mutedChannels=prefs.mutedChannels, blocked=state.blocked,
    }
    store.GCH_V5_UISettings = data
    if type(writefile) == "function" then
        pcall(function() writefile(prefs.file, Http:JSONEncode(data)) end)
    end
end

function prefs.detectLanguage()
    if prefs.language ~= "auto" then return prefs.language end
    if prefs.region == "BR" then return "pt" end
    if prefs.region == "US" then return "en" end
    for _, locale in ipairs({Localization.RobloxLocaleId, Localization.SystemLocaleId}) do
        local code = string.lower(locale):match("^%a%a")
        if code == "pt" or code == "en" or code == "es" then return code end
    end
    return "en"
end
state.language = prefs.detectLanguage()

local MAX_MESSAGES = 50
local MAX_MESSAGE_BYTES = 400
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
do
    local strings = {
        tooLarge={"Mensagem muito grande (limite de 400 bytes).","Message is too long (400-byte limit).","El mensaje supera el límite de 400 bytes."},
        search={"Buscar mensagem ou jogador","Find message or player","Buscar mensaje o jugador"},
        alertsSection={"ALERTAS E SILÊNCIO","ALERTS AND MUTES","ALERTAS Y SILENCIO"},
        mentionsOnly={"Contar apenas menções","Count mentions only","Contar solo menciones"},
        mutedChannel={"Silenciar %s","Mute %s","Silenciar %s"},
        unmutePlayers={"Reexibir jogadores ocultos (%d)","Unhide players (%d)","Mostrar jugadores ocultos (%d)"},
        replyTo={"Respondendo a %s","Replying to %s","Respondiendo a %s"},
        quoteGone={"A mensagem original saiu do histórico carregado.","The original message is outside the loaded history.","El mensaje original salió del historial cargado."},
        savedMessage={"Marcada nesta sessão.","Starred for this session.","Marcado en esta sesión."},
        unsavedMessage={"Marca removida.","Star removed.","Marca eliminada."},
        hiddenPlayer={"%s ocultado neste dispositivo.","%s hidden on this device.","%s oculto en este dispositivo."},
        searchCount={"%d resultado(s)","%d result(s)","%d resultado(s)"},
        copiedMessage={"Mensagem copiada.","Message copied.","Mensaje copiado."},
        copiedCode={"Código da sala copiado.","Room code copied.","Código de sala copiado."},
        copyCode={"Copiar código","Copy code","Copiar código"},
        emptyChannel={"📭 Nenhuma mensagem ainda","📭 No messages yet","📭 Todavía no hay mensajes"},
        connected={"✓ Conectado ao Firebase","✓ Connected to Firebase","✓ Conectado a Firebase"},
        connectionLost={"Falha na conexão: %s","Connection failed: %s","Error de conexión: %s"},
        emptyRoom={"📭 Sala vazia. Compartilhe o código!","📭 Room is empty. Share its code!","📭 Sala vacía. ¡Comparte el código!"},
        sendPending={"O envio anterior ainda está em andamento.","The previous message is still sending.","El mensaje anterior todavía se está enviando."},
        localSent={"Mensagem enviada ao chat local.","Message sent to local chat.","Mensaje enviado al chat local."},
        firebaseSent={"Mensagem enviada ao Firebase.","Message sent to Firebase.","Mensaje enviado a Firebase."},
        needRoom={"Crie ou entre em uma sala primeiro.","Create or join a room first.","Primero crea una sala o únete a una."},
        invalidRoom={"Código inválido.","Invalid room code.","Código inválido."},
        missingRoom={"Sala não encontrada.","Room not found.","Sala no encontrada."},
        inviteUsername={"Digite o nome de usuário exato, sem espaços.","Enter the exact username, without spaces.","Escribe el nombre de usuario exacto, sin espacios."},
        inviteSelf={"Você não pode convidar a si mesmo.","You can’t invite yourself.","No puedes invitarte a ti mismo."},
        inviteCooldown={"Aguarde 8 s para enviar outro convite.","Wait 8 seconds before sending another invite.","Espera 8 segundos para enviar otra invitación."},
        inviteSent={"Convite enviado!","Invite sent!","¡Invitación enviada!"},
        inviteError={"Falha no convite: %s","Could not send invite: %s","No se pudo enviar la invitación: %s"},
        sendFailed={"Falha no envio: %s","Could not send message: %s","No se pudo enviar el mensaje: %s"},
        translationFailed={"Tradução indisponível: %s","Translation unavailable: %s","Traducción no disponible: %s"},
        alreadyTranslated={"A mensagem já está no idioma selecionado.","This message is already in the selected language.","El mensaje ya está en el idioma seleccionado."},
        unavailable={"Indisponível","Unavailable","No disponible"},
        reportSent={"Denúncia registrada.","Report submitted.","Denuncia registrada."},
        reportBusy={"Enviando…","Submitting…","Enviando…"},
        reportError={"Erro ao denunciar: %s","Could not submit report: %s","No se pudo enviar la denuncia: %s"},
        offense={"Ofensa","Abuse","Insulto"},
        harassment={"Assédio","Harassment","Acoso"},
        other={"Outro","Other","Otro"},
        settingsIntro={"Personalize como o chat abre e aparece.", "Choose how the chat opens and looks.", "Personaliza cómo se abre y se ve el chat."},
        languageSection={"IDIOMA E TRADUÇÃO","LANGUAGE AND TRANSLATION","IDIOMA Y TRADUCCIÓN"},
        visualSection={"APARÊNCIA E COMPORTAMENTO","APPEARANCE AND BEHAVIOR","ASPECTO Y COMPORTAMIENTO"},
        toolsSection={"FERRAMENTAS E CONTA","TOOLS AND ACCOUNT","HERRAMIENTAS Y CUENTA"},
        auto={"Automático","Automatic","Automático"},
        motion={"Animações da interface","Interface animations","Animaciones de la interfaz"},
        glow={"Brilho neon","Neon glow","Brillo neón"},
        unreadBadge={"Contador na bolha","Unread badge","Contador en la burbuja"},
        startup={"Canal inicial","Startup channel","Canal inicial"},
        reset={"Restaurar preferências","Reset preferences","Restablecer preferencias"},
        resetDone={"Preferências restauradas.","Preferences reset.","Preferencias restablecidas."},
        testConnection={"Testar conexão Firebase","Test Firebase connection","Probar conexión Firebase"},
        testing={"Testando Firebase…","Testing Firebase…","Probando Firebase…"},
        firebaseReply={"Firebase respondeu (HTTP %s)","Firebase replied (HTTP %s)","Firebase respondió (HTTP %s)"},
        chatCleared={"Histórico local limpo.","Local history cleared.","Historial local borrado."},
        copied={"Diagnóstico copiado.","Diagnostics copied.","Diagnóstico copiado."},
        copyFailed={"Falha ao copiar.","Could not copy.","No se pudo copiar."},
        console={"Diagnóstico no console.","Diagnostics printed to the console.","Diagnóstico en la consola."},
        externalNotice={"O Firebase é externo ao Roblox e usa outro sistema de moderação. Evite compartilhar dados pessoais.","Firebase is outside Roblox and uses a separate moderation system. Avoid sharing personal information.","Firebase es externo a Roblox y usa otro sistema de moderación. Evita compartir datos personales."},
        creatorOpen={"Abrir painel do criador","Open creator dashboard","Abrir panel del creador"},
        creatorLogin={"Área do criador","Creator area","Área del creador"},
        creatorHint={"Entre com a conta Firebase Auth autorizada nas regras.","Sign in with the Firebase Auth account allowed by the rules.","Inicia sesión con la cuenta de Firebase Auth autorizada por las reglas."},
        creatorEmail={"E-mail do administrador Firebase","Firebase admin email","Correo del administrador de Firebase"},
        creatorPassword={"Senha (não salva)","Password (not saved)","Contraseña (no guardada)"},
        signIn={"Entrar","Sign in","Iniciar sesión"},
        validating={"Validando…","Signing in…","Validando…"},
        signOut={"Sair","Sign out","Cerrar sesión"},
        refresh={"Atualizar","Refresh","Actualizar"},
        privateHint={"Sala privada por código • Firebase","Private room by code • Firebase","Sala privada por código • Firebase"},
        room={"Sala %s","Room %s","Sala %s"},
        noRoom={"Nenhuma sala ativa","No active room","No hay sala activa"},
        createRoom={"Criar sala","Create room","Crear sala"},
        creatingRoom={"Criando…","Creating…","Creando…"},
        roomCode={"Código","Room code","Código"},
        joinRoom={"Entrar","Join","Entrar"},
        inviteName={"Nome para convidar","Username to invite","Usuario para invitar"},
        sendInvite={"Convidar","Invite","Invitar"},
        localWelcome={"💬 Chat local usa o TextChatService do Roblox.","💬 Local chat uses Roblox TextChatService.","💬 El chat local usa TextChatService de Roblox."},
        globalWelcome={"💜 Bem-vindo! Brasil e EUA têm canais separados.","💜 Welcome! Brazil and the US have separate channels.","💜 ¡Bienvenido! Brasil y EE.UU. tienen canales separados."},
        brazilWelcome={"🇧🇷 Canal brasileiro entre jogos e servidores.","🇧🇷 Brazilian channel across games and servers.","🇧🇷 Canal brasileño entre juegos y servidores."},
        usWelcome={"🇺🇸 Canal em inglês entre jogos e servidores.","🇺🇸 English channel across games and servers.","🇺🇸 Canal en inglés entre juegos y servidores."},
        privateWelcome={"🔒 Crie uma sala ou entre com um código.","🔒 Create a room or join with a code.","🔒 Crea una sala o entra con un código."},
        reportAction={"Denunciar","Report","Denunciar"},
        translationBusy={"Traduzindo…","Translating…","Traduciendo…"},
        roomJoined={"🔐 Você entrou na sala %s. Compartilhe o código para convidar.","🔐 You joined room %s. Share the code to invite others.","🔐 Entraste en la sala %s. Comparte el código para invitar."},
        roomInvite={"🔔 %s convidou você para a sala %s","🔔 %s invited you to room %s","🔔 %s te invitó a la sala %s"},
        connecting={"Conectando ao Firebase…","Connecting to Firebase…","Conectando a Firebase…"},
    }
    for key, values in pairs(strings) do
        WORDS.pt[key], WORDS.en[key], WORDS.es[key] = values[1], values[2], values[3]
    end
end
local function tr(key, ...)
    local value = WORDS[state.language][key] or WORDS.pt[key] or key
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
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
    if not prefs.motion then
        for property, value in pairs(goals) do target[property] = value end
        return
    end
    local ok,tween=pcall(function()
        return TweenService:Create(target,TweenInfo.new(seconds or 0.2,
            style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),goals)
    end)
    if ok and tween then tween:Play(); return tween end
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
    IgnoreGuiInset=true, AutoLocalize=false, DisplayOrder=900, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
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
local ui={panels={},nav={},presence={},normalViewport=viewport,
    glows={}, localized={}}
function ui.text(object, key, property)
    property = property or "Text"
    if not ui.localized[object] then
        object.Destroying:Once(function() ui.localized[object]=nil end)
    end
    ui.localized[object] = {key=key, property=property}
    object[property] = tr(key)
end
function ui.setGlow()
    for object in pairs(ui.glows) do
        object.Visible = prefs.glow
    end
    for key, nav in pairs(ui.nav) do
        nav.glow.Visible = prefs.glow and key == state.active
    end
end
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
    ui.glows[root]=true
    root.Destroying:Once(function() ui.glows[root]=nil end)
    root.Visible=prefs.glow
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
local sub=lbl(top,"V5.8 • NEON CHAT",20,COLORS.lilac,{Position=UDim2.fromOffset(164,64),
    Size=UDim2.new(1,-480,0,29),TextWrapped=false})
local minBtn=btn(top,"-",{Name="Minimize",Size=UDim2.fromOffset(70,60),Position=UDim2.new(1,-185,0,28),
    BackgroundColor3=COLORS.accent,TextSize=36})
local closeBtn=btn(top,"X",{Name="Close",Size=UDim2.fromOffset(70,60),Position=UDim2.new(1,-100,0,28),
    BackgroundColor3=COLORS.bad,TextSize=36})
ui.settingsButton=btn(top,"⚙",{Name="OpenSettings",TextSize=30,BackgroundColor3=COLORS.nav})
for _,b in ipairs({ui.settingsButton,minBtn,closeBtn}) do
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
local statusBar=lbl(main,tr("connecting"),17,COLORS.lilac,{Position=UDim2.new(0,83,1,-43),
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
    -- Mantém a escala e o campo na mesma árvore visual enquanto o teclado abre.
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
    heading.Size=UDim2.new(1,compact and -310 or -512,0,compact and 28 or 43)
    heading.TextSize=compact and 22 or 34
    sub.Position=UDim2.fromOffset(compact and 86 or 164,compact and 55 or 64)
    sub.Size=UDim2.new(1,compact and -310 or -512,0,26);sub.TextSize=compact and 13 or 20
    minBtn.Size=UDim2.fromOffset(compact and 44 or 70,compact and 48 or 60)
    closeBtn.Size=minBtn.Size
    minBtn.Position=UDim2.new(1,compact and -112 or -185,0,compact and 24 or 28)
    closeBtn.Position=UDim2.new(1,compact and -59 or -100,0,compact and 24 or 28)
    ui.avatar.Size=UDim2.fromOffset(compact and 45 or 72,compact and 45 or 72)
    ui.settingsButton.Size=UDim2.fromOffset(compact and 48 or 56,compact and 48 or 60)
    ui.settingsButton.Position=UDim2.new(1,compact and -166 or -249,0,compact and 24 or 28)
    ui.avatar.Position=UDim2.new(1,compact and -220 or -340,0,24)
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
    local tab=ui.panels[state.active]
    local raised=keyboardVisible and not state.minimized and tab and ui.focusedInput==tab.input
    content.ClipsDescendants=not raised
    for _,panel in pairs(ui.panels) do
        panel.reflow()
        panel.frame.ClipsDescendants=true
        panel.composer.Position=UDim2.new(0,0,1,-84)
        panel.composer.Size=UDim2.new(1,-2,0,84)
        panel.composer.ZIndex=1
    end
    if raised then
        -- Nunca trocar Parent/Visible do campo focado: isso fecha o teclado no Android.
        local scale=ui.scale.Scale
        local bottom=math.max(90,math.min(keyboardY,actualViewport.Y))-10
        local composerY=(bottom-tab.frame.AbsolutePosition.Y)/scale-84
        tab.frame.ClipsDescendants=false
        tab.composer.Position=UDim2.fromOffset(0,composerY)
        tab.composer.ZIndex=30
        tab.quick.Visible=false;tab.emojiPanel.Visible=false
    end
end
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
    ui.statusKey=nil
    statusBar.Text=tostring(message)
    statusBar.TextTransparency=prefs.motion and .55 or 0
    animate(statusBar,.22,{TextTransparency=0})
    ui.statusDot.BackgroundColor3=positive and COLORS.good or COLORS.gold
    ui.statusCheck.Text=positive and "✓" or "!"
    statusBar.TextColor3=positive and COLORS.good or COLORS.gold
    if not positive then state.lastError=tostring(message):sub(1,100) end
end
function ui.notice(key, positive, ...)
    toast(tr(key,...),positive)
    ui.statusKey=key
    ui.statusArgs=table.pack(...)
end

function ui.copyText(value, noticeKey)
    local ok=type(setclipboard)=="function" and pcall(setclipboard,value)
    ui.notice(ok and noticeKey or "copyFailed",ok==true)
end

function ui.updateUnread()
    local total=0
    for _,count in pairs(state.unread) do total=total+count end
    for key,nav in pairs(ui.nav) do
        local count=state.unread[key] or 0
        nav.unread.Text=state.mentions[key] and "@" or (count>9 and "9+" or tostring(count))
        nav.unread.Visible=prefs.badge and count>0
    end
    badge.Text=total>9 and "9+" or tostring(total)
    badge.Visible=prefs.badge and total>0
end

function ui.markRead(key)
    state.unread[key]=nil
    state.mentions[key]=nil
    ui.updateUnread()
end

function ui.quoteParts(text)
    local quote,body=text:match("^(↪ @[%w_]+: [^\r\n]+)\n(.+)$")
    return quote,body or text
end

function ui.makeQuote(username,text)
    local _,body=ui.quoteParts(text)
    local excerpt=trimText((body:gsub("%s+"," ")))
    if #excerpt>76 then
        local boundary=utf8.offset(excerpt,0,77)
        excerpt=excerpt:sub(1,boundary-1).."…"
    end
    if excerpt=="" then return nil end
    return "↪ @"..username..": "..excerpt
end

function ui.hasMention(text)
    local target=player.Name:lower()
    for name in text:lower():gmatch("%f[%w_@]@([%w_]+)") do
        if name==target then return true end
    end
    return false
end

function ui.hidePlayer(uid,username)
    state.blocked[tostring(uid)]=true
    prefs.save()
    retranslateUI()
    ui.notice("hiddenPlayer",true,tostring(username))
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
    local searchButton=btn(channelHead,"⌕",{Name="SearchHistory",Position=UDim2.new(1,-144,0,4),
        Size=UDim2.fromOffset(42,43),TextSize=27,BackgroundColor3=COLORS.nav})
    local starsButton=btn(channelHead,"☆",{Name="StarredHistory",Position=UDim2.new(1,-97,0,4),
        Size=UDim2.fromOffset(42,43),TextSize=25,BackgroundColor3=COLORS.nav})
    local latestButton=btn(channelHead,"↓",{Name="LatestMessage",Position=UDim2.new(1,-50,0,4),
        Size=UDim2.fromOffset(42,43),TextSize=26,BackgroundColor3=COLORS.nav})
    local search=instance("TextBox",{Name="HistoryQuery",Position=UDim2.fromOffset(12,48),
        Size=UDim2.new(1,-136,0,40),BackgroundColor3=COLORS.panel,BorderSizePixel=0,Visible=false,
        Text="",TextSize=17,TextColor3=COLORS.light,PlaceholderColor3=COLORS.quiet,
        ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextTruncate=Enum.TextTruncate.AtEnd},channelHead)
    corner(search,12);ui.text(search,"search","PlaceholderText")
    local results=lbl(channelHead,"",15,COLORS.lilac,{Name="HistoryResults",Visible=false,
        Position=UDim2.new(1,-116,0,48),Size=UDim2.fromOffset(106,40),TextXAlignment=Enum.TextXAlignment.Center})
    local scrollTop=105
    local scroll=instance("ScrollingFrame",{Name="Messages",Position=UDim2.fromOffset(0,scrollTop),Size=UDim2.new(1,-2,1,-scrollTop-92),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=7,
        ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=true,
        ScrollBarImageColor3=Color3.fromRGB(189,100,255),CanvasSize=UDim2.fromOffset(0,0)},frame)
    local layout=makeList(scroll,18);addPad(scroll,9)
    local previousHeight=0
    local keepBottomUntil=0
    local function refreshScroll(force)
        if not state.alive or not scroll.Parent then return end
        local scale=math.max(.01,ui.scale.Scale*ui.motion.Scale)
        local h=layout.AbsoluteContentSize.Y/scale+20
        local viewHeight=scroll.AbsoluteSize.Y/scale
        local wasNear=scroll.CanvasPosition.Y+viewHeight>=previousHeight-80
        scroll.CanvasSize=UDim2.fromOffset(0,h)
        if force or os.clock()<keepBottomUntil or wasNear then
            scroll.CanvasPosition=Vector2.new(0,math.max(0,h-viewHeight))
        end
        previousHeight=h
    end
    local function scrollToBottom()
        -- A lista recalcula sua altura depois da criação dos balões.
        keepBottomUntil=os.clock()+.35
        refreshScroll(true)
        task.defer(function() refreshScroll(true) end)
    end
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"),function() refreshScroll(false) end)
    connect(scroll:GetPropertyChangedSignal("AbsoluteSize"),function() refreshScroll(false) end)
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
    local meter=lbl(inputBar,"",12,COLORS.quiet,{Name="MessageLength",Position=UDim2.new(1,-104,1,-14),
        Size=UDim2.fromOffset(90,14),TextXAlignment=Enum.TextXAlignment.Center,Visible=false})
    local replyBar=instance("Frame",{Name="ReplyPreview",Position=UDim2.fromOffset(0,-35),
        Size=UDim2.new(1,0,0,32),BackgroundColor3=COLORS.nav,BorderSizePixel=0,Visible=false},inputBar)
    corner(replyBar,9)
    local replyLabel=lbl(replyBar,"",14,COLORS.lilac,{Position=UDim2.fromOffset(9,0),
        Size=UDim2.new(1,-54,1,0),TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
    local cancelReply=btn(replyBar,"×",{Name="CancelReply",Position=UDim2.new(1,-39,0,0),
        Size=UDim2.fromOffset(39,32),TextSize=21})
    local quick=instance("Frame",{Name="QuickActions",Position=UDim2.new(0,5,1,-230),Size=UDim2.new(1,-12,0,138),
        BackgroundColor3=COLORS.deep,Visible=false,BorderSizePixel=0,ZIndex=5},frame)
    corner(quick,20);stroke(quick,COLORS.border,1.2)
    local quickDefs={{"settingsTab","ajustes"},{"privateTab","privado"},{"debugTab","debug"},{"creatorTab","criador"}}
    for i,def in ipairs(quickDefs) do
        local action=btn(quick,tr(def[1]),{Position=UDim2.new((i-1)%2*.5,8,0,8+math.floor((i-1)/2)*62),
            Size=UDim2.new(.5,-16,0,54),BackgroundColor3=COLORS.panel,TextSize=17,ZIndex=6})
        corner(action,16)
        ui.text(action,def[1])
        connect(action.Activated,function() quick.Visible=false;selected(def[2]) end)
    end
    local function togglePopover(panel, other)
        panel.Visible=not panel.Visible
        other.Visible=false
        if panel.Visible then
            local rest=panel==quick and UDim2.new(0,5,1,-230) or UDim2.new(0,0,1,-201)
            panel.Position=rest+UDim2.fromOffset(0,12)
            animate(panel,.19,{Position=rest})
        end
    end
    local emojiPanel=instance("Frame",{Name="Emojis",Position=UDim2.new(0,0,1,-201),Size=UDim2.new(1,-2,0,108),
        BackgroundColor3=COLORS.deep,Visible=false,BorderSizePixel=0,ZIndex=5},frame)
    corner(emojiPanel,18);stroke(emojiPanel,COLORS.border,1)
    connect(plusBtn.Activated,function() togglePopover(quick,emojiPanel) end)
    connect(emoji.Activated,function() togglePopover(emojiPanel,quick) end)
    local commonEmojis={"💜","😂","🔥","😍","👍","🎮","👋","👏","🙌","😎","😅","❤️"}
    for i,glyph in ipairs(commonEmojis) do
        local b=btn(emojiPanel,glyph,{Position=UDim2.new(((i-1)%6)/6,0,math.floor((i-1)/6)/2,1),Size=UDim2.new(1/6,-2,.5,-2),
            TextSize=26,BackgroundTransparency=1,ZIndex=6})
        connect(b.Activated,function() input.Text=input.Text..glyph;emojiPanel.Visible=false;input:CaptureFocus() end)
    end
    local tab={frame=frame,title=title,hint=hint,scroll=scroll,layout=layout,input=input,send=send,
        count=0,entries={},channel=key,quick=quick,emojiPanel=emojiPanel,head=channelHead,online=onlinePill,onlineDot=onlineDot,composer=inputBar,scrollToBottom=scrollToBottom}
    function tab.refreshComposer()
        local length=#trimText(input.Text)
        if tab.reply and length>0 then length=length+#tab.reply.quote+1 end
        meter.Visible=length>0
        meter.Text=length.."/"..MAX_MESSAGE_BYTES
        meter.TextColor3=length>MAX_MESSAGE_BYTES and COLORS.bad or COLORS.quiet
        replyBar.Visible=tab.reply~=nil
        if tab.reply then replyLabel.Text=tr("replyTo",tab.reply.username) end
    end
    function tab.setReply(reply)
        tab.reply=reply
        tab.refreshComposer()
        tab.reflow()
    end
    connect(input:GetPropertyChangedSignal("Text"),tab.refreshComposer)
    connect(cancelReply.Activated,function() tab.setReply(nil) end)
    function tab.refreshSearch()
        local query=search.Visible and search.Text:lower():match("^%s*(.-)%s*$") or ""
        local found=0
        for _,entry in ipairs(tab.entries) do
            local searchable=entry:GetAttribute("HistorySearch")
            local matches=searchable and searchable:find(query,1,true)~=nil
            local blocked=state.blocked[tostring(entry:GetAttribute("MessageUID"))]
            local starred=not tab.onlyStars or entry:GetAttribute("Starred")==true
            entry.Visible=not blocked and starred and (query=="" or matches==true)
            if searchable and entry.Visible then found=found+1 end
        end
        results.Text=tr("searchCount",found)
    end
    local function setSearchVisible(visible)
        search.Visible=visible;results.Visible=visible;hint.Visible=not visible
        searchButton.Text=visible and "×" or "⌕"
        if not visible then
            search:ReleaseFocus()
            search.Text=""
        end
        tab.refreshSearch()
    end
    tab.closeSearch=function() setSearchVisible(false) end
    connect(search:GetPropertyChangedSignal("Text"),tab.refreshSearch)
    connect(searchButton.Activated,function()
        setSearchVisible(not search.Visible)
        if search.Visible then search:CaptureFocus() end
    end)
    local function setStars(enabled)
        tab.onlyStars=enabled
        starsButton.Text=enabled and "★" or "☆"
        tab.refreshSearch()
    end
    connect(starsButton.Activated,function() setStars(not tab.onlyStars) end)
    connect(latestButton.Activated,function() setStars(false);tab.closeSearch();scrollToBottom() end)
    function tab.jumpToQuote(quote)
        local match
        for _,entry in ipairs(tab.entries) do
            if entry:GetAttribute("QuoteKey")==quote and not state.blocked[tostring(entry:GetAttribute("MessageUID"))] then
                if match then ui.notice("quoteGone",false);return end
                match=entry
            end
        end
        if not match then ui.notice("quoteGone",false);return end
        setStars(false)
        tab.closeSearch()
        task.defer(function()
            if not match.Parent then return end
            local scale=math.max(.01,ui.scale.Scale*ui.motion.Scale)
            scroll.CanvasPosition=Vector2.new(0,math.max(0,scroll.CanvasPosition.Y+
                (match.AbsolutePosition.Y-scroll.AbsolutePosition.Y)/scale))
        end)
    end
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
        tab.roomStatus=lbl(control,"Nenhuma sala ativa",17,COLORS.quiet,{Position=UDim2.fromOffset(6,97),Size=UDim2.new(1,-166,0,25)})
        tab.copyCode=btn(control,"",{Name="CopyRoomCode",Position=UDim2.new(1,-154,0,96),
            Size=UDim2.fromOffset(148,32),TextSize=16,BackgroundColor3=COLORS.nav,Visible=false})
        ui.text(tab.copyCode,"copyCode")
        connect(tab.copyCode.Activated,function()
            if state.privateCode then ui.copyText(state.privateCode,"copiedCode") end
        end)
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
        scroll.Size=UDim2.new(1,-2,1,-scrollTop-extra-96-(tab.reply and 35 or 0))
        input.TextSize=compact and 17 or 20
        inputWell.Position=UDim2.fromOffset(compact and 68 or 84,14)
        inputWell.Size=UDim2.new(1,compact and -154 or -198,0,56)
        plusBtn.Position=UDim2.fromOffset(compact and 8 or 16,14)
        plusBtn.Size=UDim2.fromOffset(compact and 50 or 54,56)
        send.Position=UDim2.new(1,compact and -76 or -98,0,14)
        send.Size=UDim2.fromOffset(compact and 66 or 82,56)
        meter.Position=UDim2.new(1,compact and -88 or -104,1,-14)
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

local function plainMessage(key, message, localizedKey)
    local p=state.tabs[key]
    if not p then return end
    p.count=p.count+1
    local row=instance("Frame",{Name="SystemNote",Size=UDim2.new(1,-5,0,34),
        LayoutOrder=p.count,BackgroundTransparency=1},p.scroll)
    local line=lbl(row,tostring(message),17,COLORS.quiet,{
        Position=UDim2.fromOffset(3,2),Size=UDim2.new(1,-6,0,30),
        TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
    if localizedKey then ui.text(line,localizedKey) end
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
local function addMessage(key, uid, username, text, translated, messageId, sourceLang, gameTitle, placeId, authorAuthUid, sentTimestamp, history, accountName)
    if not state.alive or text=="" or state.blocked[tostring(uid)] then return end
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
    local quote,body=ui.quoteParts(originalText)
    if key=="local" then quote=nil;body=originalText end
    local handle=accountName or username
    local validName=type(handle)=="string" and #handle<=32 and handle:match("^[%w_]+$")
    local quoteKey=key~="local" and validName and ui.makeQuote(handle,originalText)
    local mentioned=not outgoing and ui.hasMention(body)
    local actualTranslation=translated and tostring(translated) or ""
    local showingTranslation=false
    local textFont=compact and 18 or 23
    local row=instance("Frame",{Name="Message",BackgroundTransparency=1,
        BorderSizePixel=0,LayoutOrder=p.count,Size=UDim2.new(1,-5,0,70)},p.scroll)
    row:SetAttribute("HistorySearch",(tostring(username).." "..tostring(handle).." "..originalText):lower())
    if quoteKey then row:SetAttribute("QuoteKey",quoteKey) end
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
    local quoteHeight=quote and 30 or 0
    if quote then
        local link=btn(bubble,quote,{Name="JumpToQuote",Position=UDim2.fromOffset(8,4),
            Size=UDim2.new(1,-16,0,25),TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd,
            BackgroundColor3=COLORS.deep})
        link.Activated:Connect(function() p.jumpToQuote(quote) end)
    end
    if mentioned then stroke(bubble,COLORS.gold,2) end
    local messageLabel=lbl(bubble,body,textFont,COLORS.light,{
        Position=UDim2.fromOffset(22,7+quoteHeight),Size=UDim2.new(1,outgoing and -68 or -44,1,-14-quoteHeight),
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center})
    local actions={}
    if not outgoing then
        local rowActions=instance("Frame",{Name="Actions",Position=UDim2.fromOffset(leftIndent+8,0),
            Size=UDim2.fromOffset(compact and maxBubbleWidth+4 or math.min(280,maxBubbleWidth+4),compact and 30 or 35),BackgroundTransparency=1},row)
        actions.root=rowActions
        local translateBtn=btn(rowActions,tr("translate"),{
            Position=UDim2.fromOffset(0,1),Size=UDim2.new(.46,-3,1,-2),
            BackgroundColor3=COLORS.violet,TextSize=compact and 12 or 15,
            TextColor3=COLORS.light})
        corner(translateBtn,20)
        actions.translate=translateBtn
        ui.text(translateBtn,"translate")
        if key~="local" and (tonumber(uid) or 0)>0 and messageId then
            local reportBtn=btn(rowActions,tr("reportAction"),{
                Position=UDim2.new(.46,0,0,1),Size=UDim2.new(.40,-4,1,-2),
                BackgroundColor3=COLORS.nav,TextSize=compact and 12 or 15,
                TextColor3=COLORS.lilac})
            corner(reportBtn,20);stroke(reportBtn,COLORS.border,1)
            actions.report=reportBtn
            ui.text(reportBtn,"reportAction")
        end
        if (tonumber(uid) or 0)>0 then
            -- Toque prolongado no avatar para ocultar o usuario localmente.
            if avatar then
                local holding=false
                avatar.InputBegan:Connect(function(input)
                    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                        holding=true
                        task.delay(.85,function()
                            if holding and state.alive and row.Parent then
                                ui.hidePlayer(uid,username)
                            end
                        end)
                    end
                end)
                avatar.InputEnded:Connect(function()holding=false end)
            end
        end
    end
    local utilities=instance("Frame",{Name="MessageTools",AnchorPoint=Vector2.new(outgoing and 1 or 0,0),
        Size=UDim2.fromOffset(1,32),BackgroundTransparency=1},row)
    local toolIndex=0
    local function messageTool(name,label,callback)
        local button=btn(utilities,label,{Name=name,Position=UDim2.fromOffset(toolIndex*48,0),
            Size=UDim2.fromOffset(43,31),TextSize=18,BackgroundColor3=COLORS.nav})
        toolIndex=toolIndex+1
        utilities.Size=UDim2.fromOffset(toolIndex*48-5,32)
        button.Activated:Connect(callback)
        return button
    end
    local star
    star=messageTool("StarMessage","☆",function()
        local enabled=row:GetAttribute("Starred")~=true
        row:SetAttribute("Starred",enabled)
        star.Text=enabled and "★" or "☆"
        p.refreshSearch()
        ui.notice(enabled and "savedMessage" or "unsavedMessage",true)
    end)
    if quoteKey then
        messageTool("ReplyMessage","↪",function()
            p.setReply({quote=quoteKey,username=username})
            p.input:CaptureFocus()
        end)
    end
    if validName and not outgoing and (tonumber(uid) or 0)>0 then
        messageTool("MentionPlayer","@",function()
            local prefix=p.input.Text
            if prefix~="" and not prefix:match("%s$") then prefix=prefix.." " end
            p.input.Text=prefix.."@"..handle.." "
            p.input:CaptureFocus()
        end)
    end
    if not outgoing and (tonumber(uid) or 0)>0 then
        messageTool("MutePlayer","⊘",function() ui.hidePlayer(uid,username) end)
    end
    if actions.report==nil and not outgoing and key=="local" then
        local reportBtn=btn(actions.root,tr("reportAction"),{Position=UDim2.new(.46,0,0,1),
            Size=UDim2.new(.40,-4,1,-2),BackgroundColor3=COLORS.nav,TextSize=compact and 12 or 15})
        ui.text(reportBtn,"reportAction")
        corner(reportBtn,20);stroke(reportBtn,COLORS.border,1)
        reportBtn.Activated:Connect(function()
            openedNative();toast(tr("report"),false)
        end)
    end
    if type(setclipboard)=="function" then
        if outgoing then
            actions.root=instance("Frame",{Name="Actions",AnchorPoint=Vector2.new(1,0),
                Size=UDim2.fromOffset(45,30),BackgroundTransparency=1},row)
        end
        local copyMessage=btn(actions.root,"⧉",{Name="CopyMessage",Position=UDim2.new(.86,0,0,1),
            Size=UDim2.new(.14,0,1,-2),TextSize=18,BackgroundColor3=COLORS.nav})
        if outgoing then
            copyMessage.Position=UDim2.fromOffset(0,1)
            copyMessage.Size=UDim2.new(1,0,1,-2)
        end
        copyMessage.Activated:Connect(function() ui.copyText(messageLabel.Text,"copiedMessage") end)
    end
    local reasonPanel=nil
    local function recalc()
        local str=showingTranslation and actualTranslation or body
        local y=boundTextHeight(str,textFont,bubbleWidth-(outgoing and 68 or 44))
        bubbleHeight=math.max(compact and 44 or 49,y+20)+quoteHeight
        bubble.Size=UDim2.fromOffset(bubbleWidth,bubbleHeight)
        actionsY=bubbleY+bubbleHeight+4
        if actions.root then
            actions.root.Position=outgoing and UDim2.new(1,-2,0,actionsY) or UDim2.fromOffset(leftIndent+8,actionsY)
        end
        if reasonPanel then reasonPanel.Position=UDim2.fromOffset(leftIndent,actionsY+(compact and 32 or 39)) end
        local toolsY=actionsY+(actions.root and (compact and 35 or 43) or 5)+reasonsHeight
        utilities.Position=outgoing and UDim2.new(1,-2,0,toolsY) or UDim2.fromOffset(leftIndent+8,toolsY)
        row.Size=UDim2.new(1,-5,0,toolsY+34)
    end
    if actions.translate and actualTranslation~="" and state.autoTranslate then
        showingTranslation=true;state.translationHits=state.translationHits+1
        ui.text(actions.translate,"original")
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
        if actions.root and not outgoing then actions.root.Size=UDim2.fromOffset(compact and maxBubbleWidth+4 or math.min(280,maxBubbleWidth+4),compact and 30 or 35) end
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
        actions.translate.Activated:Connect(function()
            if actualTranslation~="" then
                showingTranslation=not showingTranslation
                messageLabel.Text=showingTranslation and actualTranslation or body
                ui.text(actions.translate,showingTranslation and "original" or "translate")
                recalc();return
            end
            if key=="local" then toast(tr("noTranslation"),false);return end
            if translating then return end
            local target=state.language
            local source=sourceLang
            if source~="pt" and source~="en" and source~="es" then
                source=key=="brasil" and "pt" or key=="usa" and "en" or (target=="en" and "pt" or "en")
            end
            if source==target then ui.notice("alreadyTranslated",true);return end
            translating=true;ui.text(actions.translate,"translationBusy")
            task.spawn(function()
                local result,err=translateExternal(body,source,target)
                translating=false
                if not state.alive or not actions.translate.Parent then return end
                if result then
                    actualTranslation=result;showingTranslation=true
                    messageLabel.Text=result;ui.text(actions.translate,"original")
                    state.translationHits=state.translationHits+1;recalc()
                else
                    ui.text(actions.translate,"translate")
                    ui.notice("translationFailed",false,tostring(err))
                end
            end)
        end)
    end
    if actions.report then
        reasonPanel=instance("Frame",{Name="ReportReasons",Size=UDim2.fromOffset(maxBubbleWidth+4,30),
            BackgroundTransparency=1,Visible=false},row)
        local reasons={{"Ofensa","offense"},{"Spam","Spam"},{"Assedio","harassment"},{"Outro","other"}}
        for i,reason in ipairs(reasons) do
            local rb=btn(reasonPanel,tr(reason[2]),{Position=UDim2.new((i-1)/4,0,0,0),
                Size=UDim2.new(.25,-2,1,0),BackgroundColor3=COLORS.nav,
                TextColor3=COLORS.gold,TextSize=compact and 8 or 10})
            corner(rb,11);ui.text(rb,reason[2])
            rb.Activated:Connect(function()
                if reported then return end
                reported=true;ui.text(actions.report,"reportBusy")
                task.spawn(function()
                    local result,err=fbPost("/reports.json",{
                        reporter=player.Name,reporterUid=player.UserId,
                        reporterAuthUid=state.auth.uid or "",reported=username,
                        reportedUid=tonumber(uid) or 0,
                        reportedAuthUid=tostring(authorAuthUid or ""),
                        channel=key,ts=os.time(),messageId=tostring(messageId or ""),
                        message=originalText:sub(1,400),reason=reason[1],
                        game=tostring(gameTitle or ""):sub(1,72),placeId=tonumber(placeId) or 0,
                        roomCode=key=="privado" and tostring(state.privateCode or "") or "",
                        status="pending"
                    })
                    if not state.alive or not actions.report.Parent then return end
                    if result then
                        ui.text(actions.report,"reportSent");reasonPanel.Visible=false
                        reasonsHeight=0;recalc();ui.notice("reportSent",true)
                    else
                        reported=false;ui.text(actions.report,"reportAction")
                        ui.notice("reportError",false,tostring(err))
                    end
                end)
            end)
        end
        actions.report.Activated:Connect(function()
            if reported then return end
            showReasons=not showReasons
            reasonPanel.Visible=showReasons
            reasonsHeight=showReasons and 34 or 0
            recalc()
        end)
    end
    -- Anima o balão dentro da linha, sem alterar o layout ou mover o campo de texto.
    if prefs.motion and state.active==key and not state.minimized then
        local bubbleScale=instance("UIScale",{Scale=.94},bubble)
        animate(bubbleScale,.24,{Scale=1})
        animate(bubble,.24,{BackgroundTransparency=0})
    else
        bubble.BackgroundTransparency=0
    end
    table.insert(p.entries,row)
    if #p.entries>MAX_MESSAGES then
        local old=table.remove(p.entries,1);if old then old:Destroy() end
    end
    p.refreshSearch()
    if outgoing and not history then p.scrollToBottom() end
    if not outgoing and not history and not prefs.mutedChannels[key] and (mentioned or not prefs.mentionsOnly)
        and (state.active~=key or state.minimized) then
        state.unread[key]=math.min(99,(state.unread[key] or 0)+1)
        if mentioned then state.mentions[key]=true end
        ui.updateUnread()
    end
end

local settings=instance("ScrollingFrame",{Name="Settings",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,
    ScrollBarImageColor3=COLORS.accent,ScrollingDirection=Enum.ScrollingDirection.Y,
    CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
ui.settings={}
do
    local order=0
    local function item(object)
        order=order+1
        object.LayoutOrder=order
        return object
    end
    addPad(settings,10)
    makeList(settings,9)
    local title=item(lbl(settings,"",31,COLORS.light,{Font=Enum.Font.GothamBold}))
    ui.text(title,"settingsTab")
    local intro=item(lbl(settings,"",19,COLORS.quiet,{
        Size=UDim2.new(1,-14,0,0),AutomaticSize=Enum.AutomaticSize.Y}))
    ui.text(intro,"settingsIntro")
    local function section(key)
        local title=item(lbl(settings,"",16,COLORS.lilac,{
            Size=UDim2.new(1,-14,0,35),Font=Enum.Font.GothamBold}))
        ui.text(title,key)
    end
    local function control(id, key)
        local button=item(btn(settings,"",{
            Name=id,Size=UDim2.new(1,-14,0,60),BackgroundColor3=COLORS.panel,
            TextSize=19,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left}))
        corner(button,15)
        stroke(button,COLORS.border,1).Transparency=.25
        addPad(button,12)
        ui.settings[id]=button
        if key then ui.text(button,key) end
    end
    section("languageSection")
    control("language")
    control("translation")
    local note=item(lbl(settings,"",16,COLORS.quiet,{
        Size=UDim2.new(1,-14,0,0),AutomaticSize=Enum.AutomaticSize.Y}))
    ui.text(note,"translationHint")
    section("visualSection")
    control("motion")
    control("glow")
    control("badge")
    control("startup")
    control("reset","reset")
    section("alertsSection")
    control("mentionsOnly")
    for _,def in ipairs(tabDefs) do
        if messageTabs[def.key] then control("mute_"..def.key) end
    end
    control("unmutePlayers")
    section("toolsSection")
    control("connection","testConnection")
    control("clear","clear")
    control("creator")
    local notice=item(lbl(settings,"",16,COLORS.quiet,{
        Size=UDim2.new(1,-14,0,0),AutomaticSize=Enum.AutomaticSize.Y}))
    ui.text(notice,"externalNotice")
end

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
    local primary=i<=5
    local tab=btn(buttonsHolder,"",{Name=def.key,Size=UDim2.new(1,-2,0,compact and 94 or 104),
        BackgroundColor3=COLORS.nav,TextWrapped=true,AutoButtonColor=false,Visible=primary,LayoutOrder=i})
    corner(tab,28)
    local fill=gradient(tab,Color3.fromRGB(55,42,91),Color3.fromRGB(30,25,56),90)
    local edge=stroke(tab,Color3.fromRGB(89,65,143),1.4)
    local glow=ui.glow(tab,28,Color3.fromRGB(191,89,255),.6);glow.Visible=false
    local icon=ui.icon(tab,i<=4 and def.key or def.icon,34,UDim2.new(.5,-17,0,compact and 15 or 21))
    local label=lbl(tab,tr(def.label),compact and 17 or 21,COLORS.light,{Position=UDim2.new(0,0,1,-42),
        Size=UDim2.new(1,0,0,32),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold})
    local selectedDot=instance("Frame",{Name="ActiveDot",Size=UDim2.fromOffset(12,12),Position=UDim2.new(1,-21,0,11),
        Visible=false,BorderSizePixel=0,BackgroundColor3=COLORS.good},tab)
    round(selectedDot);ui.glow(selectedDot,6,COLORS.good,.75)
    local unread=lbl(tab,"",13,COLORS.light,{Name="UnreadCount",Position=UDim2.new(1,-35,0,8),
        Size=UDim2.fromOffset(27,21),BackgroundColor3=COLORS.bad,BackgroundTransparency=0,
        TextXAlignment=Enum.TextXAlignment.Center,Visible=false})
    round(unread)
    tabButtons[def.key]={button=tab,definition=def,edge=edge,dot=selectedDot,fill=fill,glow=glow,label=label,icon=icon,unread=unread}
    ui.nav[def.key]=tabButtons[def.key]
    connect(tab.Activated,function() selected(def.key) end)
end
-- Hover e pressão sem alterar tamanhos calculados pelo layout.
function ui.bindButton(b)
    if not b:IsA("TextButton") then return end
    local scale=instance("UIScale",{Scale=1},b)
    b.MouseEnter:Connect(function() animate(scale,.13,{Scale=prefs.motion and 1.025 or 1}) end)
    b.MouseLeave:Connect(function() animate(scale,.16,{Scale=1}) end)
    b.MouseButton1Down:Connect(function() animate(scale,.08,{Scale=prefs.motion and .96 or 1}) end)
    b.MouseButton1Up:Connect(function() animate(scale,.15,{Scale=1}) end)
end
for _,object in ipairs(main:GetDescendants()) do ui.bindButton(object) end
connect(main.DescendantAdded,function(object) ui.bindButton(object) end)
ui.fit()

ui.tabLabels={["local"]="localTab",global="globalTab",brasil="brTab",usa="usTab",privado="privateTab"}
ui.languageNames={pt="Português (Brasil)",en="English (US)",es="Español"}
ui.statusKey="connecting"
ui.statusArgs=table.pack()
ui.text(creatorHead,"creatorTab")
ui.text(creatorHint,"creatorHint")
ui.text(creatorEmail,"creatorEmail","PlaceholderText")
ui.text(creatorPassword,"creatorPassword","PlaceholderText")
ui.text(creatorLoginBtn,"signIn")
ui.text(creatorRefresh,"refresh")
ui.text(creatorLogout,"signOut")
ui.text(debugTitle,"debugTab")
ui.text(copyButton,"copy")
do
    local private=state.tabs.privado
    ui.text(private.createBtn,"createRoom")
    ui.text(private.joinBtn,"joinRoom")
    ui.text(private.roomCode,"roomCode","PlaceholderText")
    ui.text(private.recipient,"inviteName","PlaceholderText")
    ui.text(private.inviteBtn,"sendInvite")
end

function ui.updateRoomText()
    local tab=state.tabs.privado
    local label=state.privateCode and tr("room",state.privateCode)
    tab.hint.Text=label and label.." • Firebase" or tr("privateHint")
    tab.roomStatus.Text=label and "🔒 "..label or tr("noRoom")
    tab.copyCode.Visible=state.privateCode~=nil and type(setclipboard)=="function"
end

local function updateLabels()
    for object, binding in pairs(ui.localized) do
        if object.Parent then object[binding.property]=tr(binding.key) end
    end
    for _,p in pairs(tabButtons) do
        p.label.Text=tr(p.definition.label)
    end
    local hints={["local"]="localOnly",global="globalInfo",brasil="brazilWelcome",usa="usWelcome"}
    for key,tab in pairs(state.tabs) do
        tab.title.Text=tr(ui.tabLabels[key])
        if hints[key] then tab.hint.Text=tr(hints[key]) end
        tab.input.PlaceholderText=tr("typeHere")
        tab.refreshSearch()
        tab.refreshComposer()
    end
    ui.updateRoomText()
    local language=ui.languageNames[state.language]
    if prefs.language=="auto" then language=tr("auto").." · "..language end
    local function toggle(button, key, value)
        button.Text=(value and "✓  " or "○  ")..tr(key)
        button.TextColor3=value and COLORS.light or COLORS.quiet
        button.BackgroundColor3=value and COLORS.nav or COLORS.panel
    end
    ui.settings.language.Text=tr("language").."  •  "..language
    ui.settings.startup.Text=tr("startup").."  •  "..tr(ui.tabLabels[prefs.startup])
    ui.settings.creator.Text=tr(state.admin.token and "creatorOpen" or "creatorLogin")
    toggle(ui.settings.translation,"enableTranslation",state.autoTranslate)
    toggle(ui.settings.motion,"motion",prefs.motion)
    toggle(ui.settings.glow,"glow",prefs.glow)
    toggle(ui.settings.badge,"unreadBadge",prefs.badge)
    toggle(ui.settings.mentionsOnly,"mentionsOnly",prefs.mentionsOnly)
    for key in pairs(state.tabs) do
        local button=ui.settings["mute_"..key]
        button.Text=(prefs.mutedChannels[key] and "✓  " or "○  ")..tr("mutedChannel",tr(ui.tabLabels[key]))
        button.BackgroundColor3=prefs.mutedChannels[key] and COLORS.nav or COLORS.panel
    end
    local blockedCount=0
    for _ in pairs(state.blocked) do blockedCount=blockedCount+1 end
    ui.settings.unmutePlayers.Text=tr("unmutePlayers",blockedCount)
    reportInfo.Text=tr("externalNotice").."\n"..tr("report")
    if ui.statusKey then statusBar.Text=tr(ui.statusKey,table.unpack(ui.statusArgs,1,ui.statusArgs.n)) end
end
retranslateUI=updateLabels

selected=function(key)
    local changed=ui.shownPage~=key
    if changed and ui.focusedInput then ui.focusedInput:ReleaseFocus() end
    if ui.pageTween then ui.pageTween:Cancel();ui.pageTween=nil end
    if ui.page then ui.page.Position=UDim2.fromOffset(0,0) end
    ui.shownPage=key
    state.active=key
    animate(ui.settingsButton,.18,{BackgroundColor3=key=="ajustes" and COLORS.violet or COLORS.nav})
    if not state.minimized then ui.markRead(key) else ui.updateUnread() end
    for k,p in pairs(state.tabs) do
        p.frame.Visible=(k==key)
        if k~=key then p.quick.Visible=false;p.emojiPanel.Visible=false;p.closeSearch() end
    end
    settings.Visible=(key=="ajustes");debugPanel.Visible=(key=="debug");creator.Visible=(key=="criador")
    for k,p in pairs(tabButtons) do
        local active=(key==k)
        animate(p.button,.19,{BackgroundColor3=Color3.new(1,1,1)})
        animate(p.edge,.2,{Color=active and Color3.fromRGB(218,127,255) or Color3.fromRGB(77,55,139),
            Thickness=active and 1.9 or 1})
        p.dot.Visible=active
        p.glow.Visible=active and prefs.glow
        p.fill.Color=active and ColorSequence.new(Color3.fromRGB(190,90,255),Color3.fromRGB(104,25,225))
            or ColorSequence.new(Color3.fromRGB(55,42,91),Color3.fromRGB(30,25,56))
    end
    if messageTabs[key] then
        if key=="local" then
            ui.notice("localOnly",true)
        elseif key=="privado" then
            if state.privateCode then ui.notice("room",true,state.privateCode)
            else ui.notice("privateWelcome",true) end
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
    ui.page=panel and panel.frame or (key=="ajustes" and settings or (key=="debug" and debugPanel or creator))
    if changed and prefs.motion then
        ui.page.Position=UDim2.fromOffset(0,13)
        ui.pageTween=animate(ui.page,.24,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quart)
    end
    refreshStatus()
end

refreshStatus=function()
    local lines={
        "GlobalChatHub V5.8.0 | NEON UI + FIREBASE AUTH",
        "PlaceId="..tostring(game.PlaceId),
        "Transport="..state.firebaseTransport,
        "FirebaseHTTP="..state.firebaseStatus,
        "AuthStatus="..state.auth.status,
        "AuthReady="..tostring(state.auth.uid~=nil),
        "FirebaseError="..state.firebaseError,
        "Channels=global,brasil,usa (independentes)",
        "ActiveTab="..state.active,
        "Language="..state.language.." ("..prefs.language..")",
        "StartupTab="..prefs.startup,
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



connect(ui.settingsButton.Activated,function()
    if state.active=="ajustes" then selected(ui.previousPage or prefs.startup)
    else ui.previousPage=state.active;selected("ajustes") end
end)
connect(ui.settings.creator.Activated,function() selected("criador") end)
connect(ui.settings.language.Activated,function()
    local nextMode={auto="pt",pt="en",en="es",es="auto"}
    prefs.language=nextMode[prefs.language]
    state.language=prefs.detectLanguage()
    prefs.save()
    retranslateUI()
    refreshStatus()
end)
connect(ui.settings.translation.Activated,function()
    state.autoTranslate=not state.autoTranslate
    prefs.save()
    retranslateUI()
end)
for _, key in ipairs({"motion","glow","badge"}) do
    connect(ui.settings[key].Activated,function()
        prefs[key]=not prefs[key]
        prefs.save()
        ui.setGlow()
        ui.updateUnread()
        retranslateUI()
    end)
end
connect(ui.settings.mentionsOnly.Activated,function()
    prefs.mentionsOnly=not prefs.mentionsOnly
    if prefs.mentionsOnly then state.unread={};state.mentions={} end
    prefs.save()
    ui.updateUnread()
    retranslateUI()
end)
for key in pairs(state.tabs) do
    connect(ui.settings["mute_"..key].Activated,function()
        prefs.mutedChannels[key]=not prefs.mutedChannels[key] or nil
        if prefs.mutedChannels[key] then ui.markRead(key) end
        prefs.save()
        retranslateUI()
    end)
end
connect(ui.settings.unmutePlayers.Activated,function()
    state.blocked={}
    prefs.save()
    retranslateUI()
end)
connect(ui.settings.startup.Activated,function()
    local nextTab={global="local",["local"]="brasil",brasil="usa",usa="global"}
    prefs.startup=nextTab[prefs.startup]
    prefs.save()
    retranslateUI()
    refreshStatus()
end)
connect(ui.settings.reset.Activated,function()
    prefs.language="auto";prefs.startup="global"
    prefs.motion=true;prefs.glow=true;prefs.badge=true;state.autoTranslate=false
    prefs.mentionsOnly=false;prefs.mutedChannels={};state.blocked={}
    state.language=prefs.detectLanguage()
    prefs.save()
    ui.setGlow()
    ui.updateUnread()
    retranslateUI()
    ui.notice("resetDone",true)
    refreshStatus()
end)
connect(ui.settings.connection.Activated,function()
    ui.notice("testing",true)
    task.spawn(function()
        local data,err=fbGet("/ping.json")
        if not state.alive then return end
        if data~=nil then ui.notice("firebaseReply",true,state.firebaseStatus)
        else toast("❌ Firebase: "..tostring(err),false) end
        refreshStatus()
    end)
end)
connect(ui.settings.clear.Activated,function()
    for _,tab in pairs(state.tabs) do
        for _,entry in ipairs(tab.entries) do entry:Destroy() end
        tab.entries={}
        tab.count=0
        tab.refreshSearch()
    end
    state.unread={}
    state.mentions={}
    ui.updateUnread()
    ui.notice("chatCleared",true)
end)
connect(copyButton.Activated,function()
    local value=refreshStatus()
    if type(setclipboard)=="function" then
        local ok=pcall(setclipboard,value)
        ui.notice(ok and "copied" or "copyFailed",ok)
    else
        print(value);ui.notice("console",true)
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
    local draft=text
    local panel=state.tabs[key]
    local reply=panel.reply
    local generation=state.roomGeneration
    text=trimText(text)
    if text=="" then return end
    if reply then text=reply.quote.."\n"..text end
    if #text>MAX_MESSAGE_BYTES then ui.notice("tooLarge",false);return end
    local when=state.sentByTab[key] or -100
    if os.clock()-when<2.0 then toast(tr("wait"),false);return end
    if state.pendingSend[key] then ui.notice("sendPending",false);return end
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
            if panel.input.Text==draft then panel.input.Text="" end
            ui.notice("localSent",true)
        end)
        return
    end
    local path=nil
    if CHANNEL_PATHS[key] then path="/"..CHANNEL_PATHS[key]..".json"
    elseif key=="privado" and state.privateCode then
        path="/rooms/"..state.privateCode.."/msgs.json"
    end
    if not path then ui.notice("needRoom",false);return end
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
            if key~="privado" or generation==state.roomGeneration then
                if panel.input.Text==draft and panel.reply==reply then
                    panel.input.Text=""
                    panel.setReply(nil)
                end
            else
                local roomDraft=panel.roomDrafts and panel.roomDrafts[path]
                if roomDraft and roomDraft.text==draft and roomDraft.reply==reply then panel.roomDrafts[path]=nil end
            end
            ui.notice("firebaseSent",true)
            local sentPanel=state.tabs[key]
            if sentPanel then
                sentPanel.scrollToBottom()
                animate(sentPanel.send,.1,{BackgroundColor3=COLORS.good})
                task.delay(.22,function() if state.alive then animate(sentPanel.send,.25,{BackgroundColor3=Color3.new(1,1,1)}) end end)
            end
        else
            errorState(err)
            ui.notice("sendFailed",false,tostring(err))
        end
        refreshStatus()
    end)
end
for key,p in pairs(state.tabs) do
    connect(p.send.Activated,function() sendMessage(key,p.input.Text) end)
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
            currentGameName,currentPlaceId,nil,message.Timestamp and message.Timestamp.UnixTimestamp or os.time(),
            false,sender and sender.Name)
    end)
    if not ok then errorState(err) end
end
connect(TextChatService.MessageReceived,receiveLocal)

local function getRoomInfo(code)
    if not codeValid(code) then return nil,tr("invalidRoom") end
    local info,err=fbGet("/rooms/"..code.."/info.json")
    if not info then return nil,err end
    if type(info)~="table" or not info.c then return nil,tr("missingRoom") end
    return info,nil
end
local function joinRoom(code)
    code=tostring(code or ""):upper():gsub("%s+","")
    if not codeValid(code) then ui.notice("invalidRoom",false);return end
    local tab=state.tabs.privado
    tab.joinAttempt=(tab.joinAttempt or 0)+1
    local attempt=tab.joinAttempt
    task.spawn(function()
        local info,err=getRoomInfo(code)
        if not state.alive or tab.joinAttempt~=attempt then return end
        if not info then toast("❌ "..tostring(err),false);return end
        if state.privateCode==code then selected("privado");return end
        tab.roomDrafts=tab.roomDrafts or {}
        if state.privateCode then
            local previousPath="/rooms/"..state.privateCode.."/msgs.json"
            tab.roomDrafts[previousPath]={text=tab.input.Text,reply=tab.reply}
        end
        state.roomGeneration=state.roomGeneration+1
        state.privateCode=code
        local saved=tab.roomDrafts["/rooms/"..code.."/msgs.json"]
        tab.input.Text=saved and saved.text or ""
        tab.setReply(saved and saved.reply)
        ui.updateRoomText()
        tab.roomCode.Text=code
        for _,row in ipairs(tab.entries) do pcall(function() row:Destroy() end) end
        tab.entries={};tab.count=0
        tab.closeSearch()
        ui.markRead("privado")
        plainMessage("privado",tr("roomJoined",code))
        selected("privado")
    end)
end
local function createRoom()
    local p=state.tabs.privado
    if p.creating then return end
    p.creating=true
    ui.text(p.createBtn,"creatingRoom")
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
            if not token then
                p.creating=false
                if state.alive then ui.text(p.createBtn,"createRoom");toast("Login Firebase: "..tostring(authErr),false) end
                return
            end
            local created,err=fbPut("/rooms/"..chosen.."/info.json",{
                c=player.Name,uid=player.UserId,creatorAuthUid=state.auth.uid,
                ts=os.time(),v="5.3"
            },token)
            if created then joinRoom(chosen)
            else toast("Erro ao criar: "..tostring(err),false) end
        else
            toast("Não foi possível reservar um código de sala",false)
        end
        p.creating=false
        if state.alive then ui.text(p.createBtn,"createRoom") end
    end)
end
local pPrivate=state.tabs.privado
connect(pPrivate.createBtn.Activated,createRoom)
connect(pPrivate.joinBtn.Activated,function() joinRoom(pPrivate.roomCode.Text) end)
connect(pPrivate.roomCode.FocusLost,function(enter)
    if enter then joinRoom(pPrivate.roomCode.Text) end
end)
connect(pPrivate.inviteBtn.Activated,function()
    if not state.privateCode then ui.notice("needRoom",false);return end
    local target=trimText(pPrivate.recipient.Text)
    if not target:match("^[%w_]+$") or #target<3 or #target>20 then
        ui.notice("inviteUsername",false);return
    end
    if target:lower()==player.Name:lower() then ui.notice("inviteSelf",false);return end
    if os.clock()-state.inviteLast<8 then ui.notice("inviteCooldown",false);return end
    state.inviteLast=os.clock()
    task.spawn(function()
        local token,authErr=playerToken()
        if not token then toast("Login Firebase: "..tostring(authErr),false);return end
        local result,err=fbPost("/invites/"..cleanUser(target)..".json",{
            from=player.Name,fromUid=player.UserId,fromAuthUid=state.auth.uid,
            code=state.privateCode,ts=os.time(),to=target
        },token)
        if not state.alive then return end
        if result then ui.notice("inviteSent",true)
        else ui.notice("inviteError",false,tostring(err)) end
    end)
end)

-- Convites Firebase sao indexados por username, compatíveis com a versao 4.1.
local function showInvite(from,code)
    if state.currentInvite then return end
    state.currentInvite={from=from,code=code}
    local p=state.tabs.privado
    plainMessage("privado",tr("roomInvite",from,code))
    if not p.prompt then
        local panel=instance("Frame",{Position=UDim2.new(0,0,1,-134),
            Size=UDim2.new(1,0,0,35),BackgroundColor3=COLORS.deep,BorderSizePixel=0},p.frame)
        corner(panel,8)
        p.prompt=panel
        p.accept=btn(panel,"✔ ENTRAR",{Size=UDim2.new(.5,-3,1,0),BackgroundColor3=COLORS.good})
        p.decline=btn(panel,"✖ RECUSAR",{Position=UDim2.new(.5,3,0,0),Size=UDim2.new(.5,-3,1,0),BackgroundColor3=COLORS.bad})
        ui.text(p.accept,"accept")
        ui.text(p.decline,"refuse")
        connect(p.accept.Activated,function()
            local inv=state.currentInvite
            state.currentInvite=nil;p.prompt.Visible=false
            if inv then joinRoom(inv.code) end
        end)
        connect(p.decline.Activated,function()
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
                b.Activated:Connect(function()
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
            unban.Activated:Connect(function() moderateAuthUid(target,"unban",entry.id) end)
            local deleteBtn=btn(line,"🗑️ APAGAR MENSAGEM DO FIREBASE",{
                Size=UDim2.new(1,-12,0,28),TextSize=17,BackgroundColor3=COLORS.bad})
            local deleteConfirmed=false
            deleteBtn.Activated:Connect(function()
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
            resolve.Activated:Connect(function()
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
connect(creatorLoginBtn.Activated,function()
    if state.admin.loginPending then return end
    local email=trimText(creatorEmail.Text)
    local password=creatorPassword.Text
    creatorPassword.Text="" -- nao manter senha no TextBox
    if not email:find("@",1,true) or #password<6 then
        toast("Informe email e senha Firebase Auth validos",false);return
    end
    state.admin.loginPending=true
    ui.text(creatorLoginBtn,"validating")
    task.spawn(function()
        local result,err=firebaseAuthEmail(email,password)
        password=nil
        if not state.alive then return end
        state.admin.loginPending=false
        ui.text(creatorLoginBtn,"signIn")
        if not result then toast("Login falhou: "..tostring(err),false);return end
        -- Mesmo que a UI leia um papel falso, /reports e /moderation continuam protegidos nas Rules.
        local role,roleErr=fbGet("/admins/"..tostring(result.localId)..".json",result.idToken)
        if role~=true then toast("Conta sem permissao de criador: "..tostring(roleErr or "nao autorizada"),false);return end
        local a=state.admin
        a.token=result.idToken;a.refreshToken=result.refreshToken
        a.uid=result.localId;a.expireAt=os.time()+(tonumber(result.expiresIn) or 3600)
        creatorLogin.Visible=false;creatorDashboard.Visible=true
        tabButtons.criador.button.Visible=false
        retranslateUI()
        toast("👑 Criador autenticado",true)
        loadCreatorReports()
    end)
end)
connect(creatorRefresh.Activated,loadCreatorReports)
connect(creatorLogout.Activated,function()
    local a=state.admin
    a.token=nil;a.refreshToken=nil;a.uid=nil;a.expireAt=0;a.reportSeen={}
    creatorDashboard.Visible=false;creatorLogin.Visible=true
    tabButtons.criador.button.Visible=false
    retranslateUI()
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
        local lastConnectionError
        local seen={}
        while state.alive do
            local data,err=fbList(path)
            if not state.alive then break end
            if type(data)=="table" then
                lastConnectionError=nil
                local history=first
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
                    local notice=#messages==0 and "emptyChannel" or "connected"
                    plainMessage(key,tr(notice),notice)
                    first=false
                end
                for _,it in ipairs(messages) do
                    local m=it.m
                    local content=tostring(m.t or ""):sub(1,400)
                    addMessage(key,tonumber(m.uid) or 0,tostring(m.u or "?"),content,
                        nil,tostring(it.id),m.lg,
                        m.gn or (type(m.g)=="string" and not tonumber(m.g) and m.g or nil),
                        m.pid or m.g,m.authUid,m.ts,history)
                end
            elseif first and lastConnectionError~=tostring(err) then
                lastConnectionError=tostring(err)
                plainMessage(key,tr("connectionLost",lastConnectionError))
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
            local data=fbList("rooms/"..code.."/msgs")
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
                local history=first
                if first and #messages==0 then plainMessage("privado",tr("emptyRoom"),"emptyRoom") end
                first=false
                for _,it in ipairs(messages) do
                    local m=it.m
                    addMessage("privado",tonumber(m.uid) or 0,tostring(m.u or "?"),
                        tostring(m.t or ""):sub(1,400),nil,tostring(it.id),m.lg,
                        m.gn or (type(m.g)=="string" and not tonumber(m.g) and m.g or nil),
                        m.pid or m.g,m.authUid,m.ts,history)
                end
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
                    or tr("unavailable")
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

ui.bubbleMotion=instance("UIScale",{Scale=1},bubble)
local animatingWindow=false
local function minimize()
    if animatingWindow or state.minimized then return end
    animatingWindow=true;state.minimized=true
    if ui.focusedInput then ui.focusedInput:ReleaseFocus() end
    local panel=state.tabs[state.active]
    if panel then panel.closeSearch() end
    ui.fit()
    if prefs.motion then animate(ui.motion,.18,{Scale=.94},Enum.EasingStyle.Quart,Enum.EasingDirection.In) end
    local function hide()
        if not state.alive then return end
        main.Visible=false;bubble.Visible=true
        bubble.Size=UDim2.fromOffset(55,55)
        if prefs.motion then
            ui.bubbleMotion.Scale=.72
            animate(ui.bubbleMotion,.27,{Scale=1},Enum.EasingStyle.Back)
        end
        animatingWindow=false
    end
    if prefs.motion then task.delay(.19,hide) else hide() end
end
local function restore()
    if bubbleMoved then bubbleMoved=false;return end
    if animatingWindow or not state.minimized then return end
    state.minimized=false;main.Visible=true;bubble.Visible=false
    ui.motion.Scale=prefs.motion and .94 or 1
    animate(ui.motion,.25,{Scale=1},Enum.EasingStyle.Quart)
    ui.markRead(state.active)
end
connect(minBtn.Activated,minimize)
connect(bubble.Activated,restore)
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
connect(closeBtn.Activated,shutdown)

retranslateUI()
selected(prefs.startup)
ui.motion.Scale=prefs.motion and .91 or 1
animate(ui.motion,.36,{Scale=1},Enum.EasingStyle.Quart)
for key, welcome in pairs({
    global="globalWelcome", brasil="brazilWelcome", usa="usWelcome",
    privado="privateWelcome", ["local"]="localWelcome",
}) do
    plainMessage(key,tr(welcome),welcome)
end

task.spawn(function()
    local ok, country=pcall(function() return Localization:GetCountryRegionForPlayerAsync(player) end)
    if not state.alive or not ok or type(country)~="string" then return end
    prefs.region=string.upper(country)
    local language=prefs.detectLanguage()
    if language~=state.language then
        state.language=language
        retranslateUI()
        refreshStatus()
    end
end)
-- O painel Debug mostra o status em tempo real e os erros do backend.


print("[GlobalChatHub V5.8.0] Neon Chat UI + Firebase REST")
