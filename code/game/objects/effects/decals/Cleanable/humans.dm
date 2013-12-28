#define DRYING_TIME 5 * 60*10                        //for 1 unit of depth in puddle (amount var)

var/global/list/image/splatter_cache=list()

/obj/effect/decal/cleanable/blood
	name = "blood"
	desc = "It's thick and gooey. Perhaps it's the chef's cooking?"
	gender = PLURAL
	density = 0
	anchored = 1
	layer = 2
	icon = 'icons/effects/blood.dmi'
	icon_state = "mfloor1"
	random_icon_states = list("mfloor1", "mfloor2", "mfloor3", "mfloor4", "mfloor5", "mfloor6", "mfloor7")
	var/list/viruses = list()
	blood_DNA = list()
	var/basecolor="#A10808" // Color when wet.
	var/list/datum/disease2/disease/virus2 = list()
	var/amount = 5

/obj/effect/decal/cleanable/blood/Del()
	for(var/datum/disease/D in viruses)
		D.cure(0)
	..()

/obj/effect/decal/cleanable/blood/New()
	..()
	color = basecolor
	if(istype(src, /obj/effect/decal/cleanable/blood/gibs))
		return
	if(istype(src, /obj/effect/decal/cleanable/blood/tracks))
		return // We handle our own drying.
	if(src.type == /obj/effect/decal/cleanable/blood)
		if(src.loc && isturf(src.loc))
			for(var/obj/effect/decal/cleanable/blood/B in src.loc)
				if(B != src)
					if (B.blood_DNA)
						blood_DNA |= B.blood_DNA.Copy()
					del(B)
	spawn(DRYING_TIME * (amount+1))
		dry()

/obj/effect/decal/cleanable/blood/update_icon()
	if(basecolor == "rainbow") basecolor = "#[pick(list("FF0000","FF7F00","FFFF00","00FF00","0000FF","4B0082","8F00FF"))]"
	color = basecolor

/obj/effect/decal/cleanable/blood/HasEntered(mob/living/carbon/human/perp)
        if (!istype(perp))
                return
        if(amount < 1)
                return

        if(perp.shoes)
                perp.shoes:track_blood = max(amount,perp.shoes:track_blood)                //Adding blood to shoes
                if(!perp.shoes.blood_overlay)
                        perp.shoes.generate_blood_overlay()
                if(!perp.shoes.blood_DNA)
                        perp.shoes.blood_DNA = list()
                        perp.shoes.blood_overlay.color = basecolor
                        perp.shoes.overlays += perp.shoes.blood_overlay
                        perp.update_inv_shoes(1)
                perp.shoes.blood_DNA |= blood_DNA.Copy()
                perp.shoes.blood_color=basecolor
        else
                perp.track_blood = max(amount,perp.track_blood)                                //Or feet
                if(!perp.feet_blood_DNA)
                        perp.feet_blood_DNA = list()
                perp.feet_blood_DNA |= blood_DNA.Copy()
                perp.feet_blood_color=basecolor

        amount--

/obj/effect/decal/cleanable/blood/proc/dry()
		name = "dried [src.name]"
		desc = "It's dry and crusty. Someone is not doing their job."
		color = adjust_brightness(color, -50)
		amount = 0

/obj/effect/decal/cleanable/blood/attack_hand(mob/living/carbon/human/user)
	..()
	if (amount && istype(user))
		add_fingerprint(user)
		if (user.gloves)
			return
		var/taken = rand(1,amount)
		amount -= taken
		user << "<span class='notice'>You get some of \the [src] on your hands.</span>"
		if (!user.blood_DNA)
			user.blood_DNA = list()
		user.blood_DNA |= blood_DNA.Copy()
		user.bloody_hands += taken
		user.hand_blood_color = basecolor
		user.update_inv_gloves(1)
		user.verbs += /mob/living/carbon/human/proc/bloody_doodle

/obj/effect/decal/cleanable/blood/splatter
        random_icon_states = list("mgibbl1", "mgibbl2", "mgibbl3", "mgibbl4", "mgibbl5")
        amount = 2

/obj/effect/decal/cleanable/blood/drip
        name = "drips of blood"
        desc = "It's red."
        gender = PLURAL
        icon = 'icons/effects/drip.dmi'
        icon_state = "1"
        random_icon_states = list("1","2","3","4","5")
        amount = 0

/obj/effect/decal/cleanable/blood/writing
	icon_state = "tracks"
	desc = "It looks like a writing in blood."
	gender = NEUTER
	random_icon_states = list("writing1","writing2","writing3","writing4","writing5")
	amount = 0
	var/message

/obj/effect/decal/cleanable/blood/writing/New()
	..()
	if(random_icon_states.len)
		for(var/obj/effect/decal/cleanable/blood/writing/W in loc)
			random_icon_states.Remove(W.icon_state)
		icon_state = pick(random_icon_states)
	else
		icon_state = "writing1"

/obj/effect/decal/cleanable/blood/writing/examine()
	..()
	usr << "It reads: <font color='[basecolor]'>\"[message]\"<font>"

/obj/effect/decal/cleanable/blood/gibs
	name = "gibs"
	desc = "They look bloody and gruesome."
	gender = PLURAL
	density = 0
	anchored = 1
	layer = 2
	icon = 'icons/effects/blood.dmi'
	icon_state = "gibbl5"
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6")

/obj/effect/decal/cleanable/blood/gibs/update_icon()
	//overlays.Cut()
	//..()
	//overlays += image(icon, src, "[icon_state]_flesh")

/obj/effect/decal/cleanable/blood/gibs/up
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6","gibup1","gibup1","gibup1")

/obj/effect/decal/cleanable/blood/gibs/down
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6","gibdown1","gibdown1","gibdown1")

/obj/effect/decal/cleanable/blood/gibs/body
	random_icon_states = list("gibhead", "gibtorso")

/obj/effect/decal/cleanable/blood/gibs/limb
	random_icon_states = list("gibleg", "gibarm")

/obj/effect/decal/cleanable/blood/gibs/core
	random_icon_states = list("gibmid1", "gibmid2", "gibmid3")


/obj/effect/decal/cleanable/blood/gibs/proc/streak(var/list/directions)
        spawn (0)
                var/direction = pick(directions)
                for (var/i = 0, i < pick(1, 200; 2, 150; 3, 50; 4), i++)
                        sleep(3)
                        if (i > 0)
                                var/obj/effect/decal/cleanable/blood/b = new /obj/effect/decal/cleanable/blood/splatter(src.loc)
                                b.basecolor = src.basecolor
                                b.update_icon()
                                for(var/datum/disease/D in src.viruses)
                                        var/datum/disease/ND = D.Copy(1)
                                        b.viruses += ND
                                        ND.holder = b

                        if (step_to(src, get_step(src, direction), 0))
                                break


/obj/effect/decal/cleanable/mucus
	name = "mucus"
	desc = "Disgusting mucus."
	gender = PLURAL
	density = 0
	anchored = 1
	layer = 2
	icon = 'icons/effects/blood.dmi'
	icon_state = "mucus"
	random_icon_states = list("mucus")

	var/list/datum/disease2/disease/virus2 = list()
	var/dry=0 // Keeps the lag down

/obj/effect/decal/cleanable/mucus/New()
	spawn(DRYING_TIME * 2)
		dry=1
