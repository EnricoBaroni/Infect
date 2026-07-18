extends Node

var recently_moved := false
var drops := 50
var difficulty_level := 1

var reveal_map_level := 0
var reveal_room_types_level := 0
var reveal_secret_walls_level := 0
var reveal_secret_rooms_level := 0
var reveal_treasure_rooms_level := 0
var reveal_boss_rooms_level := 0

var shop_price_multiplier := 1.0
var shop_flat_discount := 0
var shop_infinite_restock_sources := 0

func get_effective_shop_cost(base_cost: int) -> int:
	var adjusted := int(ceil(float(max(0, base_cost)) * maxf(0.05, shop_price_multiplier)))
	adjusted = max(0, adjusted - max(0, shop_flat_discount))
	return adjusted

func adjust_shop_price_multiplier(multiplier: float, apply: bool) -> void:
	var safe_multiplier := maxf(0.05, multiplier)
	if apply:
		shop_price_multiplier *= safe_multiplier
	else:
		shop_price_multiplier /= safe_multiplier
	shop_price_multiplier = clampf(shop_price_multiplier, 0.05, 10.0)

func adjust_shop_flat_discount(amount: int, apply: bool) -> void:
	if apply:
		shop_flat_discount = max(0, shop_flat_discount + max(0, amount))
	else:
		shop_flat_discount = max(0, shop_flat_discount - max(0, amount))

func adjust_shop_infinite_restock_sources(delta: int) -> void:
	shop_infinite_restock_sources = max(0, shop_infinite_restock_sources + delta)

func has_shop_infinite_restock() -> bool:
	return shop_infinite_restock_sources > 0

func adjust_map_intel(
	map_delta: int,
	room_types_delta: int,
	secret_walls_delta: int,
	secret_rooms_delta: int,
	treasure_delta: int,
	boss_delta: int
) -> void:
	reveal_map_level = max(0, reveal_map_level + map_delta)
	reveal_room_types_level = max(0, reveal_room_types_level + room_types_delta)
	reveal_secret_walls_level = max(0, reveal_secret_walls_level + secret_walls_delta)
	reveal_secret_rooms_level = max(0, reveal_secret_rooms_level + secret_rooms_delta)
	reveal_treasure_rooms_level = max(0, reveal_treasure_rooms_level + treasure_delta)
	reveal_boss_rooms_level = max(0, reveal_boss_rooms_level + boss_delta)
