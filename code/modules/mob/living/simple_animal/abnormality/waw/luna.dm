#define STATUS_EFFECT_LUNAR /datum/status_effect/lunar
//I will remind you all that this technically does NOT breach.	-Kirie
/mob/living/simple_animal/hostile/abnormality/luna
	name = "\proper Il Pianto della Luna"
	desc = "A piano, with a woman sitting on the stool next to it"
	icon = 'ModularTegustation/Teguicons/96x48.dmi'
	icon_state = "dellaluna"
	portrait = "luna"
	maxHealth = 4000
	health = 4000
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	start_qliphoth = 3
	threat_level = WAW_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(20, 30, 40, 50, 55),
		ABNORMALITY_WORK_INSIGHT = list(40, 45, 50, 55, 55),
		ABNORMALITY_WORK_ATTACHMENT = list(30, 30, 50, 50, 55),
		ABNORMALITY_WORK_REPRESSION = 30,
		"Performance" = 100,
	)
	pixel_x = -32
	base_pixel_x = -32
	work_damage_amount = 10
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth
	max_boxes = 20
	ego_list = list(
		/datum/ego_datum/weapon/moonlight,
		/datum/ego_datum/armor/moonlight,
	)
	gift_type =  /datum/ego_gifts/moonlight
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY

	observation_prompt = "You enter the containment unit as respectfully as you can, the woman by the piano does not acknowledge your presence, merely clutching her cane tighter. <br>\
		\"Begin.\" She commands, her lips a tight thin line. <br>It's the first time she's ever spoken. <br>\
		The piano waits for you expectantly."
	observation_choices = list(
		"Begin a performance" = list(TRUE, "You begin to play, there is no sheet music to guide you, you play the performance that you were always meant to play. <br>\
			It's haunting and beautiful, <br>terrifying yet entrancing. <br>\
			With every key press, your body feels heavier and heavier and with every step upon the shrunken heads for pedals, your mind grows slower and more sluggish. <br>\
			By the end of the performance, you're slumped over the keyboard with hardly the strength or wherewithal to move. <br>\
			Above the piano, through your fading vision, you can swear you see the moon. <br>\
			And you despair."),
		"Refuse" = list(FALSE, "She gives no indication of being disappointed. <br>Perhaps if you played, you might understand the truth behind yourself as she did."),
	)

	var/performance = FALSE
	var/performance_length = 60 SECONDS
	var/breach_length = 404 SECONDS		//How long the song is (when I finally finish it)
	var/breached = FALSE
	var/breached_monster
	var/killspawn

/mob/living/simple_animal/hostile/abnormality/luna/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/luna/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/luna/death(gibbed)
	if(breached_monster)
		qdel(breached_monster)
	..()

/mob/living/simple_animal/hostile/abnormality/luna/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(50))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/luna/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/luna/ZeroQliphoth(mob/living/carbon/human/user)
	icon_state = "dellaluna_breach"
	//Normal breach
	if(!IsCombatMap())
		var/turf/W = pick(GLOB.department_centers)
		var/mob/living/simple_animal/hostile/luna/spawningmonster = new(get_turf(W))
		breached_monster = spawningmonster
		addtimer(CALLBACK(src, PROC_REF(BreachEnd), user), breach_length)

	//--Side Gamemodes stuff--
	//Timer will not run the timer on Rcorp.
	else
		var/mob/living/simple_animal/hostile/luna/spawningmonster = new(get_turf(src))
		breached_monster = spawningmonster
		core_enabled = FALSE//Subject to be changed later on, as the core may need to be dropped by the monster even if not lore accurate. -Mr. H
		QDEL_IN(src, 1 SECONDS) //Destroys the piano, as it is unecessary in Rcorp.

	breached = TRUE
	if(client)
		mind.transfer_to(breached_monster) //For playable abnormalities, directly lets the playing currently controlling pianto get control of the spawned mob
	return

/mob/living/simple_animal/hostile/abnormality/luna/WorkComplete(mob/living/carbon/human/user, work_type, pe)
	if(work_type == "Performance")
		datum_reference.qliphoth_change(-1)
		if(get_attribute_level(user, PRUDENCE_ATTRIBUTE) < 60)
			user.adjustSanityLoss(-500) // It's not stated in game but performing with level 3 prudence and lower make them instantly panic

		//and half your HP.
		user.adjustBruteLoss(user.maxHealth*0.5)
	..()

/mob/living/simple_animal/hostile/abnormality/luna/Worktick(mob/living/carbon/human/user, work_type)
	if(performance)
		user.deal_damage(work_damage_amount*0.60, BLACK_DAMAGE)	//take work damage


/mob/living/simple_animal/hostile/abnormality/luna/AttemptWork(mob/living/carbon/human/user, work_type)
	if(work_type == "Performance")
		to_chat(user, span_nicegreen("Please wait until the performance is completed."))
		addtimer(CALLBACK(src, PROC_REF(PerformanceEnd), user), performance_length)
		for(var/mob/living/carbon/human/L in GLOB.player_list)
			L.apply_status_effect(STATUS_EFFECT_LUNAR)

		if(!performance)
			performance = TRUE
			playsound(user, 'sound/abnormalities/luna/moonlight_sonata.ogg', 100, FALSE, 28)	//Let the people know.

		if(breached)	//You will have to start a new performance to delete the breached abno.
			killspawn = TRUE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/luna/proc/BreachEnd(mob/living/carbon/human/user)
	datum_reference.qliphoth_change(3)
	breached = FALSE
	icon_state = "dellaluna"
	qdel(breached_monster)


/mob/living/simple_animal/hostile/abnormality/luna/proc/PerformanceEnd(mob/living/carbon/human/user)
	if(breached && killspawn)
		BreachEnd()

	killspawn = FALSE
	performance = FALSE
	to_chat(user, span_nicegreen("The performance is completed."))


//Side Gamemodes stuff, should only ever be called outside of the main gamemode
/mob/living/simple_animal/hostile/abnormality/luna/BreachEffect(mob/living/carbon/human/user, breach_type)
	ZeroQliphoth()
	return FALSE

/* Monster Half */
/mob/living/simple_animal/hostile/luna
	name = "La Luna"
	desc = "A tall, cloaked figure."
	icon = 'ModularTegustation/Teguicons/48x64.dmi'
	icon_state = "luna"
	base_pixel_x = -8
	pixel_x = -8
	health = 2600
	maxHealth = 2600
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 32
	melee_damage_upper = 41
	rapid_melee = 2
	robust_searching = TRUE
	ranged = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "beats"
	attack_verb_simple = "beat"
	attack_sound = 'sound/weapons/teasmack.ogg'
	can_patrol = TRUE
	var/aoeactive
	var/canaoe = TRUE
	var/aoerange = 5
	var/aoedamage = 60

//mob/living/simple_animal/hostile/luna/Initialize()
//Cannot figure out how to make this stop
//	..()
//	playsound(src, 'sound/abnormalities/luna/mvmt3.ogg', 180, FALSE, 28)	//Let the people know.

/mob/living/simple_animal/hostile/luna/Move()
	if(aoeactive)
		return FALSE
	..()

/mob/living/simple_animal/hostile/luna/OpenFire()
	if(!canaoe)
		return
	aoeactive = TRUE
	canaoe = FALSE
	playsound(src, 'sound/magic/wandodeath.ogg', 200, FALSE, 9)
	addtimer(CALLBACK(src, PROC_REF(AOE)), 9)
	addtimer(CALLBACK(src, PROC_REF(Reset)), 7 SECONDS)


/mob/living/simple_animal/hostile/luna/proc/AOE()
	for(var/turf/T in view(aoerange, src))
		new /obj/effect/temp_visual/revenant(T)
		HurtInTurf(T, list(), aoedamage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE)
	aoeactive = FALSE

/mob/living/simple_animal/hostile/luna/proc/Reset()
	canaoe = TRUE

//Lunar
//Just the classic La Luna buff
/datum/status_effect/lunar
	id = "lunar"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 60 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/lunar

/atom/movable/screen/alert/status_effect/lunar
	name = "Lunar Blessing"
	desc = "Your temperance is buffed for a short period of time."
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "lunar"

/datum/status_effect/lunar/on_apply()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 10)
	status_holder.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 10)

/datum/status_effect/lunar/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -10)
	status_holder.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -10)

#undef STATUS_EFFECT_LUNAR
