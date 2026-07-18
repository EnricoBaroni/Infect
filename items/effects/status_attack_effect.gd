extends AttackEffectData
class_name StatusAttackEffect

func _append_status_payload(
	attack_data: AttackData,
	status_id: String,
	duration: float,
	magnitude: float,
	tick_interval: float,
	max_stacks: int,
	stack_rule: String,
	visual_tint: Color,
	proc_chance: float = 1.0,
	proc_luck_to_full: float = 0.0,
	proc_max_chance: float = 1.0
) -> void:
	if attack_data == null:
		return
	if status_id == "":
		return

	var payload := StatusPayload.new()
	payload.status_id = status_id
	payload.duration = max(0.0, duration)
	payload.magnitude = max(0.0, magnitude)
	payload.tick_interval = max(0.0, tick_interval)
	payload.max_stacks = max(1, max_stacks)
	payload.stack_rule = stack_rule
	payload.visual_tint = visual_tint
	payload.proc_chance = clampf(proc_chance, 0.0, 1.0)
	payload.proc_luck_to_full = max(0.0, proc_luck_to_full)
	payload.proc_max_chance = clampf(proc_max_chance, 0.0, 1.0)
	attack_data.status_payloads.append(payload)
