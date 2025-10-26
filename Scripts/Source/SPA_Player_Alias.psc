Scriptname SPA_Player_Alias extends ReferenceAlias  

	Event OnPlayerLoadGame()
		(GetOwningQuest() as SPA_Main).startup()
	EndEvent