extends Node

func _ready() -> void:
	GameState.reset_case()
	GameState.incoming_call = false
	if GameState.phone_ready():
		_fail("telefon baştan açık")
	if GameState.try_pin("1903"):
		_fail("olay yeri olmadan şifre geçti")
	if GameState.travel("interrogation"):
		_fail("gözaltı erken açıldı")
	GameState.brief()
	if not GameState.briefing_done:
		_fail("brifing yok")
	for id in ["hotspot_phone", "hotspot_desk", "hotspot_column", "hotspot_suv"]:
		GameState.inspect_hotspot(id)
	if not GameState.phone_ready():
		_fail("telefon delili yok")
	if GameState.try_pin("0000"):
		_fail("yanlış şifre geçti")
	if not GameState.try_pin("1903"):
		_fail("1903 açılmadı")
	for item in ["bank", "notes", "sms_zafer", "sms_concert"]:
		GameState.open_phone_item(item)
	GameState.search_esorgu("06 KZY 44")
	GameState.search_esorgu("yok boyle kayit")
	if GameState.esorgu_history.is_empty() or GameState.esorgu_history[0]["found"]:
		_fail("boş sorgu kayıt varmış gibi")
	GameState.search_esorgu("Kuzey Hafriyat")
	GameState.search_esorgu("Tarık Soylu")
	GameState.search_esorgu("0532 190 30 06")
	GameState.search_esorgu("Zafer Yılmaz")
	GameState.search_esorgu("otopsi")
	if not GameState.esorgu_history[0]["found"]:
		_fail("telefon sorgusu sonuçsuz")
	if not GameState.link_clues("clue_bank_500k", "clue_company_record"):
		_fail("kanıt bağı kurulamadı")
	if GameState.link_clues("clue_bank_500k", "clue_company_record"):
		_fail("aynı bağ ikinci kez kuruldu")
	if not GameState.arrest_unlocked():
		_fail("gözaltı hâlâ kilitli")
	if not GameState.travel("interrogation"):
		_fail("sorgu odasına geçilemedi")
	GameState.select_suspect("zafer")
	GameState.slam_evidence("clue_no_suicide")
	if int(GameState.stress["zafer"]) != 10:
		_fail("yanlış kanıt stresi %s" % str(GameState.stress["zafer"]))
	for id in ["clue_zafer_sms", "clue_concrete_report", "clue_cracked_column"]:
		GameState.slam_evidence(id)
	if not GameState.confessed["zafer"]:
		_fail("Zafer itiraf etmedi")
	GameState.select_suspect("tarik")
	if GameState.dialogue_options().size() != 2:
		_fail("Tarık başlangıç seçenekleri %d (şirket dalı kilitli olmalı)" % GameState.dialogue_options().size())
	GameState.choose_option(0)
	if GameState.dialogue_node["tarik"] != "money" or int(GameState.stress["tarik"]) != 5:
		_fail("diyalog dalı: %s stres %s" % [GameState.dialogue_node["tarik"], str(GameState.stress["tarik"])])
	if GameState.dialogue_options().size() != 2:
		_fail("dekont dalı kanıt vurulmadan açık")
	GameState.slam_evidence("clue_bank_500k")
	GameState.dialogue_node["tarik"] = "money"
	if GameState.dialogue_options().size() != 3:
		_fail("doğru kanıt yeni dal açmadı")
	for id in ["clue_pts_06kzy44", "clue_hts_tarik"]:
		GameState.slam_evidence(id)
	if not GameState.confessed["tarik"]:
		_fail("Tarık itiraf etmedi")
	if not GameState.case_is_closed():
		_fail("dosya kapanmadı")
	if int(GameState.bpm["tarik"]) != 160:
		_fail("BPM %s" % str(GameState.bpm["tarik"]))
	GameState.slam_evidence("clue_bank_500k")
	if int(GameState.stress["tarik"]) != 100:
		_fail("tekrar kanıt stresi değişti")
	for path in ["res://scenes/office.tscn", "res://scenes/site.tscn", "res://scenes/interrogation.tscn"]:
		var node := (load(path) as PackedScene).instantiate()
		add_child(node)
		await get_tree().process_frame
		await get_tree().process_frame
		node.queue_free()
		await get_tree().process_frame
	print("PLAYTHROUGH_OK")
	get_tree().quit(0)


func _fail(reason: String) -> void:
	push_error(reason)
	print("PLAYTHROUGH_FAIL %s" % reason)
	get_tree().quit(1)
