extends ReactiveEffectData
class_name ShopPriceMultiplierEffect

@export var price_multiplier: float = 0.5
@export var flat_discount: int = 0

func create_runtime(_player: Player) -> ReactiveEffectInstance:
	var runtime := ShopPriceMultiplierRuntime.new()
	runtime.configure(price_multiplier, flat_discount)
	return runtime