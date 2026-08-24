extends ReactiveEffectInstance
class_name ShopPriceMultiplierRuntime

var _price_multiplier := 1.0
var _flat_discount := 0

func configure(price_multiplier: float, flat_discount: int) -> void:
	_price_multiplier = maxf(0.05, price_multiplier)
	_flat_discount = max(0, flat_discount)

func activate() -> void:
	Global.adjust_shop_price_multiplier(_price_multiplier, true)
	Global.adjust_shop_flat_discount(_flat_discount, true)

func deactivate() -> void:
	Global.adjust_shop_price_multiplier(_price_multiplier, false)
	Global.adjust_shop_flat_discount(_flat_discount, false)