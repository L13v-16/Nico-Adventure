extends Node
## Keyboard preferences are independent of progress, audio and menu navigation.
signal changed
const PATH="user://controls.cfg"
const ROWS=[
	["move_left","Esquerda","Movimento 2D",[KEY_A,KEY_LEFT],"2d"],
	["move_right","Direita","Movimento 2D",[KEY_D,KEY_RIGHT],"2d"],
	["jump","Pular","Movimento 2D",[KEY_SPACE,KEY_W],"2d"],
	["climb_up","Subir corrente","Movimento 2D",[KEY_UP],"2d"],
	["climb_down","Descer corrente","Movimento 2D",[KEY_DOWN],"2d"],
	["lab3d_left","Esquerda","Laboratório 3D",[KEY_A,KEY_LEFT],"3d"],
	["lab3d_right","Direita","Laboratório 3D",[KEY_D,KEY_RIGHT],"3d"],
	["lab3d_forward","Avançar","Laboratório 3D",[KEY_W,KEY_UP],"3d"],
	["lab3d_back","Recuar","Laboratório 3D",[KEY_S,KEY_DOWN],"3d"],
	["lab3d_jump","Pulo / pulo duplo","Laboratório 3D",[KEY_SPACE],"3d"],
	["lab3d_boost","Deslizar / queda 1","Laboratório 3D",[KEY_SHIFT],"3d"],
	["lab3d_dodge","Deslizar / queda 2","Laboratório 3D",[KEY_CTRL],"3d"],
	["attack","Atacar / giro","Ações",[KEY_J,KEY_X],"both"],
	["interagir","Interagir / cipó","Ações",[KEY_E],"both"],
	["element_cast","Lançar poder","Ações",[KEY_K],"both"],
	["element_swap","Trocar fogo / gelo","Ações",[KEY_Q],"both"],
	["jose_command","Cabeçada de José","Ações",[KEY_C],"2d"],
	["lab_throw","Arremessar soro","Ações",[KEY_F],"both"],
	["inventory","Mochila","Ações",[KEY_I],"both"],
	["restart_checkpoint","Voltar ao checkpoint (2D)","Ações",[KEY_R],"2d"],
	["pause_game","Pausar","Ações",[KEY_ESCAPE],"both"]]
var bindings:Dictionary={}
var _extras:Dictionary={}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for row:Array in ROWS:
		var action:String=row[0];_extras[action]=[]
		var source:String={"move_left":"ui_left","move_right":"ui_right","climb_up":"ui_up","climb_down":"ui_down","jump":"ui_accept"}.get(action,action)
		if InputMap.has_action(source):
			for event:InputEvent in InputMap.action_get_events(source):
				if not event is InputEventKey:_extras[action].append(event.duplicate())
		if not InputMap.has_action(action):InputMap.add_action(action)
	reload_saved()
func defaults() -> Dictionary:
	var result:Dictionary={}
	for row:Array in ROWS:result[row[0]]=row[3].duplicate()
	return result
func reload_saved() -> void:
	bindings=defaults();var config:=ConfigFile.new()
	if config.load(PATH)==OK:
		for row:Array in ROWS:
			var codes:Variant=config.get_value("keyboard",row[0],bindings[row[0]])
			if not codes is Array or codes.size()<1 or codes.size()>2:continue
			var valid:=true
			for code:Variant in codes:
				if not code is int or not _valid_key(code):valid=false
			if valid and (codes.size()==1 or codes[0]!=codes[1]):bindings[row[0]]=codes.duplicate()
	for action:String in bindings:
		for code:int in bindings[action]:
			if not conflict(action,code).is_empty():bindings=defaults();break
	_apply();changed.emit()
func _valid_key(code:int) -> bool:return code>0 and not OS.get_keycode_string(code).is_empty() and code not in [KEY_ALT,KEY_META]
func _apply() -> void:
	for row:Array in ROWS:
		var action:String=row[0];Input.action_release(action);InputMap.action_erase_events(action)
		for code:int in bindings[action]:
			var event:=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(action,event)
		for event:InputEvent in _extras.get(action,[]):InputMap.action_add_event(action,event)
func conflict(action:String,code:int) -> String:
	var context:="both"
	for row:Array in ROWS:
		if row[0]==action:context=row[4]
	for row:Array in ROWS:
		if row[0]!=action and (context=="both" or row[4]=="both" or context==row[4]) and code in bindings[row[0]]:return row[1]+" · "+row[2]
	return ""
func assign(action:String,slot:int,code:int) -> String:
	if not bindings.has(action) or slot not in [0,1] or not _valid_key(code):return "Tecla inválida."
	var other:=conflict(action,code)
	if not other.is_empty():return "Já usada em "+other+". Escolha outra tecla."
	var next:=bindings.duplicate(true);var codes:Array=next[action]
	if code in codes:
		var index:=codes.find(code)
		if slot>=codes.size():return "Essa tecla já está nesta ação."
		if index!=slot and slot<codes.size():var old:int=codes[slot];codes[slot]=code;codes[index]=old
	elif slot<codes.size():codes[slot]=code
	else:codes.append(code)
	return _commit(next)
func clear_secondary(action:String) -> String:
	if not bindings.has(action):return "Ação inválida."
	var next:=bindings.duplicate(true);next[action]=[next[action][0]];return _commit(next)
func restore_defaults() -> String:return _commit(defaults())
func _commit(next:Dictionary) -> String:
	var config:=ConfigFile.new();config.set_value("controls","version",1)
	for action:String in next:config.set_value("keyboard",action,next[action])
	var error:=config.save(PATH+".tmp")
	if error==OK:error=DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
	if error!=OK:return "Não foi possível salvar as teclas. Tente novamente."
	bindings=next;_apply();changed.emit();return ""
func key_name(code:int) -> String:
	var title:=OS.get_keycode_string(code)
	return {"Space":"Espaço","Escape":"Esc","Left":"←","Right":"→","Up":"↑","Down":"↓","BackSpace":"Bksp","PageDown":"PgDn","PageUp":"PgUp"}.get(title,title)
func key_label(action:String,slot:int=-1) -> String:
	var codes:Array=bindings.get(action,[])
	if slot>=0:return key_name(codes[slot]) if slot<codes.size() else "—"
	var names:=PackedStringArray()
	for code:int in codes:names.append(key_name(code))
	return " / ".join(names)
func hint(text:String,three_d:bool=false) -> String:
	# Only instruction labels call this; story dialogue and menu navigation do not.
	var replacements:={"J":"attack","X":"attack","E":"interagir","I":"inventory","K":"element_cast","Q":"element_swap","C":"jose_command","F":"lab_throw","R":"restart_checkpoint","Espaço":"lab3d_jump" if three_d else "jump","ESPAÇO":"lab3d_jump" if three_d else "jump","ESC":"pause_game","SHIFT":"lab3d_boost","CTRL":"lab3d_dodge","J / X":"attack","Espaço / W":"jump"}
	var regex:=RegEx.new();regex.compile("(?<![\\p{L}\\p{N}_])(?:J / X|Espaço / W|Setas / A D|A / D|WASD(?: ou setas| / setas)?|ESPAÇO|Espaço|SHIFT|CTRL|ESC|J|X|E|I|K|Q|C|F|R)(?![\\p{L}\\p{N}_])")
	var matches:=regex.search_all(text)
	for i in range(matches.size()-1,-1,-1):
		var match:RegExMatch=matches[i];var token:=match.get_string();var value:=""
		if token in ["Setas / A D","A / D"]:value=key_label("move_left")+" · "+key_label("move_right")
		elif token.begins_with("WASD"):value=key_label("lab3d_forward",0)+"/"+key_label("lab3d_left",0)+"/"+key_label("lab3d_back",0)+"/"+key_label("lab3d_right",0)
		else:value=key_label(replacements[token],-1 if token in ["J / X","Espaço / W"] else 0)
		text=text.substr(0,match.get_start())+value+text.substr(match.get_end())
	return text
