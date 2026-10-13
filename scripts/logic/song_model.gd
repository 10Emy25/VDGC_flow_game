class_name SongModel
extends RefCounted

var syllables: Array[Dictionary] = []
var lines: Array[String] = []
var duration := 0.0

func _init(data: Dictionary) -> void:
	var units := 0
	for index in range(data.lines.size()):
		var text := ""
		var syllable_index := 0
		for syllable in data.lines[index].syllables:
			var start := duration
			units += int(syllable[1])
			# Avoid cumulative floating-point drift at karaoke and loop boundaries.
			duration = snappedf(units * data.unit_s, 0.000001)
			var word_end: bool = data.lines[index].get("word_ends", []).is_empty()
			for boundary in data.lines[index].get("word_ends", []):
				if syllable_index == int(boundary):
					word_end = true
			syllables.append({"text": syllable[0], "start": start, "end": duration, "line": index, "word_end": word_end})
			text += syllable[0] + (" " if word_end else "")
			syllable_index += 1
		lines.append(text.strip_edges())

func current(time: float) -> int:
	var wrapped := fposmod(time, duration)
	for index in range(syllables.size()):
		if wrapped >= syllables[index].start and wrapped < syllables[index].end:
			return index
	return 0
