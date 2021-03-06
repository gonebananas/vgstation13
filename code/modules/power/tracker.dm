//Solar tracker
//Machine that tracks the sun and reports it's direction to the solar controllers
//As long as this is working, solar panels on same powernet will track automatically

/obj/machinery/power/tracker
	name = "solar tracker"
	desc = "A solar directional tracker."
	icon = 'icons/obj/power.dmi'
	icon_state = "tracker"
	anchored = 1
	density = 1
	directwired = 1
	use_power = 0

	var/sun_angle = 0	//Sun angle as set by sun datum

/obj/machinery/power/tracker/New(var/turf/loc, var/obj/machinery/power/solar_assembly/S)
	..(loc)
	if(!S)
		S = new /obj/machinery/power/solar_assembly(src)
		S.glass_type = /obj/item/stack/sheet/rglass
		S.tracker = 1
		S.anchored = 1
	S.loc = src
	connect_to_network()

/obj/machinery/power/tracker/disconnect_from_network()
	..()
	solars_list.Remove(src)

/obj/machinery/power/tracker/connect_to_network()
	..()
	solars_list.Add(src)

//Called by datum/sun/calc_position() as sun's angle changes
/obj/machinery/power/tracker/proc/set_angle(var/angle)
	sun_angle = angle

	//Set icon dir to show sun illumination
	dir = turn(NORTH, -angle - 22.5)	//22.5 deg bias ensures, e.g. 67.5-112.5 is EAST

	//Check we can draw power
	if(stat & NOPOWER)
		return

	//Find all solar controls and update them
	//Currently, just update all controllers in world
	// ***TODO: better communication system using network
	if(powernet)
		for(var/obj/machinery/power/solar_control/C in get_solars_powernet())
			if(powernet.nodes.Find(C))
				if(get_dist(C, src) < SOLAR_MAX_DIST)
					C.tracker_update(angle)

/obj/machinery/power/tracker/attackby(var/obj/item/weapon/W, var/mob/user)
	if(iscrowbar(W))
		playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
		if(do_after(user, 50))
			var/obj/machinery/power/solar_assembly/S = locate() in src
			if(S)
				S.loc = src.loc
				S.give_glass()
			playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
			user.visible_message("<span class='notice'>[user] takes the glass off the tracker.</span>")
			del(src)
		return
	..()

//Timed process
//Make sure we can draw power from the powernet
/obj/machinery/power/tracker/process()

	var/avail = surplus()

	if(avail > 500)
		add_load(500)
		stat &= ~NOPOWER
	else
		stat |= NOPOWER

/obj/machinery/power/tracker/Destroy()
	solars_list -= src
	..()

//Tracker Electronic

/obj/item/weapon/tracker_electronics

	name = "tracker electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = 2.0