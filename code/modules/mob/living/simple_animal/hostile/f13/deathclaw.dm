/*IN THIS FILE:
-Deathclaws
*/

//Base Deathclaw
/mob/living/simple_animal/hostile/deathclaw
	name = "deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match."
	icon = 'icons/fallout/mobs/monsters/deathclaw.dmi'
	icon_state = "deathclaw"
	icon_living = "deathclaw"
	icon_dead = "deathclaw_dead"
	icon_gib = "deathclaw_gib"
	maxHealth = 750
	health = 750
	obj_damage = 200
	armour_penetration = 0.6
	melee_damage_lower = 40
	melee_damage_upper = 50
	footstep_type = FOOTSTEP_MOB_HEAVY
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	speed = -1.8//Actual speed handled by move_to_delay
	move_to_delay = 1.8

	gender = MALE
	a_intent = INTENT_HARM //So we can not move past them.
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	robust_searching = TRUE
	speak = list("ROAR!","Rawr!","GRRAAGH!","Growl!")
	speak_emote = list("growls", "roars")
	emote_hear = list("grumbles.","grawls.")
	emote_taunt = list("stares ferociously", "stomps")
	speak_chance = 10
	taunt_chance = 25

	stat_attack = UNCONSCIOUS

	see_in_dark = 8
	decompose = FALSE
	wound_bonus = 0 //This might be a TERRIBLE idea
	bare_wound_bonus = 0
	sharpness = SHARP_EDGED
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/deathclaw = 4,
							/obj/item/stack/sheet/animalhide/deathclaw = 2,
							/obj/item/stack/sheet/bone = 4)
	response_help_simple  = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple   = "hits"
	attack_verb_simple = "claws"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = list("deathclaw")
	gold_core_spawnable = HOSTILE_SPAWN
	move_resist = MOVE_FORCE_OVERPOWERING
	emote_taunt_sound = list('sound/f13npc/deathclaw/taunt.ogg')
	aggrosound = list('sound/f13npc/deathclaw/aggro1.ogg', 'sound/f13npc/deathclaw/aggro2.ogg', )
	idlesound = list('sound/f13npc/deathclaw/idle.ogg',)
	death_sound = 'sound/f13npc/deathclaw/death.ogg'
/*
	var/charging = FALSE
*/
/mob/living/simple_animal/hostile/deathclaw/playable
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = FALSE

// Mother death claw
/mob/living/simple_animal/hostile/deathclaw/mother
	name = "mother deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one is an angry mother."
	icon_state = "deathclaw_mother"
	icon_living = "deathclaw_mother"
	icon_dead = "deathclaw_mother_dead"
	icon_gib = null
	gender = FEMALE
	maxHealth = 800
	health = 800
	stat_attack = UNCONSCIOUS
	melee_damage_lower = 50
	melee_damage_upper = 55
	armour_penetration = 0.7
	footstep_type = FOOTSTEP_MOB_HEAVY
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/deathclaw = 6,
							/obj/item/stack/sheet/animalhide/deathclaw = 3)

/mob/living/simple_animal/hostile/deathclaw/mother/AttackingTarget()
	var/mob/living/M = target
	if(!ishuman(M) || M.health > 20)
		..()
		return

	if(get_dist(src, M) > 0)
		a_intent = INTENT_GRAB
		grab_state = GRAB_NECK
		summon_backup(15)

		start_pulling(M, 1)
		M.grabbedby(src)
		M.drop_all_held_items()
		M.stop_pulling()

		var/obj/item/bodypart/chest/O = M.get_bodypart(BODY_ZONE_CHEST)
		O.force_wound_upwards(/datum/wound/pierce/critical)

		visible_message("<span class='danger'>[src] growls, lifting [M] into the air and violently executing them!</span>")
		to_chat(M, "<span class='userdanger'>[src] lifts you into the air, violently putting an end to your life!</span>")

		M.adjustBruteLoss(100)//Not tanking this without abuse of a specific mechanic. Bypasses armor.

	if(!ishuman(M) || M.health <= 0)
		src.drop_all_held_items()
		src.stop_pulling()

//Legendary Deathclaw
/mob/living/simple_animal/hostile/deathclaw/legendary
	name = "legendary deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one is a legendary enemy."
	maxHealth = 1500
	health = 1500
	color = "#FFFF00"
	stat_attack = UNCONSCIOUS
	melee_damage_lower = 55
	melee_damage_upper = 55
	armour_penetration = 0.8
	footstep_type = FOOTSTEP_MOB_HEAVY
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/deathclaw = 6)

/mob/living/simple_animal/hostile/deathclaw/legendary/Initialize(mapload)
	. = ..()
	if(prob(37))
		guaranteed_butcher_results = list(/obj/item/melee/unarmed/deathclawgauntlet = 1)

/mob/living/simple_animal/hostile/deathclaw/legendary/AttackingTarget()
	var/mob/living/M = target
	if(!ishuman(M) || M.health > 20)
		..()
		return

	if(get_dist(src, M) > 0)
		a_intent = INTENT_GRAB
		grab_state = GRAB_NECK
		summon_backup(15)

		start_pulling(M, 1)
		M.grabbedby(src)
		M.drop_all_held_items()
		M.stop_pulling()

		var/obj/item/bodypart/chest/O = M.get_bodypart(BODY_ZONE_CHEST)
		O.force_wound_upwards(/datum/wound/pierce/critical)

		visible_message("<span class='danger'>[src] growls, lifting [M] into the air and violently executing them!</span>")
		to_chat(M, "<span class='userdanger'>[src] lifts you into the air, violently putting an end to your life!</span>")

		M.adjustBruteLoss(100)//Not tanking this without abuse of a specific mechanic. Bypasses armor.

	if(!ishuman(M) || M.health <= 0)
		src.drop_all_held_items()
		src.stop_pulling()

//Power Armor Deathclaw the tankest and the scariest deathclaw in the West. One mistake will end you. May the choice be with you.
/mob/living/simple_animal/hostile/deathclaw/power_armor
	name = "power armored deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. Someone had managed to put power armor on him."
	icon_state = "combatclaw"
	icon_living = "combatclaw"
	icon_dead = "combatclaw_dead"
	maxHealth = 2500
	health = 2500
	stat_attack = UNCONSCIOUS
	melee_damage_lower = 70
	melee_damage_upper = 80
	armour_penetration = 0.9
	footstep_type = FOOTSTEP_MOB_HEAVY


/mob/living/simple_animal/hostile/deathclaw/power_armor/AttackingTarget()
	var/mob/living/M = target
	if(!ishuman(M) || M.health > 20)
		..()
		return

	if(get_dist(src, M) > 0)
		a_intent = INTENT_GRAB
		grab_state = GRAB_NECK
		summon_backup(15)

		start_pulling(M, 1)
		M.grabbedby(src)
		M.drop_all_held_items()
		M.stop_pulling()

		var/obj/item/bodypart/chest/O = M.get_bodypart(BODY_ZONE_CHEST)
		O.force_wound_upwards(/datum/wound/pierce/critical)

		visible_message("<span class='danger'>[src] growls, lifting [M] into the air and violently executing them!</span>")
		to_chat(M, "<span class='userdanger'>[src] lifts you into the air, violently putting an end to your life!</span>")

		M.adjustBruteLoss(100)//Not tanking this without abuse of a specific mechanic. Bypasses armor.

	if(!ishuman(M) || M.health <= 0)
		src.drop_all_held_items()
		src.stop_pulling()
/*
/mob/living/simple_animal/hostile/deathclaw/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return
	if(prob(10))
		visible_message(span_danger("\The [src] growls, enraged!"))

		addtimer(CALLBACK(src, .proc/Charge), 3)
	if(prob(85) || Proj.damage > 30) //prob(x) = chance for proj to actually do something, adjust depending on how OP you want deathclaws to be
		return ..()
	else
		visible_message(span_danger("\The [Proj] bounces off \the [src]'s thick hide!"))
		return 0

/mob/living/simple_animal/hostile/deathclaw/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/deathclaw/AttackingTarget()
	if(!charging)
		return ..()

/mob/living/simple_animal/hostile/deathclaw/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/deathclaw/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	. = ..()
	if(charging)
		DestroySurroundings()

/mob/living/simple_animal/hostile/deathclaw/proc/Charge()
	var/turf/T = get_turf(target)
	if(!T || T == loc)
		return
	charging = TRUE
	visible_message(span_danger(">[src] charges!"))
	DestroySurroundings()
	walk(src, 0)
	setDir(get_dir(src, T))
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 1)
	throw_at(T, get_dist(src, T), 1, src, 0, callback = CALLBACK(src, .proc/charge_end))

/mob/living/simple_animal/hostile/deathclaw/proc/charge_end(list/effects_to_destroy)
	charging = FALSE
	if(target)
		Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/deathclaw/Bump(atom/A)
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			A.ex_act(EXPLODE_HEAVY)
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/deathclaw/throw_impact(atom/A)
	if(!charging)
		return ..()

	else if(isliving(A))
		var/mob/living/L = A
		L.visible_message(span_danger("[src] slams into [L]!"), span_userdanger("[src] slams into you!"))
		L.apply_damage(melee_damage_lower/2, BRUTE)
		playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 3)


	charging = FALSE
	charging = FALSE
*/
