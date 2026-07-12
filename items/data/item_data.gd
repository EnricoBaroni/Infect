extends Resource
class_name ItemData

@export var id: String
@export var name: String
@export_multiline var description: String

@export var quality: int = 0

@export var pool_tags: PackedStringArray = []
@export var effects: Array[EffectData] = []
