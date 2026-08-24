extends Node
class_name AttackEvaluationSystem

@onready var inventory: InventorySystem = $"../InventorySystem"

func apply_to_attack_data(attack_data: AttackData) -> void:
	if attack_data == null:
		return
	if inventory == null:
		return

	for item in inventory.passive_items:
		if item == null:
			continue

		for effect in item.effects:
			if effect == null:
				continue
			if effect is AttackEffectData:
				effect.apply_to_attack_data(attack_data)
