/datum/disease/fake_gbs
	name = "GBS"
	medical_name = "Neutered Guillain-Barré Syndrome"
	max_stages = 5
	spread_text = "On contact"
	spread_flags = DISEASE_SPREAD_CONTACT | DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_FLUIDS
	cure_text = REAGENT_ADRANOL + " & " + REAGENT_SULFUR
	cures = list(REAGENT_ID_ADRANOL, REAGENT_ID_SULFUR)
	agent = "Gravitokinetic Bipotential SADS-"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/human/monkey)
	desc = "If left untreated death will occur."
	danger = DISEASE_BIOHAZARD // Mimics real GBS

/datum/disease/fake_gbs/stage_act()
	if(!..())
		return FALSE
	switch(stage)
		if(2)
			if(prob(1))
				affected_mob.emote("sneeze")
		if(3)
			if(prob(5))
				affected_mob.emote("cough")
			else if(prob(5))
				affected_mob.emote("gasp")
			if(prob(10))
				to_chat(affected_mob, span_danger("You're starting to feel very weak..."))
		if(4)
			if(prob(10))
				affected_mob.emote("cough")
		if(5)
			if(prob(10))
				affected_mob.emote("cough")
