extends CanvasLayer

signal cancelled

const TEXT := {
	"en": {
		"option": "Use GIF preloading",
		"hint": "Preload all applied GIFs now and on each game launch. Reduces first-display stalls, but increases startup time and RAM/VRAM use. Unused Art Packs are excluded.",
		"estimate": "%d GIF cards / %d frames: about %.0f MiB of pixel data, plus overhead. Long GIFs use up to 256 sampled frames.",
		"title": "Preparing GIF card art",
		"progress": "Cards %d / %d  |  Frames %d / %d",
		"cancel": "Stop for this session",
		"failed": "Some frames could not be loaded (%d cards). Your images and Art Packs were not deleted. Check the files, then apply GIF settings again to retry.",
		"close": "Close"
	},
	"ko": {
		"option": "GIF 프리로딩 사용",
		"hint": "현재 적용된 모든 GIF를 지금과 게임 실행 시 미리 불러옵니다. 첫 표시 시 끊김을 줄이지만 시작 시간과 RAM/VRAM 사용량이 증가합니다. 미사용 아트팩은 제외됩니다.",
		"estimate": "GIF 카드 %d개 / %d프레임: 픽셀 데이터 약 %.0f MiB + 추가 메모리. 긴 GIF는 최대 256프레임으로 샘플링합니다.",
		"title": "GIF 카드 이미지 준비 중",
		"progress": "카드 %d / %d  |  프레임 %d / %d",
		"cancel": "이번 실행에서는 준비 중단",
		"failed": "일부 프레임을 불러오지 못했습니다(카드 %d개). 이미지와 아트팩은 삭제하지 않았습니다. 파일 확인 후 GIF 설정을 다시 적용하면 재시도합니다.",
		"close": "닫기"
	},
	"zh": {
		"option": "启用 GIF 预加载",
		"hint": "立即及每次启动游戏时预加载所有已应用的 GIF。可减少首次显示时的卡顿，但会增加启动时间和内存/显存占用。不包含未使用的美术包。",
		"estimate": "%d 张 GIF 卡牌 / %d 帧：像素数据约 %.0f MiB，另需额外内存。较长的 GIF 最多采样 256 帧。",
		"title": "正在准备 GIF 卡牌图片",
		"progress": "卡牌 %d / %d  |  帧 %d / %d",
		"cancel": "本次停止预加载",
		"failed": "部分帧无法加载（%d 张卡牌）。图片和美术包未被删除。请检查文件，然后再次应用 GIF 设置以重试。",
		"close": "关闭"
	},
	"ja": {
		"option": "GIF プリロードを使用",
		"hint": "適用中のすべての GIF を今すぐ、またゲーム起動時に読み込みます。初回表示時のカクつきを軽減しますが、起動時間とメモリ・VRAM 使用量が増えます。未使用のアートパックは対象外です。",
		"estimate": "GIF カード %d 枚 / %d フレーム：ピクセルデータ約 %.0f MiB と追加メモリ。長い GIF は最大 256 フレームに間引きます。",
		"title": "GIF カード画像を準備中",
		"progress": "カード %d / %d  |  フレーム %d / %d",
		"cancel": "今回のプリロードを中止",
		"failed": "一部のフレームを読み込めませんでした（%d 枚）。画像とアートパックは削除していません。ファイルを確認し、GIF 設定を再度適用して再試行してください。",
		"close": "閉じる"
	}
}

var _locale := "en"
var _panel: PanelContainer
var _estimate: Label
var _status: Label
var _card_name: Label
var _bar: ProgressBar
var _button: Button
var _finished := false


static func translated(locale: String, key: String) -> String:
	return String(TEXT.get(locale, TEXT["en"]).get(key, key))


static func estimate_text(locale: String, estimate: Dictionary) -> String:
	return translated(locale, "estimate") % [int(estimate.get("cards", 0)), int(estimate.get("frames", 0)), float(estimate.get("bytes", 0)) / 1048576.0]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	var file = FileAccess.open("user://card_art_editor/ui_settings.json", FileAccess.READ)
	if file != null:
		var settings = JSON.parse_string(file.get_as_text())
		if settings is Dictionary:
			_locale = String(settings.get("locale", "en"))
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.065, 0.08, 0.96)))
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)
	var title = _label(22)
	title.text = translated(_locale, "title")
	box.add_child(title)
	_estimate = _label(16)
	box.add_child(_estimate)
	_status = _label(18)
	box.add_child(_status)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 24
	_bar.add_theme_stylebox_override("background", _style(Color(0.04, 0.04, 0.05)))
	_bar.add_theme_stylebox_override("fill", _style(Color(0.08, 0.38, 0.66)))
	box.add_child(_bar)
	_card_name = _label(16)
	box.add_child(_card_name)
	_button = Button.new()
	_button.text = translated(_locale, "cancel")
	_button.add_theme_color_override("font_color", Color.WHITE)
	_button.add_theme_stylebox_override("normal", _style(Color(0.09, 0.1, 0.12)))
	_button.add_theme_stylebox_override("hover", _style(Color(0.12, 0.18, 0.24)))
	_button.add_theme_stylebox_override("pressed", _style(Color(0.08, 0.15, 0.22)))
	_button.pressed.connect(_on_button_pressed)
	box.add_child(_button)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_button.grab_focus()


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.16, 0.52, 0.83)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _resize() -> void:
	_panel.custom_minimum_size.x = maxf(240, minf(640, get_viewport().get_visible_rect().size.x - 48))


func show_estimate(estimate: Dictionary) -> void:
	_estimate.text = estimate_text(_locale, estimate)


func update_progress(current: int, total: int, cards: int, total_cards: int, card_name: String) -> void:
	_bar.max_value = maxi(1, total)
	_bar.value = current
	_status.text = translated(_locale, "progress") % [cards, total_cards, current, total]
	_card_name.text = card_name


func finish(failed_cards: int) -> void:
	if failed_cards == 0:
		queue_free()
		return
	_finished = true
	_status.text = translated(_locale, "failed") % failed_cards
	_button.text = translated(_locale, "close")


func _on_button_pressed() -> void:
	if _finished:
		queue_free()
	else:
		cancelled.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_button_pressed()
