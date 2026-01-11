Scriptname SPA_Main extends Quest  
Package Property SPA_VampireBite  Auto  
Package Property SPA_Hug  Auto  


Scene Property SPA_PairedAnim_VampireBite  Auto  
Scene Property SPA_PairedAnim_Hug  Auto  
Scene Property SPA_PairedAnim_Kill  Auto  
Scene Property SPA_PairedAnim_SneakKill  Auto  
Scene Property SPA_PairedAnim_StandTalk  Auto  

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
Idle Property pa_1HMKillMoveDecapSlash  Auto  
Idle Property pa_1HMKillMoveBackStab  Auto  

STATIC Property SPA_XMarker  Auto  

ActorBase Property DLC1Serana  Auto
Keyword Property vampire_keyword  Auto  

bool Property isPairedAnimRunning = false auto
string Property animEventWaitFor = "PairEnd" AutoReadOnly
string Property animEventVampire = "VFD_BloodDecals_Event" AutoReadOnly

function startup()
    Debug.Notification("SkyrimNet_Paired Main loaded...")
    MiscUtil.PrintConsole("SkyrimNet_Paired Main loaded...")

    registerEventSchemaFeed()
    registerEventSchemaFeedFailed()
endfunction


bool Function VampireFeed_IsEligible(Actor akActor1, Actor akActor2)
    if !akActor1 || !akActor2
        console("Invalid targets: Invalid actor(s) ")
        return false
    endif

    ActorBase baseActor = akActor1.GetBaseObject() as ActorBase
    if baseActor == DLC1Serana
        return true
    endif

    return akActor1.HasKeyword(vampire_keyword)
EndFunction

bool Function ExecuteTarget_IsEligible(Actor akActor1, Actor akActor2)
    if !akActor1 || !akActor2
        console("Invalid targets: Invalid actor(s)")
        return false
    endif

    if akActor2.IsDead()
        console("Invalid target: Target is already dead")
        return false
    endif

    ; Generic execution actions - eligible if actors exist and target is alive
    return true
EndFunction

bool Function HugActor_IsEligible(Actor akActor1, Actor akActor2)
    if !akActor1 || !akActor2
        console("Invalid targets: Invalid actor(s)")
        return false
    endif
    if akActor2.IsDead()
        console("Invalid target: Target is already dead")
        return false
    endif
    return true
EndFunction


Function VampireBite_Execute(Actor akActor1, Actor akActor2)
    if !akActor1 || !akActor2
        Debug.Trace("[SkyrimNetInternal] FeedOnActor: Invalid actor(s)")
        return
    endif
    Actor attacker = akActor1
    Actor target   = akActor2

    debugConsole("[SkyrimNetInternal] FeedOnActor: " + attacker.GetDisplayName() + " feeding on " + target.GetDisplayName())

    vampClearAliases()
    vampFillAliases(attacker, target)
    debugConsole("Starting Vampire Bite scene")
    triggerSceneVampireBite()
    vampClearAliases()
EndFunction

Function ExecuteTarget_Execute(Actor akActor1, Actor akActor2, bool silent = false)
    if !akActor1 || !akActor2
        Debug.Trace("[SkyrimNetInternal] ExecuteTarget: Invalid actor(s)")
        return
    endif
    Actor attacker = akActor1
    Actor target = akActor2

    if silent
        debugConsole("[SkyrimNetInternal] SneakExecuteTarget: " + attacker.GetDisplayName() + " silently executing " + target.GetDisplayName())
    else
        debugConsole("[SkyrimNetInternal] ExecuteTarget: " + attacker.GetDisplayName() + " executing " + target.GetDisplayName())
    endif

    vampClearAliases()
    vampFillAliases(attacker, target)

    if silent
        debugConsole("Starting Sneak Kill scene")
        triggerSceneSneakKillTarget()
    else
        debugConsole("Starting Execute Kill scene")
        triggerSceneKillTarget()
    endif

    vampClearAliases()
EndFunction

Function HugActor_Execute(Actor akActor1, Actor akActor2)
    if !akActor1 || !akActor2
        Debug.Trace("[SkyrimNetInternal] HugActor: Invalid actor(s)")
        return
    endif
    Actor hugger = akActor1
    Actor target = akActor2

    debugConsole("[SkyrimNetInternal] HugActor: " + hugger.GetDisplayName() + " hugging " + target.GetDisplayName())

    hugClearAliases()
    hugFillAliases(hugger, target)
    debugConsole("Starting Hug scene")
    triggerSceneHug()
    hugClearAliases()

    string prompt = hugger.GetDisplayName() + " hugs " + target.GetDisplayName()
    SkyrimNetApi.RegisterEvent("hug", prompt, hugger, target)
EndFunction

Function StandTalkActor(Actor akOriginator, string contextJson, string paramsJson) global
    actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    if (!akOriginator || !akTarget)
        Debug.Trace("[SkyrimNetInternal] TeamHuddle: akOriginator or akTarget is null")
        return
    endif

    Quest questBase = Quest.GetQuest("SN_PairedAnim_Main") ;
    SPA_Main questInstance = questBase as SPA_Main

    questInstance.debugConsole("[SkyrimNetInternal] TeamHuddle: quest Instance: "+ questInstance )
    questInstance.debugConsole("[SkyrimNetInternal] TeamHuddle: " + akOriginator.GetDisplayName() + " talking with " + akTarget.GetDisplayName())

    questInstance.hugClearAliases()
    questInstance.hugFillAliases(akOriginator, akTarget)
    questInstance.debugConsole("Starting TeamHuddle scene")
    questInstance.triggerSceneStandTalk(60)
    questInstance.hugClearAliases()
    questInstance.debugConsole("Ending TeamHuddle scene")
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

    console("Registered vampire_feed event schema")

EndFunction

Function registerEventSchemaFeedFailed(bool isEphemeral = false)
    String fieldsJson = "[" + \
        "{\"name\":\"attacker\",\"type\":0,\"required\":true,\"description\":\"The vampire who attempted to feed\"}," + \
        "{\"name\":\"target\",\"type\":0,\"required\":true,\"description\":\"The intended victim\"}," + \
        "{\"name\":\"failure_reason\",\"type\":0,\"required\":false,\"description\":\"Why the feeding failed\",\"defaultValue\":\"animation_failed\"}," + \
        "{\"name\":\"was_in_combat\",\"type\":2,\"required\":false,\"description\":\"Whether the vampire was in combat during the attempt\",\"defaultValue\":false}," + \
        "{\"name\":\"target_state\",\"type\":0,\"required\":false,\"description\":\"State of target during attempt\",\"defaultValue\":\"unknown\"}" + \
        "]"

    String formatTemplatesJson = "{" + \
        "\"recent_events\":\"**{{attacker}}** attempted to feed on {{target}} but failed ({{failure_reason}}) ({{time_desc}})\"," + \
        "\"raw\":\"{{attacker}} failed to feed on {{target}}\"," + \
        "\"compact\":\"{{attacker}} -> {{target}} (failed: {{failure_reason}})\"," + \
        "\"verbose\":\"Failed Vampire Feed: {{attacker}} attempted to feed on {{target}} - Reason: {{failure_reason}}, Combat: {{was_in_combat}}, Target State: {{target_state}}\"" + \
        "}"

    SkyrimNetApi.RegisterEventSchema("vampire_feed_failed", "Failed Vampire Feeding Attempt", \
                                "A vampire's failed attempt to feed on a victim", \
                                fieldsJson, formatTemplatesJson, isEphemeral, 120000)

    console("Registered vampire_feed_failed event schema")

EndFunction

; Helper function: Convert boolean to JSON-compatible string
String Function BoolToJsonString(bool value)
    if value
        return "true"
    endif
    return "false"
EndFunction

; Helper function: Register event with combat-based logic
Function RegisterEventByContext(string eventId, string eventType, string description, string eventDataJson, int ttl, Actor attacker, Actor target, bool inCombat)
    if !SkyrimNetApi.ValidateEventData(eventType, eventDataJson)
        debugConsole("ERROR: Validation failed for " + eventType + " event data!")
        return
    EndIf

    debugConsole(eventDataJson)

    if inCombat
        int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, description, eventDataJson, ttl, attacker, target)
        if result == 0
            debugConsole("SkyrimNet: Registered " + eventType + " event - " + eventId)
        Else
            debugConsole("SkyrimNet: Failed to register " + eventType + " event - " + eventId)
        EndIf
    Else
        SkyrimNetApi.RegisterEvent(eventType, eventDataJson, attacker, target)
    EndIf
EndFunction

Function registerVampireFeedEvent(Actor attacker, Actor target, int ttl = 120)
    bool wasDetected = attacker.IsDetectedBy(target)
    bool inCombat = attacker.IsInCombat()
    bool targetAware = target.IsDetectedBy(attacker)

    String attackerName = attacker.GetDisplayName()
    String targetName = target.GetDisplayName()

    ; Determine feed type based on context
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

    String eventDataJson = "{" + \
        "\"attacker\":\"" + attackerName + "\"," + \
        "\"target\":\"" + targetName + "\"," + \
        "\"feed_type\":\"" + feedType + "\"," + \
        "\"was_detected\":" + BoolToJsonString(wasDetected) + "," + \
        "\"in_combat\":" + BoolToJsonString(inCombat) + "," + \
        "\"target_aware\":" + BoolToJsonString(targetAware) + \
        "}"

    String eventId = "vampirefeed_" + target.GetFormID() + "_" + (Utility.GetCurrentRealTime() as Int)
    String description = attackerName + " feeds on " + targetName

    RegisterEventByContext(eventId, "vampire_feed", description, eventDataJson, ttl, attacker, target, inCombat)
EndFunction

Function registerVampireFeedFailedEvent(Actor attacker, Actor target, string failureReason = "animation_failed", int ttl = 120)
    if !attacker || !target
        debugConsole("ERROR: Cannot register failed feed event - invalid actors")
        return
    EndIf

    bool inCombat = attacker.IsInCombat()

    String attackerName = attacker.GetDisplayName()
    String targetName = target.GetDisplayName()

    ; Determine target state for context
    String targetState = "unknown"
    if target.GetSleepState() >= 3
        targetState = "sleeping"
    ElseIf target.IsInCombat()
        targetState = "in_combat"
    ElseIf target.GetSitState() == 3
        targetState = "sitting"
    Else
        targetState = "standing"
    EndIf

    String eventDataJson = "{" + \
        "\"attacker\":\"" + attackerName + "\"," + \
        "\"target\":\"" + targetName + "\"," + \
        "\"failure_reason\":\"" + failureReason + "\"," + \
        "\"was_in_combat\":" + BoolToJsonString(inCombat) + "," + \
        "\"target_state\":\"" + targetState + "\"" + \
        "}"

    String eventId = "vampirefeed_failed_" + target.GetFormID() + "_" + (Utility.GetCurrentRealTime() as Int)
    String description = attackerName + " failed to feed on " + targetName

    RegisterEventByContext(eventId, "vampire_feed_failed", description, eventDataJson, ttl, attacker, target, inCombat)
EndFunction

Function triggerSceneVampireBite()
    triggerScene(SPA_PairedAnim_VampireBite)
EndFunction

Function triggerSceneKillTarget(int timeout = 30)
    triggerScene(SPA_PairedAnim_Kill, timeout)
EndFunction

Function triggerSceneSneakKillTarget(int timeout = 30)
    triggerScene(SPA_PairedAnim_SneakKill, timeout)
EndFunction

Function triggerSceneHug()
    triggerScene(SPA_PairedAnim_Hug)
EndFunction

Function triggerSceneStandTalk(int timeout = 20)
    triggerScene(SPA_PairedAnim_StandTalk, timeout)
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
    debugConsole("Package finished running")
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

Idle Function calcKillMove(Actor attacker, Actor victim)
    Idle killmoveIdle
    
    ; Calculate angle between attacker and victim
    float headingAngle = victim.GetHeadingAngle(attacker)
    
    ; Check if victim is facing away (back attack)
    if (headingAngle < -90 || headingAngle > 90)
        ; Behind the victim - use backstab killmove
        killmoveIdle = pa_1HMKillMoveBackStab
        debugConsole("Selected backstab killmove from behind")
    else
        ; Facing the victim - use frontal decapitation
        killmoveIdle = pa_1HMKillMoveDecapSlash
        debugConsole("Selected decapitation killmove from front")
    endif
    
    debugConsole("Getting Killmove animation: " + killmoveIdle)
    return killmoveIdle
EndFunction

Function playBiteAnimatoin()
    Actor attacker = VampAttackerRef.GetActorRef()
    Actor victim = VampVictimRef.GetActorRef()

    bool success = _playBiteAnimatoin(attacker, victim)

    if success
        registerVampireFeedEvent(attacker, victim)
    else
        registerVampireFeedFailedEvent(attacker, victim, "animation_failed")
    endif
EndFunction

bool Function playHugAnimatoin()
    return _playHugAnimation(HugAttackerRef.GetActorRef(), HugVictimRef.GetActorRef())
EndFunction

bool Function _playBiteAnimatoin(Actor attacker, Actor victim)
    Idle feedAnim = calcFeedAnimation(attacker, victim)
    return playPairedAnimation(attacker, victim, feedAnim)
EndFunction

bool Function _playHugAnimation(Actor attacker, Actor victim)
    return playPairedAnimation(attacker, victim, pa_HugA)
EndFunction

Function playKillActor(bool suppressAlarm=false)
    _killActor(VampAttackerRef.GetActorRef(), VampVictimRef.GetActorRef(), false, false, suppressAlarm)
EndFunction

bool Function playPairedAnimation(Actor attacker, Actor victim, idle anim)
    ; AlignActorsForPairedAnimation(attacker, victim)

    Debug.SendAnimationEvent(victim, "IdleStop")
    Utility.Wait(0.2)
    return attacker.PlayIdleWithTarget(anim, victim)
EndFunction


Function _killActor(Actor attacker, Actor victim, bool allowEssential=false, bool isProtected=false, bool suppressAlarm=false)
    debugConsole("triggerin killing animation")
    if !ValidateKill(attacker, victim, allowEssential, isProtected)
        return
    endif

    ActorBase victimBase = victim.GetBaseObject() as ActorBase
    bool wasEssential = victimBase.IsEssential()
    bool wasProtected = victimBase.IsProtected()
    bool canKill = true

    if wasEssential
        if !allowEssential
            Debug.Trace("Cannot kill essential actor: " + victim.GetDisplayName())
            canKill = false
        endif
    elseif wasProtected
        if !isProtected && attacker != Game.GetPlayer()
            Debug.Trace("Protected actor can only be killed by player: " + victim.GetDisplayName())
            canKill = false
        endif
    endif

        if !canKill
        return
    endif

    ; AlignActorsForPairedAnimation(attacker, victim)
    ; Debug.SendAnimationEvent(victim, "IdleStop")

    ToggleRestraints(victim, true)

    If (!RegisterForAnimationEvent(attacker, animEventVampire))
		debugConsole("Attacker Failed to register for" + animEventVampire)
	EndIf

    If (!RegisterForAnimationEvent(attacker, animEventWaitFor))
		debugConsole("Attacker Failed to register for " + animEventWaitFor)
	EndIf

    if wasEssential
        victimBase.SetEssential(false)
    endif
    if wasProtected
        victimBase.SetProtected(false)
    endif

    ; Suppress alarm/crime if requested
    if suppressAlarm
        victim.StopCombatAlarm()
        victim.SetNoBleedoutRecovery(true)
    endif

    Idle selectedKillmove = calcKillMove(attacker, victim)
    bool animStarted = playPairedAnimation(attacker, victim, selectedKillmove)
    if !animStarted
        victim.Kill(attacker)
    endif

    ToggleRestraints(victim, false)
    UnregisterForAnimationEvent(attacker, animEventVampire)

    if !victim.IsDead()
        if wasEssential
            victimBase.SetEssential(true)
        endif
        if wasProtected
            victimBase.SetProtected(true)
        endif
    endif
EndFunction


Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	debugConsole("Animation event received: " + asEventName)
	if asEventName == animEventVampire
		debugConsole("VampireFeed event detected - sendin mod event")
		registerVampireFeedEvent(VampAttackerRef.GetActorRef(), VampVictimRef.GetActorRef())
        UnregisterForAnimationEvent(VampAttackerRef.GetActorRef(), animEventVampire)
    endif
endEvent

Function ToggleRestraints(Actor victim, bool lock)
    if lock
        Debug.SendAnimationEvent(victim, "IdleStop")
    endif
    victim.SetRestrained(lock)
    victim.SetDontMove(lock)
EndFunction

Function AlignActorsForPairedAnimation(Actor attacker, Actor victim)
    float distance = attacker.GetDistance(victim)
    
    ; Move closer
    if distance > 120
        attacker.MoveTo(victim, 100 * Math.Sin(victim.GetAngleZ()), 100 * Math.Cos(victim.GetAngleZ()), 0)
        ; Utility.Wait(0.1)
    endif

    ; Rotate Victim
    float headingAngle = victim.GetHeadingAngle(attacker)
    float targetAngle = attacker.GetAngleZ()

    if (headingAngle > -90 && headingAngle < 90)
        targetAngle += 180.0 ; Face to Face
    endif
    
    if targetAngle >= 360.0
        targetAngle -= 360.0
    endif

    victim.SetAngle(victim.GetAngleX(), victim.GetAngleY(), targetAngle)
EndFunction

bool Function ValidateKill(Actor attacker, Actor victim, bool allowEssential, bool allowProtected)
    If !attacker || !victim || attacker.IsDead() || victim.IsDead()
        return false
    EndIf 

    int levelDifference = victim.GetLevel() - attacker.GetLevel()
    if levelDifference > 10
        Debug.Trace("Target too high level")
        return false
    endif

    ActorBase vBase = victim.GetBaseObject() as ActorBase
    
    if vBase.IsEssential() && !allowEssential
        Debug.Trace("Target is Essential")
        return false
    endif

    if vBase.IsProtected() && !allowProtected && attacker != Game.GetPlayer()
        Debug.Trace("Target is Protected and attacker is not Player")
        return false
    endif

    return true
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
    MiscUtil.PrintConsole("SPA: "+in)
    Debug.Trace("SPA: "+in)
EndFunction
