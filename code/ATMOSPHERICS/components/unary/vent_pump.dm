#define EXTERNAL_PRESSURE_BOUND ONE_ATMOSPHERE
#define INTERNAL_PRESSURE_BOUND 0
#define PRESSURE_CHECKS 1

#define PRESSURE_CHECK_EXTERNAL 1
#define PRESSURE_CHECK_INTERNAL 2

#undefine

/obj/machinery/atmospherics/unary/vent_pump
	icon = 'icons/atmos/vent_pump.dmi'
	icon_state = "map_vent"

	name = "Air Vent"
	desc = "Has a valve and pump attached to it"
	use_power = 1
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	active_power_usage = 7500	//This also doubles as a measure of how powerful the pump is, in Watts. 7500 W ~ 10 HP

	var/area/initial_loc
	level = 1
	var/area_uid
	var/id_tag = null

	var/on = 0
	var/pump_direction = 1 //0 = siphoning, 1 = releasing

	var/last_power_draw = 0
	var/last_flow_rate = 0

	var/external_pressure_bound = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound = INTERNAL_PRESSURE_BOUND

	var/pressure_checks = PRESSURE_CHECKS
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	// Used when handling incoming radio signals requesting default settings
	var/external_pressure_bound_default = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound_default = INTERNAL_PRESSURE_BOUND
	var/pressure_checks_default = PRESSURE_CHECKS

	var/welded = 0 // Added for aliens -- TLE

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/radio_filter_out
	var/radio_filter_in

/obj/machinery/atmospherics/unary/vent_pump/on
	on = 1
	icon_state = "map_vent_out"

/obj/machinery/atmospherics/unary/vent_pump/siphon
	pump_direction = 0

/obj/machinery/atmospherics/unary/vent_pump/siphon/on
	on = 1
	icon_state = "map_vent_in"

/obj/machinery/atmospherics/unary/vent_pump/New()
	icon = null
	initial_loc = get_area(loc)
	if (initial_loc.master)
		initial_loc = initial_loc.master
	area_uid = initial_loc.uid
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)
	if(ticker && ticker.current_state == 3)//if the game is running
		src.initialize()
		src.broadcast_status()
	..()

/obj/machinery/atmospherics/unary/vent_pump/high_volume
	name = "Large Air Vent"
	power_channel = EQUIP

/obj/machinery/atmospherics/unary/vent_pump/high_volume/New()
	..()
	air_contents.volume = 1000

/obj/machinery/atmospherics/unary/vent_pump/update_icon(var/safety = 0)
	if(!check_icon_cache())
		return

	overlays.Cut()
	
	var/vent_icon = "vent"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(T.intact && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
		vent_icon += "h"
		
	if(welded)
		vent_icon += "weld"
	else if(!powered())
		vent_icon += "off"
	else
		vent_icon += "[on ? "[pump_direction ? "out" : "in"]" : "off"]"

	overlays += icon_manager.get_atmos_icon("device", , , vent_icon)

/obj/machinery/atmospherics/unary/vent_pump/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		if(T.intact && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
			return
		else
			add_underlay(T, node, dir)

/obj/machinery/atmospherics/unary/vent_pump/hide()
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/unary/vent_pump/process()
	..()
	
	//reset these each iteration
	last_power_draw = 0
	last_flow_rate = 0
	
	if(stat & (NOPOWER|BROKEN))
		return
	if (!node)
		on = 0
	//broadcast_status() // from now air alarm/control computer should request update purposely --rastaf0
	if(!on)
		update_use_power(0)
		return 0

	if(welded)
		return 0

	if(pump_direction) //internal -> external
		pump_to_external()
	else //external -> internal
		pump_to_internal()

	return 1


/obj/machinery/atmospherics/unary/vent_pump/proc/pump_to_external()
	var/datum/gas_mixture/environment = loc.return_air()
	var/environment_pressure = environment.return_pressure()
	
	var/pressure_delta = 10000

	if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
		pressure_delta = min(pressure_delta, (external_pressure_bound - environment_pressure))
	if(pressure_checks & PRESSURE_CHECK_INTERNAL)
		pressure_delta = min(pressure_delta, (air_contents.return_pressure() - internal_pressure_bound))

	if(pressure_delta > 0.5 && (air_contents.temperature > 0 || environment.temperature > 0))
		//Figure out how much gas to transfer
		
		//unfortunately there's no good way to get the volume of the room, so assume 10 tiles
		//we might overshoot in small rooms when dealing with huge pressures but it won't be so bad
		var/output_volume = environment.volume * 10
		var/air_temperature = environment.temperature? environment.temperature : air_contents.temperature
		
		var/transfer_moles = pressure_delta*output_volume/(air_temperature * R_IDEAL_GAS_EQUATION)
		
		//Calculate the amount of energy required
		var/specific_entropy = environment.specific_entropy() - air_contents.specific_entropy()	//environment is gaining moles, air_contents is loosing
		var/specific_power = 0	// W/mol
		
		//If specific_entropy is < 0 then transfer_moles is limited by how powerful the pump is
		if (specific_entropy < 0)
			specific_power = -specific_entropy*air_temperature		//how much power we need per mole
			transfer_moles = min(transfer_moles, active_power_usage / specific_power)
		
		//Get the gas to be transferred
		var/input_pressure = air_contents.return_pressure()
		var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)
		
		if (isnull(removed)) //not sure why this would happen, but it does at the very beginning of the game
			update_use_power(0)
			return
		
		if (input_pressure > 0)
			last_flow_rate = removed.total_moles()*R_IDEAL_GAS_EQUATION*removed.temperature/input_pressure

		//If specific_entropy is < 0 then extra power needs to be supplied to move gas
		if (specific_entropy < 0)
			//pump draws power and heats gas according to 2nd law of thermodynamics
			var/power_draw = round(transfer_moles*specific_power)
			removed.add_thermal_energy(power_draw)
			handle_power_draw(power_draw)
		else
			handle_power_draw(idle_power_usage)
			
		loc.assume_air(removed)

		if(network)
			network.update = 1
	else
		update_use_power(0)

//This is largely identical to pump_to_external(), except since the source and sink are two different types we can't just reuse the same proc :(
/obj/machinery/atmospherics/unary/vent_pump/proc/pump_to_internal()
	var/datum/gas_mixture/environment = loc.return_air()
	var/environment_pressure = environment.return_pressure()
	
	var/pressure_delta = 10000
	
	if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
		pressure_delta = min(pressure_delta, (environment_pressure - external_pressure_bound))
	if(pressure_checks & PRESSURE_CHECK_INTERNAL)
		pressure_delta = min(pressure_delta, (internal_pressure_bound - air_contents.return_pressure()))

	if(pressure_delta > 0.5 && (air_contents.temperature > 0 || environment.temperature > 0))
		//Figure out how much gas to transfer
		var/output_volume = air_contents.volume
		if (network && network.air_transient)
			output_volume = network.air_transient.volume	//use the network volume if we can get it
		
		var/air_temperature = air_contents.temperature? air_contents.temperature : environment.temperature
		
		var/transfer_moles = pressure_delta*output_volume/(air_temperature * R_IDEAL_GAS_EQUATION)
		
		//Calculate the amount of energy required
		var/specific_entropy = air_contents.specific_entropy() - environment.specific_entropy()	//air_contents is gaining moles, environment is loosing
		var/specific_power = 0	// W/mol
		
		//If specific_entropy is < 0 then transfer_moles is limited by how powerful the pump is
		if (specific_entropy < 0)
			specific_power = -specific_entropy*air_temperature		//how much power we need per mole
			transfer_moles = min(transfer_moles, active_power_usage / specific_power)
		
		//Get the gas to be transferred
		var/input_pressure = environment.return_pressure()
		var/datum/gas_mixture/removed = loc.remove_air(transfer_moles)
		
		if (isnull(removed)) //in space
			update_use_power(0)
			return
		
		if (input_pressure > 0)
			last_flow_rate = removed.total_moles()*R_IDEAL_GAS_EQUATION*removed.temperature/input_pressure

		//If specific_entropy is < 0 then extra power needs to be supplied to move gas
		if (specific_entropy < 0)
			//pump draws power and heats gas according to 2nd law of thermodynamics
			var/power_draw = round(transfer_moles*specific_power)
			removed.add_thermal_energy(power_draw)
			handle_power_draw(power_draw)
		else
			handle_power_draw(idle_power_usage)
			
		air_contents.merge(removed)

		if(network)
			network.update = 1
	else
		update_use_power(0)

//This proc handles power usages so that we only have to call use_power() when the pump is loaded but not at full load. 
/obj/machinery/atmospherics/unary/vent_pump/proc/handle_power_draw(var/usage_amount)
	if (usage_amount > active_power_usage - 5)
		update_use_power(2)
	else
		update_use_power(1)
		
		if (usage_amount > idle_power_usage)
			use_power(round(usage_amount))
	
	last_power_draw = usage_amount

//Radio remote control

/obj/machinery/atmospherics/unary/vent_pump/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency,radio_filter_in)

/obj/machinery/atmospherics/unary/vent_pump/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = list(
		"area" = src.area_uid,
		"tag" = src.id_tag,
		"device" = "AVP",
		"power" = on,
		"direction" = pump_direction?("release"):("siphon"),
		"checks" = pressure_checks,
		"internal" = internal_pressure_bound,
		"external" = external_pressure_bound,
		"timestamp" = world.time,
		"sigtype" = "status",
		"power_draw" = last_power_draw,
		"flow_rate" = last_flow_rate,
	)

	if(!initial_loc.air_vent_names[id_tag])
		var/new_name = "[initial_loc.name] Vent Pump #[initial_loc.air_vent_names.len+1]"
		initial_loc.air_vent_names[id_tag] = new_name
		src.name = new_name
	initial_loc.air_vent_info[id_tag] = signal.data

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1


/obj/machinery/atmospherics/unary/vent_pump/initialize()
	..()

	//some vents work his own spesial way
	radio_filter_in = frequency==1439?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==1439?(RADIO_TO_AIRALARM):null
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/unary/vent_pump/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return
	//log_admin("DEBUG \[[world.timeofday]\]: /obj/machinery/atmospherics/unary/vent_pump/receive_signal([signal.debug_print()])")
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["purge"] != null)
		pressure_checks &= ~1
		pump_direction = 0

	if(signal.data["stabalize"] != null)
		pressure_checks |= 1
		pump_direction = 1

	if(signal.data["power"] != null)
		on = text2num(signal.data["power"])

	if(signal.data["power_toggle"] != null)
		on = !on

	if(signal.data["checks"] != null)
		if (signal.data["checks"] == "default")
			pressure_checks = pressure_checks_default
		else
			pressure_checks = text2num(signal.data["checks"])

	if(signal.data["checks_toggle"] != null)
		pressure_checks = (pressure_checks?0:3)

	if(signal.data["direction"] != null)
		pump_direction = text2num(signal.data["direction"])

	if(signal.data["set_internal_pressure"] != null)
		if (signal.data["set_internal_pressure"] == "default")
			internal_pressure_bound = internal_pressure_bound_default
		else
			internal_pressure_bound = between(
				0,
				text2num(signal.data["set_internal_pressure"]),
				ONE_ATMOSPHERE*50
			)

	if(signal.data["set_external_pressure"] != null)
		if (signal.data["set_external_pressure"] == "default")
			external_pressure_bound = external_pressure_bound_default
		else
			external_pressure_bound = between(
				0,
				text2num(signal.data["set_external_pressure"]),
				ONE_ATMOSPHERE*50
			)

	if(signal.data["adjust_internal_pressure"] != null)
		internal_pressure_bound = between(
			0,
			internal_pressure_bound + text2num(signal.data["adjust_internal_pressure"]),
			ONE_ATMOSPHERE*50
		)

	if(signal.data["adjust_external_pressure"] != null)


		external_pressure_bound = between(
			0,
			external_pressure_bound + text2num(signal.data["adjust_external_pressure"]),
			ONE_ATMOSPHERE*50
		)

	if(signal.data["init"] != null)
		name = signal.data["init"]
		return

	if(signal.data["status"] != null)
		spawn(2)
			broadcast_status()
		return //do not update_icon

		//log_admin("DEBUG \[[world.timeofday]\]: vent_pump/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/unary/vent_pump/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if (WT.remove_fuel(0,user))
			user << "\blue Now welding the vent."
			if(do_after(user, 20))
				if(!src || !WT.isOn()) return
				playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)
				if(!welded)
					user.visible_message("[user] welds the vent shut.", "You weld the vent shut.", "You hear welding.")
					welded = 1
					update_icon()
				else
					user.visible_message("[user] unwelds the vent.", "You unweld the vent.", "You hear welding.")
					welded = 0
					update_icon()
			else
				user << "\blue The welding tool needs to be on to start this task."
		else
			user << "\blue You need more welding fuel to complete this task."
			return 1
	else
		..()

/obj/machinery/atmospherics/unary/vent_pump/examine()
	set src in oview(1)
	..()
	if(welded)
		usr << "It seems welded shut."

/obj/machinery/atmospherics/unary/vent_pump/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/unary/vent_pump/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if (!istype(W, /obj/item/weapon/wrench))
		return ..()
	if (!(stat & NOPOWER) && on)
		user << "\red You cannot unwrench this [src], turn it off first."
		return 1
	var/turf/T = src.loc
	if (node && node.level==1 && isturf(T) && T.intact)
		user << "\red You must remove the plating first."
		return 1
	var/datum/gas_mixture/int_air = return_air()
	var/datum/gas_mixture/env_air = loc.return_air()
	if ((int_air.return_pressure()-env_air.return_pressure()) > 2*ONE_ATMOSPHERE)
		user << "\red You cannot unwrench this [src], it too exerted due to internal pressure."
		add_fingerprint(user)
		return 1
	playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
	user << "\blue You begin to unfasten \the [src]..."
	if (do_after(user, 40))
		user.visible_message( \
			"[user] unfastens \the [src].", \
			"\blue You have unfastened \the [src].", \
			"You hear ratchet.")
		new /obj/item/pipe(loc, make_from=src)
		del(src)

/obj/machinery/atmospherics/unary/vent_pump/Del()
	if(initial_loc)
		initial_loc.air_vent_info -= id_tag
		initial_loc.air_vent_names -= id_tag
	..()
	return

/*
	Alt-click to ventcrawl - Monkeys, aliens, slimes and mice.
	This is a little buggy but somehow that just seems to plague ventcrawl.
	I am sorry, I don't know why.
*/
/obj/machinery/atmospherics/unary/vent_pump/AltClick(var/mob/living/ML)
	if(istype(ML))
		var/list/ventcrawl_verbs = list(/mob/living/carbon/monkey/verb/ventcrawl, /mob/living/carbon/alien/verb/ventcrawl, /mob/living/carbon/slime/verb/ventcrawl,/mob/living/simple_animal/mouse/verb/ventcrawl)
		if(length(ML.verbs & ventcrawl_verbs)) // alien queens have this removed, an istype would be complicated
			ML.handle_ventcrawl(src)
			return
	..()
