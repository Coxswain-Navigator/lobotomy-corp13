
/mob/living/brain/Life()
	if (notransform)
		return
	if(!loc)
		return
	. = ..()
	handle_emp_damage()

/mob/living/brain/update_stat()
	if(status_flags & GODMODE)
		return
	if(health <= death_threshold)
		if(stat != DEAD)
			death()
		var/obj/item/organ/brain/BR
		if(container?.brain)
			BR = container.brain
		else if(istype(loc, /obj/item/organ/brain))
			BR = loc
		if(BR)
			BR.damage = BRAIN_DAMAGE_DEATH //beaten to a pulp

/mob/living/brain/proc/handle_emp_damage()
	if(emp_damage)
		if(stat == DEAD)
			emp_damage = 0
		else
			emp_damage = max(emp_damage-1, 0)

/mob/living/brain/handle_status_effects()
	return

/mob/living/brain/handle_traits()
	return



