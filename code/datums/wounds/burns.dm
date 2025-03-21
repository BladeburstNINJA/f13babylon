

// TODO: well, a lot really, but specifically I want to add potential fusing of clothing/equipment on the affected area, and limb infections, though those may go in body part code
/datum/wound/burn
	a_or_from = "from"
	wound_type = WOUND_BURN
	processes = TRUE
	sound_effect = 'sound/effects/wounds/sizzle1.ogg'
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE)

	treatable_by = list(/obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh) // sterilizer and alcohol will require reagent treatments, coming soon

		// Flesh damage vars
	/// How much damage to our flesh we currently have. Once both this and infestation reach 0, the wound is considered healed
	var/flesh_damage = 5
	/// Our current counter for how much flesh regeneration we have stacked from regenerative mesh/synthflesh/whatever, decrements each tick and lowers flesh_damage
	var/flesh_healing = 0

		// Infestation vars (only for severe and critical)
	/// How quickly infection breeds on this burn if we don't have disinfectant
	var/infestation_rate = 0
	/// Our current level of infection
	var/infestation = 0
	/// Our current level of sanitization/anti-infection, from disinfectants/alcohol/UV lights. While positive, totally pauses and slowly reverses infestation effects each tick
	var/sanitization = 0

	/// Once we reach infestation beyond WOUND_INFESTATION_SEPSIS, we get this many warnings before the limb is completely paralyzed (you'd have to ignore a really bad burn for a really long time for this to happen)
	var/strikes_to_lose_limb = 3


/datum/wound/burn/handle_process()
	. = ..()
	if(strikes_to_lose_limb == 0)
		if(prob(1))
			victim.visible_message("<span class='danger'>The infection on the remnants of [victim]'s [limb.name] shift and bubble nauseatingly!</span>", "<span class='warning'>You can feel the infection on the remnants of your [limb.name] coursing through your veins!</span>")
		return

	if(victim.reagents)
		if(victim.reagents.has_reagent(/datum/reagent/medicine/spaceacillin))
			sanitization += 7
		if(victim.reagents.has_reagent(/datum/reagent/abraxo_cleaner/sterilizine) || victim.reagents.has_reagent(/datum/reagent/consumable/ethanol))
			sanitization += 5
			flesh_healing -= 2 //Rubbing alcohol onto fresh burns will make it worse, but sterile
		if(victim.reagents.has_reagent(/datum/reagent/medicine/mine_salve))
			sanitization += 4
			flesh_healing += 1

	if(limb.current_gauze)
		limb.seep_gauze(WOUND_BURN_SANITIZATION_RATE)

	if(flesh_healing > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		flesh_damage = max(0, flesh_damage - 2)
		flesh_healing = max(0, flesh_healing - bandage_factor) // good bandages multiply the length of flesh healing

	// here's the check to see if we're cleared up
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>The burns on your [limb.name] have cleared up!</span>")
		qdel(src)
		return

	// sanitization is checked after the clearing check but before the rest, because we freeze the effects of infection while we have sanitization
	if(sanitization > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE)
		sanitization = max(0, sanitization - (WOUND_BURN_SANITIZATION_RATE * bandage_factor))
		return

	infestation += infestation_rate

	switch(infestation)
		if(0 to WOUND_INFECTION_MODERATE)
		if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
			if(prob(30))
				victim.adjustToxLoss(0.2)
				if(prob(6))
					to_chat(victim, "<span class='warning'>The blisters on your [limb.name] ooze a strange pus...</span>")
		if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
			if(!disabling && prob(2))
				to_chat(victim, "<span class='warning'><b>Your [limb.name] completely locks up, as you struggle for control against the infection!</b></span>")
				disabling = TRUE
			else if(disabling && prob(8))
				to_chat(victim, "<span class='notice'>You regain sensation in your [limb.name], but it's still in terrible shape!</span>")
				disabling = FALSE
			else if(prob(20))
				victim.adjustToxLoss(0.5)
		if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
			if(!disabling && prob(3))
				to_chat(victim, "<span class='warning'><b>You suddenly lose all sensation of the festering infection in your [limb.name]!</b></span>")
				disabling = TRUE
			else if(disabling && prob(3))
				to_chat(victim, "<span class='notice'>You can barely feel your [limb.name] again, and you have to strain to retain motor control!</span>")
				disabling = FALSE
			else if(prob(1))
				to_chat(victim, "<span class='warning'>You contemplate life without your [limb.name]...</span>")
				victim.adjustToxLoss(0.75)
			else if(prob(4))
				victim.adjustToxLoss(1)
		if(WOUND_INFECTION_SEPTIC to INFINITY)
			victim.adjustToxLoss(0.5) //When the infection is septic, toxin damage isn't a roll of the dice anymore, it's happening.
			if(limb.body_zone == BODY_ZONE_HEAD || limb.body_zone == BODY_ZONE_CHEST) //These limbs will never be permanently destroyed, but they've got vital organs. When they reach septic level, they deal more tox damage.
				victim.adjustToxLoss(1)
				return
			if(prob(infestation))
				switch(strikes_to_lose_limb)
					if(3 to INFINITY)
						to_chat(victim, "<span class='deadsay'>The skin on your [limb.name] is literally dripping off, you feel awful!</span>")
					if(2)
						to_chat(victim, "<span class='deadsay'><b>The infection in your [limb.name] is literally dripping off, you feel horrible!</b></span>")
					if(1)
						to_chat(victim, "<span class='deadsay'><b>Infection has just about completely claimed your [limb.name]!</b></span>")
					if(0)
						to_chat(victim, "<span class='deadsay'><b>The last of the nerve endings in your [limb.name] wither away, as the infection completely paralyzes your joint connector.</b></span>")
						threshold_penalty = 120 // piss easy to destroy
						var/datum/brain_trauma/severe/paralysis/sepsis = new (limb.body_zone)
						victim.gain_trauma(sepsis)
				strikes_to_lose_limb--

/datum/wound/burn/get_examine_description(mob/user)
	if(strikes_to_lose_limb <= 0)
		return "<span class='deadsay'><B>[victim.p_their(TRUE)] [limb.name] is completely dead and unrecognizable as organic.</B></span>"

	var/list/condition = list("[victim.p_their(TRUE)] [limb.name] [examine_desc]")
	if(limb.current_gauze)
		var/bandage_condition
		switch(limb.current_gauze.absorption_capacity)
			if(0 to 1.25)
				bandage_condition = "pus-soaked "
			if(1.25 to 2.75)
				bandage_condition = "badly pus-stained "
			if(2.75 to 4)
				bandage_condition = "slightly pus-stained "
			if(4 to INFINITY)
				bandage_condition = "clean "

		condition += " underneath a dressing of [bandage_condition] [limb.current_gauze.name]"
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				condition += ", <span class='deadsay'>with small spots of discoloration along the nearby veins!</span>"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				condition += ", <span class='deadsay'>with dark clouds spreading outwards under the skin!</span>"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				condition += ", <span class='deadsay'>with streaks of rotten infection pulsating outward!</span>"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				return "<span class='deadsay'><B>[victim.p_their(TRUE)] [limb.name] is a mess of char and rot, skin literally dripping off the bone with infection!</B></span>"
			else
				condition += "!"

	return "<B>[condition.Join()]</B>"

/datum/wound/burn/get_scanner_description(mob/user)
	if(strikes_to_lose_limb == 0)
		var/oopsie = "Type: [name]\nSeverity: [severity_text()]"
		oopsie += "<div class='ml-3'>Infection Level: <span class='deadsay'>The infection is total. The bodypart is lost. Amputate or augment limb immediately.</span></div>"
		return oopsie

	. = ..()
	. += "<div class='ml-3'>"

	if(infestation <= sanitization && flesh_damage <= flesh_healing)
		. += "No further treatment required: Burns will heal shortly."
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				. += "Infection Level: Moderate\n"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				. += "Infection Level: Severe\n"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				. += "Infection Level: <span class='deadsay'>CRITICAL</span>\n"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				. += "Infection Level: <span class='deadsay'>LOSS IMMINENT</span>\n"
		if(infestation > sanitization)
			. += "\tSurgery will remove infection. Antibiotics like penicillin or miner's salve will remove infection. The burn must be treated separately with synthflesh, regenerative mesh, and ointment.\n"

		if(flesh_damage > 0)
			. += "Flesh damage detected: Please apply ointment or regenerative mesh to allow recovery.\n"
	. += "</div>"

/*
	new burn common procs
*/

/// if someone is using ointment on our burns
/datum/wound/burn/proc/ointment(obj/item/stack/medical/ointment/I, mob/user)
	user.visible_message("<span class='notice'>[user] begins applying [I] to [victim]'s [limb.name]...</span>", "<span class='notice'>You begin applying [I] to [user == victim ? "your" : "[victim]'s"] [limb.name]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), extra_checks = CALLBACK(src, .proc/still_exists)))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] applies [I] to [victim].</span>", "<span class='green'>You apply [I] to [user == victim ? "your" : "[victim]'s"] [limb.name].</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration
	infestation -= I.sanitization * 0.05

	if((infestation <= 0 || sanitization >= infestation) && (flesh_damage <= 0 || flesh_healing > flesh_damage))
		to_chat(user, "<span class='notice'>You've done all you can with [I], now you must wait for the flesh on [victim]'s [limb.name] to recover.</span>")
	else
		try_treating(I, user)

/// if someone is using mesh on our burns
/datum/wound/burn/proc/mesh(obj/item/stack/medical/mesh/I, mob/user)
	user.visible_message("<span class='notice'>[user] begins wrapping [victim]'s [limb.name] with [I]...</span>", "<span class='notice'>You begin wrapping [user == victim ? "your" : "[victim]'s"] [limb.name] with [I]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), target=victim, extra_checks = CALLBACK(src, .proc/still_exists)))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] applies [I] to [victim].</span>", "<span class='green'>You apply [I] to [user == victim ? "your" : "[victim]'s"] [limb.name].</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration
	infestation -= I.sanitization * 0.2

	if(sanitization >= infestation && flesh_healing > flesh_damage)
		to_chat(user, "<span class='notice'>You've done all you can with [I], now you must wait for the flesh on [victim]'s [limb.name] to recover.</span>")
	else
		try_treating(I, user)

/// Paramedic UV penlights
/datum/wound/burn/proc/uv(obj/item/flashlight/pen/paramedic/I, mob/user)
	if(!COOLDOWN_FINISHED(I, uv_cooldown))
		to_chat(user, "<span class='notice'>[I] is still recharging!</span>")
		return
	if(infestation <= 0 || infestation < sanitization)
		to_chat(user, "<span class='notice'>There's no infection to treat on [victim]'s [limb.name]!</span>")
		return

	user.visible_message("<span class='notice'>[user] flashes the burns on [victim]'s [limb] with [I].</span>", "<span class='notice'>You flash the burns on [user == victim ? "your" : "[victim]'s"] [limb.name] with [I].</span>", vision_distance=COMBAT_MESSAGE_RANGE)
	sanitization += I.uv_power
	COOLDOWN_START(I, uv_cooldown, I.uv_cooldown_length)

/datum/wound/burn/treat(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/medical/ointment))
		ointment(I, user)
	else if(istype(I, /obj/item/stack/medical/mesh))
		mesh(I, user)
	else if(istype(I, /obj/item/flashlight/pen/paramedic))
		uv(I, user)

// people complained about burns not healing on stasis beds, so in addition to checking if it's cured, they also get the special ability to very slowly heal on stasis beds if they have the healing effects stored
/datum/wound/burn/on_stasis()
	. = ..()
	if(flesh_healing > 0)
		flesh_damage = max(0, flesh_damage - 0.2)
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>The burns on your [limb.name] have cleared up!</span>")
		qdel(src)
		return
	if(sanitization > 0)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE * 0.2)

/datum/wound/burn/on_synthflesh(amount)
	flesh_healing += amount * 2 // 20u patch will heal 40 flesh standard

// we don't even care about first degree burns, straight to second
/datum/wound/burn/moderate
	name = "Second Degree Burns"
	desc = "Patient is suffering considerable burns with mild skin penetration, weakening limb integrity and increased burning sensations."
	treat_text = "Apply penicillin, miner's salve, abraxo cleaner to clear infection, and use bandages, synthetic flesh, ointment, or regenerative mesh to heal the damaged tissue."
	examine_desc = "is badly burned and breaking out in blisters"
	occur_text = "breaks out with violent red burns"
	severity = WOUND_SEVERITY_MODERATE
	damage_mulitplier_penalty = 1.05
	threshold_minimum = 50
	threshold_penalty = 30 // burns cause significant decrease in limb integrity compared to other wounds
	status_effect_type = /datum/status_effect/wound/burn/moderate
	flesh_damage = 5
	scar_keyword = "burnmoderate"

/datum/wound/burn/severe
	name = "Third Degree Burns"
	desc = "Patient is suffering extreme burns with full skin penetration, creating serious risk of infection and greatly reduced limb integrity."
	treat_text = "Apply penicillin, miner's salve, abraxo cleaner to clear infection, and use bandages, synthetic flesh, ointment, or regenerative mesh to heal the damaged tissue. Surgery will help treat infection, but not the burn itself."
	examine_desc = "appears seriously charred, with aggressive red splotches"
	occur_text = "chars rapidly, exposing ruined tissue and spreading angry red burns"
	severity = WOUND_SEVERITY_SEVERE
	damage_mulitplier_penalty = 1.1
	threshold_minimum = 90
	threshold_penalty = 40
	status_effect_type = /datum/status_effect/wound/burn/severe
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.05 // appx 13 minutes to reach sepsis without any treatment
	flesh_damage = 10.5
	scar_keyword = "burnsevere"

/datum/wound/burn/critical
	name = "Catastrophic Burns"
	desc = "Patient is suffering near complete loss of tissue and significantly charred muscle and bone, creating life-threatening risk of infection and negligible limb integrity."
	treat_text = "Use surgery to treat infection, followed by penicillin, miner's salve, or abraxo. Ointment and regenerative mesh will treat both tissue damage and infection, and synthetic flesh will treat burn."
	examine_desc = "is a ruined mess of blanched bone, melted fat, and charred tissue"
	occur_text = "vaporizes as flesh, bone, and fat melt together in a horrifying mess"
	severity = WOUND_SEVERITY_CRITICAL
	damage_mulitplier_penalty = 1.15
	sound_effect = 'sound/effects/wounds/sizzle2.ogg'
	threshold_minimum = 150
	threshold_penalty = 80
	status_effect_type = /datum/status_effect/wound/burn/critical
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.10 // appx 4.33 minutes to reach sepsis without any treatment
	flesh_damage = 20
	scar_keyword = "burncritical"
