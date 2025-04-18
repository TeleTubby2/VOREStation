/obj/item/assembly/signaler
	name = "remote signaling device"
	desc = "Used to remotely activate devices.  Tap against another secured signaler to transfer configuration."
	icon_state = "signaller"
	item_state = "signaler"
	origin_tech = list(TECH_MAGNET = 1)
	matter = list(MAT_STEEL = 1000, MAT_GLASS = 200)
	wires = WIRE_RECEIVE | WIRE_PULSE | WIRE_RADIO_PULSE | WIRE_RADIO_RECEIVE

	secured = TRUE

	var/code = 30
	var/frequency = 1457
	var/delay = 0
	var/airlock_wire = null
	var/datum/wires/connected = null
	var/datum/radio_frequency/radio_connection
	var/deadman = FALSE

/obj/item/assembly/signaler/Initialize(mapload)
	. = ..()
	set_frequency(frequency)

/obj/item/assembly/signaler/activate()
	if(!process_cooldown())
		return FALSE
	signal()
	return TRUE

/obj/item/assembly/signaler/update_icon()
	if(holder)
		holder.update_icon()

/obj/item/assembly/signaler/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Signaler", name)
		ui.open()

/obj/item/assembly/signaler/tgui_data(mob/user)
	var/list/data = list()
	data["frequency"] = frequency
	data["code"] = code
	data["minFrequency"] = RADIO_LOW_FREQ
	data["maxFrequency"] = RADIO_HIGH_FREQ
	return data

/obj/item/assembly/signaler/tgui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("signal")
			INVOKE_ASYNC(src, PROC_REF(signal))
			. = TRUE
		if("freq")
			frequency = unformat_frequency(params["freq"])
			frequency = sanitize_frequency(frequency, RADIO_LOW_FREQ, RADIO_HIGH_FREQ)
			set_frequency(frequency)
			. = TRUE
		if("code")
			code = text2num(params["code"])
			code = clamp(round(code), 1, 100)
			. = TRUE
		if("reset")
			if(params["reset"] == "freq")
				set_frequency(initial(frequency))
			else
				code = initial(code)
			. = TRUE

	update_icon()

/obj/item/assembly/signaler/attackby(var/obj/item/W, mob/user, params)
	if(issignaler(W))
		var/obj/item/assembly/signaler/signaler2 = W
		if(secured && signaler2.secured)
			code = signaler2.code
			set_frequency(signaler2.frequency)
			to_chat(user, "You transfer the frequency and code of [signaler2] to [src].")
	else
		..()

/obj/item/assembly/signaler/proc/signal()
	if(!radio_connection)
		return
	if(is_jammed(src))
		return

	var/datum/signal/signal = new
	signal.source = src
	signal.encryption = code
	signal.data["message"] = "ACTIVATE"
	radio_connection.post_signal(src, signal)

/obj/item/assembly/signaler/pulse(var/radio = 0)
	if(is_jammed(src))
		return FALSE
	if(connected && wires)
		connected.pulse_assembly(src)
	else if(holder)
		holder.process_activation(src, 1, 0)
	else
		..(radio)
	return TRUE

/obj/item/assembly/signaler/receive_signal(datum/signal/signal)
	if(!signal)
		return FALSE
	if(signal.encryption != code)
		return FALSE
	if(!(src.wires & WIRE_RADIO_RECEIVE))
		return FALSE
	if(is_jammed(src))
		return FALSE
	pulse(1)

	if(!holder)
		for(var/mob/O in hearers(1, src.loc))
			O.show_message("[icon2html(src, O.client)] *beep* *beep*", 3, "*beep* *beep*", 2)

/obj/item/assembly/signaler/proc/set_frequency(new_frequency)
	if(!frequency)
		return
	if(!radio_controller)
		addtimer(CALLBACK(src, PROC_REF(radio_checkup), new_frequency), 2 SECONDS)
		return
	set_radio(new_frequency)

/obj/item/assembly/signaler/proc/radio_checkup(new_frequency)
	PROTECTED_PROC(TRUE)
	if(!radio_controller)
		return
	set_radio(new_frequency)


/obj/item/assembly/signaler/proc/set_radio(new_frequency)
	PROTECTED_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, RADIO_CHAT)

/obj/item/assembly/signaler/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	frequency = 0
	. = ..()
