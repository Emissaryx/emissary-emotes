EmissaryEmotes = EmissaryEmotes or {}
EmissaryEmotes.Settings = EmissaryEmotes.Settings or {}
EmissaryEmotes.Data = EmissaryEmotes.Data or {}
local EE=EmissaryEmotes
local WINDOW="EmissaryEmotesWindow"
local TOGGLE="EmissaryEmotes_Toggler"
local MAX_BUTTONS=90
local COLS=4
local TAB_NAMES={"All","Favorites","Recent","Social","Poses","Fun"}
local SOCIAL={wave=true,bow=true,hello=true,bye=true,salute=true,thank=true,thanks=true,agree=true,disagree=true,yes=true,no=true,cheer=true,clap=true,point=true,smile=true,laugh=true,lol=true,sorry=true}
local FUN={dance=true,drink=true,drunk=true,eat=true,fart=true,puke=true,pig=true,chicken=true,howl=true,waaagh=true,warcry=true,warhammer=true,zombie=true,peck=true,karen=true,okboomer=true,showoff=true,flex=true,pickteeth=true}
-- CSV also contains internal/system commands that happen to have animation IDs.
-- These are not player emotes and must never be sent as slash emotes.
local BLOCKED={chairsit=true,kick=true}
EE.currentTab="All"; EE.currentPage=1; EE.visible={}; EE.buttonToEmote={}; EE.tabByWindow={}
EE.perPage=40
EE.cols=4
EE.rows=10
local function W(s) return towstring(s or "") end
local function lower(s) return string.lower(tostring(s or "")) end
local function fav(c) return EE.Settings.favorites and EE.Settings.favorites[c]==true end
local function recent(c) if not EE.Settings.recent then return false end for _,v in ipairs(EE.Settings.recent) do if v==c then return true end end return false end
local function realEmote(e)
 local c=e and lower(e.command) or ""
 return e and c~="" and not BLOCKED[c] and e.anim and tostring(e.anim)~=""
end
local function matches(e)
 local c=lower(e.command)
 if EE.currentTab=="All" then return true end
 if EE.currentTab=="Favorites" then return fav(c) end
 if EE.currentTab=="Recent" then return recent(c) end
 if EE.currentTab=="Social" then return SOCIAL[c]==true end
 if EE.currentTab=="Fun" then return FUN[c]==true end
 if EE.currentTab=="Poses" then local t=string.upper(tostring(e.transition or "")); return t~="" and t~="STAND" end
 return true
end

-- Launcher lock state. Right-click the icon to toggle.
EE.launcherLocked = EE.launcherLocked or false

function EE.ApplyLauncherLock()
 if DoesWindowExist(TOGGLE) then
  WindowSetMovable(TOGGLE, not EE.launcherLocked)
 end
end

function EE.ToggleLauncherLock()
 EE.launcherLocked = not EE.launcherLocked
 EE.ApplyLauncherLock()
 if EE.launcherLocked then
  TextLogAddEntry("Chat",0,L"Emissary Emotes icon locked.")
 else
  TextLogAddEntry("Chat",0,L"Emissary Emotes icon unlocked.")
 end
end

function EE.ApplyIconVisibility()
 if DoesWindowExist(TOGGLE) then
  WindowSetShowing(TOGGLE, EE.Settings.iconVisible ~= false)
 end
end

function EE.ToggleIconVisibility()
 EE.Settings.iconVisible = not (EE.Settings.iconVisible ~= false)
 EE.ApplyIconVisibility()
 if EE.Settings.iconVisible then
  TextLogAddEntry("Chat",0,L"Emissary Emotes icon shown.")
 else
  TextLogAddEntry("Chat",0,L"Emissary Emotes icon hidden. Type /ee to open Emissary Emotes or /ee icon to show the icon again.")
 end
end

function EE.SlashCommand(text)
 local arg=lower(text)
 arg=string.gsub(arg,"^%s+","")
 arg=string.gsub(arg,"%s+$","")
 if arg=="" then
  EE.Toggle()
 elseif arg=="icon" then
  EE.ToggleIconVisibility()
 elseif arg=="show" then
  WindowSetShowing(WINDOW,true); EE.Refresh()
 elseif arg=="hide" then
  WindowSetShowing(WINDOW,false)
 else
  TextLogAddEntry("Chat",0,L"Emissary Emotes: /ee = open/close, /ee icon = show/hide icon")
 end
end


local function EEAnchor(win, point, rel, relpoint, x, y)
 WindowClearAnchors(win)
 WindowAddAnchor(win,point,rel,relpoint,x,y)
end

function EE.ApplyWindowSize(width,height)
 width=tonumber(width) or tonumber(EE.Settings.windowWidth) or 820
 height=tonumber(height) or tonumber(EE.Settings.windowHeight) or 510

 -- Keep the frame usable.
 if width<720 then width=720 end
 if height<430 then height=430 end
 if width>1180 then width=1180 end
 if height>760 then height=760 end

 WindowSetDimensions(WINDOW,width,height)

 -- Responsive grid: add/remove columns and rows based on available space.
 local left=24
 local top=118
 local gapX=14
 local gapY=2
 local buttonH=27
 local minButtonW=145
 local usableW=width-48
 local cols=math.floor((usableW+gapX)/(minButtonW+gapX))
 if cols<4 then cols=4 end
 if cols>6 then cols=6 end

 local footerH=78
 local usableH=height-top-footerH
 local rows=math.floor((usableH+gapY)/(buttonH+gapY))
 if rows<8 then rows=8 end
 if rows>15 then rows=15 end

 local buttonW=math.floor((usableW-(cols-1)*gapX)/cols)
 EE.cols=cols
 EE.rows=rows
 EE.perPage=cols*rows

 WindowSetDimensions(WINDOW.."Body",width-20,height-54)
 WindowSetDimensions(WINDOW.."ModeHeader",width-28,26)
 WindowSetDimensions(WINDOW.."Content",width-28,height-204)
 WindowSetDimensions(WINDOW.."FooterBg",width-28,54)
 WindowSetDimensions(WINDOW.."FooterRule",width-28,2)

 local tabGap=7
 local tabLeft=14
 local tabWidth=math.floor((width-28-(5*tabGap))/6)
 for i=1,#TAB_NAMES do
  local tw=WINDOW.."Tab"..i
  WindowSetDimensions(tw,tabWidth,28)
  WindowSetDimensions(tw.."Label",tabWidth,28)
  EEAnchor(tw,"topleft",WINDOW,"topleft",tabLeft+(i-1)*(tabWidth+tabGap),46)
 end

 for i=1,MAX_BUTTONS do
  local w=WINDOW.."Emote"..i
  local idx=i-1
  local col=math.mod(idx,cols)
  local row=math.floor(idx/cols)
  WindowSetDimensions(w,buttonW,buttonH)
  EEAnchor(w,"topleft",WINDOW,"topleft",left+col*(buttonW+gapX),top+row*(buttonH+gapY))
 end

 local footerY=height-78
 EEAnchor(WINDOW.."FooterBg","topleft",WINDOW,"topleft",14,footerY)
 EEAnchor(WINDOW.."FooterRule","topleft",WINDOW,"topleft",14,footerY)
 EEAnchor(WINDOW.."Prev","topleft",WINDOW,"topleft",28,footerY+14)
 EEAnchor(WINDOW.."Next","topright",WINDOW,"topright",-28,footerY+14)
 WindowSetDimensions(WINDOW.."PageLabel",width-390,28)
 EEAnchor(WINDOW.."PageLabel","top",WINDOW,"top",0,footerY+14)

 -- Keep the grip on the lower-right corner.
 EEAnchor(WINDOW.."ResizeGrip","bottomright",WINDOW,"bottomright",-5,-5)
 LabelSetText(WINDOW.."ResizeGripLabel",L"//")

 EE.Settings.windowWidth=width
 EE.Settings.windowHeight=height
 EE.appliedWindowWidth=width
 EE.appliedWindowHeight=height
 EE.Refresh()
end

function EE.StartResize()
 WindowUtils.BeginResize(WINDOW,"topleft",720,430,nil)
end

function EE.StopResize()
 -- WAR/WindowUtils owns mouse release and finishes the native resize.
end

function EE.OnResizeGripMouseOver()
 Tooltips.CreateTextOnlyTooltip(WINDOW.."ResizeGrip",nil)
 Tooltips.SetTooltipText(1,1,L"Drag to resize")
 Tooltips.SetTooltipText(2,1,L"Window size is remembered")
 Tooltips.Finalize()
 Tooltips.AnchorTooltip(Tooltips.ANCHOR_WINDOW_TOP)
end

function EE.OnLauncherMouseOver()
 Tooltips.CreateTextOnlyTooltip(TOGGLE,nil)
 Tooltips.SetTooltipText(1,1,L"Emissary Emotes")
 Tooltips.SetTooltipText(2,1,L"Left-click: open / close")
 if EE.launcherLocked then
  Tooltips.SetTooltipText(3,1,L"Right-click: unlock icon")
 else
  Tooltips.SetTooltipText(3,1,L"Right-click: lock icon")
 end
 Tooltips.SetTooltipText(4,1,L"/ee icon: show / hide icon")
 Tooltips.Finalize()
 Tooltips.AnchorTooltip(Tooltips.ANCHOR_WINDOW_BOTTOM_RIGHT)
end



function EE.UpdateResize()
 if WindowGetResizing and WindowGetResizing(WINDOW) then
  return
 end

 local w,h=WindowGetDimensions(WINDOW)
 if not w or not h then return end

 local aw=EE.appliedWindowWidth
 local ah=EE.appliedWindowHeight
 if not aw or not ah then
  EE.appliedWindowWidth=w
  EE.appliedWindowHeight=h
  return
 end

 if w~=aw or h~=ah then
  EE.ApplyWindowSize(w,h)
 end
end


function EE.UpdatePagingButtonColors()
 local total=#(EE.filtered or {})
 local perPage=EE.perPage or 1
 local pages=math.max(1,math.ceil(total/perPage))
 local page=EE.page or 1

 local prevEnabled=page>1
 local nextEnabled=page<pages

 -- Enabled paging text keeps the addon gold. Disabled paging text uses the
 -- same muted gray-gold on both sides.
 if prevEnabled then
  ButtonSetTextColor(WINDOW.."Prev",Button.ButtonState.NORMAL,235,201,73)
 else
  ButtonSetTextColor(WINDOW.."Prev",Button.ButtonState.NORMAL,125,118,96)
 end

 if nextEnabled then
  ButtonSetTextColor(WINDOW.."Next",Button.ButtonState.NORMAL,235,201,73)
 else
  ButtonSetTextColor(WINDOW.."Next",Button.ButtonState.NORMAL,125,118,96)
 end
end

function EE.Initialize()
 if DoesWindowExist(TOGGLE) then WindowSetDimensions(TOGGLE,40,40) end
 -- Tortall's main meter does NOT use savesettings.  RoR was restoring an old
 -- saved height after XML/OnInitialize, which is why our footer appeared outside
 -- the frame.  The launcher alone uses savesettings/LayoutEditor.
 EE.Settings.favorites=EE.Settings.favorites or {}; EE.Settings.recent=EE.Settings.recent or {}; EE.Settings.tab=EE.Settings.tab or "All"; EE.currentTab=EE.Settings.tab
 if EE.Settings.iconVisible==nil then EE.Settings.iconVisible=true end
 EE.ApplyIconVisibility()
 if LibSlash then
  LibSlash.RegisterSlashCmd("ee",function(input) EE.SlashCommand(input) end)
  LibSlash.RegisterSlashCmd("emissaryemotes",function(input) EE.SlashCommand(input) end)
 end
 LabelSetText(WINDOW.."TitleBarText",L"Emissary Emotes")
 LabelSetText(WINDOW.."HintLabel",L"Left: play   Right: favorite")
 ButtonSetText(WINDOW.."Prev",L"<  PREVIOUS"); ButtonSetText(WINDOW.."Next",L"NEXT  >"); LabelSetText(WINDOW.."ModeHeaderTitle",L"EMOTE COLLECTION"); LabelSetText(WINDOW.."ModeHeaderSub",L"Left: play   Right: favorite")
 EE.SetupMaps(); for i=1,#TAB_NAMES do ButtonSetStayDownFlag(WINDOW.."Tab"..i,true) end; EE.ApplyWindowSize(EE.Settings.windowWidth,EE.Settings.windowHeight)
 TextLogAddEntry("Chat",0,L"Emissary Emotes v1.0 initialized.")
end
function EE.SetupMaps()
 for i,name in ipairs(TAB_NAMES) do local w=WINDOW.."Tab"..i; EE.tabByWindow[w]=name; LabelSetText(w.."Label",W(name)) end
 for i=1,MAX_BUTTONS do EE.buttonToEmote[WINDOW.."Emote"..i]=nil end
end
function EE.BuildVisible()
 EE.visible={}
 if EE.currentTab=="Recent" then
  for _,cmd in ipairs(EE.Settings.recent) do for _,e in ipairs(EE.Data) do if realEmote(e) and lower(e.command)==cmd then table.insert(EE.visible,e); break end end end
 else
  for _,e in ipairs(EE.Data) do if realEmote(e) and matches(e) then table.insert(EE.visible,e) end end
  table.sort(EE.visible,function(a,b) return lower(a.command)<lower(b.command) end)
 end
end
local function displayName(command)
 local s=tostring(command or "")
 s=s:gsub("^/","")
 s=s:gsub("_"," ")
 s=s:gsub("(%l)(%u)","%1 %2")
 return (s:gsub("(%a)([%w']*)",function(a,b) return string.upper(a)..string.lower(b) end))
end

function EE.Refresh()
 EE.BuildVisible(); local pages=math.max(1,math.ceil(#EE.visible/EE.perPage)); if EE.currentPage>pages then EE.currentPage=pages end; if EE.currentPage<1 then EE.currentPage=1 end
 local first=(EE.currentPage-1)*EE.perPage+1
 for i=1,MAX_BUTTONS do local w=WINDOW.."Emote"..i; local e=nil; if i<=EE.perPage then e=EE.visible[first+i-1] end; EE.buttonToEmote[w]=e
  if e then local isFav=fav(lower(e.command)); LabelSetText(w.."Label",W(displayName(e.command))); LabelSetText(w.."Star",isFav and L"*" or L""); WindowSetShowing(w,true) else WindowSetShowing(w,false) end
 end
 for i,name in ipairs(TAB_NAMES) do
  local w=WINDOW.."Tab"..i
  local pill=w.."Pill"
  if name==EE.currentTab then
   WindowSetShowing(pill,true)
   LabelSetTextColor(w.."Label",8,8,6)
   ButtonSetPressedFlag(w,true)
  else
   WindowSetShowing(pill,false)
   LabelSetTextColor(w.."Label",218,194,96)
   ButtonSetPressedFlag(w,false)
  end
 end
 LabelSetText(WINDOW.."PageLabel",W(EE.currentTab.."  |  "..#EE.visible.." emotes  |  Page "..EE.currentPage.." / "..pages))
 local canPrev=EE.currentPage>1
 local canNext=EE.currentPage<pages
 ButtonSetDisabledFlag(WINDOW.."Prev",not canPrev)
 ButtonSetDisabledFlag(WINDOW.."Next",not canNext)
 EE.UpdatePagingButtonColors()
end
function EE.Toggle() WindowSetShowing(WINDOW,not WindowGetShowing(WINDOW)); if WindowGetShowing(WINDOW) then EE.Refresh() end end
function EE.Hide() WindowSetShowing(WINDOW,false) end
function EE.OnTabClick() local t=EE.tabByWindow[SystemData.ActiveWindow.name]; if t then EE.currentTab=t; EE.Settings.tab=t; EE.currentPage=1; EE.Refresh() end end
function EE.PreviousPage() EE.currentPage=EE.currentPage-1; EE.Refresh() end
function EE.NextPage() EE.currentPage=EE.currentPage+1; EE.Refresh() end
function EE.AddRecent(c) c=lower(c); local out={c}; for _,v in ipairs(EE.Settings.recent) do if v~=c and #out<20 then table.insert(out,v) end end; EE.Settings.recent=out end
function EE.OnEmoteClick() local e=EE.buttonToEmote[SystemData.ActiveWindow.name]; if not e then return end; EE.AddRecent(e.command); SendChatText(W("/"..e.command),L""); if EE.currentTab=="Recent" then EE.Refresh() end end
function EE.OnFavoriteClick() local e=EE.buttonToEmote[SystemData.ActiveWindow.name]; if not e then return end; local c=lower(e.command); EE.Settings.favorites[c]=not fav(c); EE.Refresh() end
function EE.OnEmoteMouseOver()
 local win=SystemData.MouseOverWindow.name
 local e=EE.buttonToEmote[win]
 if not e then return end
 Tooltips.CreateTextOnlyTooltip(win,nil)
 Tooltips.SetTooltipText(1,1,W(displayName(e.command)))
 Tooltips.SetTooltipText(2,1,W("/"..tostring(e.command or "")))
 Tooltips.SetTooltipText(3,1,L"Left-click to play   Right-click to favorite")
 Tooltips.Finalize()
 Tooltips.AnchorTooltip(Tooltips.ANCHOR_WINDOW_TOP)
end
