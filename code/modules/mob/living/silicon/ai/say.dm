/mob/living/silicon/ai/say(var/message)
	if(parent && istype(parent) && parent.stat != 2)
		parent.say(message)
		return
		//If there is a defined "parent" AI, it is actually an AI, and it is alive, anything the AI tries to say is said by the parent instead.
	..(message)
