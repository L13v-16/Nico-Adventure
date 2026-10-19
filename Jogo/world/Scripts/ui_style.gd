extends RefCounted
## UiStyle — estilos compartilhados da interface (menu, pausa, resultados).
##
## Usado por preload (sem class_name) para não depender do cache global de
## classes, que só é preenchido ao abrir o editor.

const TITLE_COLOR := Color(0.75, 0.95, 0.72)
const TEXT_COLOR := Color(0.86, 0.92, 0.96)
const MUTED_COLOR := Color(0.62, 0.72, 0.8)
const GOLD_COLOR := Color(1.0, 0.88, 0.42)
const DIM_COLOR := Color(0.02, 0.03, 0.07, 0.72)
const PANEL_BG := Color(0.045, 0.075, 0.14, 0.97)
const PANEL_BORDER := Color(0.55, 0.83, 0.57, 1.0)

const RANK_COLORS := {
	"S": Color(1.0, 0.86, 0.35),
	"A": Color(0.62, 0.92, 0.66),
	"B": Color(0.62, 0.84, 0.98),
	"C": Color(0.8, 0.82, 0.86),
	"D": Color(0.95, 0.62, 0.55),
}


static func label(text: String, font_size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func shadowed_label(text: String, font_size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := label(text, font_size, color, align)
	node.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	node.add_theme_constant_override("shadow_offset_x", 2)
	node.add_theme_constant_override("shadow_offset_y", 2)
	return node


static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.01, 0.02, 0.05, 0.45)
	style.shadow_size = 6
	return style


## Gradiente vertical desenhado em faixas que se sobrepõem 1px, para não
## deixar as emendas aparecendo entre uma faixa e outra.
static func draw_v_gradient(canvas: CanvasItem, rect: Rect2, top: Color, bottom: Color, steps: int = 64) -> void:
	var height := rect.size.y / float(steps)
	for index in steps:
		var t := float(index) / float(maxi(steps - 1, 1))
		canvas.draw_rect(
			Rect2(rect.position.x, rect.position.y + floorf(height * float(index)), rect.size.x, ceilf(height) + 1.0),
			top.lerp(bottom, t)
		)


static func button_style(background: Color, border: Color, padding: float = 6.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = padding + 4.0
	style.content_margin_right = padding + 4.0
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func button(text: String, font_size: int = 15) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_font_size_override("font_size", font_size)
	var padding: float = maxf(roundf(float(font_size) * 0.3), 3.0)
	node.add_theme_color_override("font_color", TEXT_COLOR)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_focus_color", Color.WHITE)
	node.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.56))
	node.add_theme_stylebox_override("normal", button_style(Color(0.07, 0.13, 0.2, 0.9), Color(0.3, 0.44, 0.56, 0.9), padding))
	node.add_theme_stylebox_override("hover", button_style(Color(0.12, 0.22, 0.3, 0.95), Color(0.5, 0.78, 0.6, 1.0), padding))
	node.add_theme_stylebox_override("pressed", button_style(Color(0.05, 0.1, 0.16, 1.0), Color(0.5, 0.78, 0.6, 1.0), padding))
	node.add_theme_stylebox_override("focus", button_style(Color(0.12, 0.22, 0.3, 0.95), Color(0.62, 0.9, 0.7, 1.0), padding))
	node.add_theme_stylebox_override("disabled", button_style(Color(0.06, 0.08, 0.12, 0.7), Color(0.2, 0.26, 0.32, 0.8), padding))
	return node


static func divider() -> ColorRect:
	var node := ColorRect.new()
	node.custom_minimum_size = Vector2(0.0, 1.0)
	node.color = Color(0.35, 0.5, 0.63, 0.55)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func slider_row(title: String, value: float, on_change: Callable, on_release: Callable = Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label_node := Label.new()
	label_node.text = title
	label_node.add_theme_font_size_override("font_size", 12)
	label_node.add_theme_color_override("font_color", TEXT_COLOR)
	label_node.custom_minimum_size = Vector2(58.0, 0.0)
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label_node)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(140.0, 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	if on_release.is_valid():
		slider.drag_ended.connect(on_release)
	row.add_child(slider)
	return row


static func check_row(title: String, value: bool, on_toggle: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label_node := Label.new()
	label_node.text = title
	label_node.add_theme_font_size_override("font_size", 12)
	label_node.add_theme_color_override("font_color", TEXT_COLOR)
	label_node.custom_minimum_size = Vector2(120.0, 0.0)
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label_node)

	var check := CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(on_toggle)
	row.add_child(check)
	return row
