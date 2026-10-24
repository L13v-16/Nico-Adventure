extends "res://world/Scripts/lab_music.gd"
func _exploration_path() -> String:return "res://world/Audio/Corporation/corporate_cage_rift.wav"
func _battle_path() -> String:return "res://world/Audio/Corporation/forged_in_steel_storm.wav"
func _update_track() -> void:
	var boss:=get_parent().get_node_or_null("Boss")
	var fighting:bool=boss!=null and not boss.dead and (boss.active or boss.phase>1)
	var desired:="boss" if fighting else "corporation"
	if desired==current_track:return
	current_track=desired;Sfx.use_scene_music(self,battle if desired=="boss" else exploration)
