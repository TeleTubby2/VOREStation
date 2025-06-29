/*
//////////////////////////////////////

Weakness

	Slightly noticeable.
	Lowers resistance slightly.
	Decreases stage speed moderately.
	Decreases transmittablity moderately.
	Moderate Level.

Bonus
	Weakens the host

//////////////////////////////////////
*/

/datum/symptom/weakness
	name = "Weakness"
	stealth = -1
	resistance = -1
	stage_speed = -2
	transmission = -2
	symptom_delay_min = 20 SECONDS
	symptom_delay_max = 60 SECONDS
	level = 3
	severity = 3

	prefixes = list("Weakening ", "Weak's ")

/datum/symptom/weakness/Activate(datum/disease/advance/A)
	..()
	if(prob(SYMPTOM_ACTIVATION_PROB))
		var/mob/living/M = A.affected_mob
		switch(A.stage)
			if(1, 2)
				to_chat(M, span_warning(pick("You feel weak.", "You feel lazy.")))
			if(3, 4)
				to_chat(M, span_boldwarning(pick("You feel very frail.", "You think you might faint.")))
				M.Weaken(10)
			else
				to_chat(M, span_userdanger(pick("You feel tremendously weak!", "Your body trembles as exhaustion creeps over you.")))
				M.Weaken(20)
				if(M.weakened > 60 && !M.stat)
					M.visible_message(span_warning("[M] faints!"), span_userdanger("You swoon and faint..."))
					M.AdjustSleeping(10)
	return
