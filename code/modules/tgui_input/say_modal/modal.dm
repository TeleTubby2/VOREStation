/** Assigned say modal of the client */
/client/var/datum/tgui_say/tgui_say

/**
 * Creates a JSON encoded message to open TGUI say modals properly.
 *
 * Arguments:
 * channel - The channel to open the modal in.
 * Returns:
 * string - A JSON encoded message to open the modal.
 */
/client/proc/tgui_say_create_open_command(channel)
	var/message = TGUI_CREATE_MESSAGE("open", list(
		channel = channel,
	))
	return "\".output tgui_say.browser:update [message]\""

/**
 * The tgui say modal. This initializes an input window which hides until
 * the user presses one of the speech hotkeys. Once something is entered, it will
 * delegate the speech to the proper channel.
 */
/datum/tgui_say
	/// The user who opened the window
	var/client/client
	/// Injury phrases to blurt out
	var/list/hurt_phrases = list("GACK!", "GLORF!", "OOF!", "AUGH!", "OW!", "URGH!", "HRNK!")
	/// Max message length
	var/max_length = MAX_MESSAGE_LEN
	/// The modal window
	var/datum/tgui_window/window
	/// Boolean for whether the tgui_say was opened by the user.
	var/window_open
	/// Any partial packets that we have received from TGUI, waiting to be sent
	var/partial_packets

/** Creates the new input window to exist in the background. */
/datum/tgui_say/New(client/client, id)
	src.client = client
	window = new(client, id)
	winset(client, "tgui_say", "size=1,1;is-visible=0;")
	window.subscribe(src, PROC_REF(on_message))
	window.is_browser = TRUE

/**
 * After a brief period, injects the scripts into
 * the window to listen for open commands.
 */
/datum/tgui_say/proc/initialize()
	set waitfor = FALSE
	// Sleep to defer initialization to after client constructor
	sleep(3 SECONDS)
	window.initialize(
			strict_mode = TRUE,
			fancy = TRUE,
			inline_css = file("tgui/public/tgui-say.bundle.css"),
			inline_js = file("tgui/public/tgui-say.bundle.js"),
	);

/**
 * Ensures nothing funny is going on window load.
 * Minimizes the window, sets max length, closes all
 * typing and thinking indicators. This is triggered
 * as soon as the window sends the "ready" message.
 */
/datum/tgui_say/proc/load()
	window_open = FALSE

	var/minimum_width = client?.prefs?.read_preference(/datum/preference/numeric/tgui_say_width) || 1
	var/minimum_height = (client?.prefs?.read_preference(/datum/preference/numeric/tgui_say_height) || 1) * 20 + 10
	winset(client, "tgui_say", "pos=410,400;is-visible=0;")

	window.send_message("props", list(
		"lightMode" = client?.prefs?.read_preference(/datum/preference/toggle/tgui_say_light),
		"scale" = client.prefs?.read_preference(/datum/preference/toggle/ui_scale),
		"minimumWidth" = minimum_width,
		"minimumHeight" = minimum_height,
		"maxLength" = max_length,
	))

	stop_thinking()
	return TRUE

/**
 * Sets the window as "opened" server side, though it is already
 * visible to the user. We do this to set local vars &
 * start typing (if enabled and in an IC channel). Logs the event.
 *
 * Arguments:
 * payload - A list containing the channel the window was opened in.
 */
/datum/tgui_say/proc/open(payload)
	if(!payload?["channel"])
		CRASH("No channel provided to an open TGUI-Say")
	window_open = TRUE
	if(payload["channel"] != OOC_CHANNEL && payload["channel"] != ADMIN_CHANNEL)
		start_thinking()
	return TRUE

/**
 * Closes the window serverside. Closes any open chat bubbles
 * regardless of preference. Logs the event.
 */
/datum/tgui_say/proc/close()
	window_open = FALSE
	stop_thinking()

/**
 * The equivalent of ui_act, this waits on messages from the window
 * and delegates actions.
 */
/datum/tgui_say/proc/on_message(type, payload, href_list)
	if(type == "ready")
		load()
		return TRUE
	if(type == "open")
		open(payload)
		return TRUE
	if(type == "close")
		close()
		return TRUE
	if(type == "thinking")
		if(payload["visible"] == TRUE)
			start_thinking(payload["channel"])
			return TRUE
		if(payload["visible"] == FALSE)
			stop_thinking(payload["channel"])
			return TRUE
		return FALSE
	if(type == "typing")
		start_typing(payload["channel"])
		return TRUE
	if(type == "entry" || type == "force")
		var/id = href_list["packetId"]
		if(!isnull(id))
			id = text2num(id)

			var/total = text2num(href_list["totalPackets"])
			if(id == 1)
				if(total > MAX_MESSAGE_CHUNKS)
					return

				partial_packets = new /list(total)

			partial_packets[id] = href_list["packet"]

			if(id != total)
				return

			var/assembled_payload = ""
			for(var/packet in partial_packets)
				assembled_payload += packet

			payload = json_decode(assembled_payload)
			partial_packets = null
		handle_entry(type, payload)
		return TRUE
	if(type == "lenwarn")
		var/mlen = payload["length"]
		var/maxlen = payload["maxlength"]
		to_chat(client, span_warning(span_bold("Warning") + ": Message with [mlen] exceeded the maximum length of [maxlen]."))
	return FALSE
