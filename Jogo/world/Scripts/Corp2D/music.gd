extends "res://world/Scripts/lab_music.gd"
func _update_track() -> void:
	var boss:=get_parent().get_node_or_null("Boss")
	var desired:="boss" if boss!=null and boss.active else "corporation"
	if desired==current_track:return
	current_track=desired;Sfx.use_scene_music(self,battle if desired=="boss" else exploration)
