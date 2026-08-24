extends RefCounted
class_name ReactiveEffectInstance

func activate() -> void:
	pass

func deactivate() -> void:
	pass

## Evaluates a proc chance with luck modifier.
## Returns true if the proc succeeds (random roll passes).
## Parameters:
## - base_chance: base proc chance (0.0 to 1.0)
## - player: the player instance (needed for stats/luck)
## - luck_to_full: how much luck stat contributes to final chance
## - max_proc_chance: cap on final proc chance (0.0 to 1.0)
func evaluate_proc(base_chance: float, player: Player, luck_to_full: float, max_proc_chance: float) -> bool:
	var final_chance := base_chance
	if luck_to_full > 0.0 and player != null and player.stats != null:
		final_chance = EventBus.evaluate_luck_proc(base_chance, player.stats.luck, luck_to_full, max_proc_chance)
	return randf() <= final_chance
