<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <UiMod name="EmissaryEmotes" version="@project-version@" date="@project-date@">
  <VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="2.0" />
  <Author name="Emissary" email="" />
  <Description text="Emissary Emotes - native WAR-styled emote browser for Return of Reckoning" />
  <Dependencies>
   <Dependency name="EATemplate_DefaultWindowSkin" />
   <Dependency name="EASystem_Utils" />
   <Dependency name="EASystem_WindowUtils" />
   <Dependency name="EASystem_Tooltips" />
   <Dependency name="EASystem_LayoutEditor" />
  </Dependencies>
  <Files>
   <File name="EmissaryEmotesData.lua" />
   <File name="EmissaryEmotes.lua" />
   <File name="EmissaryEmotes.xml" />
  </Files>
  <OnInitialize>
   <CreateWindow name="EmissaryEmotes_Toggler" show="true" />
   <CreateWindow name="EmissaryEmotesWindow" show="false" />
  </OnInitialize>
  <SavedVariables><SavedVariable name="EmissaryEmotes.Settings" /></SavedVariables>
 </UiMod>
</ModuleFile>
