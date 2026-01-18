;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PF_SPA_VampireBite_P_END Extends Package Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(Actor akActor)
;BEGIN CODE
SPA_Main sp_main = (GetOwningQuest() as SPA_Main)
sp_main.debugConsole("trigger package VampireBite ")
Actor attacker = sp_main.getVampAttacker()
Actor victim = sp_main.getVampVictim()
sp_main.playBiteAnimatoin(attacker, victim)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
