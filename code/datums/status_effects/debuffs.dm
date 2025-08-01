#define TRAIT_STATUS_EFFECT(effect_id) "[effect_id]-trait"

//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	tick_interval = 0
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()
	if(. && (needs_update_stat || issilicon(owner)))
		owner.update_stat()


/datum/status_effect/incapacitating/on_remove()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()


//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"

/datum/status_effect/incapacitating/stun/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stun/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	return ..()


//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"

/datum/status_effect/incapacitating/knockdown/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/knockdown/on_remove()
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	return ..()


//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/immobilized/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/immobilized/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	return ..()


//PARALYZED
/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"

/datum/status_effect/incapacitating/paralyzed/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/paralyzed/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	return ..()


//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/unconscious/on_remove()
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.getStaminaLoss())
		owner.adjustStaminaLoss(-0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds


//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /atom/movable/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	tick_interval = 2 SECONDS
	var/mob/living/carbon/carbon_owner
	var/mob/living/carbon/human/human_owner
	/// Whether we listen to apply damage signal or not
	var/remove_on_damage = FALSE

/datum/status_effect/incapacitating/sleeping/on_creation(mob/living/new_owner)
	. = ..()
	if(.)
		if(iscarbon(owner)) //to avoid repeated istypes
			carbon_owner = owner
		if(ishuman(owner))
			human_owner = owner

/datum/status_effect/incapacitating/sleeping/Destroy()
	carbon_owner = null
	human_owner = null
	return ..()

/datum/status_effect/incapacitating/sleeping/on_apply()
	. = ..()
	if(!.)
		return
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = -1
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_insomniac))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_sleepy))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_owner_damage))

/datum/status_effect/incapacitating/sleeping/on_remove()
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), COMSIG_MOB_APPLY_DAMGE))
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = initial(tick_interval)
	return ..()

///If the mob is sleeping and gain the TRAIT_SLEEPIMMUNE we remove the TRAIT_KNOCKEDOUT and stop the tick() from happening
/datum/status_effect/incapacitating/sleeping/proc/on_owner_insomniac(mob/living/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = -1

///If the mob has the TRAIT_SLEEPIMMUNE but somehow looses it we make him sleep and restart the tick()
/datum/status_effect/incapacitating/sleeping/proc/on_owner_sleepy(mob/living/source)
	SIGNAL_HANDLER
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = initial(tick_interval)

/datum/status_effect/incapacitating/sleeping/proc/on_owner_damage(datum/source, damage, damagetype, def_zone)
	if(!remove_on_damage)
		return
	if(damage < 5)
		return
	QDEL_NULL(src)

/datum/status_effect/incapacitating/sleeping/tick()
	if(owner.maxHealth)
		var/health_ratio = owner.health / owner.maxHealth
		var/healing = -0.2
		if((locate(/obj/structure/bed) in owner.loc))
			healing -= 0.3
		else if((locate(/obj/structure/table) in owner.loc))
			healing -= 0.1
		for(var/obj/item/bedsheet/bedsheet in range(owner.loc,0))
			if(bedsheet.loc != owner.loc) //bedsheets in your backpack/neck don't give you comfort
				continue
			healing -= 0.1
			break //Only count the first bedsheet
		if(health_ratio > 0.8)
			owner.adjustBruteLoss(healing)
			owner.adjustFireLoss(healing)
			owner.adjustToxLoss(healing * 0.5, TRUE, TRUE)
		owner.adjustStaminaLoss(healing)
	if(human_owner?.drunkenness)
		human_owner.drunkenness *= 0.997 //reduce drunkenness by 0.3% per tick, 6% per 2 seconds
	if(prob(20))
		if(carbon_owner)
			carbon_owner.handle_dreams()
		if(prob(10) && owner.health > owner.crit_threshold)
			owner.emote("snore")

/atom/movable/screen/alert/status_effect/asleep
	name = "Asleep"
	desc = "You've fallen asleep. Wait a bit and you should wake up. Unless you don't, considering how helpless you are."
	icon_state = "asleep"

//STASIS
/datum/status_effect/grouped/stasis
	id = "stasis"
	duration = -1
	tick_interval = 10
	alert_type = /atom/movable/screen/alert/status_effect/stasis
	var/last_dead_time

/datum/status_effect/grouped/stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = station_time_timestamp(wtime=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/grouped/stasis/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	if(.)
		update_time_of_death()
		owner.reagents?.end_metabolization(owner, FALSE)

/datum/status_effect/grouped/stasis/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	owner.add_filter("stasis_status_ripple", 2, list("type" = "ripple", "flags" = WAVE_BOUNDED, "radius" = 0, "size" = 2))
	var/filter = owner.get_filter("stasis_status_ripple")
	animate(filter, radius = 32, time = 15, size = 0, loop = -1)


/datum/status_effect/grouped/stasis/tick()
	update_time_of_death()

/datum/status_effect/grouped/stasis/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("stasis_status_ripple")
	update_time_of_death()
	return ..()

/atom/movable/screen/alert/status_effect/stasis
	name = "Stasis"
	desc = "Your biological functions have halted. You could live forever this way, but it's pretty boring."
	icon_state = "stasis"

//GOLEM GANG

//OTHER DEBUFFS
/datum/status_effect/strandling //get it, strand as in durathread strand + strangling = strandling hahahahahahahahahahhahahaha i want to die
	id = "strandling"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/strandling

/datum/status_effect/strandling/on_apply()
	ADD_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/datum/status_effect/strandling/on_remove()
	REMOVE_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/atom/movable/screen/alert/status_effect/strandling
	name = "Choking strand"
	desc = "A magical strand of Durathread is wrapped around your neck, preventing you from breathing! Click this icon to remove the strand."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/status_effect/strandling/Click(location, control, params)
	. = ..()
	if(usr != owner)
		return
	to_chat(owner, "<span class='notice'>You attempt to remove the durathread strand from around your neck.</span>")
	if(do_after(owner, 3.5 SECONDS, owner))
		if(isliving(owner))
			var/mob/living/L = owner
			to_chat(owner, "<span class='notice'>You succesfuly remove the durathread strand.</span>")
			L.remove_status_effect(STATUS_EFFECT_CHOKINGSTRAND)

//OTHER DEBUFFS
/datum/status_effect/pacify
	id = "pacify"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	duration = 100
	alert_type = null

/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_wrath

/atom/movable/screen/alert/status_effect/his_wrath
	name = "His Wrath"
	desc = "You fled from His Grace instead of feeding Him, and now you suffer."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE)

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = -1
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.see_invisible = SEE_INVISIBLE_OBSERVER
	owner.see_in_dark = 2

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/crusher_mark
	id = "crusher_mark"
	duration = 300 //if you leave for 30 seconds you lose the mark, deal with it
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/mutable_appearance/marked_underlay
	var/obj/item/kinetic_crusher/hammer_synced


/datum/status_effect/crusher_mark/on_creation(mob/living/new_owner, obj/item/kinetic_crusher/new_hammer_synced)
	. = ..()
	if(.)
		hammer_synced = new_hammer_synced

/datum/status_effect/crusher_mark/on_apply()
	if(owner.mob_size >= MOB_SIZE_LARGE)
		marked_underlay = mutable_appearance('icons/effects/effects.dmi', "shield2")
		marked_underlay.pixel_x = -owner.pixel_x
		marked_underlay.pixel_y = -owner.pixel_y
		owner.underlays += marked_underlay
		return TRUE
	return FALSE

/datum/status_effect/crusher_mark/Destroy()
	hammer_synced = null
	if(owner)
		owner.underlays -= marked_underlay
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/crusher_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/datum/status_effect/eldritch
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	///underlay used to indicate that someone is marked
	var/mutable_appearance/marked_underlay
	///path for the underlay
	var/effect_sprite = ""

/datum/status_effect/eldritch/on_creation(mob/living/new_owner, ...)
	marked_underlay = mutable_appearance('icons/effects/effects.dmi', effect_sprite,BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/eldritch/on_apply()
	if(owner.mob_size >= MOB_SIZE_HUMAN)
		RegisterSignal(owner,COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_owner_underlay))
		owner.update_icon()
		return TRUE
	return FALSE

/datum/status_effect/eldritch/on_remove()
	UnregisterSignal(owner,COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	return ..()

/datum/status_effect/eldritch/proc/update_owner_underlay(atom/source, list/overlays)
	SIGNAL_HANDLER

	overlays += marked_underlay

/datum/status_effect/eldritch/Destroy()
	QDEL_NULL(marked_underlay)
	return ..()

/**
 * What happens when this mark gets poppedd
 *
 * Adds actual functionality to each mark
 */
/datum/status_effect/eldritch/proc/on_effect()
	playsound(owner, 'sound/magic/repulse.ogg', 75, TRUE)
	qdel(src) //what happens when this is procced.

//Each mark has diffrent effects when it is destroyed that combine with the mansus grasp effect.
/datum/status_effect/eldritch/flesh
	id = "flesh_mark"
	effect_sprite = "emark1"

/datum/status_effect/eldritch/flesh/on_effect()

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/obj/item/bodypart/bodypart = pick(H.bodyparts)
		var/datum/wound/slash/severe/crit_wound = new
		crit_wound.apply_wound(bodypart)
	return ..()

/datum/status_effect/eldritch/ash
	id = "ash_mark"
	effect_sprite = "emark2"
	///Dictates how much damage and stamina loss this mark will cause.
	var/repetitions = 1

/datum/status_effect/eldritch/ash/on_creation(mob/living/new_owner, _repetition = 5)
	. = ..()
	repetitions = min(1,_repetition)

/datum/status_effect/eldritch/ash/on_effect()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustStaminaLoss(10 * repetitions)
		carbon_owner.adjustFireLoss(5 * repetitions)
		for(var/mob/living/carbon/victim in range(1,carbon_owner))
			if(IS_HERETIC(victim) || victim == carbon_owner)
				continue
			victim.apply_status_effect(type,repetitions-1)
			break
	return ..()

/datum/status_effect/eldritch/rust
	id = "rust_mark"
	effect_sprite = "emark3"

/datum/status_effect/eldritch/rust/on_effect()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbon_owner = owner
	for(var/obj/item/I in carbon_owner.get_all_gear())
		//Affects roughly 75% of items
		if(!QDELETED(I) && prob(75)) //Just in case
			I.take_damage(100)
	return ..()

/datum/status_effect/eldritch/void
	id = "void_mark"
	effect_sprite = "emark4"

/datum/status_effect/eldritch/void/on_effect()
	var/turf/open/turfie = get_turf(owner)
	turfie.TakeTemperature(-40)
	owner.adjust_bodytemperature(-20)
	return ..()

/// A status effect used for specifying confusion on a living mob.
/// Created automatically with /mob/living/set_confusion.
/datum/status_effect/confusion
	id = "confusion"
	alert_type = null
	var/strength

/datum/status_effect/confusion/tick()
	strength -= 1
	if (strength <= 0)
		owner.remove_status_effect(STATUS_EFFECT_CONFUSION)
		return

/datum/status_effect/confusion/proc/set_strength(new_strength)
	strength = new_strength

/datum/status_effect/stacking/saw_bleed
	id = "saw_bleed"
	tick_interval = 6
	delay_before_decay = 5
	stack_threshold = 10
	max_stacks = 10
	overlay_file = 'icons/effects/bleed.dmi'
	underlay_file = 'icons/effects/bleed.dmi'
	overlay_state = "bleed"
	underlay_state = "bleed"
	var/bleed_damage = 200

/datum/status_effect/stacking/saw_bleed/fadeout_effect()
	new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/stacking/saw_bleed/threshold_cross_effect()
	owner.adjustBruteLoss(bleed_damage)
	var/turf/T = get_turf(owner)
	new /obj/effect/temp_visual/bleed/explode(T)
	for(var/d in GLOB.alldirs)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, d)
	playsound(T, "desecration", 100, TRUE, -1)

/datum/status_effect/stacking/saw_bleed/bloodletting
	id = "bloodletting"
	stack_threshold = 7
	max_stacks = 7
	bleed_damage = 20

/datum/status_effect/neck_slice
	id = "neck_slice"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = -1

/datum/status_effect/neck_slice/tick()
	var/mob/living/carbon/human/H = owner
	var/obj/item/bodypart/throat = H.get_bodypart(BODY_ZONE_HEAD)
	if(H.stat == DEAD || !throat)
		H.remove_status_effect(/datum/status_effect/neck_slice)

	var/still_bleeding = FALSE
	for(var/thing in throat.wounds)
		var/datum/wound/W = thing
		if(W.wound_type == WOUND_SLASH && W.severity > WOUND_SEVERITY_MODERATE)
			still_bleeding = TRUE
			break
	if(!still_bleeding)
		H.remove_status_effect(/datum/status_effect/neck_slice)

	if(prob(10))
		H.emote(pick("gasp", "gag", "choke"))

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //time added by additional curses
	return C

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /atom/movable/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 32)
		playsound(owner, 'sound/effects/curse5.ogg', 20, TRUE, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, TRUE, -1)
	var/turf/ownerloc = get_turf(owner)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(ownerloc, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize()
	. = ..()
	deltimer(timerid)


/datum/status_effect/gonbola_pacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null

/datum/status_effect/gonbola_pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	ADD_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	ADD_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")
	to_chat(owner, "<span class='notice'>You suddenly feel at peace and feel no need to make any sudden or rash actions...</span>")
	return ..()

/datum/status_effect/gonbola_pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	REMOVE_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	REMOVE_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	examine_text = "<span class='warning'>SUBJECTPRONOUN seems slow and unfocused.</span>"
	var/stun = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/trance

/atom/movable/screen/alert/status_effect/trance
	name = "Trance"
	desc = "Everything feels so distant, and you can feel your thoughts forming loops inside your head..."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(60, TRUE)
	owner.dizziness = 20

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(hypnotize))
	ADD_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.add_client_colour(/datum/client_colour/monochrome/trance)
	owner.visible_message("[stun ? "<span class='warning'>[owner] stands still as [owner.p_their()] eyes seem to focus on a distant point.</span>" : ""]", \
	"<span class='warning'>[pick("You feel your thoughts slow down...", "You suddenly feel extremely dizzy...", "You feel like you're in the middle of a dream...","You feel incredibly relaxed...")]</span>")
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.dizziness = 0
	owner.remove_client_colour(/datum/client_colour/monochrome/trance)
	to_chat(owner, "<span class='warning'>You snap out of your trance!</span>")

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args)
	SIGNAL_HANDLER

	if(!owner.can_hear())
		return
	var/mob/hearing_speaker = hearing_args[HEARING_SPEAKER]
	if(hearing_speaker == owner)
		return
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	// The brain trauma itself does its own set of logging, but this is the only place the source of the hypnosis phrase can be found.
	C.log_message("has been hypnotised by the phrase '[hearing_args[HEARING_RAW_MESSAGE]]' spoken by [key_name(hearing_speaker)]", LOG_ATTACK)
	hearing_speaker.log_message("has hypnotised [key_name(C)] with the phrase '[hearing_args[HEARING_RAW_MESSAGE]]'", LOG_ATTACK, log_globally = FALSE)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, gain_trauma), /datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, Stun), 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null

/datum/status_effect/spasms/tick()
	if(prob(15))
		switch(rand(1,5))
			if(1)
				if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
					to_chat(owner, "<span class='warning'>Your leg spasms!</span>")
					step(owner, pick(GLOB.cardinals))
			if(2)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				if(I)
					to_chat(owner, "<span class='warning'>Your fingers spasm!</span>")
					owner.log_message("used [I] due to a Muscle Spasm", LOG_ATTACK)
					I.attack_self(owner)
			if(3)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM

				var/range = 1
				if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
					range = 7

				var/list/mob/living/targets = list()
				for(var/mob/M in oview(owner, range))
					if(isliving(M))
						targets += M
				if(LAZYLEN(targets))
					to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
					owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
					owner.ClickOn(pick(targets))
				owner.a_intent = prev_intent
			if(4)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM
				to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
				owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
				owner.ClickOn(owner)
				owner.a_intent = prev_intent
			if(5)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				var/list/turf/targets = list()
				for(var/turf/T in oview(owner, 3))
					targets += T
				if(LAZYLEN(targets) && I)
					to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
					owner.log_message("threw [I] due to a Muscle Spasm", LOG_ATTACK)
					owner.throw_item(pick(targets))

/datum/status_effect/convulsing
	id = "convulsing"
	duration = 	150
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/convulsing

/datum/status_effect/convulsing/on_creation(mob/living/zappy_boy)
	. = ..()
	to_chat(zappy_boy, "<span class='boldwarning'>You feel a shock moving through your body! Your hands start shaking!</span>")

/datum/status_effect/convulsing/tick()
	var/mob/living/carbon/H = owner
	if(prob(40))
		var/obj/item/I = H.get_active_held_item()
		if(I && H.dropItemToGround(I))
			H.visible_message("<span class='notice'>[H]'s hand convulses, and they drop their [I.name]!</span>","<span class='userdanger'>Your hand convulses violently, and you drop what you were holding!</span>")
			H.jitteriness += 5

/atom/movable/screen/alert/status_effect/convulsing
	name = "Shaky Hands"
	desc = "You've been zapped with something and your hands can't stop shaking! You can't seem to hold on to anything."
	icon_state = "convulsing"

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	to_chat(new_owner, "<span class='boldwarning'>My body can't handle the mutations! I need to get my mutations removed fast!</span>")

/datum/status_effect/dna_melt/on_remove()
	if(!ishuman(owner))
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/human/H = owner
	H.something_horrible(kill_either_way)

/atom/movable/screen/alert/status_effect/dna_melt
	name = "Genetic Breakdown"
	desc = "I don't feel so good. Your body can't handle the mutations! You have one minute to remove your mutations, or you will be met with a horrible fate."
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 100
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/atom/movable/screen/alert/status_effect/go_away
	name = "TO THE STARS AND BEYOND!"
	desc = "I must go, my people need me!"
	icon_state = "high"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 1800//3 minutes
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = null
	var/msg_stage = 0//so you dont get the most intense messages immediately

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick("<span class='warning'>[pick("Your head hurts.", "Your head pounds.")]</span>",
				"<span class='warning'>[pick("You're having difficulty breathing.", "Your breathing becomes heavy.")]</span>",
				"<span class='warning'>[pick("You feel dizzy.", "Your head spins.")]</span>",
				"<span notice='warning'>[pick("You swallow excess mucus.", "You lightly cough.")]</span>",
				"<span class='warning'>[pick("Your head hurts.", "Your mind blanks for a moment.")]</span>",
				"<span class='warning'>[pick("Your throat hurts.", "You clear your throat.")]</span>")
		if(301 to 600)
			if(prob(2))
				fake_msg = pick("<span class='warning'>[pick("Your head hurts a lot.", "Your head pounds incessantly.")]</span>",
				"<span class='warning'>[pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")]</span>",
				"<span class='warning'>You feel very [pick("dizzy","woozy","faint")].</span>",
				"<span class='warning'>[pick("You hear a ringing in your ear.", "Your ears pop.")]</span>",
				"<span class='warning'>You nod off for a moment.</span>")
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick("<span class='userdanger'>[pick("Your head hurts!", "You feel a burning knife inside your brain!", "A wave of pain fills your head!")]</span>",
					"<span class='userdanger'>[pick("Your lungs hurt!", "It hurts to breathe!")]</span>",
					"<span class='warning'>[pick("You feel nauseated.", "You feel like you're going to throw up!")]</span>")
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++

/datum/status_effect/corrosion_curse
	id = "corrosion_curse"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = 1 SECONDS

/datum/status_effect/corrosion_curse/on_creation(mob/living/new_owner, ...)
	. = ..()
	to_chat(owner, "<span class='danger'>Your feel your body starting to break apart...</span>")

/datum/status_effect/corrosion_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	var/chance = rand(0,100)
	switch(chance)
		if(0 to 19)
			H.vomit()
		if(20 to 29)
			H.Dizzy(10)
		if(30 to 39)
			H.adjustOrganLoss(ORGAN_SLOT_LIVER,5)
		if(40 to 49)
			H.adjustOrganLoss(ORGAN_SLOT_HEART,5)
		if(50 to 59)
			H.adjustOrganLoss(ORGAN_SLOT_STOMACH,5)
		if(60 to 69)
			H.adjustOrganLoss(ORGAN_SLOT_EYES,10)
		if(70 to 79)
			H.adjustOrganLoss(ORGAN_SLOT_EARS,10)
		if(80 to 89)
			H.adjustOrganLoss(ORGAN_SLOT_LUNGS,10)
		if(90 to 99)
			H.adjustOrganLoss(ORGAN_SLOT_TONGUE,10)
		if(100)
			H.adjustOrganLoss(ORGAN_SLOT_BRAIN,20)

/datum/status_effect/amok
	id = "amok"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/amok/on_apply(mob/living/afflicted)
	. = ..()
	to_chat(owner, "<span class='boldwarning'>You feel filled with a rage that is not your own!</span>")

/datum/status_effect/amok/tick()
	. = ..()
	var/prev_intent = owner.a_intent
	owner.a_intent = INTENT_HARM

	var/list/mob/living/targets = list()
	for(var/mob/living/potential_target in oview(owner, 1))
		if(IS_HERETIC(potential_target) || IS_HERETIC_MONSTER(potential_target))
			continue
		targets += potential_target
	if(LAZYLEN(targets))
		owner.log_message(" attacked someone due to the amok debuff.", LOG_ATTACK) //the following attack will log itself
		owner.ClickOn(pick(targets))
	owner.a_intent = prev_intent

/datum/status_effect/cloudstruck
	id = "cloudstruck"
	status_type = STATUS_EFFECT_REPLACE
	duration = 3 SECONDS
	on_remove_on_mob_delete = TRUE
	///This overlay is applied to the owner for the duration of the effect.
	var/mutable_appearance/mob_overlay

/datum/status_effect/cloudstruck/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/cloudstruck/on_apply()
	mob_overlay = mutable_appearance('icons/effects/eldritch.dmi', "cloud_swirl", ABOVE_MOB_LAYER)
	owner.overlays += mob_overlay
	owner.update_icon()
	ADD_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	return TRUE

/datum/status_effect/cloudstruck/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	if(owner)
		owner.overlays -= mob_overlay
		owner.update_icon()

/datum/status_effect/cloudstruck/Destroy()
	. = ..()
	QDEL_NULL(mob_overlay)


//~~~LC13 General Debuffs~~~
#define MOB_HALFSPEED /datum/movespeed_modifier/qliphothoverload
/datum/status_effect/qliphothoverload
	id = "qliphoth intervention field"
	duration = 15 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH
	var/statuseffectvisual

/datum/status_effect/qliphothoverload/on_apply()
	. = ..()
	owner.add_movespeed_modifier(MOB_HALFSPEED)

	var/mutable_appearance/effectvisual = mutable_appearance('icons/obj/clockwork_objects.dmi', "vanguard")
	effectvisual.pixel_x = -owner.pixel_x
	effectvisual.pixel_y = -owner.pixel_y
	statuseffectvisual = effectvisual
	owner.add_overlay(statuseffectvisual)

/datum/status_effect/qliphothoverload/on_remove()
	owner.remove_movespeed_modifier(MOB_HALFSPEED)

	owner.cut_overlay(statuseffectvisual)
	return ..()


#define MOB_HALFSPEEDDEFENSE /datum/movespeed_modifier/qliphothshred
/datum/status_effect/qliphothshred
	id = "qliphoth intervention field +"
	duration = 15 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH
	var/statuseffectvisual

/datum/status_effect/qliphothshred/on_apply()
	. = ..()
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/qliphothshred)

/datum/status_effect/qliphothshred/on_remove()
	if(isanimal(owner))
		var/mob/living/simple_animal/M = owner
		M.RemoveModifier(/datum/dc_change/qliphothshred)
	return ..()

#define MOB_QUARTERSPEED /datum/movespeed_modifier/bloodhold
/datum/status_effect/bloodhold
	id = "bloodhold"
	duration = 8 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH
	var/statuseffectvisual

/datum/status_effect/bloodhold/on_apply()
	. = ..()
	owner.add_movespeed_modifier(MOB_QUARTERSPEED)
	to_chat(owner, "<span class='warning'>You are slowed down as your own blood resists your movement!</span>")
	var/mutable_appearance/effectvisual = mutable_appearance('icons/obj/clockwork_objects.dmi', "hateful_manacles")
	effectvisual.pixel_x = -owner.pixel_x
	effectvisual.pixel_y = -owner.pixel_y
	statuseffectvisual = effectvisual
	owner.add_overlay(statuseffectvisual)

/datum/status_effect/bloodhold/on_remove()
	owner.remove_movespeed_modifier(MOB_QUARTERSPEED)

	owner.cut_overlay(statuseffectvisual)
	return ..()

//update_stamina() is move_to_delay = (initial(move_to_delay) + (staminaloss * 0.06))
// 100 stamina damage equals 6 additional move_to_delay. So 167*0.06 = 10.02

/datum/status_effect/rend_red
	id = "rend red armor"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 60 //6 seconds
	alert_type = null

/datum/status_effect/rend_red/on_apply()
	. = ..()
	if(!isanimal(owner))
		qdel(src)
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/rend/red)
//20% damage increase. Hitting any abnormality that has a negative value will cause this
//to be a buff to their healing.

/datum/status_effect/rend_red/on_remove()
	. = ..()
	if(isanimal(owner))
		var/mob/living/simple_animal/M = owner
		M.RemoveModifier(/datum/dc_change/rend/red)


//White Damage Debuff
/datum/status_effect/rend_white
	id = "rend white armor"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 50 //5 seconds since it's melee-ish
	alert_type = null

/datum/status_effect/rend_white/on_apply()
	. = ..()
	if(!isanimal(owner))
		qdel(src)
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/rend/white)

/datum/status_effect/rend_white/on_remove()
	. = ..()
	if(isanimal(owner))
		var/mob/living/simple_animal/M = owner
		M.RemoveModifier(/datum/dc_change/rend/white)

//Black Damage Debuff

/datum/status_effect/rend_black
	id = "rend black armor"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 50 //5 seconds since it's melee-ish
	alert_type = null

/datum/status_effect/rend_black/on_apply()
	. = ..()
	if(!isanimal(owner))
		qdel(src)
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/rend/black)

/datum/status_effect/rend_black/on_remove()
	. = ..()
	if(isanimal(owner))
		var/mob/living/simple_animal/M = owner
		M.RemoveModifier(/datum/dc_change/rend/black)

#undef MOB_HALFSPEED

#define STATUS_EFFECT_LCBURN /datum/status_effect/stacking/lc_burn // Deals true damage every 5 sec, can't be applied to godmode (contained abos)
/datum/status_effect/stacking/lc_burn
	id = "lc_burn"
	alert_type = /atom/movable/screen/alert/status_effect/lc_burn
	max_stacks = 50
	tick_interval = 5 SECONDS
	consumed_on_threshold = FALSE
	var/new_stack = FALSE
	var/safety = TRUE

/atom/movable/screen/alert/status_effect/lc_burn
	name = "Burning"
	desc = "You're on fire!!"
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "lc_burn"

/datum/status_effect/stacking/lc_burn/can_have_status()
	return (owner.stat != DEAD || !(owner.status_flags & GODMODE))

/datum/status_effect/stacking/lc_burn/add_stacks(stacks_added)
	..()
	Update_Burn_Overlay(owner)
	new_stack = TRUE

//Deals true damage
/datum/status_effect/stacking/lc_burn/tick()
	if(!can_have_status())
		qdel(src)
	to_chat(owner, "<span class='warning'>The flame consumes you!!</span>")
	owner.playsound_local(owner, 'sound/effects/burn.ogg', 50, TRUE)
	if(ishuman(owner))
		owner.apply_damage(stacks, BURN, null, owner.run_armor_check(null, BURN))
	else
		owner.apply_damage(stacks*4, BURN, null, owner.run_armor_check(null, BURN)) // x4 on non humans (Average burn stack is 20. 80/5 sec, extra 16 pure dps)

	//Deletes itself after 2 tick if no new burn stack was given
	if(safety)
		if(new_stack)
			stacks = round(stacks/2)
			new_stack = FALSE
			Update_Burn_Overlay(owner)
		else
			qdel(src)

//Update burn appearance
/datum/status_effect/stacking/lc_burn/proc/Update_Burn_Overlay(mob/living/owner)
	if(stacks && !(owner.on_fire) && ishuman(owner))
		if(stacks >= 15)
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Generic_mob_burning", -FIRE_LAYER))
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Standing", -FIRE_LAYER))
			owner.add_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Standing", -FIRE_LAYER))
		else
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Standing", -FIRE_LAYER))
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Generic_mob_burning", -FIRE_LAYER))
			owner.add_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Generic_mob_burning", -FIRE_LAYER))

/datum/status_effect/stacking/lc_burn/on_remove()
	if(!(owner.on_fire) && ishuman(owner))
		owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Generic_mob_burning", -FIRE_LAYER))
		owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "Standing", -FIRE_LAYER))
	..()

//Mob Proc
/mob/living/proc/apply_lc_burn(stacks)
	var/datum/status_effect/stacking/lc_burn/B = src.has_status_effect(/datum/status_effect/stacking/lc_burn)
	if(!B)
		src.apply_status_effect(/datum/status_effect/stacking/lc_burn, stacks)
	else
		B.add_stacks(stacks)

#define STATUS_EFFECT_LCBLEED /datum/status_effect/stacking/lc_bleed // Deals true damage every 5 sec, can't be applied to godmode (contained abos)
/datum/status_effect/stacking/lc_bleed
	id = "lc_bleed"
	alert_type = /atom/movable/screen/alert/status_effect/lc_bleed
	max_stacks = 50
	tick_interval = 5 SECONDS
	consumed_on_threshold = FALSE
	var/new_stack = FALSE
	var/safety = TRUE
	var/bleed_cooldown = 20
	var/bleed_time

/atom/movable/screen/alert/status_effect/lc_bleed
	name = "Bleeding"
	desc = "You're currently bleeding!!"
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "lc_bleed"

//Bleed Damage Stuff
/datum/status_effect/stacking/lc_bleed/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(Moved))
	owner.playsound_local(owner, 'sound/effects/bleed_apply.ogg', 25, TRUE)

//Deals true damage
/datum/status_effect/stacking/lc_bleed/proc/Moved(mob/user, atom/new_location)
	SIGNAL_HANDLER
	if (world.time - bleed_time < bleed_cooldown)
		return
	bleed_time = world.time
	if(!can_have_status())
		qdel(src)
	to_chat(owner, "<span class='warning'>Your organs bleed due to your movement!!</span>")
	owner.playsound_local(owner, 'sound/effects/bleed.ogg', 25, TRUE)
	if(stacks >= 5)
		var/obj/effect/decal/cleanable/blood/B = locate() in get_turf(owner)
		if(!B)
			B = new /obj/effect/decal/cleanable/blood(get_turf(owner))
			B.bloodiness = 100
	if(ishuman(owner))
		owner.adjustBruteLoss(max(0, stacks))
	else
		owner.adjustBruteLoss(stacks*4) // x4 on non humans
	new /obj/effect/temp_visual/damage_effect/bleed(get_turf(owner))
	stacks = round(stacks/2)
	if(stacks == 0)
		qdel(src)


/datum/status_effect/stacking/lc_bleed/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
	return ..()

/datum/status_effect/stacking/lc_bleed/can_have_status()
	return (owner.stat != DEAD || !(owner.status_flags & GODMODE))

/datum/status_effect/stacking/lc_bleed/add_stacks(stacks_added)
	..()
	new_stack = TRUE

// The Stack Decaying
/datum/status_effect/stacking/lc_bleed/tick()
	if(safety)
		if(new_stack)
			new_stack = FALSE
		else
			qdel(src)

//Mob Proc
/mob/living/proc/apply_lc_bleed(stacks)
	var/datum/status_effect/stacking/lc_bleed/B = src.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!B)
		src.apply_status_effect(/datum/status_effect/stacking/lc_bleed, stacks)
	else
		B.add_stacks(stacks)

/datum/status_effect/display/dyscrasone_withdrawl
	id = "dyscrasone_withdrawl"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = null
	display_name = "sadface_all_stats"

/datum/status_effect/display/dyscrasone_withdrawl/on_apply()
	. = ..()
	var/mob/living/carbon/human/L = owner
	L.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, -25)
	L.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -25)
	L.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -25)
	L.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -25)

/datum/status_effect/display/dyscrasone_withdrawl/on_remove()
	var/mob/living/carbon/human/L = owner
	L.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 25)
	L.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 25)
	L.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 25)
	L.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 25)
	return ..()

/datum/status_effect/stacking/pallid_noise
	id = "pallidnoise"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 15 SECONDS//15 seconds per stack, a bit over a minute when maxed out
	tick_interval = 10
	max_stacks = 5
	stacks = 1
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/pallid_noise
	consumed_on_threshold = FALSE

/atom/movable/screen/alert/status_effect/pallid_noise
	name = "Pallid Noise"
	desc = "Hideous noises reverberate through your own head, all speaking a language you don't understand, yet do."
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "pallid_noise"

/datum/status_effect/stacking/pallid_noise/tick()//TODO:change this to golden apple's life tick for less lag
	if(!ishuman(owner))
		owner.apply_damage(stacks * 5, WHITE_DAMAGE, null, owner.run_armor_check(null, WHITE_DAMAGE))
		return
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjustSanityLoss(stacks * stacks)//sanity damage is the # of stacks squared

/datum/status_effect/healing_block
	id = "healing_block_base"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/healing_block/on_apply()
	if(!HAS_TRAIT(owner, TRAIT_PHYSICAL_HEALING_BLOCKED))
		ADD_TRAIT(owner, TRAIT_PHYSICAL_HEALING_BLOCKED, STATUS_EFFECT_TRAIT)
	if(ishuman(owner) && !HAS_TRAIT(owner, TRAIT_SANITY_HEALING_BLOCKED))
		ADD_TRAIT(owner, TRAIT_SANITY_HEALING_BLOCKED, STATUS_EFFECT_TRAIT)
	return TRUE

/datum/status_effect/healing_block/on_remove()
	if(locate(/datum/status_effect/healing_block) in owner.status_effects)
		return
	REMOVE_TRAIT(owner, TRAIT_PHYSICAL_HEALING_BLOCKED, STATUS_EFFECT_TRAIT)
	if(ishuman(owner))
		REMOVE_TRAIT(owner, TRAIT_SANITY_HEALING_BLOCKED, STATUS_EFFECT_TRAIT)

// Tremor
/datum/status_effect/stacking/lc_tremor
	id = "lc_tremor"
	alert_type = /atom/movable/screen/alert/status_effect/lc_tremor
	max_stacks = 50
	tick_interval = 10 SECONDS
	consumed_on_threshold = FALSE
	var/new_stack = TRUE

/atom/movable/screen/alert/status_effect/lc_tremor
	name = "Tremor"
	desc = "You're unsteady on your feet, and move a bit slower."
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "tremor"

//Slowdown on stack, prepares tremor burst
/datum/status_effect/stacking/lc_tremor/on_apply()
	. = ..()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/tremor, multiplicative_slowdown = stacks * 0.4)

/datum/status_effect/stacking/lc_tremor/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/tremor)
	return ..()

/datum/status_effect/stacking/lc_tremor/add_stacks(stacks)
	. = ..()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/tremor, multiplicative_slowdown = stacks * 0.4)

/datum/status_effect/stacking/lc_tremor/can_have_status()
	return (owner.stat != DEAD || !(owner.status_flags & GODMODE))

// The Stack Decaying
/datum/status_effect/stacking/lc_tremor/tick()
	if(new_stack)
		new_stack = FALSE
	else
		qdel(src)

/datum/status_effect/stacking/lc_tremor/proc/TremorBurst()
	new /obj/effect/temp_visual/weapon_stun/tremorburst(get_turf(owner))
	playsound(owner, 'sound/effects/tremorburst.ogg', 50, FALSE)
	if(ishuman(owner))
		owner.Knockdown(stacks)
		qdel(src)
		return
	owner.adjustBruteLoss(5 * stacks)
	qdel(src)

//Mob Proc
/mob/living/proc/apply_lc_tremor(stacks, tremorburst)
	var/datum/status_effect/stacking/lc_tremor/T = src.has_status_effect(/datum/status_effect/stacking/lc_tremor)
	if(!T)
		src.apply_status_effect(/datum/status_effect/stacking/lc_tremor, stacks)
		new /obj/effect/temp_visual/damage_effect/tremor(get_turf(src))
		return

	if(T.stacks < tremorburst)
		T.add_stacks(stacks)
		new /obj/effect/temp_visual/damage_effect/tremor(get_turf(src))
		T.new_stack = TRUE
		return
	T.TremorBurst()


/datum/movespeed_modifier/tremor
	multiplicative_slowdown = 0
	variable = TRUE
