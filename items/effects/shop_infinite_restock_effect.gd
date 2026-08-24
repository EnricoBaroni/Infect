extends ReactiveEffectData
class_name ShopInfiniteRestockEffect

func create_runtime(_player: Player) -> ReactiveEffectInstance:
	return ShopInfiniteRestockRuntime.new()