/mob/living/simple_animal/hostile/abnormality/redblooded
	name = "Red Blooded American"
	desc = "A bright red demon with oversized arms and greasy black hair. It is keeping its eyes focused on you."
	icon = 'ModularTegustation/Teguicons/32x48.dmi'
	icon_state = "american_idle"
	icon_living = "american_idle"
	core_icon = "american"
	portrait = "red_blooded_american"
	var/icon_furious = "american_idle_injured"
	del_on_death = TRUE
	maxHealth = 825
	health = 825
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 4
	attack_sound = 'sound/weapons/ego/mace1.ogg'
	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	melee_damage_type = RED_DAMAGE
	stat_attack = HARD_CRIT
	ranged = TRUE
	ranged_cooldown_time = 4 SECONDS
	casingtype = /obj/item/ammo_casing/caseless/true_patriot
	projectilesound = 'sound/weapons/gun/shotgun/shot.ogg'
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 10
	melee_damage_upper = 15
	faction = list("hostile")
	speak_emote = list("snarls")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 45,
		ABNORMALITY_WORK_INSIGHT = 35,
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = list(60, 60, 60, 55, 55),
	)
	max_boxes = 14
	work_damage_amount = 6
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/red_blooded
	harvest_phrase = span_notice("You take a blood sample from %ABNO. The blood fizzles inside the %VESSEL.")
	harvest_phrase_third = "%PERSON fills %VESSEL with a blood sample from %ABNO."

	ego_list = list(
		/datum/ego_datum/weapon/patriot,
		/datum/ego_datum/armor/patriot,
	)
	gift_type = /datum/ego_gifts/patriot
	gift_message = "Protect and serve."
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "\"I was a good soldier, you know.\" <br>\
		\"Blowing freakshits away with my shotgun. <br>Talking with my brothers in arms.\" <br>\
		\"That's all I ever needed. <br>All I ever wanted. <br>Even now, I fight for the glory of my country.\" <br>\
		\"Do you have anything, anyone, to serve and protect?\""
	observation_choices = list(
		"I do" = list(TRUE, "\"Heh.\" <br>\
			\"We might not be on the same side but I can respect that.\" <br>\
			\"Go on then, freak. <br>Show me that you can protect what matters to you.\""),
		"I don't" = list(FALSE, "\"Feh. <br>Then what's the point of living, huh?\" <br>\
			\"Without a flag to protect, without a goal to achieve...\" <br>\
			\"Are you any better than an animal? <br>Get out of my sight.\""),
	)

	var/ammo = 6
	var/max_ammo = 6
	var/reload_time = 2 SECONDS
	var/last_reload_time = 0
	var/bloodlust = 0 //more you do repression, more damage it deals. decreases on other works.
	var/list/fighting_quotes = list(
		"Go ahead, freakshit! Do your best!",
		"Pft. Go ahead and try, freakshit.",
		"Good, something fun for once. Go ahead, freakshit.",
		"One of you finally has some balls.",
		"Pathetic. You're too weak for this, you know?",
	)

	var/list/bored_quotes = list(
		"Boring. C'mon, we both know a little roughhousing would be better.",
		"Aw, what a wimp. Alright, you do your thing, pansy.",
		"Yawn. Damn, you freakshits are lame.",
		"Commies. None of them have any fight in them, do they?",
		"Why was I sent here if I was just going to sit around waiting all day?",
	)

	var/list/breach_quotes = list(
		"Time to wipe you freakshits out!",
		"HA! It's over for you freaks!",
		"You're outmatched! Just drop dead already!",
		"Eat shit, you fucking commies!",
		"This is going to be fun!",
	)

/mob/living/simple_animal/hostile/abnormality/redblooded/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, "<h1>You are Red Blooded American, A Support Role Abnormality.</h1><br>\
		<b>|The American Way|: When you pick on a tile at least 2 sqrs away, You will consume 1 ammo to fire 6 pellets which deal 18 damage each.<br>\
		You passively reload 1 ammo every 2 seconds, but you can also reload 1 ammo by hitting humans or mechs.</b>")

/mob/living/simple_animal/hostile/abnormality/redblooded/AttemptWork(mob/living/carbon/human/user, work_type)
	work_damage_amount = 6 + bloodlust
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		say(pick(fighting_quotes))
		bloodlust +=2
	if(bloodlust >= 6)
		icon_state = icon_furious
	else
		icon_state = "american_idle"
	return ..()

/mob/living/simple_animal/hostile/abnormality/redblooded/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(50)) //slightly higher than other TETHs, given that the counter can be raised
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/redblooded/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/redblooded/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		datum_reference.qliphoth_change(1)
	if(work_type != ABNORMALITY_WORK_REPRESSION)
		if(bloodlust > 0)
			bloodlust -= ( 1 + round(bloodlust / 5)) //just to keep high bloodlust from being impossibly hard to lower
		if(bloodlust == 0)
			say(pick(bored_quotes))
	return ..()

/mob/living/simple_animal/hostile/abnormality/redblooded/ZeroQliphoth(mob/living/carbon/human/user)
	say(pick(breach_quotes))
	BreachEffect()
	return

//Breach
/mob/living/simple_animal/hostile/abnormality/redblooded/proc/Reload()
	playsound(src, 'sound/weapons/gun/general/bolt_rack.ogg', 25, TRUE)
	to_chat(src, span_nicegreen("You reload your shotgun..."))
	ammo += 1

/mob/living/simple_animal/hostile/abnormality/redblooded/Life()
	. = ..()
	if (last_reload_time < world.time - reload_time)
		last_reload_time = world.time
		if (ammo < max_ammo)
			Reload()

/mob/living/simple_animal/hostile/abnormality/redblooded/AttackingTarget(atom/attacked_target)
	if(ammo < max_ammo)
		if(isliving(attacked_target))
			Reload()
		if(ismecha(attacked_target))
			Reload()
	return ..()

/mob/living/simple_animal/hostile/abnormality/redblooded/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	icon_state = "american_aggro"
	GiveTarget(user)

/mob/living/simple_animal/hostile/abnormality/redblooded/MoveToTarget(list/possible_targets)
	if(ranged_cooldown <= world.time)
		OpenFire(target)
	return ..()

/mob/living/simple_animal/hostile/abnormality/redblooded/OpenFire(atom/A)
	if(get_dist(src, A) >= 2)
		if(ammo <= 0)
			to_chat(src, span_warning("Out of ammo!"))
			return FALSE
		else
			ammo -= 1
			return ..()
	else
		return FALSE

//Projectiles
/obj/item/ammo_casing/caseless/true_patriot
	name = "true patriot casing"
	desc = "a true patriot casing"
	projectile_type = /obj/projectile/true_patriot
	pellets = 6
	variance = 25

/obj/projectile/true_patriot
	name = "american pellet"
	desc = "100% real, surplus military ammo."
	damage_type = RED_DAMAGE

	damage = 8

/obj/item/ammo_casing/caseless/rcorp_true_patriot
	name = "true patriot casing"
	desc = "a true patriot casing"
	projectile_type = /obj/projectile/rcorp_true_patriot
	pellets = 6
	variance = 25

/obj/projectile/rcorp_true_patriot
	name = "american pellet"
	desc = "100% real, surplus military ammo."
	damage_type = RED_DAMAGE

	damage = 18

/datum/reagent/abnormality/red_blooded
	name = "Boiling Red Blood"
	description = "Cherry red blood that is constantly boiling. It'll burn going down but it motives you to keep fighting."
	color = "#D2042D"
	health_restore = -1
	sanity_restore = 0.2
	metabolization_rate = 0.8 * REAGENTS_METABOLISM
	stat_changes = list(0, 0, 0, 5) //damages your HP but boosts justice and lightly heals SP.


