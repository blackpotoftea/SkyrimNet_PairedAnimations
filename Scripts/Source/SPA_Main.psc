Scriptname SPA_Main extends Quest  
Package Property SPA_VampireBite  Auto  
Package Property SPA_Hug  Auto  


Scene Property SPA_PairedAnim_VampireBite  Auto  
Scene Property SPA_PairedAnim_Hug  Auto  

ReferenceAlias Property VampAttackerRef  Auto  
ReferenceAlias Property VampVictimRef  Auto  
ReferenceAlias Property HugAttackerRef  Auto  
ReferenceAlias Property HugVictimRef  Auto  

Idle Property VampireFeedingBedLeft_Loose  Auto  
Idle Property VampireFeedingBedRollLeft_Loose  Auto  
Idle Property VampireFeedingBedRight_Loose  Auto  
Idle Property VampireFeedingBedRollRight_Loose  Auto  
Idle Property IdleVampireStandingBack  Auto  
Idle Property IdleVampireStandingFront  Auto  
Idle Property pa_HugA  Auto

Keyword Property Vampire  Auto

function startup()
    Debug.Notification("SkyrimNet_Paired Main loaded...")
    MiscUtil.PrintConsole("SkyrimNet_Paired Main loaded...")

    registerPairedActions()
    registerEventSchemaFeed()
endfunction


bool Function FeedOnActor_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    return true
EndFunction

bool Function HugActor_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    return true
EndFunction



Function VampireBite(Actor attacker, string contextJson, string paramsJson) global
    actor target = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if (!attacker || !target)
        Debug.Trace("[SkyrimNetInternal] FeedOnActor: akOriginator or akTarget is null")
        return
    endif

    Quest questBase = Quest.GetQuest("SN_PairedAnim_Main") ;
    SPA_Main questInstance = questBase as SPA_Main

    questInstance.debugConsole("[SkyrimNetInternal] FeedOnActor: quest Instance: "+ questInstance )
    questInstance.debugConsole("[SkyrimNetInternal] FeedOnActor: Feeding " + attacker.GetDisplayName() + " with " + target.GetDisplayName())

    questInstance.vampClearAliases()
    questInstance.vampFillAliases(attacker, target)
    questInstance.debugConsole("Staring Vampire Bite scene")
    questInstance.triggerSceneVampireBite()
    questInstance.vampClearAliases()
    string prompt = attacker.GetDisplayName() + " feed on "  + target.GetDisplayName()

    questInstance.registerVampireFeedEvent(attacker, target)
    ; SkyrimNetApi.RegisterEvent("vampire_feed",prompt, attacker, target)
EndFunction

Function HugActor(Actor akOriginator, string contextJson, string paramsJson) global
    actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if (!akOriginator || !akTarget)
        Debug.Trace("[SkyrimNetInternal] HugActor: akOriginator or akTarget is null")
        return
    endif

    Quest questBase = Quest.GetQuest("SN_PairedAnim_Main") ;
    SPA_Main questInstance = questBase as SPA_Main

    Debug.Trace("[SkyrimNetInternal] HugActor: quest Instance: "+ questInstance )
    Debug.Trace("[SkyrimNetInternal] HugActor: Feeding " + akTarget.GetDisplayName() + " with " + akOriginator.GetDisplayName())

    questInstance.hugClearAliases()
    questInstance.hugFillAliases(akOriginator, akTarget)
    questInstance.debugConsole("Staring Hug scene")
    questInstance.triggerSceneHug()
    questInstance.hugClearAliases()
    string prompt = akOriginator.GetDisplayName() + " hugs "  + akTarget.GetDisplayName()
    SkyrimNetApi.RegisterEvent("hug",prompt, akOriginator, akTarget)

EndFunction


Function registerPairedActions()
    SkyrimNetApi.RegisterAction("FeedTarget", "Vampire Feed on person", \
                        "SPA_Main", "FeedOnActor_IsEligible", \
                        "SPA_Main", "VampireBite", \
                        "", "PAPYRUS", \
                        1, "{\"target\": \"Actor\"}")

    SkyrimNetApi.RegisterAction("HugTarget", "Hug person", \
                        "SPA_Main", "HugActor_IsEligible", \
                        "SPA_Main", "HugActor", \
                        "", "PAPYRUS", \
                        1, "{\"target\": \"Actor\"}")                        
EndFunction

Function registerEventSchemaFeed(bool isEphemeral = false)
    String fieldsJson = "[" + \
        "{\"name\":\"attacker\",\"type\":0,\"required\":true,\"description\":\"The attacker doing the feeding\"}," + \
        "{\"name\":\"target\",\"type\":0,\"required\":true,\"description\":\"The target being fed upon\"}," + \
        "{\"name\":\"feed_type\",\"type\":0,\"required\":false,\"description\":\"Type of feed based on context\",\"defaultValue\":\"normal\"}," + \
        "{\"name\":\"was_detected\",\"type\":2,\"required\":false,\"description\":\"Whether the feeding was detected by the target\",\"defaultValue\":false}," + \
        "{\"name\":\"in_combat\",\"type\":2,\"required\":false,\"description\":\"Whether the vampire was in combat during feeding\",\"defaultValue\":false}," + \
        "{\"name\":\"target_aware\",\"type\":2,\"required\":false,\"description\":\"Whether the target was aware of the attacker\",\"defaultValue\":false}" + \
        "]"

    String formatTemplatesJson = "{" + \
        "\"recent_events\":\"**{{attacker}}** feeds on {{target}}{{#if in_combat}} during combat{{/if}}{{#if was_detected}} (detected!){{/if}} ({{time_desc}})\"," + \
        "\"raw\":\"{{attacker}} fed on {{target}}\"," + \
        "\"compact\":\"{{attacker}} -> {{target}} ({{feed_type}} feed)\"," + \
        "\"verbose\":\"Vampire Feeding: {{attacker}} fed on {{target}} - Type: {{feed_type}}, Detected: {{was_detected}}, Combat: {{in_combat}}, Victim Aware: {{target_aware}}\"" + \
        "}"

    SkyrimNetApi.RegisterEventSchema("vampire_feed", "Vampire Feeding Event", \
                                "A vampire feeding on a victim", \
                                fieldsJson, formatTemplatesJson, isEphemeral, 120000)

    Debug.Trace("SkyrimNet: Registered vampire_feed event schema")

EndFunction

Function registerVampireFeedEvent(Actor attacker, Actor target, int ttl = 120)

    bool wasDetected = attacker.IsDetectedBy(target)
    bool inCombat = attacker.IsInCombat()
    bool targetAware = target.IsDetectedBy(attacker)

    String attackerName = attacker.GetDisplayName()
    String targetName = target.GetDisplayName()


    String feedType = "normal"
    if inCombat
        feedType = "combat"
    ElseIf target.GetSleepState() == 3 && !wasDetected

        feedType = "stealth_sleeping"
    ElseIf !wasDetected && !targetAware
        feedType = "stealth"
    ElseIf wasDetected || targetAware
        feedType = "willing"
    EndIf
  
    ; Papyrus workaround: papyrus will turn "true" to "TRUE" if returned via function
    ; Which not work as valid json
    ; Build entire JSON property strings to avoid capitalization
    String detectedProp = "\"was_detected\":false"
    if wasDetected
        detectedProp = "\"was_detected\":true"
    endif

    String inCombatProp = "\"in_combat\":false"
    if inCombat
        inCombatProp = "\"in_combat\":true"
    endif

    String targetAwareProp = "\"target_aware\":false"
    if targetAware
        targetAwareProp = "\"target_aware\":true"
    endif

    String eventDataJson = "{" + \
        "\"attacker\":\"" + attackerName + "\"," + \
        "\"target\":\"" + targetName + "\"," + \
        "\"feed_type\":\"" + feedType + "\"," + \
        detectedProp + "," + \
        inCombatProp + "," + \
        targetAwareProp + \
        "}"
    
    String eventId = "vampirefeed_" + target.GetFormID() + "_" + (Utility.GetCurrentRealTime() as Int)
    String description = attacker.GetDisplayName() + " feeds on " + target.GetDisplayName()
    

    if !SkyrimNetApi.ValidateEventData("vampire_feed", eventDataJson)
        debugConsole("ERROR: Validation failed for event data!")
        return
    EndIf

    debugConsole(eventDataJson)

    ; Comabt feed are registred as short lived events
    if inCombat
        int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, "vampire_feed", description, eventDataJson, ttl, attacker, target)
        if result == 0
            debugConsole("SkyrimNet: Registered vampire feed event - " + eventId)
        Else
            debugConsole("SkyrimNet: Failed to register vampire feed event - " + eventId)
        EndIf
    Else
        SkyrimNetApi.RegisterEvent("vampire_feed", eventDataJson, attacker, target)
    EndIf

EndFunction

function triggerSceneVampireBite()
    triggerScene(SPA_PairedAnim_VampireBite)
EndFunction

function triggerSceneHug()
    triggerScene(SPA_PairedAnim_Hug)
EndFunction

Function triggerScene(Scene sceneToRun, int timeout = 20)
    sceneToRun.Start()
    debugConsole("Package running: " + sceneToRun.IsPlaying())

    int elapsed = 0

    While sceneToRun.IsPlaying() && elapsed < timeout
        Utility.Wait(1)
        elapsed += 1
    EndWhile

    if sceneToRun.IsPlaying()
        debugConsole("Scene timeout reached. Scene is still playing.. bailing...")
        sceneToRun.Stop()
    EndIf
EndFunction

Idle Function calcFeedAnimation(Actor attacker, Actor target)
    Idle feedAnimIdle
    ; debugConsole("Feedin target state:")
    ; debugConsole("health: "+target.GetActorValue("Health"))
    ; debugConsole("sleep: "+target.GetSleepState())
    ; debugConsole("is dead: "+target.isDead())
    ; debugConsole("site: "+target.GetSitState())
    
    ; console("HeadingAngle: "+target.GetHeadingAngle(attacker))
    if( (target.GetSleepState() >= 3) || target.isDead() )
        if( target.IsInInterior() )
			if( target.GetHeadingAngle(attacker) > 0 )
                feedAnimIdle = VampireFeedingBedLeft_Loose
			else
                feedAnimIdle = VampireFeedingBedRight_Loose
			endif
		else
			if( target.GetHeadingAngle(attacker) > 0)
                feedAnimIdle = VampireFeedingBedrollLeft_Loose
			else
                feedAnimIdle = VampireFeedingBedrollRight_Loose
			endif
		endif 
    elseif( target.GetSitState() == 3 )
        feedAnimIdle = VampireFeedingBedRight_Loose
    else
        if(  target.GetHeadingAngle(attacker) < -90 || target.GetHeadingAngle(attacker) > 90 )
            feedAnimIdle = IdleVampireStandingBack
        else
            feedAnimIdle = IdleVampireStandingFront
        endIF
    endIF
    debugConsole("Getting Feedin animation: "+feedAnimIdle)
    return feedAnimIdle
EndFunction

Function playBiteAnimatoin()
    _playBiteAnimatoin(VampAttackerRef.GetActorRef(), VampVictimRef.GetActorRef())
EndFunction

Function playHugAnimatoin()
    _playHugAnimation(HugAttackerRef.GetActorRef(), HugVictimRef.GetActorRef())
EndFunction

Function _playBiteAnimatoin(Actor attacker, Actor victim)
    Idle feedAnim = calcFeedAnimation(attacker, victim)
    playPairedAnimation(attacker, victim, feedAnim)
EndFunction

Function _playHugAnimation(Actor attacker, Actor victim)
    playPairedAnimation(attacker, victim, pa_HugA)
EndFunction

Function playPairedAnimation(Actor attacker, Actor victim, idle anim)
    bool playingAnimation = attacker.PlayIdleWithTarget(anim, victim as ObjectReference)
    debugConsole("player anim:"+ anim + " anim status : "+playingAnimation)
EndFunction

Function vampClearAliases()
    VampAttackerRef.Clear()
    VampVictimRef.Clear()
EndFunction

Function hugClearAliases()
    HugAttackerRef.Clear()
    HugVictimRef.Clear()
EndFunction

Function vampFillAliases(Actor attacker, actor victim)
    VampAttackerRef.ForceRefTo(attacker)
    VampVictimRef.ForceRefTo(victim)
EndFunction

Function hugFillAliases(Actor attacker, actor victim)
    HugAttackerRef.ForceRefTo(attacker)
    HugVictimRef.ForceRefTo(victim)
EndFunction

function console(string in)
    MiscUtil.PrintConsole("SPA: "+in)
EndFunction

function debugConsole(string in)
    ; Debug.Notification("SFE: "+in)
    MiscUtil.PrintConsole("SPA: "+in)
    Debug.Trace("SPA: "+in)
EndFunction

String Function boolToString(Bool b)
    if b
        return "true"
    else
        return "false"
    endif
EndFunction

String Function testStrReturn(String b)
    return b
EndFunction