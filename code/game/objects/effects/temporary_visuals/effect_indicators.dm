//Small visuals used for indicating damage or healing or similar
/obj/effect/temp_visual/healing
	icon = 'ModularTegustation/Teguicons/lc13_coloreffect.dmi'
	icon_state = "healing"
	layer = ABOVE_ALL_MOB_LAYER
	//duration based on the frames in the sprites.
	duration = 8

/obj/effect/temp_visual/healing/Initialize(mapload)
	. = ..()
	pixel_x = rand(-12, 12)
	pixel_y = rand(-9, 0)

/obj/effect/temp_visual/healing/no_dam
	icon_state = "no_dam"

/obj/effect/temp_visual/healing/charge
	icon_state = "charge"

/obj/effect/temp_visual/damage_effect
	icon = 'ModularTegustation/Teguicons/lc13_coloreffect.dmi'
	layer = ABOVE_ALL_MOB_LAYER
	//Icon state is actually the base icon for intilization

/obj/effect/temp_visual/damage_effect/Initialize(mapload)
	icon_state = "[icon_state][rand(1,2)]"
	pixel_x = rand(-12, 12)
	pixel_y = rand(-9, 9)
	return ..()

/obj/effect/temp_visual/damage_effect/red
	icon_state = "dam_red"

/obj/effect/temp_visual/damage_effect/white
	icon_state = "dam_white"

/obj/effect/temp_visual/damage_effect/black
	icon_state = "dam_black"

/obj/effect/temp_visual/damage_effect/pale
	icon_state = "dam_pale"

/obj/effect/temp_visual/damage_effect/burn
	icon_state = "dam_burn"

/obj/effect/temp_visual/damage_effect/tox
	icon_state = "dam_tox"

/obj/effect/temp_visual/damage_effect/bleed
	icon_state = "dam_bleed"

/obj/effect/temp_visual/damage_effect/tremor
	icon_state = "tremor"

/obj/effect/temp_visual/damage_effect/sinking
	icon_state = "sinking"

/obj/effect/temp_visual/damage_effect/rupture
	icon_state = "rupture"

//Stuntime visual for when you're stunned by your weapon, so you know what happened.
/obj/effect/temp_visual/weapon_stun
	icon = 'ModularTegustation/Teguicons/lc13_coloreffect.dmi'
	icon_state = "stun"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 9

/obj/effect/temp_visual/weapon_stun/tremorburst
	icon_state = "tremorburst"

/obj/effect/temp_visual/area_heal
	name = "large healing aura"
	desc = "A large area of restorative energy."
	icon = 'ModularTegustation/Teguicons/lc13_effects64x64.dmi'
	icon_state = "healarea_fade"
	duration = 15
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	density = FALSE
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	alpha = 200
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
