// Bluespace crystals, used in telescience and when crushed it will blink you to a random turf.

/obj/item/bluespace_crystal
	name = "bluespace crystal"
	desc = "A glowing bluespace crystal, not much is known about how they work. It looks very delicate."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "bluespace_crystal"
	w_class = ITEMSIZE_TINY
	origin_tech = list(TECH_BLUESPACE = 6, TECH_MATERIAL = 3)
	var/blink_range = 8 // The teleport range when crushed/thrown at someone.

/obj/item/bluespace_crystal/Initialize(mapload)
	. = ..()
	pixel_x = rand(-5, 5)
	pixel_y = rand(-5, 5)

/obj/item/bluespace_crystal/attack_self(mob/user)
	user.visible_message(span_warning("[user] crushes [src]!"), span_danger("You crush [src]!"))
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread()
	s.set_up(5, 1, get_turf(src))
	s.start()
	blink_mob(user)
	user.unEquip(src)
	qdel(src)

/obj/item/bluespace_crystal/proc/blink_mob(mob/living/L)
	do_teleport(L, get_turf(L), blink_range, asoundin = 'sound/effects/phasein.ogg')

/obj/item/bluespace_crystal/throw_impact(atom/hit_atom)
	if(!..()) // not caught in mid-air
		visible_message(span_notice("[src] fizzles and disappears upon impact!"))
		var/turf/T = get_turf(hit_atom)
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread()
		s.set_up(5, 1, T)
		s.start()
		if(isliving(hit_atom))
			blink_mob(hit_atom)
		qdel(src)

// Artifical bluespace crystal, doesn't give you much research.

/obj/item/bluespace_crystal/artificial
	name = "artificial bluespace crystal"
	desc = "An artificially made bluespace crystal, it looks delicate."
	origin_tech = list(TECH_BLUESPACE = 3, TECH_PHORON = 4)
	blink_range = 4 // Not as good as the organic stuff!
