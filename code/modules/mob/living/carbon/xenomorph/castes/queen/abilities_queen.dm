// ***************************************
// *********** Hive message
// ***************************************
/datum/action/ability/xeno_action/hive_message
	name = "Hive Message" // Also known as Word of Queen.
	action_icon_state = "queen_order"
	desc = "Announces a message to the hive."
	ability_cost = 50
	cooldown_duration = 10 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_QUEEN_HIVE_MESSAGE,
	)
	use_state_flags = ABILITY_USE_LYING

/datum/action/ability/xeno_action/hive_message/action_activate()
	var/mob/living/carbon/xenomorph/queen/Q = owner

	//Preferring the use of multiline input as the message box is larger and easier to quickly proofread before sending to hive.
	var/input = stripped_multiline_input(Q, "Maximum message length: [MAX_BROADCAST_LEN]", "Hive Message", "", MAX_BROADCAST_LEN, TRUE)
	//Newlines are of course stripped and replaced with a space.
	input = capitalize(trim(replacetext(input, "\n", " ")))
	if(!input)
		return
	var/filter_result = is_ic_filtered(input)
	if(filter_result)
		to_chat(Q, span_warning("That announcement contained a word prohibited in IC chat! Consider reviewing the server rules.\n<span replaceRegex='show_filtered_ic_chat'>\"[input]\"</span>"))
		SSblackbox.record_feedback(FEEDBACK_TALLY, "ic_blocked_words", 1, lowertext(config.ic_filter_regex.match))
		REPORT_CHAT_FILTER_TO_USER(src, filter_result)
		log_filter("IC", input, filter_result)
		return FALSE
	if(NON_ASCII_CHECK(input))
		to_chat(Q, span_warning("That announcement contained characters prohibited in IC chat! Consider reviewing the server rules."))
		return FALSE

	log_game("[key_name(Q)] has messaged the hive with: \"[input]\"")
	deadchat_broadcast(" has messaged the hive: \"[input]\"", Q, Q)
	var/queens_word = "<span class='maptext' style=font-size:18pt;text-align:center valign='top'><u>HIVE MESSAGE:</u><br></span>" + input

	var/sound/queen_sound = sound(get_sfx("queen"), channel = CHANNEL_ANNOUNCEMENTS)
	var/sound/king_sound = sound('sound/voice/xenos_roaring.ogg', channel = CHANNEL_ANNOUNCEMENTS)
	for(var/mob/living/carbon/xenomorph/X AS in Q.hive.get_all_xenos())
		switch(Q.caste_base_type)
			if(/mob/living/carbon/xenomorph/queen)
				SEND_SOUND(X, queen_sound)
				//In case in combat, couldn't read fast enough, or needs to copy paste into a translator. Here's the old hive message.
				to_chat(X, span_xenoannounce("<h2 class='alert'>The words of the queen reverberate in your head...</h2><br>[span_alert(input)]<br><br>"))
			if(/mob/living/carbon/xenomorph/king)
				SEND_SOUND(X, king_sound)
				to_chat(X, span_xenoannounce("<h2 class='alert'>The words of the king reverberate in your head...</h2><br>[span_alert(input)]<br><br>"))
			if(/mob/living/carbon/xenomorph/shrike)
				SEND_SOUND(X, queen_sound)
				to_chat(X, span_xenoannounce("<h2 class='alert'>The words of the shrike reverberate in your head...</h2><br>[span_alert(input)]<br><br>"))
		//Display the ruler's hive message at the top of the game screen.
		X.play_screen_text(queens_word, /atom/movable/screen/text/screen_text/queen_order)

	succeed_activate()
	add_cooldown()



/////////////////////////////////
// Impregnate - Queen Variation - Harm intent = Lethal, Help = Gentle
/////////////////////////////////

/datum/action/ability/activable/xeno/impregnatequeen
	name = "Royal Treatment"
	action_icon_state = "impregnate"
	desc = "Directly use your ovipositor to lay one or more larva directly within a host. This is especially harmful, and only grows moreso with each larva inserted, and leaves permanent internal damage on the host with each excess larva.; This method can easily kill a host, so be careful!"
	cooldown_duration = 2.5 SECONDS
	use_state_flags = ABILITY_USE_STAGGERED
	ability_cost = 200
	gamemode_flags = ABILITY_NUCLEARWAR
	target_flags = ABILITY_HUMAN_TARGET
	var/lethaldamage
	var/damagescaledivisor = 2.5 //The divisor that the damage form uses
	var/damageperlarva = 20 //The base damage per larva. Is divided by damagescaledivider, then timesd by the amount of larvae present in the host past 6 larva
	var/list/helpintenttext = list("caringly fuck", "carefully impregnate", "regally rail", "tantrically mate")
	var/list/harmintenttext = list("roughly rut", "roughly rail", "harshly slam", "dangerously seed", "overly stuff")
	var/list/damagetypes = list(BRUTE,BURN,TOX)
	var/sexverb
	var/larvalbunch = 3 //How many can the Queen lay at once?
	var/chancebunch = 25 //How often on a prob() will this occur...
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_IMPREGNATE,
	)

/datum/action/ability/activable/xeno/impregnatequeen/can_use_ability(mob/living/A, silent, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/xenomorph/X = owner
	var/mob/living/victim = A
	if(A.stat == DEAD)
		to_chat(owner, span_warning("Why would we sully our loins mating with the dead? Get a lesser being to do it for us..."))
		return FALSE
	if(ismonkey(A))
		A.apply_damage(95, BRUTE, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //They CERTAINLY aren't fitting in a monkey.
		to_chat(owner, span_warning("We stop trying to fuck \the [A]. They're simply too small to hold royal larva!"))
		return FALSE
	var/implanted_embryos = 0
	for(var/obj/item/alien_embryo/implanted in A.contents)
		implanted_embryos++
	if(implanted_embryos >= MAX_LARVA_PREGNANCIES)
		if(X.a_intent == INTENT_HARM)
			to_chat(X, span_warning("This host is already full of young ones... But you ignore it against your better judgement! Gripping the host tight, you continue..."))
			lethaldamage = TRUE //Yep.
		else
			to_chat(X, span_warning("This host is already full of young ones, and you don't want to hurt them! You feel if you were more HARMFUL, you might be able to fit a few more larva inside though..."))
			lethaldamage = FALSE //Nup.
			return FALSE
	switch(X.a_intent)
		if(INTENT_HARM)
			sexverb = pick(harmintenttext)
		if(INTENT_HELP)
			sexverb = pick(helpintenttext)
	if(!ishuman(A) && !isxeno(A))
		to_chat(owner, span_warning("This one wouldn't be able to bear a young one."))
		return FALSE
	if(owner.do_actions) //can't use if busy
		return FALSE
	if(!owner.Adjacent(victim)) //checks if owner next to target
		return FALSE
	if(X.on_fire)
		if(!silent)
			to_chat(X, span_warning("We feel as if exposing our genitals while on fire is a bad idea..."))
		return FALSE
	X.visible_message(span_danger("[X] starts to [sexverb] [victim]!"), \
	span_danger("We start to [sexverb] [victim]!"), null, 5)

//RECODE HERE
/datum/action/ability/activable/xeno/impregnatequeen/use_ability(mob/living/A)
	var/channel = SSsounds.random_available_channel()
	var/mob/living/carbon/xenomorph/X = owner
	var/victimhole = "[A.gender == MALE ? "ass" : "pussy"]"
	if(ishuman(A))
		switch(X.a_intent)
			if(INTENT_HARM)
				sexverb = pick(harmintenttext)
				lethaldamage = TRUE
			if(INTENT_HELP)
				sexverb = pick(helpintenttext)
				lethaldamage = FALSE
	X.face_atom(A)
	X.do_jitter_animation() //No need for the human to jostle too.
	to_chat(owner, span_warning("We will impregnate this host shortly. Remain in proximity."))
	playsound(X, 'sound/effects/alien_plapping.ogg', 40, channel = channel)
	if(!do_after(X, 1.5 SECONDS, FALSE, A, BUSY_ICON_DANGER, extra_checks = CALLBACK(owner, TYPE_PROC_REF(/mob, break_do_after_checks), list("health" = X.health))))
		to_chat(owner, span_warning("We stop [sexverb] \the [A]. They probably were loose anyways."))
		X.stop_sound_channel(channel)
		return fail_activate()
	owner.visible_message(span_warning("[X] [sexverb]s [A]"), span_warning("We destroy [A]'s poor [victimhole]!"), span_warning("You hear harsh slapping."), 5, A)
	A.apply_damage(5, BRUTE, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //Too many larvae!
	A.reagents.remove_reagent(/datum/reagent/toxin/xeno_aphrotoxin, 20) // Remove aphrotoxin cause orgasm or otherwise genital action.
	new /obj/effect/decal/cleanable/blood/splatter/xenocum(owner.loc)
	if(A.stat == CONSCIOUS)
		to_chat(A, span_warning("[X] thoroughly [sexverb]s you!"))
	var/implanted_embryos = 0
	for(var/obj/item/alien_embryo/implanted in A.contents)
		implanted_embryos++
	if(implanted_embryos >= MAX_LARVA_PREGNANCIES)
		to_chat(owner, span_danger("This Host is way too full! You begin to overstuff them..."))
		A.apply_damage((damageperlarva/damagescaledivisor)*implanted_embryos, BRUTE, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //Too many larvae!
		A.apply_damage(1, CLONE, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //ripping that womb
		if(A.stat == CONSCIOUS)
			to_chat(owner, span_danger("This Host's belly looks like they are about to burst!.."))
			to_chat(A, span_highdanger("You're too full, you feel like you're going to burst apart! You might want to beg [X] to stop... If they'll listen.")) //Way too many.
			if(implanted_embryos >= (MAX_LARVA_PREGNANCIES*2))
				for(var/D in damagetypes)
					A.apply_damage((damageperlarva/damagescaledivisor)*implanted_embryos, D, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //It'll get worse!
					A.apply_damage(1, CLONE, BODY_ZONE_PRECISE_GROIN, updating_health = TRUE) //REALLY ripping that womb
	if(prob(chancebunch)) //Queen has a higher chance to lay in batches.
		for(var/lcount=0, lcount<larvalbunch, lcount++)
			var/obj/item/alien_embryo/larba = new(A)
			larba.hivenumber = X.hivenumber
			larba.emerge_target_flavor = victimhole
		to_chat(owner, span_danger("You lay multiple larva at once!"))
		to_chat(A, span_danger("You feel multiple larva being inserted at once!"))
	else
		var/obj/item/alien_embryo/embryo = new(A)
		embryo.hivenumber = X.hivenumber
		embryo.emerge_target_flavor = victimhole
		GLOB.round_statistics.now_pregnant++
		SSblackbox.record_feedback("tally", "round_statistics", 1, "now_pregnant") //Only counts once to give Xenomorphs a fair chance.
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[X.ckey]
		personal_statistics.impregnations++

		add_cooldown()
		succeed_activate()

	if(isxeno(A))
		to_chat(owner, span_danger("They aren't worth wasting your larva on."))
		return FALSE

// ***************************************
// *********** Screech
// ***************************************
/datum/action/ability/activable/xeno/screech
	name = "Screech"
	action_icon_state = "screech"
	desc = "A large area knockdown that causes pain and screen-shake."

	ability_cost = 250
	cooldown_duration = 100 SECONDS
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_SCREECH,
	)

/datum/action/ability/activable/xeno/screech/on_cooldown_finish()
	to_chat(owner, span_warning("We feel our throat muscles vibrate. We are ready to screech again."))
	return ..()

/datum/action/ability/activable/xeno/screech/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/queen/X = owner

	//screech is so powerful it kills huggers in our hands
	if(istype(X.r_hand, /obj/item/clothing/mask/facehugger))
		var/obj/item/clothing/mask/facehugger/FH = X.r_hand
		if(FH.stat != DEAD)
			FH.kill_hugger()

	if(istype(X.l_hand, /obj/item/clothing/mask/facehugger))
		var/obj/item/clothing/mask/facehugger/FH = X.l_hand
		if(FH.stat != DEAD)
			FH.kill_hugger()

	succeed_activate()
	add_cooldown()

	playsound(X.loc, 'sound/voice/alien_queen_screech.ogg', 75, 0)
	X.visible_message(span_xenohighdanger("\The [X] emits an ear-splitting guttural roar!"))
	GLOB.round_statistics.queen_screech++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "queen_screech")
	X.create_shriekwave() //Adds the visual effect. Wom wom wom
	//stop_momentum(charge_dir) //Screech kills a charge

	var/list/nearby_living = list()
	for(var/mob/living/L in hearers(WORLD_VIEW, X))
		nearby_living.Add(L)

	for(var/i in GLOB.mob_living_list)
		var/mob/living/L = i
		if(get_dist(L, X) > WORLD_VIEW_NUM)
			continue
		L.screech_act(X, WORLD_VIEW_NUM, L in nearby_living)

/datum/action/ability/activable/xeno/screech/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/screech/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(get_dist(target, owner) > 4)
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

// ***************************************
// *********** Overwatch
// ***************************************
/datum/action/ability/xeno_action/watch_xeno
	name = "Watch Xenomorph"
	action_icon_state = "watch_xeno"
	desc = "See from the target Xenomorphs vision. Click again the ability to stop observing"
	ability_cost = 0
	use_state_flags = ABILITY_USE_LYING
	var/overwatch_active = FALSE

/datum/action/ability/xeno_action/watch_xeno/give_action(mob/living/L)
	. = ..()
	RegisterSignal(L, COMSIG_MOB_DEATH, PROC_REF(on_owner_death))
	RegisterSignal(L, COMSIG_XENOMORPH_WATCHXENO, PROC_REF(on_list_xeno_selection))

/datum/action/ability/xeno_action/watch_xeno/remove_action(mob/living/L)
	if(overwatch_active)
		stop_overwatch()
	UnregisterSignal(L, list(COMSIG_MOB_DEATH, COMSIG_XENOMORPH_WATCHXENO))
	return ..()

/datum/action/ability/xeno_action/watch_xeno/should_show()
	return FALSE // Overwatching now done through hive status UI!

/datum/action/ability/xeno_action/watch_xeno/proc/start_overwatch(mob/living/carbon/xenomorph/target)
	if(!can_use_action()) // Check for action now done here as action_activate pipeline has been bypassed with signal activation.
		return

	var/mob/living/carbon/xenomorph/watcher = owner
	var/mob/living/carbon/xenomorph/old_xeno = watcher.observed_xeno
	if(old_xeno == target)
		stop_overwatch(TRUE)
		return
	if(old_xeno)
		stop_overwatch(FALSE)
	watcher.observed_xeno = target
	if(isxenoqueen(watcher)) // Only queen needs the eye shown.
		target.hud_set_queen_overwatch()
	watcher.reset_perspective()
	RegisterSignal(target, COMSIG_HIVE_XENO_DEATH, PROC_REF(on_xeno_death))
	RegisterSignals(target, list(COMSIG_XENOMORPH_EVOLVED, COMSIG_XENOMORPH_DEEVOLVED), PROC_REF(on_xeno_evolution))
	RegisterSignal(watcher, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement))
	RegisterSignal(watcher, COMSIG_XENOMORPH_TAKING_DAMAGE, PROC_REF(on_damage_taken))
	overwatch_active = TRUE
	set_toggle(TRUE)

/datum/action/ability/xeno_action/watch_xeno/proc/stop_overwatch(do_reset_perspective = TRUE)
	var/mob/living/carbon/xenomorph/watcher = owner
	var/mob/living/carbon/xenomorph/observed = watcher.observed_xeno
	watcher.observed_xeno = null
	if(!QDELETED(observed))
		UnregisterSignal(observed, list(COMSIG_HIVE_XENO_DEATH, COMSIG_XENOMORPH_EVOLVED, COMSIG_XENOMORPH_DEEVOLVED))
		if(isxenoqueen(watcher)) // Only queen has to reset the eye overlay.
			observed.hud_set_queen_overwatch()
	if(do_reset_perspective)
		watcher.reset_perspective()
	UnregisterSignal(watcher, list(COMSIG_MOVABLE_MOVED, COMSIG_XENOMORPH_TAKING_DAMAGE))
	overwatch_active = FALSE
	set_toggle(FALSE)

/datum/action/ability/xeno_action/watch_xeno/proc/on_list_xeno_selection(datum/source, mob/living/carbon/xenomorph/selected_xeno)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(start_overwatch), selected_xeno)

/datum/action/ability/xeno_action/watch_xeno/proc/on_xeno_evolution(datum/source, mob/living/carbon/xenomorph/new_xeno)
	SIGNAL_HANDLER
	start_overwatch(new_xeno)

/datum/action/ability/xeno_action/watch_xeno/proc/on_xeno_death(datum/source, mob/living/carbon/xenomorph/dead_xeno)
	SIGNAL_HANDLER
	if(overwatch_active)
		stop_overwatch()

/datum/action/ability/xeno_action/watch_xeno/proc/on_owner_death(mob/source, gibbing)
	SIGNAL_HANDLER
	if(overwatch_active)
		stop_overwatch()

/datum/action/ability/xeno_action/watch_xeno/proc/on_movement(datum/source, atom/oldloc, direction, Forced)
	SIGNAL_HANDLER
	if(overwatch_active)
		stop_overwatch()

/datum/action/ability/xeno_action/watch_xeno/proc/on_damage_taken(datum/source, damage)
	SIGNAL_HANDLER
	if(overwatch_active)
		stop_overwatch()


// ***************************************
// *********** Queen zoom
// ***************************************
/datum/action/ability/xeno_action/toggle_queen_zoom
	name = "Toggle Queen Zoom"
	action_icon_state = "toggle_queen_zoom"
	desc = "Zoom out for a larger view around wherever you are looking."
	ability_cost = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TOGGLE_QUEEN_ZOOM,
	)


/datum/action/ability/xeno_action/toggle_queen_zoom/action_activate()
	var/mob/living/carbon/xenomorph/queen/xeno = owner
	if(xeno.do_actions)
		return
	if(xeno.is_zoomed)
		zoom_xeno_out(xeno.observed_xeno ? FALSE : TRUE)
		return
	if(!do_after(xeno, 1 SECONDS, FALSE, null, BUSY_ICON_GENERIC) || xeno.is_zoomed)
		return
	zoom_xeno_in(xeno.observed_xeno ? FALSE : TRUE) //No need for feedback message if our eye is elsewhere.


/datum/action/ability/xeno_action/toggle_queen_zoom/proc/zoom_xeno_in(message = TRUE)
	var/mob/living/carbon/xenomorph/xeno = owner
	RegisterSignal(xeno, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement))
	if(message)
		xeno.visible_message(span_notice("[xeno] emits a broad and weak psychic aura."),
		span_notice("We start focusing our psychic energy to expand the reach of our senses."), null, 5)
	xeno.zoom_in(0, 12)


/datum/action/ability/xeno_action/toggle_queen_zoom/proc/zoom_xeno_out(message = TRUE)
	var/mob/living/carbon/xenomorph/xeno = owner
	UnregisterSignal(xeno, COMSIG_MOVABLE_MOVED)
	if(message)
		xeno.visible_message(span_notice("[xeno] stops emitting its broad and weak psychic aura."),
		span_notice("We stop the effort of expanding our senses."), null, 5)
	xeno.zoom_out()


/datum/action/ability/xeno_action/toggle_queen_zoom/proc/on_movement(datum/source, atom/oldloc, direction, Forced)
	zoom_xeno_out()


// ***************************************
// *********** Set leader
// ***************************************
/datum/action/ability/xeno_action/set_xeno_lead
	name = "Choose/Follow Xenomorph Leaders"
	action_icon_state = "xeno_lead"
	desc = "Make a target Xenomorph a leader."
	ability_cost = 200
	use_state_flags = ABILITY_USE_LYING

/datum/action/ability/xeno_action/set_xeno_lead/should_show()
	return FALSE // Leadership now set through hive status UI!

/datum/action/ability/xeno_action/set_xeno_lead/give_action(mob/living/L)
	. = ..()
	RegisterSignal(L, COMSIG_XENOMORPH_LEADERSHIP, PROC_REF(try_use_action))

/datum/action/ability/xeno_action/set_xeno_lead/remove_action(mob/living/L)
	. = ..()
	UnregisterSignal(L, COMSIG_XENOMORPH_LEADERSHIP)

/// Signal handler for the set_xeno_lead action that checks can_use
/datum/action/ability/xeno_action/set_xeno_lead/proc/try_use_action(datum/source, mob/living/carbon/xenomorph/target)
	SIGNAL_HANDLER
	if(!can_use_action())
		return
	INVOKE_ASYNC(src, PROC_REF(select_xeno_leader), target)

/// Check if there is an empty slot and promote the passed xeno to a hive leader
/datum/action/ability/xeno_action/set_xeno_lead/proc/select_xeno_leader(mob/living/carbon/xenomorph/selected_xeno)
	var/mob/living/carbon/xenomorph/queen/xeno_ruler = owner

	if(selected_xeno.queen_chosen_lead)
		unset_xeno_leader(selected_xeno)
		return

	if(xeno_ruler.xeno_caste.queen_leader_limit <= length(xeno_ruler.hive.xeno_leader_list))
		xeno_ruler.balloon_alert(xeno_ruler, "No more leadership slots")
		return

	set_xeno_leader(selected_xeno)

/// Remove the passed xeno's leadership
/datum/action/ability/xeno_action/set_xeno_lead/proc/unset_xeno_leader(mob/living/carbon/xenomorph/selected_xeno)
	var/mob/living/carbon/xenomorph/xeno_ruler = owner
	xeno_ruler.balloon_alert(xeno_ruler, "Xeno demoted")
	selected_xeno.balloon_alert(selected_xeno, "Leadership removed")
	selected_xeno.hive.remove_leader(selected_xeno)
	selected_xeno.hud_set_queen_overwatch()
	selected_xeno.handle_xeno_leader_pheromones(xeno_ruler)

	selected_xeno.update_leader_icon(FALSE)

/// Promote the passed xeno to a hive leader, should not be called direct
/datum/action/ability/xeno_action/set_xeno_lead/proc/set_xeno_leader(mob/living/carbon/xenomorph/selected_xeno)
	var/mob/living/carbon/xenomorph/xeno_ruler = owner
	if(!(selected_xeno.xeno_caste.can_flags & CASTE_CAN_BE_LEADER))
		xeno_ruler.balloon_alert(xeno_ruler, "Xeno cannot lead")
		return
	xeno_ruler.balloon_alert(xeno_ruler, "Xeno promoted")
	selected_xeno.balloon_alert(selected_xeno, "Promoted to leader")
	to_chat(selected_xeno, span_xenoannounce("[xeno_ruler] has selected us as a Hive Leader. The other Xenomorphs must listen to us. We will also act as a beacon for the Queen's pheromones."))

	xeno_ruler.hive.add_leader(selected_xeno)
	selected_xeno.hud_set_queen_overwatch()
	selected_xeno.handle_xeno_leader_pheromones(xeno_ruler)
	notify_ghosts("\ [xeno_ruler] has designated [selected_xeno] as a Hive Leader", source = selected_xeno, action = NOTIFY_ORBIT)

	selected_xeno.update_leader_icon(TRUE)

// ***************************************
// *********** Queen Acidic Salve
// ***************************************
/datum/action/ability/activable/xeno/psychic_cure/queen_give_heal
	name = "Heal"
	action_icon_state = "heal_xeno"
	desc = "Apply a minor heal to the target."
	cooldown_duration = 5 SECONDS
	ability_cost = 150
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_QUEEN_HEAL,
	)
	heal_range = HIVELORD_HEAL_RANGE
	target_flags = ABILITY_XENO_TARGET|ABILITY_HUMAN_TARGET

/datum/action/ability/activable/xeno/psychic_cure/queen_give_heal/use_ability(mob/living/target)
	if(!ismob(target))
		return FALSE
	if(owner.do_actions)
		return FALSE
	if(!do_mob(owner, target, 1 SECONDS, BUSY_ICON_FRIENDLY, BUSY_ICON_MEDICAL))
		return FALSE
	target.visible_message(span_xenowarning("\the [owner] vomits healing resin over [target], mending their wounds!"))
	playsound(target, "alien_drool", 25)
	new /obj/effect/temp_visual/telekinesis(get_turf(target))
	var/mob/living/carbon/xenomorph/patient = target
	patient.salve_healing()
	owner.changeNext_move(CLICK_CD_RANGE)
	succeed_activate()
	add_cooldown()
	if(owner.client)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
		personal_statistics.heals++

/// Heals the target.
/mob/living/proc/salve_healing()
	var/amount = 50
	var/mob/living/carbon/xenomorph/X = src
	var/recovery_aura = isxeno(src) ? X.recovery_aura : 2
	if(recovery_aura)
		amount += recovery_aura * maxHealth * 0.01
	var/remainder = max(0, amount - getBruteLoss())
	if(!isxeno(src))
		amount = amount/2
	adjustBruteLoss(-amount)
	adjustFireLoss(-remainder, updating_health = TRUE)
	adjust_sunder(-amount/10)

// ***************************************
// *********** Queen plasma
// ***************************************
/datum/action/ability/activable/xeno/queen_give_plasma
	name = "Give Plasma"
	action_icon_state = "queen_give_plasma"
	desc = "Give plasma to a target Xenomorph (you must be overwatching them.)"
	ability_cost = 150
	cooldown_duration = 8 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_QUEEN_GIVE_PLASMA,
	)
	use_state_flags = ABILITY_USE_LYING
	target_flags = ABILITY_MOB_TARGET

/datum/action/ability/activable/xeno/queen_give_plasma/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!isxeno(target))
		return FALSE
	var/mob/living/carbon/xenomorph/receiver = target
	if(!CHECK_BITFIELD(use_state_flags|override_flags, ABILITY_IGNORE_DEAD_TARGET) && receiver.stat == DEAD)
		if(!silent)
			receiver.balloon_alert(owner, "Cannot give plasma, dead")
		return FALSE
	if(!CHECK_BITFIELD(receiver.xeno_caste.can_flags, CASTE_CAN_BE_GIVEN_PLASMA))
		if(!silent)
			receiver.balloon_alert(owner, "Cannot give plasma")
			return FALSE
	var/mob/living/carbon/xenomorph/giver = owner
	if(giver.z != receiver.z)
		if(!silent)
			receiver.balloon_alert(owner, "Cannot give plasma, too far")
		return FALSE
	if(receiver.plasma_stored >= receiver.xeno_caste.plasma_max)
		if(!silent)
			receiver.balloon_alert(owner, "Cannot give plasma, full")
		return FALSE


/datum/action/ability/activable/xeno/queen_give_plasma/give_action(mob/living/L)
	. = ..()
	RegisterSignal(L, COMSIG_XENOMORPH_QUEEN_PLASMA, PROC_REF(try_use_ability))

/datum/action/ability/activable/xeno/queen_give_plasma/remove_action(mob/living/L)
	. = ..()
	UnregisterSignal(L, COMSIG_XENOMORPH_QUEEN_PLASMA)

/// Signal handler for the queen_give_plasma action that checks can_use
/datum/action/ability/activable/xeno/queen_give_plasma/proc/try_use_ability(datum/source, mob/living/carbon/xenomorph/target)
	SIGNAL_HANDLER
	if(!can_use_ability(target, FALSE, ABILITY_IGNORE_SELECTED_ABILITY))
		return
	use_ability(target)

/datum/action/ability/activable/xeno/queen_give_plasma/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/receiver = target
	add_cooldown()
	receiver.gain_plasma(300)
	succeed_activate()
	receiver.balloon_alert_to_viewers("Queen plasma", ignored_mobs = GLOB.alive_human_list)
	if (get_dist(owner, receiver) > 7)
		// Out of screen transfer.
		owner.balloon_alert(owner, "Transferred plasma")


#define BULWARK_LOOP_TIME 1 SECONDS
#define BULWARK_RADIUS 4
#define BULWARK_ARMOR_MULTIPLIER 0.25

/datum/action/ability/xeno_action/bulwark
	name = "Royal Bulwark"
	action_icon_state = "bulwark"
	desc = "Creates a field of defensive energy, filling chinks in the armor of nearby sisters, making them more resilient."
	ability_cost = 100
	cooldown_duration = 20 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_QUEEN_BULWARK,
	)
	/// assoc list xeno = armor_diff
	var/list/armor_mod_keys = list()

/datum/action/ability/xeno_action/bulwark/action_activate()
	var/list/turf/affected_turfs = RANGE_TURFS(BULWARK_RADIUS, owner)
	add_cooldown()

	for(var/turf/target AS in affected_turfs)
		//yes I realize this adds and removes it every move but its simple
		//also we use this and not aura because we want speedy updates on entering
		RegisterSignal(target, COMSIG_ATOM_EXITED, PROC_REF(remove_buff))
		RegisterSignal(target, COMSIG_ATOM_ENTERED, PROC_REF(apply_buff))
		ADD_TRAIT(target, TRAIT_BULWARKED_TURF, XENO_TRAIT)
		for(var/mob/living/carbon/xenomorph/xeno in target)
			apply_buff(null, xeno)

	var/obj/effect/abstract/particle_holder/aoe_particles = new(owner.loc, /particles/bulwark_aoe)
	aoe_particles.particles.position = generator(GEN_SQUARE, 0, 16 + (BULWARK_RADIUS-1)*32, LINEAR_RAND)
	while(do_after(owner, BULWARK_LOOP_TIME, BUSY_ICON_MEDICAL, extra_checks = CALLBACK(src, TYPE_PROC_REF(/datum/action, can_use_action), FALSE, ABILITY_IGNORE_COOLDOWN|ABILITY_USE_BUSY)))
		succeed_activate()

	aoe_particles.particles.spawning = 0
	QDEL_IN(aoe_particles, 4 SECONDS)

	for(var/turf/target AS in affected_turfs)
		UnregisterSignal(target, list(COMSIG_ATOM_EXITED, COMSIG_ATOM_ENTERED))
		REMOVE_TRAIT(target, TRAIT_BULWARKED_TURF, XENO_TRAIT)
		for(var/mob/living/carbon/xenomorph/xeno AS in armor_mod_keys)
			remove_buff(null, xeno)
	affected_turfs = null

///adds buff to xenos
/datum/action/ability/xeno_action/bulwark/proc/apply_buff(datum/source, mob/living/carbon/xenomorph/xeno, direction)
	SIGNAL_HANDLER
	if(!isxeno(xeno) || armor_mod_keys[xeno] || !owner.issamexenohive(xeno))
		return
	var/datum/armor/basearmor = getArmor(arglist(xeno.xeno_caste.soft_armor))
	var/datum/armor/armordiff = basearmor.scaleAllRatings(BULWARK_ARMOR_MULTIPLIER)
	xeno.soft_armor = xeno.soft_armor.attachArmor(armordiff)
	armor_mod_keys[xeno] = armordiff

///removes the buff from xenos
/datum/action/ability/xeno_action/bulwark/proc/remove_buff(datum/source, mob/living/carbon/xenomorph/xeno, direction)
	SIGNAL_HANDLER
	if(direction) // triggered by moving signal, check if next turf is in bulwark
		var/turf/next = get_step(source, direction)
		if(HAS_TRAIT(next, TRAIT_BULWARKED_TURF))
			return
	if(armor_mod_keys[xeno])
		xeno.soft_armor = xeno.soft_armor.detachArmor(armor_mod_keys[xeno])
		armor_mod_keys -= xeno

/particles/bulwark_aoe
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = list("cross" = 1, "x" = 1, "rectangle" = 1, "up_arrow" = 1, "down_arrow" = 1, "square" = 1)
	width = 500
	height = 500
	count = 2000
	spawning = 50
	gravity = list(0, 0.1)
	color = LIGHT_COLOR_PURPLE
	lifespan = 13
	fade = 5
	fadein = 5
	scale = 0.8
	friction = generator(GEN_NUM, 0.1, 0.15)
	spin = generator(GEN_NUM, -20, 20)
