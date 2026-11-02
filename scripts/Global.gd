
extends Node # Global

const initialLife = 100
const initialAmmo = 20

var life: int = initialLife
var ammo: int = initialAmmo

var enemyDeadDict: Dictionary = {}

var playerPosition: Vector3 = Vector3.ZERO
var hasLoadedGame: bool = false
