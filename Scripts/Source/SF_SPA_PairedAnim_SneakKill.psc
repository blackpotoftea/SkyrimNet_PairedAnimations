;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 14
Scriptname SF_SPA_PairedAnim_SneakKill Extends Scene Hidden

;BEGIN FRAGMENT Fragment_6
Function Fragment_6()
;BEGIN CODE
Utility.Wait(0.1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_7
Function Fragment_7()
;BEGIN CODE
; phase2 complete
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_10
Function Fragment_10()
;BEGIN CODE
; Utility.Wait(0.2)
SPA_Main sp_main = (GetOwningQuest() as SPA_Main)
sp_main.debugConsole("trigger sneak kill animation")
Actor attacker = sp_main.getVampAttacker()
Actor victim = sp_main.getVampVictim()
sp_main.playKillActor(attacker, victim, true)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
