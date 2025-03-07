/*
* Highly Experimental Feature for spawning mobs
* in a wave and commanding them to go to a location.
*/

#define SEND_ON_SIGNAL 1
#define SEND_ON_WAVE 2
#define SEND_TILL_MAX 3

/datum/component/monwave_spawner
	var/assault_pace
	//Cooldowns for procs.
	var/resume_cooldown = 0
	var/generate_wave_cooldown = 0
	var/generate_wave_cooldown_time = 5 SECONDS
	//Our assault target
	var/assault_target
	//Leader of the assault
	var/obj/effect/wave_commander/wave_leader
	//Max amount of mobs we can spawn
	var/max_existing_mobs = 30
	//Who did we spawn and check if they dont exist anymore.
	var/list/existing_mobs = list()
	//Faction our spawned creatures belong to
	var/list/faction = list("hostile")
	//Last wave of soldiers
	var/list/last_wave = list()
	//current wave of soldiers
	var/list/current_wave = list()
	//The wave order that wave_composition copies. The value of each type is how many are in each wave.
	var/list/wave_order = list()
	var/list/wave_composition = list()
	//Path to target
	var/list/assult_path = list()

//Experimental So i dont have to use the procs all the time
/datum/component/monwave_spawner/Initialize(attack_target, assault_type = SEND_ON_WAVE, max_mobs = 30, list/wave_faction = list("hostile"), list/new_wave_order)
	if(!isstructure(parent) && !ishostile(parent))
		return COMPONENT_INCOMPATIBLE

	assault_target = attack_target
	max_existing_mobs = max_mobs
	faction = wave_faction.Copy()
	assault_pace = assault_type
	if(new_wave_order)
		wave_order = new_wave_order.Copy()

	if(!assault_target && assault_pace != SEND_ON_SIGNAL)
		qdel(src)
	GeneratePath()
	BeginProcessing()

/datum/component/monwave_spawner/process(delta_time)
	if(!parent || !assault_target)
		qdel(src)
		return
	if(length(last_wave) && world.time >= resume_cooldown)
		CleanupAssault()
		resume_cooldown = world.time + (1 MINUTES)
		return
	if(world.time >= generate_wave_cooldown)
		GenerateWave()
		generate_wave_cooldown = world.time + generate_wave_cooldown_time
		return

/datum/component/monwave_spawner/proc/BeginProcessing()
	if(assault_pace == SEND_ON_SIGNAL)
		return
	START_PROCESSING(SSdcs, src)

//Each Generation decreases the mobs value in the list by 1 and removes it from the list if it is empty.
//If the wave_composition is empty then it will send the wave out to their assault destination while the new wave is generated.
//If the last wave is still alive the second wave will remain where they are.
/datum/component/monwave_spawner/proc/GenerateWave()
	if(!length(wave_composition))
		if(assault_target)
			if(assault_pace != SEND_TILL_MAX && length(last_wave))
				return FALSE
			return StartAssault(assault_target)
		return FALSE
	var/mob/living/W = pick(wave_composition)
	wave_composition[W] -= 1
	if(wave_composition[W] <= 0)
		wave_composition -= W
	return SpawnMob(W)

//Each time a mob is spawned it is added to current_wave.
/datum/component/monwave_spawner/proc/SpawnMob(mob/living/simple_animal/hostile/mobtype)
	var/mob/living/simple_animal/hostile/spawned_mob = new mobtype(pick(get_adjacent_open_turfs(parent)))
	if(!wave_leader && LeaderQualifications(spawned_mob))
		wave_leader = spawned_mob
	current_wave += spawned_mob
	spawned_mob.faction = faction.Copy()
	RegisterSignal(spawned_mob, COMSIG_LIVING_DEATH, PROC_REF(MinionSlain))
	return spawned_mob

/datum/component/monwave_spawner/proc/MinionSlain(mob/living/M)
	SIGNAL_HANDLER

	last_wave -= M
	current_wave -= M

//Leader Modularization if you want to make only certain mobs leaders.
/datum/component/monwave_spawner/proc/LeaderQualifications(mob/living/simple_animal/hostile/recruit)
	if(!isliving(recruit))
		return FALSE
	if(recruit.stat == DEAD)
		return FALSE
	return TRUE

//Begin Assault and reset wave_composition for next wave.
/datum/component/monwave_spawner/proc/StartAssault(enemy_base)
	if(!enemy_base)
		return FALSE
	wave_leader = new /obj/effect/wave_commander(get_turf(parent))
	for(var/i in current_wave)
		if(isnull(i))
			current_wave -= i
		if(ishostile(i))
			var/mob/living/simple_animal/hostile/H = i
			if(H.stat == DEAD)
				current_wave -= H
				continue
			walk_to(H, wave_leader, rand(0,2), H.move_to_delay)
	wave_leader.DoPath(assult_path)
	wave_composition = LAZYCOPY(wave_order)
	last_wave = LAZYCOPY(current_wave)
	LAZYCLEARLIST(current_wave)
	return TRUE

//Despawns any idle monsters who lost the wave.
/datum/component/monwave_spawner/proc/CleanupAssault()
	for(var/mob/living/simple_animal/hostile/H in last_wave)
		if(!H.target)
			H.dust(FALSE)
	return length(last_wave)

//Generates a path for the Mob Commander
/datum/component/monwave_spawner/proc/GeneratePath(turf_to_go)
	var/target_loc = assault_target
	if(turf_to_go)
		target_loc = get_turf(turf_to_go)
	assult_path = get_path_to(parent, target_loc, /turf/proc/Distance_cardinal, 0, 200)

//Invisible Effect only visible to ghosts. Uses a altered form of Hostile Patrol Code -IP
/obj/effect/wave_commander
	name = "wave commander"
	desc = "A incorporial force that leads a group of monsters."
	icon = 'ModularTegustation/Teguicons/tegu_effects.dmi'
	icon_state = "target_field"
	invisibility = 40
	movement_type = PHASING | FLYING
	var/move_tries = 0
	var/patrol_move_timer = 0
	var/list/our_path = list()

/obj/effect/wave_commander/proc/DoPath(list/assault_path)
	our_path = assault_path.Copy()
	if(length(our_path) <= 0)
		RemoveCommander()
		return FALSE
	MoveInPath(our_path[length(our_path)])
	return TRUE

/obj/effect/wave_commander/proc/MoveInPath(dest)
	if(!dest || !our_path || !length(our_path)) //A-star failed or a path/destination was not set.
		RemoveCommander()
		return FALSE
	dest = get_turf(dest) //We must always compare turfs, so get the turf of the dest var if dest was originally something else.
	var/turf/last_node = get_turf(our_path[length(our_path)]) //This is the turf at the end of the path, it should be equal to dest.
	if(get_turf(src) == dest) //We have arrived, no need to move again.
		return TRUE
	else if(dest != last_node) //The path should lead us to our given destination. If this is not true, we must stop.
		return FALSE
	if(move_tries < 5)
		StepInPath(dest)
	else
		RemoveCommander()
		return FALSE
	patrol_move_timer = addtimer(CALLBACK(src, PROC_REF(MoveInPath), dest), 5, TIMER_STOPPABLE)
	return TRUE

/obj/effect/wave_commander/proc/StepInPath(dest)
	if(!our_path || !length(our_path))
		RemoveCommander()
		return FALSE
	if(length(our_path) > 1)
		step_towards(src, our_path[1])
		if(get_turf(src) == our_path[1]) //Successful move
			if(!our_path || !length(our_path))
				return
			our_path.Cut(1, 2)
			move_tries = 0
		else
			move_tries++
			return FALSE
	else if(length(our_path) == 1)
		RemoveCommander()
	return TRUE

/obj/effect/wave_commander/proc/RemoveCommander()
	if(patrol_move_timer)
		deltimer(patrol_move_timer)
	QDEL_IN(src, 5)

