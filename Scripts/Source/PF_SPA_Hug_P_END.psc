;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PF_SPA_Hug_P_END Extends Package Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(Actor akActor)
;BEGIN CODE
Debug.Notification("SkyrimNet_Paired Main loaded...")

SPA_Main sp_main = (GetOwningQuest() as SPA_Main)
sp_main.debugConsole("trigger package Hug")
Actor attacker = sp_main.getHugAttacker()
Actor victim = sp_main.getHugVictim()
sp_main.playHugAnimatoin(attacker, victim)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
