// the power cell
// charge from 0 to 100%
// fits in APC to provide backup power

/obj/item/weapon/cell/New()
	..()

	charge = charge * maxcharge/100.0		// map obj has charge as percentage, convert to real value here

	spawn(5)
		updateicon()


/obj/item/weapon/cell/proc/updateicon()

	if(maxcharge <= 2500)
		icon_state = "cell"
	else
		icon_state = "hpcell"

	overlays = null

	if(charge < 0.01)
		return
	else if(charge/maxcharge >=0.995)
		overlays += image('power.dmi', "cell-o2")
	else
		overlays += image('power.dmi', "cell-o1")

/obj/item/weapon/cell/proc/percent()		// return % charge of cell
	return 100.0*charge/maxcharge

// use power from a cell
/obj/item/weapon/cell/proc/use(var/amount)
	charge = max(0, charge-amount)
	if(rigged && amount > 0)
		explode()

// recharge the cell
/obj/item/weapon/cell/proc/give(var/amount)
	var/power_used = min(maxcharge-charge,amount)
	charge += power_used
	if(rigged && amount > 0)
		explode()
	return power_used


/obj/item/weapon/cell/examine()
	set src in view(1)
	if(usr /*&& !usr.stat*/)
		if(maxcharge <= 2500)
			usr << "[desc]\nThe manufacturer's label states this cell has a power rating of [maxcharge], and that you should not swallow it.\nThe charge meter reads [round(src.percent() )]%."
		else
			usr << "This power cell has an exciting chrome finish, as it is an uber-capacity cell type! It has a power rating of [maxcharge]!!!\nThe charge meter reads [round(src.percent() )]%."


/obj/item/weapon/cell/attackby(obj/item/W, mob/user)
	var/obj/item/clothing/gloves/G = W
	if(istype(G))
		if(charge < 1000)
			return

		G.elecgen = 1
		G.uses = min(5, round(charge / 1000))
		use(G.uses*1000)
		updateicon()
		user << "\red These gloves are now electrically charged!"

	else if(istype(W, /obj/item/weapon/reagent_containers/syringe))
		var/obj/item/weapon/reagent_containers/syringe/S = W

		user << "You inject the solution into the power cell."

		if(S.reagents.has_reagent("plasma", 5))

			rigged = 1

		S.reagents.clear_reagents()


/obj/item/weapon/cell/proc/explode()
	var/turf/T = get_turf(src.loc)
/*
 * 1000-cell	explosion(T, -1, 0, 1, 1)
 * 2500-cell	explosion(T, -1, 0, 1, 1)
 * 10000-cell	explosion(T, -1, 1, 3, 3)
 * 15000-cell	explosion(T, -1, 2, 4, 4)
 * */
	if (charge==0)
		return
	var/devastation_range = -1 //round(charge/11000)
	var/heavy_impact_range = round(sqrt(charge)/60)
	var/light_impact_range = round(sqrt(charge)/30)
	var/flash_range = light_impact_range
	if (light_impact_range==0)
		rigged = 0
		corrupt()
		return
	//explosion(T, 0, 1, 2, 2)
	explosion(T, devastation_range, heavy_impact_range, light_impact_range, flash_range)

	spawn(1)
		del(src)

/obj/item/weapon/cell/proc/corrupt()
	charge /= 2
	maxcharge /= 2
	if (prob(10))
		rigged = 1 //broken batterys are dangerous

/obj/item/weapon/cell/ex_act(severity)

	switch(severity)
		if(1.0)
			del(src)
			return
		if(2.0)
			if (prob(50))
				del(src)
				return
			if (prob(50))
				corrupt()
		if(3.0)
			if (prob(25))
				del(src)
				return
			if (prob(25))
				corrupt()
	return
	
/obj/item/weapon/cell/blob_act()
	if(prob(75))
		explode()
