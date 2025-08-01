/// Simple, mostly AI-controlled critters, such as pets, bots, and drones.
/mob/living/simple_animal
	name = "animal"
	icon = 'icons/mob/animal.dmi'
	health = 20
	maxHealth = 20
	gender = PLURAL //placeholder
	living_flags = MOVES_ON_ITS_OWN
	status_flags = CANPUSH

	var/icon_living = ""
	///Icon when the animal is dead. Don't use animated icons for this.
	var/icon_dead = ""
	///We only try to show a gibbing animation if this exists.
	var/icon_gib = null
	///Flip the sprite upside down on death. Mostly here for things lacking custom dead sprites.
	var/flip_on_death = FALSE

	var/list/speak = list()
	///Emotes while speaking IE: `Ian [emote], [text]` -- `Ian barks, "WOOF!".` Spoken text is generated from the speak variable.
	var/list/speak_emote = list()
	var/speak_chance = 0
	///Hearable emotes
	var/list/emote_hear = list()
	///Unlike speak_emote, the list of things in this variable only show by themselves with no spoken text. IE: Ian barks, Ian yaps
	var/list/emote_see = list()

	var/turns_per_move = 1
	var/turns_since_move = 0
	///Use this to temporarely stop random movement or to if you write special movement code for animals.
	var/stop_automated_movement = 0
	///Does the mob wander around when idle?
	var/wander = FALSE
	///When set to 1 this stops the animal from moving when someone is pulling it.
	var/stop_automated_movement_when_pulled = 1

	///When someone interacts with the simple animal.
	///Help-intent verb in present continuous tense.
	var/response_help_continuous = "pokes"
	///Help-intent verb in present simple tense.
	var/response_help_simple = "poke"
	///Disarm-intent verb in present continuous tense.
	var/response_disarm_continuous = "shoves"
	///Disarm-intent verb in present simple tense.
	var/response_disarm_simple = "shove"
	///Harm-intent verb in present continuous tense.
	var/response_harm_continuous = "hits"
	///Harm-intent verb in present simple tense.
	var/response_harm_simple = "hit"
	var/harm_intent_damage = 3
	///Minimum force required to deal any damage.
	var/force_threshold = 0
	///Maximum amount of stamina damage the mob can be inflicted with total
	var/max_staminaloss = 200
	///How much stamina the mob recovers per call of update_stamina
	var/stamina_recovery = 10

	///Minimal body temperature without receiving damage
	var/minbodytemp = 250
	///Maximal body temperature without receiving damage
	var/maxbodytemp = 350
	///This damage is taken when the body temp is too cold.
	var/unsuitable_cold_damage
	///This damage is taken when the body temp is too hot.
	var/unsuitable_heat_damage

	///Healable by medical stacks? Defaults to yes.
	var/healable = 1

	///Atmos effect - Yes, you can make creatures that require plasma or co2 to survive. N2O is a trace gas and handled separately, hence why it isn't here. It'd be hard to add it. Hard and me don't mix (Yes, yes make all the dick jokes you want with that.) - Errorage
	///Leaving something at 0 means it's off - has no maximum.
	var/list/atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	///This damage is taken when atmos doesn't fit all the requirements above.
	var/unsuitable_atmos_damage = 2

	//Defaults to zero so Ian can still be cuddly. Moved up the tree to living! This allows us to bypass some hardcoded stuff.
	melee_damage_lower = 0
	melee_damage_upper = 0
	///how much damage this simple animal does to objects, if any.
	var/obj_damage = 0
	///How much armour they ignore, as a flat reduction from the targets armour value.
	var/armour_penetration = 0
	///Damage type of a simple mob's melee attack, should it do damage.
	var/melee_damage_type = RED_DAMAGE
	/// 1 for full damage , 0 for none , -1 for 1:1 heal from that source., Starts as a list and becomes a datum post Initialize()
	var/datum/dam_coeff/damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	/// The unmodified values for the dam_coeff datum
	var/datum/dam_coeff/unmodified_damage_coeff_datum
	/// The list of all modifiers to the current DC datum
	var/list/damage_mods = list()
	///Attacking verb in present continuous tense.
	var/attack_verb_continuous = "attacks"
	///Attacking verb in present simple tense.
	var/attack_verb_simple = "attack"
	/// Sound played when the critter attacks.
	var/attack_sound
	/// Override for the visual attack effect shown on 'do_attack_animation()'.
	var/attack_vis_effect
	///Attacking, but without damage, verb in present continuous tense.
	var/friendly_verb_continuous = "nuzzles"
	///Attacking, but without damage, verb in present simple tense.
	var/friendly_verb_simple = "nuzzle"
	///Set to 1 to allow breaking of crates,lockers,racks,tables; 2 for walls; 3 for Rwalls.
	var/environment_smash = ENVIRONMENT_SMASH_NONE

	///LETS SEE IF I CAN SET SPEEDS FOR SIMPLE MOBS WITHOUT DESTROYING EVERYTHING. Higher speed is slower, negative speed is faster.
	var/speed = 1

	///Hot simple_animal baby making vars.
	var/list/childtype = null
	var/next_scan_time = 0
	///Sorry, no spider+corgi buttbabies.
	var/animal_species

	///Simple_animal access.
	///Innate access uses an internal ID card.
	var/obj/item/card/id/access_card = null
	///In the event that you want to have a buffing effect on the mob, but don't want it to stack with other effects, any outside force that applies a buff to a simple mob should at least set this to 1, so we have something to check against.
	var/buffed = 0
	///If the mob can be spawned with a gold slime core. HOSTILE_SPAWN are spawned with plasma, FRIENDLY_SPAWN are spawned with blood.
	var/gold_core_spawnable = NO_SPAWN

	var/datum/component/spawner/nest

	///Sentience type, for slime potions.
	var/sentience_type = SENTIENCE_ORGANIC

	///List of things spawned at mob's loc when it dies.
	var/list/loot = list()
	///Causes mob to be deleted on death, useful for mobs that spawn lootable corpses.
	var/del_on_death = 0

	var/allow_movement_on_non_turfs = FALSE

	///Played when someone punches the creature.
	var/attacked_sound = "punch"

	///If the creature has, and can use, hands.
	var/dextrous = FALSE
	var/dextrous_hud_type = /datum/hud/dextrous

	///If the creature should have an innate TRAIT_MOVE_FLYING trait added on init that is also toggled off/on on death/revival.
	var/is_flying_animal = FALSE

	///The Status of our AI, can be set to AI_ON (On, usual processing), AI_IDLE (Will not process, but will return to AI_ON if an enemy comes near), AI_OFF (Off, Not processing ever), AI_Z_OFF (Temporarily off due to nonpresence of players).
	var/AIStatus = AI_ON
	///once we have become sentient, we can never go back.
	var/can_have_ai = TRUE

	///convenience var for forcibly waking up an idling AI on next check.
	var/shouldwakeup = FALSE

	///Domestication.
	var/tame = FALSE
	///What the mob eats, typically used for taming or animal husbandry.
	var/list/food_type
	///Starting success chance for taming.
	var/tame_chance
	///Added success chance after every failed tame attempt.
	var/bonus_tame_chance

	///I don't want to confuse this with client registered_z.
	var/my_z
	///What kind of footstep this mob should have. Null if it shouldn't have any.
	var/footstep_type

	///How much wounding power it has
	var/wound_bonus = CANT_WOUND
	///How much bare wounding power it has
	var/bare_wound_bonus = 0
	///If the attacks from this are sharp
	var/sharpness = SHARP_NONE
	///Generic flags
	var/simple_mob_flags = NONE

	/// Used for making mobs show a heart emoji when pet.
	var/pet_bonus = FALSE
	/// A string for an emote used when pet_bonus == true for the mob being pet.
	var/pet_bonus_emote = ""

	var/occupied_tiles_left = 0
	var/occupied_tiles_right = 0
	var/occupied_tiles_down = 0
	var/occupied_tiles_up = 0
	var/occupied_tiles_left_current = 0
	var/occupied_tiles_right_current = 0
	var/occupied_tiles_down_current = 0
	var/occupied_tiles_up_current = 0
	var/list/projectile_blockers = null
	var/list/offsets_pixel_x = list("south" = 0, "north" = 0, "west" = 0, "east" = 0)
	var/list/offsets_pixel_y = list("south" = 0, "north" = 0, "west" = 0, "east" = 0)
	var/should_projectile_blockers_change_orientation = FALSE

	//If they should get they city faction in City gamemodes
	var/city_faction = TRUE

/mob/living/simple_animal/Initialize()
	. = ..()
	GLOB.simple_animals[AIStatus] += src
	if(gender == PLURAL)
		gender = pick(MALE,FEMALE)
	if(!real_name)
		real_name = name
	if(!loc)
		stack_trace("Simple animal being instantiated in nullspace")
	update_simplemob_varspeed()
	if(dextrous)
		AddComponent(/datum/component/personal_crafting)
		ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, ROUNDSTART_TRAIT)
	if(is_flying_animal)
		ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)

	if(speak)
		speak = string_list(speak)
	if(speak_emote)
		speak_emote = string_list(speak_emote)
	if(emote_hear)
		emote_hear = string_list(emote_hear)
	if(emote_see)
		emote_see = string_list(emote_hear)
	if(atmos_requirements)
		atmos_requirements = string_assoc_list(atmos_requirements)
	if (islist(damage_coeff))
		unmodified_damage_coeff_datum = makeDamCoeff(damage_coeff)
		damage_coeff = makeDamCoeff(damage_coeff)
	else if (!damage_coeff)
		damage_coeff = makeDamCoeff()
		unmodified_damage_coeff_datum = makeDamCoeff()
	else if (!istype(damage_coeff, /datum/dam_coeff))
		stack_trace("Invalid type [damage_coeff.type] found in .damage_coeff during /simple_animal Initialize()")
	if(footstep_type)
		AddComponent(/datum/component/footstep, footstep_type)
	if(!unsuitable_cold_damage)
		unsuitable_cold_damage = unsuitable_atmos_damage
	if(!unsuitable_heat_damage)
		unsuitable_heat_damage = unsuitable_atmos_damage
	//LC13 Check, it's here to give everything nightvision on Rcorp.
	if(IsCombatMap())
		var/obj/effect/proc_holder/spell/targeted/night_vision/bloodspell = new
		AddSpell(bloodspell)
	//LC13 Check. If it's the citymap, they all gain a faction
	if(SSmaptype.maptype in SSmaptype.citymaps)
		if(city_faction)
			faction += "hostile"
	if(occupied_tiles_down > 0 || occupied_tiles_up > 0 || occupied_tiles_left > 0 || occupied_tiles_right > 0)
		occupied_tiles_left_current = occupied_tiles_left
		occupied_tiles_right_current = occupied_tiles_right
		occupied_tiles_down_current = occupied_tiles_down
		occupied_tiles_up_current = occupied_tiles_up
		projectile_blockers = list()
		for(var/i in (x - occupied_tiles_left) to (x + occupied_tiles_right))
			for(var/j in (y - occupied_tiles_down) to (y + occupied_tiles_up))
				if(i == x && j == y)
					continue
				projectile_blockers += new /mob/living/simple_animal/projectile_blocker_dummy(locate(i, j, z), src)
		RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(OnDirChange))

	if(damage_coeff.getCoeff(FIRE) == 1) // LC13 burn armor calculator. Looks at red armor, and ignores up to 50% of armor. deals full damage to mobs weak to red
		var/red_mod = damage_coeff.getCoeff(RED_DAMAGE)
		switch(red_mod)
			if(-INFINITY to 0)
				red_mod = red_mod
			if(0.001 to 0.5)
				red_mod = red_mod * 1.5
			if(0.5 to 1)
				red_mod = (((1 - red_mod) / 2) + red_mod) // 50% armor ignore
		ChangeResistances(list(FIRE = red_mod))

/mob/living/simple_animal/proc/SetOccupiedTiles(down = 0, up = 0, left = 0, right = 0)
	occupied_tiles_down = down
	occupied_tiles_up = up
	occupied_tiles_left = left
	occupied_tiles_right = right
	occupied_tiles_down_current = down
	occupied_tiles_up_current = up
	occupied_tiles_left_current = left
	occupied_tiles_right_current = right
	var/amount_needed = (down + up + 1) * (left + right + 1) - 1
	if(!projectile_blockers)
		projectile_blockers = list()
		RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(OnDirChange))
	if(amount_needed > projectile_blockers.len)
		for(var/i in (projectile_blockers.len + 1) to amount_needed)
			projectile_blockers += new /mob/living/simple_animal/projectile_blocker_dummy(get_turf(src), src)
	else if(amount_needed < projectile_blockers.len)
		for(var/i in (amount_needed + 1) to projectile_blockers.len)
			qdel(projectile_blockers[1])
			projectile_blockers.Cut(1, 2)
	var/current_element = 1
	for(var/i in (-occupied_tiles_left) to occupied_tiles_right)
		for(var/j in (-occupied_tiles_down) to occupied_tiles_up)
			if(i == 0 && j == 0)
				continue
			var/mob/living/simple_animal/projectile_blocker_dummy/pbd = projectile_blockers[current_element]
			pbd.offset_x = i
			pbd.offset_y = j
			++current_element
	setDir(dir)

/mob/living/simple_animal/Life()
	. = ..()
	if(staminaloss > 0)
		adjustStaminaLoss(-stamina_recovery, FALSE, TRUE)

/mob/living/simple_animal/proc/OnDirChange(atom/thing, dir, newdir)
	SIGNAL_HANDLER
	pixel_x = offsets_pixel_x[dir2text(newdir)]
	base_pixel_x = pixel_x
	pixel_y = offsets_pixel_y[dir2text(newdir)]
	base_pixel_y = pixel_y
	if(should_projectile_blockers_change_orientation)
		for(var/mob/living/simple_animal/projectile_blocker_dummy/D in projectile_blockers)
			var/turf/T
			switch(newdir)
				if(SOUTH)
					occupied_tiles_left_current = occupied_tiles_left
					occupied_tiles_right_current = occupied_tiles_right
					occupied_tiles_down_current = occupied_tiles_down
					occupied_tiles_up_current = occupied_tiles_up
					T = locate(x + D.offset_x, y + D.offset_y, z)
				if(NORTH)
					occupied_tiles_left_current = occupied_tiles_right
					occupied_tiles_right_current = occupied_tiles_left
					occupied_tiles_down_current = occupied_tiles_up
					occupied_tiles_up_current = occupied_tiles_down
					T = locate(x - D.offset_x, y - D.offset_y, z)
				if(WEST)
					occupied_tiles_left_current = occupied_tiles_down
					occupied_tiles_right_current = occupied_tiles_up
					occupied_tiles_down_current = occupied_tiles_right
					occupied_tiles_up_current = occupied_tiles_left
					T = locate(x + D.offset_y, y - D.offset_x, z)
				if(EAST)
					occupied_tiles_left_current = occupied_tiles_up
					occupied_tiles_right_current = occupied_tiles_down
					occupied_tiles_down_current = occupied_tiles_left
					occupied_tiles_up_current = occupied_tiles_right
					T = locate(x - D.offset_y, y + D.offset_x, z)
			D.doMove(T)

/mob/living/simple_animal/onTransitZ(old_z, new_z)
	. = ..()
	Moved()

/mob/living/simple_animal/Destroy()
	GLOB.simple_animals[AIStatus] -= src
	if (SSnpcpool.state == SS_PAUSED && LAZYLEN(SSnpcpool.currentrun))
		SSnpcpool.currentrun -= src

	if(nest)
		nest.spawned_mobs -= src
		nest = null

	var/turf/T = get_turf(src)
	if (T && AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src

	if(projectile_blockers)
		QDEL_LIST(projectile_blockers)
	return ..()

/mob/living/simple_animal/vv_edit_var(var_name, var_value)
	. = ..()
	switch(var_name)
		if(NAMEOF(src, is_flying_animal))
			if(stat != DEAD)
				if(!is_flying_animal)
					REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
				else
					ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)

/mob/living/simple_animal/attackby(obj/item/O, mob/user, params)
	if(!is_type_in_list(O, food_type))
		return ..()
	if(stat == DEAD)
		to_chat(user, span_warning("[src] is dead!"))
		return
	user.visible_message(span_notice("[user] hand-feeds [O] to [src]."), span_notice("You hand-feed [O] to [src]."))
	qdel(O)
	if(tame)
		return
	if (prob(tame_chance)) //note: lack of feedback message is deliberate, keep them guessing!
		tame = TRUE
		tamed(user)
	else
		tame_chance += bonus_tame_chance

///Extra effects to add when the mob is tamed, such as adding a riding component
/mob/living/simple_animal/proc/tamed(whomst)
	tame = TRUE

/mob/living/simple_animal/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		. += span_deadsay("Upon closer examination, [p_they()] appear[p_s()] to be dead.")


/mob/living/simple_animal/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0)
			death()
		else
			set_stat(CONSCIOUS)
	med_hud_set_status()

/mob/living/simple_animal/handle_status_effects()
	..()
	if(stuttering)
		stuttering = 0

/**
 * Updates the simple mob's stamina loss.
 *
 * Updates the speed and staminaloss of a given simplemob.
 * Reduces the stamina loss by stamina_recovery
 */
/mob/living/simple_animal/update_stamina()
	set_varspeed(initial(speed) + (staminaloss * 0.06))

/mob/living/simple_animal/proc/handle_automated_action()
	set waitfor = FALSE
	return

/mob/living/simple_animal/proc/handle_automated_movement()
	set waitfor = FALSE
	if(!stop_automated_movement && wander)
		if((isturf(loc) || allow_movement_on_non_turfs) && (mobility_flags & MOBILITY_MOVE))		//This is so it only moves if it's not inside a closet, gentics machine, etc.
			turns_since_move++
			if(turns_since_move >= turns_per_move)
				if(!(stop_automated_movement_when_pulled && pulledby)) //Some animals don't move when pulled
					var/anydir = pick(GLOB.cardinals)
					if(Process_Spacemove(anydir))
						Move(get_step(src, anydir), anydir)
						turns_since_move = 0
			return 1

/mob/living/simple_animal/proc/handle_automated_speech(override)
	set waitfor = FALSE
	if(speak_chance)
		if(prob(speak_chance) || override)
			if(speak?.len)
				if((emote_hear?.len) || (emote_see?.len))
					var/length = speak.len
					if(emote_hear?.len)
						length += emote_hear.len
					if(emote_see?.len)
						length += emote_see.len
					var/randomValue = rand(1,length)
					if(randomValue <= speak.len)
						say(pick(speak), forced = "poly")
					else
						randomValue -= speak.len
						if(emote_see && randomValue <= emote_see.len)
							manual_emote(pick(emote_see))
						else
							manual_emote(pick(emote_hear))
				else
					say(pick(speak), forced = "poly")
			else
				if(!(emote_hear?.len) && (emote_see?.len))
					manual_emote(pick(emote_see))
				if((emote_hear?.len) && !(emote_see?.len))
					manual_emote(pick(emote_hear))
				if((emote_hear?.len) && (emote_see?.len))
					var/length = emote_hear.len + emote_see.len
					var/pick = rand(1,length)
					if(pick <= emote_see.len)
						manual_emote(pick(emote_see))
					else
						manual_emote(pick(emote_hear))

/mob/living/simple_animal/proc/environment_air_is_safe()
	. = TRUE

	if(pulledby && pulledby.grab_state >= GRAB_KILL && atmos_requirements["min_oxy"])
		. = FALSE //getting choked

	if(isturf(loc) && isopenturf(loc))
		var/turf/open/ST = loc
		if(ST.air)
			var/ST_gases = ST.air.gases
			ST.air.assert_gases(arglist(GLOB.hardcoded_gases))

			var/tox = ST_gases[/datum/gas/plasma][MOLES]
			var/oxy = ST_gases[/datum/gas/oxygen][MOLES]
			var/n2  = ST_gases[/datum/gas/nitrogen][MOLES]
			var/co2 = ST_gases[/datum/gas/carbon_dioxide][MOLES]

			ST.air.garbage_collect()

			if(atmos_requirements["min_oxy"] && oxy < atmos_requirements["min_oxy"])
				. = FALSE
			else if(atmos_requirements["max_oxy"] && oxy > atmos_requirements["max_oxy"])
				. = FALSE
			else if(atmos_requirements["min_tox"] && tox < atmos_requirements["min_tox"])
				. = FALSE
			else if(atmos_requirements["max_tox"] && tox > atmos_requirements["max_tox"])
				. = FALSE
			else if(atmos_requirements["min_n2"] && n2 < atmos_requirements["min_n2"])
				. = FALSE
			else if(atmos_requirements["max_n2"] && n2 > atmos_requirements["max_n2"])
				. = FALSE
			else if(atmos_requirements["min_co2"] && co2 < atmos_requirements["min_co2"])
				. = FALSE
			else if(atmos_requirements["max_co2"] && co2 > atmos_requirements["max_co2"])
				. = FALSE
		else
			if(atmos_requirements["min_oxy"] || atmos_requirements["min_tox"] || atmos_requirements["min_n2"] || atmos_requirements["min_co2"])
				. = FALSE

/mob/living/simple_animal/proc/environment_temperature_is_safe(datum/gas_mixture/environment)
	. = TRUE
	var/areatemp = get_temperature(environment)
	if((areatemp < minbodytemp) || (areatemp > maxbodytemp))
		. = FALSE

/mob/living/simple_animal/handle_environment(datum/gas_mixture/environment)
	var/atom/A = loc
	if(isturf(A))
		var/areatemp = get_temperature(environment)
		if(abs(areatemp - bodytemperature) > 5)
			var/diff = areatemp - bodytemperature
			diff = diff / 5
			adjust_bodytemperature(diff)

	if(!environment_air_is_safe())
		adjustHealth(unsuitable_atmos_damage)
		if(unsuitable_atmos_damage > 0)
			throw_alert("not_enough_oxy", /atom/movable/screen/alert/not_enough_oxy)
	else
		clear_alert("not_enough_oxy")

	handle_temperature_damage()

/mob/living/simple_animal/proc/handle_temperature_damage()
	if(bodytemperature < minbodytemp)
		adjustHealth(unsuitable_cold_damage)
		switch(unsuitable_cold_damage)
			if(1 to 5)
				throw_alert("temp", /atom/movable/screen/alert/cold, 1)
			if(5 to 10)
				throw_alert("temp", /atom/movable/screen/alert/cold, 2)
			if(10 to INFINITY)
				throw_alert("temp", /atom/movable/screen/alert/cold, 3)
	else if(bodytemperature > maxbodytemp)
		adjustHealth(unsuitable_heat_damage)
		switch(unsuitable_heat_damage)
			if(1 to 5)
				throw_alert("temp", /atom/movable/screen/alert/hot, 1)
			if(5 to 10)
				throw_alert("temp", /atom/movable/screen/alert/hot, 2)
			if(10 to INFINITY)
				throw_alert("temp", /atom/movable/screen/alert/hot, 3)
	else
		clear_alert("temp")

/mob/living/simple_animal/gib()
	if(butcher_results || guaranteed_butcher_results)
		var/list/butcher = list()
		if(butcher_results)
			butcher += butcher_results
		if(guaranteed_butcher_results)
			butcher += guaranteed_butcher_results
		var/atom/Tsec = drop_location()
		for(var/path in butcher)
			for(var/i in 1 to butcher[path])
				new path(Tsec)
	..()

/mob/living/simple_animal/gib_animation()
	if(icon_gib)
		new /obj/effect/temp_visual/gib_animation/animal(loc, icon_gib)


/mob/living/simple_animal/say_mod(input, list/message_mods = list())
	if(length(speak_emote))
		verb_say = pick(speak_emote)
	return ..()

/mob/living/simple_animal/proc/set_varspeed(var_value)
	speed = var_value
	update_simplemob_varspeed()

/mob/living/simple_animal/proc/update_simplemob_varspeed()
	if(speed == 0)
		remove_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed)
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = speed)

/mob/living/simple_animal/get_status_tab_items()
	. = ..()
	. += ""
	. += "Health: [round((health / maxHealth) * 100)]%"

/mob/living/simple_animal/proc/drop_loot()
	if(loot?.len)
		for(var/i in loot)
			new i(loc)

/mob/living/simple_animal/death(gibbed)
	if(nest)
		nest.spawned_mobs -= src
		nest = null
	drop_loot()
	if(dextrous)
		drop_all_held_items()
	if(del_on_death)
		..()
		//Prevent infinite loops if the mob Destroy() is overridden in such
		//a manner as to cause a call to death() again
		del_on_death = FALSE
		qdel(src)
	else
		if(is_flying_animal)
			REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
		health = 0
		icon_state = icon_dead
		if(flip_on_death)
			transform = transform.Turn(180)
		density = FALSE
		..()

/mob/living/simple_animal/proc/CanAttack(atom/the_target)
	if(see_invisible < the_target.invisibility)
		return FALSE
	if(ismob(the_target))
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE
	if (isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat != CONSCIOUS)
			return FALSE
	if (ismecha(the_target))
		var/obj/vehicle/sealed/mecha/M = the_target
		if(LAZYLEN(M.occupants))
			return FALSE
	return TRUE

/mob/living/simple_animal/handle_fire()
	return TRUE

/mob/living/simple_animal/IgniteMob()
	return FALSE

/mob/living/simple_animal/extinguish_mob()
	return

/mob/living/simple_animal/revive(full_heal = FALSE, admin_revive = FALSE)
	. = ..()
	if(!.)
		return
	icon_state = icon_living
	density = initial(density)
	if(is_flying_animal)
		ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)

/mob/living/simple_animal/proc/make_babies() // <3 <3 <3
	if(gender != FEMALE || stat || next_scan_time > world.time || !childtype || !animal_species || !SSticker.IsRoundInProgress())
		return
	next_scan_time = world.time + 400
	var/alone = TRUE
	var/mob/living/simple_animal/partner
	var/children = 0
	for(var/mob/M in view(7, src))
		if(M.stat != CONSCIOUS) //Check if it's conscious FIRST.
			continue
		var/is_child = is_type_in_list(M, childtype)
		if(is_child) //Check for children SECOND.
			children++
		else if(istype(M, animal_species))
			if(M.ckey)
				continue
			else if(!is_child && M.gender == MALE && !(M.flags_1 & HOLOGRAM_1)) //Better safe than sorry ;_;
				partner = M

		else if(isliving(M) && !faction_check_mob(M)) //shyness check. we're not shy in front of things that share a faction with us.
			return //we never mate when not alone, so just abort early

	if(alone && partner && children < 3)
		var/childspawn = pickweight(childtype)
		var/turf/target = get_turf(loc)
		if(target)
			return new childspawn(target)

/mob/living/simple_animal/stripPanelUnequip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/simple_animal/stripPanelEquip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()


/mob/living/simple_animal/update_resting()
	if(resting)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	return ..()


/mob/living/simple_animal/update_transform()
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/changed = FALSE

	if(resize != RESIZE_DEFAULT_SIZE)
		changed = TRUE
		ntransform.Scale(resize)
		resize = RESIZE_DEFAULT_SIZE

	if(changed)
		animate(src, transform = ntransform, time = 2, easing = EASE_IN|EASE_OUT)

/mob/living/simple_animal/proc/sentience_act() //Called when a simple animal gains sentience via gold slime potion
	toggle_ai(AI_OFF) // To prevent any weirdness.
	can_have_ai = FALSE

/mob/living/simple_animal/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	see_invisible = initial(see_invisible)
	see_in_dark = initial(see_in_dark)
	sight = initial(sight)

	if(client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return
	sync_lighting_plane_alpha()

//Will always check hands first, because access_card is internal to the mob and can't be removed or swapped.
/mob/living/simple_animal/get_idcard(hand_first)
	return (..() || access_card)

/mob/living/simple_animal/can_hold_items(obj/item/I)
	return dextrous && ..()

/mob/living/simple_animal/activate_hand(selhand)
	if(!dextrous)
		return ..()
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1
	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1
	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode()

/mob/living/simple_animal/swap_hand(hand_index)
	. = ..()
	if(!.)
		return
	if(!dextrous)
		return
	if(!hand_index)
		hand_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = hand_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[hand_index]"]
		if(H)
			H.update_icon()
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_icon()

/mob/living/simple_animal/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE)
	. = ..(I, del_on_fail, merge_stacks)
	update_inv_hands()

/mob/living/simple_animal/update_inv_hands()
	if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
		for(var/obj/item/I in held_items)
			var/index = get_held_index_of_item(I)
			I.layer = ABOVE_HUD_LAYER
			I.plane = ABOVE_HUD_PLANE
			I.screen_loc = ui_hand_position(index)
			client.screen |= I

//ANIMAL RIDING

/mob/living/simple_animal/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(user.incapacitated())
		return
	for(var/atom/movable/A in get_turf(src))
		if(A != src && A != M && A.density)
			return

	return ..()

/mob/living/simple_animal/proc/toggle_ai(togglestatus)
	if(!can_have_ai && (togglestatus != AI_OFF))
		return
	if (AIStatus != togglestatus)
		if (togglestatus > 0 && togglestatus < 5)
			if (togglestatus == AI_Z_OFF || AIStatus == AI_Z_OFF)
				var/turf/T = get_turf(src)
				if (AIStatus == AI_Z_OFF)
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src
				else
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] += src
			GLOB.simple_animals[AIStatus] -= src
			GLOB.simple_animals[togglestatus] += src
			AIStatus = togglestatus
		else
			stack_trace("Something attempted to set simple animals AI to an invalid state: [togglestatus]")

/mob/living/simple_animal/proc/consider_wakeup()
	if (pulledby || shouldwakeup)
		toggle_ai(AI_ON)

/mob/living/simple_animal/onTransitZ(old_z, new_z)
	..()
	if (AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[old_z] -= src
		toggle_ai(initial(AIStatus))

///This proc is used for adding the swabbale element to mobs so that they are able to be biopsied and making sure holograpic and butter-based creatures don't yield viable cells samples.
/mob/living/simple_animal/proc/add_cell_sample()
	return

/mob/living/simple_animal/relaymove(mob/living/user, direction)
	if(user.incapacitated())
		return
	return relaydrive(user, direction)

/mob/living/simple_animal/deadchat_plays(mode = ANARCHY_MODE, cooldown = 12 SECONDS)
	. = AddComponent(/datum/component/deadchat_control/cardinal_movement, mode, list(), cooldown, CALLBACK(src, PROC_REF(stop_deadchat_plays)))

	if(. == COMPONENT_INCOMPATIBLE)
		return

	stop_automated_movement = TRUE

/mob/living/simple_animal/proc/stop_deadchat_plays()
	stop_automated_movement = FALSE

// -- LC13 THINGS --

/mob/living/simple_animal/proc/IsCombatMap() //Is it currently a combat gamemode? Used to check for a few interactions, like if somethings can teleport.
	if(SSmaptype.maptype in SSmaptype.combatmaps)
		return TRUE
	return FALSE
