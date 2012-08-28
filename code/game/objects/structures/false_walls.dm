/obj/structure/falsewall
	var/mineral = "metal"

/obj/structure/falserwall
	var/mineral = "metal"

/obj/structure/falsewall/gold
	mineral = "gold"

/obj/structure/falsewall/silver
	mineral = "silver"

/obj/structure/falsewall/diamond
	mineral = "diamond"

/obj/structure/falsewall/uranium
	mineral = "uranium"
	var/active = null
	var/last_event = 0

/obj/structure/falsewall/plasma
	mineral = "plasma"

/obj/structure/falsewall/clown
	mineral = "clown"

/obj/structure/falsewall/sandstone
	mineral = "sandstone"

/*/obj/structure/falsewall/wood
	mineral = "wood"*/

/obj/structure/falsewall/attack_hand(mob/user as mob)
	if(density)
		// Open wall
		icon_state = "[mineral]fwall_open"
		flick("[mineral]fwall_opening", src)
		sleep(15)
		src.density = 0
		SetOpacity(0)
	else
		flick("[mineral]fwall_closing", src)
		icon_state = "[mineral]0"
		sleep(15)
		src.density = 1
		SetOpacity(1)
		src.relativewall()

/obj/structure/falsewall/uranium/attack_hand(mob/user as mob)
	radiate()
	..()

/obj/structure/falsewall/update_icon()//Calling icon_update will refresh the smoothwalls if it's closed, otherwise it will make sure the icon is correct if it's open
	..()
	if(density)
		icon_state = "[mineral]0"
		src.relativewall()
	else
		icon_state = "[mineral]fwall_open"

/obj/structure/falsewall/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/screwdriver))
		var/turf/T = get_turf(src)
		user.visible_message("[user] tightens some bolts on the wall.", "You tighten the bolts on the wall.")
		if(!mineral)
			T.ReplaceWithWall()
		else
			T.ReplaceWithMineralWall(mineral)
		del(src)

	if( istype(W, /obj/item/weapon/weldingtool) )
		var/obj/item/weapon/weldingtool/WT = W
		if( WT:welding )
			var/turf/T = get_turf(src)
			if(!mineral)
				T.ReplaceWithWall()
			else
				T.ReplaceWithMineralWall(mineral)
			if(mineral != "plasma")//Stupid shit keeps me from pushing the attackby() to plasma walls -Sieve
				T = get_turf(src)
				T.attackby(W,user)
			del(src)

	else if( istype(W, /obj/item/weapon/pickaxe/plasmacutter) )
		var/turf/T = get_turf(src)
		if(!mineral)
			T.ReplaceWithWall()
		else
			T.ReplaceWithMineralWall(mineral)
		if(mineral != "plasma")
			T = get_turf(src)
			T.attackby(W,user)
		del(src)

	//DRILLING
	else if (istype(W, /obj/item/weapon/pickaxe/diamonddrill))
		var/turf/T = get_turf(src)
		if(!mineral)
			T.ReplaceWithWall()
		else
			T.ReplaceWithMineralWall(mineral)
		T = get_turf(src)
		T.attackby(W,user)
		del(src)

	else if( istype(W, /obj/item/weapon/melee/energy/blade) )
		var/turf/T = get_turf(src)
		if(!mineral)
			T.ReplaceWithWall()
		else
			T.ReplaceWithMineralWall(mineral)
		if(mineral != "plasma")
			T = get_turf(src)
			T.attackby(W,user)
		del(src)
	/*

		var/turf/T = get_turf(user)
		user << "\blue Now adding plating..."
		sleep(40)
		if (get_turf(user) == T)
			user << "\blue You added the plating!"
			var/turf/Tsrc = get_turf(src)
			Tsrc.ReplaceWithWall()

	*/

/obj/structure/falsewall/uranium/attackby(obj/item/weapon/W as obj, mob/user as mob)
	radiate()
	..()

/obj/structure/falsewall/update_icon()//Calling icon_update will refresh the smoothwalls if it's closed, otherwise it will make sure the icon is correct if it's open
	..()
	if(density)
		icon_state = "[mineral]0"
		src.relativewall()
	else
		icon_state = "[mineral]fwall_open"

/obj/structure/falserwall/
	attack_hand(mob/user as mob)
		if(density)
			// Open wall
			icon_state = "frwall_open"
			flick("frwall_opening", src)
			sleep(15)
			density = 0
			SetOpacity(0)
		else
			icon_state = "r_wall"
			flick("frwall_closing", src)
			sleep(15)
			density = 1
			SetOpacity(1)
			relativewall()


	attackby(obj/item/weapon/W as obj, mob/user as mob)
		if(istype(W, /obj/item/weapon/screwdriver))
			var/turf/T = get_turf(src)
			user.visible_message("[user] tightens some bolts on the r wall.", "You tighten the bolts on the wall.")
			T.ReplaceWithWall() //Intentionally makes a regular wall instead of an r-wall (no cheap r-walls for you).
			del(src)

		if( istype(W, /obj/item/weapon/weldingtool) )
			var/obj/item/weapon/weldingtool/WT = W
			if( WT.remove_fuel(0,user) )
				var/turf/T = get_turf(src)
				T.ReplaceWithWall()
				T = get_turf(src)
				T.attackby(W,user)
				del(src)

		else if( istype(W, /obj/item/weapon/pickaxe/plasmacutter) )
			var/turf/T = get_turf(src)
			T.ReplaceWithWall()
			T = get_turf(src)
			T.attackby(W,user)
			del(src)

		//DRILLING
		else if (istype(W, /obj/item/weapon/pickaxe/diamonddrill))
			var/turf/T = get_turf(src)
			T.ReplaceWithWall()
			T = get_turf(src)
			T.attackby(W,user)
			del(src)

		else if( istype(W, /obj/item/weapon/melee/energy/blade) )
			var/turf/T = get_turf(src)
			T.ReplaceWithWall()
			T = get_turf(src)
			T.attackby(W,user)
			del(src)

/obj/structure/falsewall/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			for(var/mob/living/L in range(3,src))
				L.apply_effect(12,IRRADIATE,0)
			for(var/turf/simulated/wall/mineral/T in range(3,src))
				if(T.mineral == "uranium")
					T.radiate()
			last_event = world.time
			active = null
			return
	return
