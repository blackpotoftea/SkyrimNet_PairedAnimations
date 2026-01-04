Scriptname SPA_Player_Alias extends ReferenceAlias  


event OnInit()
    startup()
endevent

event OnPlayerLoadGame()
    startup()
endevent


Function startup()
    (GetOwningQuest() as SPA_Main).startup()
EndFunction