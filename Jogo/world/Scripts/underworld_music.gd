extends Node
var current_track:=""
var _exploration:AudioStreamWAV
var _battle:AudioStreamWAV
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_exploration=_loop("res://world/Audio/Underworld/hollow_chain_murmurs.wav")
	_battle=_loop("res://world/Audio/Underworld/obsidian_chainbreaker.wav")
	_update_track()
func _loop(path:String) -> AudioStreamWAV:
	var stream:AudioStreamWAV=load(path).duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=int(stream.get_length()*stream.mix_rate)
	return stream
func _process(_delta:float) -> void:_update_track()
func _update_track() -> void:
	var boss:=get_parent().get_node_or_null("Boss")
	var fighting:bool=boss!=null and boss.active and not boss.is_dead()
	var desired:="boss" if fighting else "underworld"
	if desired==current_track:return
	current_track=desired
	Sfx.use_scene_music(self,_battle if fighting else _exploration)
