class_name SongModel
extends RefCounted

var syllables: Array[Dictionary] = []
var lines: Array[String] = []
var line_parts: Array[String] = []
var duration := 0.0
# Time at which the song is cut off (before the final "cut" syllable is sung).
var cut_time := -1.0

func _init(data: Dictionary) -> void:
	var units := 0
	for index in range(data.lines.size()):
		var line: Dictionary = data.lines[index]
		var text := ""
		var syllable_index := 0
		var count: int = line.syllables.size()
		for syllable in line.syllables:
			var start := snappedf(units * data.unit_s, 0.000001)
			var is_cut: bool = line.get("cut_last", false) and syllable_index == count - 1
			if is_cut and cut_time < 0.0:
				cut_time = start
			units += int(syllable[1])
			# Avoid cumulative floating-point drift at karaoke and loop boundaries.
			var end := snappedf(units * data.unit_s, 0.000001)
			var word_end: bool = line.get("word_ends", []).is_empty()
			for boundary in line.get("word_ends", []):
				if syllable_index == int(boundary):
					word_end = true
			syllables.append({"text": syllable[0], "start": start, "end": end, "line": index, "word_end": word_end, "cut": is_cut, "part": line.get("part", "")})
			text += syllable[0] + (" " if word_end else "")
			syllable_index += 1
		lines.append(text.strip_edges())
		line_parts.append(line.get("part", ""))
	duration = snappedf(units * data.unit_s, 0.000001)
	if cut_time >= 0.0:
		duration = snappedf(cut_time + data.get("cut_silence_s", 0.0), 0.000001)

func current(time: float) -> int:
	var wrapped := fposmod(time, duration)
	for index in range(syllables.size()):
		if wrapped >= syllables[index].start and wrapped < syllables[index].end:
			return index
	return syllables.size() - 1

func part_at(time: float) -> String:
	return syllables[current(time)].part
