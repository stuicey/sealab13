/obj/effect/plant/HasProximity(var/atom/movable/AM)

	plant_controller.add_plant(src)
	if(!is_mature() || seed.get_trait(TRAIT_SPREAD) != 2)
		return

	var/mob/living/M = AM
	if(!istype(M))
		return

	if(!buckled_mob && !M.buckled && !M.anchored && (M.small || prob(round(seed.get_trait(TRAIT_POTENCY)/2))))
		entangle(M)

/obj/effect/plant/attack_hand(mob/user as mob)
	plant_controller.add_plant(src)
	manual_unbuckle(user)

/obj/effect/plant/proc/trodden_on(var/mob/living/victim)
	plant_controller.add_plant(src)
	if(!is_mature())
		return
	var/mob/living/carbon/human/H = victim
	if(!istype(H) || H.shoes)
		return
	seed.do_thorns(victim,src)
	seed.do_sting(victim,src,pick("r_foot","l_foot","r_leg","l_leg"))

/obj/effect/plant/proc/unbuckle()
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			buckled_mob.buckled = null
			buckled_mob.anchored = initial(buckled_mob.anchored)
			buckled_mob.update_canmove()
		buckled_mob = null
	return

/obj/effect/plant/proc/manual_unbuckle(mob/user as mob)
	if(buckled_mob)
		if(prob(seed ? min(max(0,100 - seed.get_trait(TRAIT_POTENCY)/2),100) : 50))
			if(buckled_mob.buckled == src)
				if(buckled_mob != user)
					buckled_mob.visible_message(\
						"<span class='notice'>[user.name] frees [buckled_mob.name] from \the [src].</span>",\
						"<span class='notice'>[user.name] frees you from \the [src].</span>",\
						"<span class='warning'>You hear shredding and ripping.</span>")
				else
					buckled_mob.visible_message(\
						"<span class='notice'>[buckled_mob.name] struggles free of \the [src].</span>",\
						"<span class='notice'>You untangle \the [src] from around yourself.</span>",\
						"<span class='warning'>You hear shredding and ripping.</span>")
			unbuckle()
		else
			var/text = pick("rip","tear","pull")
			user.visible_message(\
				"<span class='notice'>[user.name] [text]s at \the [src].</span>",\
				"<span class='notice'>You [text] at \the [src].</span>",\
				"<span class='warning'>You hear shredding and ripping.</span>")
	return

/obj/effect/plant/proc/entangle(var/mob/living/victim)

	if(buckled_mob)
		return

	victim.buckled = src
	victim.update_canmove()
	buckled_mob = victim

	if(victim.loc != src.loc)
		src.visible_message("<span class='danger'>Tendrils lash out from \the [src] and drag \the [victim] in!</span>")
		victim.loc = src.loc
	victim << "<span class='danger'>Tendrils [pick("wind", "tangle", "tighten")] around you!</span>"
