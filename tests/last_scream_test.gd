extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	var finale := LastScream.new()
	add_child(finale)
	finale.set_process(false)
	assert(finale.phase == "roar" and finale.intro_black.color.a == 1)
	finale._process(7)
	assert(finale.phase == "roar")
	finale._process(0.6)
	assert(finale.phase == "auto_scream" and finale.scream_played)
	finale._process(0.9)
	assert(finale.intro_black.color.a < 1)
	finale._process(1)
	assert(finale.phase == "player_light" and finale.intro_black.color.a == 1)
	assert(finale.scream_bar.visible)
	VoiceInput.is_audible = true
	VoiceInput.is_shouting = false
	VoiceInput.level01 = 0.4
	finale._process(4)
	assert(finale.light_reveal == 0 and finale.intro_black.color.a == 1)
	VoiceInput.is_shouting = true
	VoiceInput.level01 = 1
	finale._process(3)
	assert(finale.light_reveal > 0 and finale.light_reveal < 1)
	assert(finale.intro_black.color.a > 0)
	finale._process(3)
	assert(finale.phase == "invitation")
	finale._process(2)
	assert(finale.caption.text.length() > 0 and finale.caption.text.length() < finale.invitation.length())
	finale._process(5.1)
	assert(finale.phase == "voice" and finale.taunt_cloud.size() == 8)
	for i in range(3):
		VoiceInput.is_audible = true
		VoiceInput.is_shouting = true
		finale._process(2.3)
		assert(finale.phase == "reply" and finale.caption.text == finale.replies[i])
		VoiceInput.is_audible = false
		VoiceInput.is_shouting = false
		finale._process(3.3)
	assert(finale.phase == "white")
	finale._process(3.6)
	assert(finale.phase == "wake")
	assert(finale.dream_ending != null and finale.dream_ending.phase == "wake")
	finale.dream_ending.set_process(false)
	finale.dream_ending._process(1.4)
	assert(finale.dream_ending.subtitle.text == "It is just a dream..")
	print("V5 finale: sustained roars, automatic cry/reblack, player-powered gradual light, slow invitation, waves and ending passed")
	get_tree().quit()
