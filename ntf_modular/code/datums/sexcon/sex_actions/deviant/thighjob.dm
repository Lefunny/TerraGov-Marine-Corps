/datum/sex_action/thighjob
	name = "Use their thighs to get off"

/datum/sex_action/thighjob/shows_on_menu(mob/living/carbon/user, mob/living/carbon/target)
	if(user == target)
		return FALSE
	if(isxeno(user))
		var/mob/living/carbon/xenomorph/userxeno
		if(userxeno.client?.prefs?.xenogender < 3)
			return FALSE
	else
		if(user.gender != MALE)
			return FALSE
	return TRUE

/datum/sex_action/thighjob/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(isxeno(user))
		var/mob/living/carbon/xenomorph/userxeno
		if(userxeno.client?.prefs?.xenogender < 3)
			return FALSE
	else
		if(user.gender != MALE)
			return FALSE
	return TRUE

/datum/sex_action/thighjob/on_start(mob/living/carbon/user, mob/living/carbon/target)
	..()
	user.visible_message(span_warning("[user] grabs [target]'s thighs and shoves his cock inbetween!"))

/datum/sex_action/thighjob/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.do_message_signature("[type]"))
		user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] fucks [target]'s thighs."))
	playsound(user, 'ntf_modular/sound/misc/mat/fingering.ogg', 20, TRUE, -2)
	do_thrust_animate(user, target)

	user.sexcon.perform_sex_action(user, 2, 4, TRUE)
	user.sexcon.handle_passive_ejaculation()

/datum/sex_action/thighjob/on_finish(mob/living/carbon/user, mob/living/carbon/target)
	..()
	user.visible_message(span_warning("[user] pulls his cock out from inbetween [target]'s thighs."))
