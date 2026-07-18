extends ReactiveEffectInstance
class_name ShopInfiniteRestockRuntime

func activate() -> void:
	Global.adjust_shop_infinite_restock_sources(1)

func deactivate() -> void:
	Global.adjust_shop_infinite_restock_sources(-1)