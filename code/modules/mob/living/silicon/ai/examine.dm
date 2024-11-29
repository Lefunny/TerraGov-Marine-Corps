/mob/living/silicon/ai/examine(mob/user)
	SHOULD_CALL_PARENT(FALSE) // TODO ai and human examine dont send examine signal
	var/msg = "<span class='info'><br>"
	msg += "This is [icon2html(src, user)] <b>[src]</b>!<br>"

	if(stat == DEAD)
		msg += "[span_deadsay("It appears to be powered-down.")]<br>"
	else
		msg += "<span class='warning'>"
		if(getBruteLoss())
			if(getBruteLoss() < 30)
				msg += "It looks slightly dented.<br>"
			else
				msg += "<B>It looks severely dented!</B><br>"
		if(getFireLoss())
			if(getFireLoss() < 30)
				msg += "It looks slightly charred.<br>"
			else
				msg += "<B>Its casing is melted and heat-warped!</B><br>"

		if(stat == UNCONSCIOUS)
			msg += "It is non-responsive and displaying the text: \"RUNTIME: Sensory Overload, stack 26/3\".<br>"

		if(!client)
			msg += "[src]/Core.exe has stopped responding! Searching for a solution to the problem...<br>"

		msg += "</span>"
	if(ooc_notes||ooc_notes_likes||ooc_notes_dislikes||ooc_notes_favs||ooc_notes_maybes)
		msg += "OOC Notes: <a href='?src=\ref[src];ooc_notes=1'>\[View\]</a> - <a href='?src=\ref[src];print_ooc_notes_to_chat=1'>\[Print\]</a>"

	msg += "</span>"

	return list(msg)

/mob/living/silicon/ai/get_examine_string(mob/user, thats)
	return null

