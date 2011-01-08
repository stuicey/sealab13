//BLIND

/client/proc/blind(mob/M as mob in oview())
	set category = "Spells"
	set name = "Blind"
//	if(!usr.casting()) return
	usr.verbs -= /client/proc/blind
	spawn(300)
		usr.verbs += /client/proc/blind

	usr.whisper("STI KALY")
//	usr.spellvoice()

	var/obj/overlay/B = new /obj/overlay( M.loc )
	B.icon_state = "blspell"
	B.icon = 'wizard.dmi'
	B.name = "spell"
	B.anchored = 1
	B.density = 0
	B.layer = 4
	M.canmove = 0
	spawn(5)
		del(B)
		M.canmove = 1
	M << text("\blue Your eyes cry out in pain!")
	M.disabilities |= 1
	spawn(300)
		M.disabilities &= ~1
	M.eye_blind = 10
	M.eye_blurry = 20
	return

//MAGIC MISSILE

/client/proc/magicmissile()
	set category = "Spells"
	set name = "Magic missile"
	set desc="Whom"
	if(!usr.casting()) return

	usr.say("FORTI GY AMA")
	usr.spellvoice()

	for (var/mob/M as mob in oview())
		spawn(0)
			var/obj/overlay/A = new /obj/overlay( usr.loc )
			A.icon_state = "magicm"
			A.icon = 'wizard.dmi'
			A.name = "a magic missile"
			A.anchored = 0
			A.density = 0
			A.layer = 4
			var/i
			for(i=0, i<20, i++)
				var/obj/overlay/B = new /obj/overlay( A.loc )
				B.icon_state = "magicmd"
				B.icon = 'wizard.dmi'
				B.name = "trail"
				B.anchored = 1
				B.density = 0
				B.layer = 3
				spawn(5)
					del(B)
				step_to(A,M,0)
				if (get_dist(A,M) == 0)
					M.weakened += 5
					M.fireloss += 10
					del(A)
					return
				sleep(5)
			del(A)

	usr.verbs -= /client/proc/magicmissile
	spawn(100)
		usr.verbs += /client/proc/magicmissile

//SMOKE

/client/proc/smokecloud()

	set category = "Spells"
	set name = "Smoke"
	set desc = "Creates a cloud of smoke"
//	if(!usr.casting()) return
	usr.verbs -= /client/proc/smokecloud
	spawn(120)
		usr.verbs += /client/proc/smokecloud
	var/datum/effects/system/bad_smoke_spread/smoke = new /datum/effects/system/bad_smoke_spread()
	smoke.set_up(10, 0, usr.loc)
	smoke.start()

//FORCE WALL

/obj/forcefield
	desc = "A space wizard's magic wall."
	name = "FORCEWALL"
	icon = 'mob.dmi'
	icon_state = "shield"
	anchored = 1.0
	opacity = 0
	density = 1
	unacidable = 1

/client/proc/forcewall()

	set category = "Spells"
	set name = "Forcewall"
	set desc = "Create a forcewall on your location."

//	if(!usr.casting()) return

	usr.verbs -= /client/proc/forcewall
	spawn(100)
		usr.verbs += /client/proc/forcewall
	var/forcefield

	usr.whisper("TARCOL MINTI ZHERI")
//	usr.spellvoice()

	forcefield =  new /obj/forcefield(locate(usr.x,usr.y,usr.z))
	spawn (300)
		del (forcefield)
	return

//FIREBALLAN

/client/proc/fireball(mob/T as mob in oview())
	set category = "Spells"
	set name = "Fireball"
	set desc="Fireball target:"
//	if(!usr.casting()) return

	usr.verbs -= /client/proc/fireball
	spawn(200)
		usr.verbs += /client/proc/fireball

	usr.say("ONI SOMA")
//	usr.spellvoice()

	var/obj/overlay/A = new /obj/overlay( usr.loc )
	A.icon_state = "fireball"
	A.icon = 'wizard.dmi'
	A.name = "a fireball"
	A.anchored = 0
	A.density = 0
	var/i
	for(i=0, i<100, i++)
		step_to(A,T,0)
		if (get_dist(A,T) <= 1)
			T.bruteloss += 20
			T.fireloss += 25

			explosion(T.loc, -1, -1, 2, 2)
			del(A)
			return
		sleep(2)
	del(A)
	return

//KNOCK

/client/proc/knock()
	set category = "Spells"
	set name = "Knock"
//	if(!usr.casting()) return
	usr.verbs -= /client/proc/knock
	spawn(100)
		usr.verbs += /client/proc/knock

	usr.whisper("AULIE OXIN FIERA")
//	usr.spellvoice()

	for(var/obj/machinery/door/G in oview(3))
		spawn(1)
			G.open()
	return

//KILL

/mob/proc/kill(mob/M as mob in oview(1))
	set category = "Spells"
	set name = "Disintegrate"
	if(!usr.casting()) return
	usr.verbs -= /mob/proc/kill
	spawn(600)
		usr.verbs += /mob/proc/kill

	usr.say("EI NATH")
	usr.spellvoice()

	var/datum/effects/system/spark_spread/s = new /datum/effects/system/spark_spread
	s.set_up(4, 1, M)
	s.start()

	M.dust()

//DISABLE TECH

/mob/proc/tech()
	set category = "Spells"
	set name = "Disable Technology"
	if(!usr.casting()) return
	usr.verbs -= /mob/proc/tech
	spawn(400)
		usr.verbs += /mob/proc/tech

	usr.say("NEC CANTIO")
	usr.spellvoice()

	var/turf/myturf = get_turf(usr)

	var/obj/overlay/pulse = new/obj/overlay ( myturf )
	pulse.icon = 'effects.dmi'
	pulse.icon_state = "emppulse"
	pulse.name = "emp pulse"
	pulse.anchored = 1
	spawn(20)
		del(pulse)

	for(var/obj/item/weapon/W in range(world.view-1, myturf))

		if (istype(W, /obj/item/assembly/m_i_ptank) || istype(W, /obj/item/assembly/r_i_ptank) || istype(W, /obj/item/assembly/t_i_ptank))

			var/fuckthis
			if(istype(W:part1,/obj/item/weapon/tank/plasma))
				fuckthis = W:part1
				fuckthis:ignite()
			if(istype(W:part2,/obj/item/weapon/tank/plasma))
				fuckthis = W:part2
				fuckthis:ignite()
			if(istype(W:part3,/obj/item/weapon/tank/plasma))
				fuckthis = W:part3
				fuckthis:ignite()


	for(var/mob/M in viewers(world.view-1, myturf))

		if(!istype(M, /mob/living)) continue
		if(M == usr) continue

		if (istype(M, /mob/living/silicon))
			M.fireloss += 25
			flick("noise", M:flash)
			M << "\red <B>*BZZZT*</B>"
			M << "\red Warning: Electromagnetic pulse detected."
			if(istype(M, /mob/living/silicon/ai))
				if (prob(30))
					switch(pick(1,2,3)) //Add Random laws.
						if(1)
							M:cancel_camera()
						if(2)
							M:lockdown()
						if(3)
							M:ai_call_shuttle()
			continue


		M << "\red <B>Your equipment malfunctions.</B>" //Yeah, i realise that this WILL
														//show if theyre not carrying anything
														//that is affected. lazy.
		if (locate(/obj/item/weapon/cloaking_device, M))
			for(var/obj/item/weapon/cloaking_device/S in M)
				S.active = 0
				S.icon_state = "shield0"

		if (locate(/obj/item/weapon/gun/energy, M))
			for(var/obj/item/weapon/gun/energy/G in M)
				G.charges = 0
				G.update_icon()

		if ((istype(M, /mob/living/carbon/human)) && (istype(M:glasses, /obj/item/clothing/glasses/thermal)))
			M << "\red <B>Your thermals malfunction.</B>"
			M.eye_blind = 3
			M.eye_blurry = 5
			M.disabilities |= 1
			spawn(100)
				M.disabilities &= ~1

		if (locate(/obj/item/device/radio, M))
			for(var/obj/item/device/radio/R in M) //Add something for the intercoms.
				R.broadcasting = 0
				R.listening = 0

		if (locate(/obj/item/device/flash, M))
			for(var/obj/item/device/flash/F in M) //Add something for the intercoms.
				F.attack_self()

		if (locate(/obj/item/weapon/baton, M))
			for(var/obj/item/weapon/baton/B in M) //Add something for the intercoms.
				B.charges = 0

		if(locate(/obj/item/clothing/under/chameleon, M))
			for(var/obj/item/clothing/under/chameleon/C in M) //Add something for the intercoms.
				M << "\red <B>Your jumpsuit malfunctions</B>"
				C.name = "psychedelic"
				C.desc = "Groovy!"
				C.icon_state = "psyche"
				C.color = "psyche"
				spawn(200)
					C.name = "Black Jumpsuit"
					C.icon_state = "bl_suit"
					C.color = "black"
					C.desc = null

		M << "\red <B>BZZZT</B>"


	for(var/obj/machinery/A in range(world.view-1, myturf))
		A.use_power(7500)

		var/obj/overlay/pulse2 = new/obj/overlay ( A.loc )
		pulse2.icon = 'effects.dmi'
		pulse2.icon_state = "empdisable"
		pulse2.name = "emp sparks"
		pulse2.anchored = 1
		pulse2.dir = pick(cardinal)

		spawn(10)
			del(pulse2)

		if(istype(A, /obj/machinery/turret))
			A:enabled = 0
			A:lasers = 0
			A:power_change()

		if(istype(A, /obj/machinery/computer) && prob(20))
			A:set_broken()

		if(istype(A, /obj/machinery/firealarm) && prob(50))
			A:alarm()

		if(istype(A, /obj/machinery/power/smes))
			A:online = 0
			A:charging = 0
			A:output = 0
			A:charge -= 1e6
			if (A:charge < 0)
				A:charge = 0
			spawn(100)
				A:output = initial(A:output)
				A:charging = initial(A:charging)
				A:online = initial(A:online)

		if(istype(A, /obj/machinery/door))
			if(prob(20) && (istype(A,/obj/machinery/door/airlock) || istype(A,/obj/machinery/door/window)) )
				A:open()
			if(A:secondsElectrified != 0) continue
			A:secondsElectrified = -1
			spawn(300)
				A:secondsElectrified = 0

		if(istype(A, /obj/machinery/power/apc))
			if(A:cell)
				A:cell:charge -= 1000
				if (A:cell:charge < 0)
					A:cell:charge = 0
			A:lighting = 0
			A:equipment = 0
			A:environ = 0
			spawn(600)
				A:equipment = 3
				A:environ = 3

		if(istype(A, /obj/machinery/camera))
			A.icon_state = "cameraemp"
			A:network = null                   //Not the best way but it will do. I think.
			spawn(600)
				A:network = initial(A:network)
				A:icon_state = initial(A:icon_state)
			for(var/mob/living/silicon/ai/O in world)
				if (O.current == A)
					O.cancel_camera()
					O << "Your connection to the camera has been lost."
			for(var/mob/O in world)
				if (istype(O.machine, /obj/machinery/computer/security))
					var/obj/machinery/computer/security/S = O.machine
					if (S.current == A)
						O.machine = null
						S.current = null
						O.reset_view(null)
						O << "The screen bursts into static."

		if(istype(A, /obj/machinery/clonepod))
			A:malfunction()

//BLINK

/client/proc/blink()
	set category = "Spells"
	set name = "Blink"
	set desc="Blink"
	if(!usr.casting()) return
	var/list/turfs = new/list()
	for(var/turf/T in orange(6))
		if(istype(T,/turf/space)) continue
		if(T.density) continue
		if(T.x>world.maxx-4 || T.x<4)	continue	//putting them at the edge is dumb
		if(T.y>world.maxy-4 || T.y<4)	continue
		turfs += T
	if(!turfs.len) turfs += pick(/turf in orange(6))
	var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
	smoke.set_up(10, 0, usr.loc)
	smoke.start()
	var/turf/picked = pick(turfs)
	if(!isturf(picked)) return
	usr.loc = picked
	usr.verbs -= /client/proc/blink
	spawn(40)
		usr.verbs += /client/proc/blink

//TELEPORT

/mob/proc/teleport()
	set category = "Spells"
	set name = "Teleport"
	set desc="Teleport"
	if(!usr.casting()) return
	var/A
	usr.verbs -= /mob/proc/teleport
/*
	var/list/theareas = new/list()
	for(var/area/AR in world)
		if(istype(AR, /area/shuttle) || istype(AR, /area/syndicate_station)) continue
		if(theareas.Find(AR.name)) continue
		var/turf/picked = pick(get_area_turfs(AR.type))
		if (picked.z == src.z)
			theareas += AR.name
			theareas[AR.name] = AR
*/

	A = input("Area to jump to", "BOOYEA", A) in teleportlocs

	spawn(600)
		usr.verbs += /mob/proc/teleport

	var/area/thearea = teleportlocs[A]

	usr.say("SCYAR NILA [uppertext(A)]")
	usr.spellvoice()

	var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
	smoke.set_up(5, 0, usr.loc)
	smoke.attach(usr)
	smoke.start()
	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		if(!T.density)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T

	usr.loc = pick(L)

	smoke.start()

/mob/proc/teleportscroll()
	if(usr.stat)
		usr << "Not when you're incapicated."
		return
	var/A

	A = input("Area to jump to", "BOOYEA", A) in teleportlocs
	var/area/thearea = teleportlocs[A]

	var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
	smoke.set_up(5, 0, usr.loc)
	smoke.attach(usr)
	smoke.start()
	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		if(!T.density)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T

	usr.loc = pick(L)

	smoke.start()

//JAUNT

/client/proc/jaunt()
	set category = "Spells"
	set name = "Ethereal Jaunt"
	if(!usr.casting()) return
	usr.verbs -= /client/proc/jaunt
	spawn(300)
		usr.verbs += /client/proc/jaunt
	spell_jaunt(usr)

/proc/spell_jaunt(var/mob/H, time = 50)
	if(H.stat) return
	spawn(0)
		var/mobloc = get_turf(H.loc)
		var/obj/dummy/spell_jaunt/holder = new /obj/dummy/spell_jaunt( mobloc )
		var/atom/movable/overlay/animation = new /atom/movable/overlay( mobloc )
		animation.name = "water"
		animation.density = 0
		animation.anchored = 1
		animation.icon = 'mob.dmi'
		animation.icon_state = "liquify"
		animation.layer = 5
		animation.master = holder
		flick("liquify",animation)
		H.loc = holder
		H.client.eye = holder
		var/datum/effects/system/steam_spread/steam = new /datum/effects/system/steam_spread()
		steam.set_up(10, 0, mobloc)
		steam.start()
		sleep(time)
		mobloc = get_turf(H.loc)
		animation.loc = mobloc
		steam.location = mobloc
		steam.start()
		H.canmove = 0
		sleep(20)
		flick("reappear",animation)
		sleep(5)
		H.loc = mobloc
		H.canmove = 1
		H.client.eye = H
		del(animation)
		del(holder)

/obj/dummy/spell_jaunt
	name = "water"
	icon = 'effects.dmi'
	icon_state = "nothing"
	var/canmove = 1
	density = 0
	anchored = 1

/obj/dummy/spell_jaunt/relaymove(var/mob/user, direction)
	if (!src.canmove) return
	switch(direction)
		if(NORTH)
			src.y++
		if(SOUTH)
			src.y--
		if(EAST)
			src.x++
		if(WEST)
			src.x--
		if(NORTHEAST)
			src.y++
			src.x++
		if(NORTHWEST)
			src.y++
			src.x--
		if(SOUTHEAST)
			src.y--
			src.x++
		if(SOUTHWEST)
			src.y--
			src.x--
	src.canmove = 0
	spawn(2) src.canmove = 1

/obj/dummy/spell_jaunt/ex_act(blah)
	return
/obj/dummy/spell_jaunt/bullet_act(blah,blah)
	return

//MUTATE

/client/proc/mutate()
	set category = "Spells"
	set name = "Mutate"
	if(!usr.casting()) return
	usr.verbs -= /client/proc/mutate
	spawn(400)
		usr.verbs += /client/proc/mutate

	usr.say("BIRUZ BENNAR")
	usr.spellvoice()

	usr << text("\blue You feel strong! Your mind expands!")
	if (!(usr.mutations & 8))
		usr.mutations |= 8
	if (!(usr.mutations & 1))
		usr.mutations |= 1
	spawn (300)
		if (usr.mutations & 1) usr.mutations &= ~1
		if (usr.mutations & 8) usr.mutations &= ~8
	return

//BODY SWAP

/mob/proc/swap(mob/M as mob in oview())
	set category = "Spells"
	set name = "Body Swap"

	if(M.client && M.mind)
		if(!M.mind.special_role && (istype(M, /mob/living/carbon/human)))
			var/mob/living/carbon/human/H = M
			var/mob/living/carbon/human/U = src

			U.whisper("GIN'YU CAPAN")
			U.verbs -= /mob/proc/swap
			if(U.mind.special_verbs.len)
				for(var/V in U.mind.special_verbs)
					U.verbs -= V

			var/mob/dead/observer/G = new /mob/dead/observer(H) //To properly transfer clients so no-one gets kicked off the game.

			H.client.mob = G
			G.mind = H.mind

			U.client.mob = H
			H.mind = U.mind
			if(H.mind.special_verbs.len)
				var/spell_loss = 1
				var/probability = 95
				for(var/V in H.mind.special_verbs)
					if(spell_loss == 0)
						H.verbs += V
					else
						if(prob(probability))
							H.verbs += V
							probability -= 7
						else
							spell_loss = 0
							H.mind.special_verbs -= V
							spawn(500)
								H << "The mind transfer has robbed you of a spell."


			G.client.mob = U
			U.mind = G.mind

			U.mind.current = U
			H.mind.current = H
			spawn(500)
				U << "Something about your body doesn't seem quite right..."

			U.paralysis += 20
			H.paralysis += 20

			spawn(600)
				H.verbs += /mob/proc/swap

			del(G)
		else
			src << "Their mind is resisting your spell."
			return

	else
		src << "Their mind is not compatible."
	return