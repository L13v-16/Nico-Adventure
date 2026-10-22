extends Node
var current_track:=""
var exploration:AudioStreamWAV
var battle:AudioStreamWAV
var silence:AudioStreamWAV
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	exploration=_theme(false);battle=_theme(true);silence=Sfx._synth(1,0,0,Sfx.Wave.SINE,0,.01,.01)
	silence.loop_mode=AudioStreamWAV.LOOP_FORWARD;silence.loop_end=int(silence.get_length()*silence.mix_rate)
	_update_track()
func _theme(fast:bool) -> AudioStreamWAV:
	var sequence:Array=[]
	var tones:=[146.83,220.0,293.66,261.63,174.61,261.63,349.23,293.66,164.81,246.94,329.63,293.66,130.81,196.0,261.63,220.0]
	for repeat in 4:
		for note in tones:sequence.append([note*(2 if fast and repeat%2 else 1),.18 if fast else .34])
	var stream:AudioStreamWAV=Sfx._sequence(sequence,Sfx.Wave.TRIANGLE,.17 if fast else .1,.015,.09)
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate);return stream
func _process(_delta:float) -> void:_update_track()
func _update_track() -> void:
	var boss:=get_parent().get_node_or_null("Boss")
	var desired:="silence" if boss!=null and boss.dying else ("boss" if boss!=null and boss.active else "lab")
	if desired==current_track:return
	current_track=desired;Sfx.use_scene_music(self,silence if desired=="silence" else (battle if desired=="boss" else exploration))
