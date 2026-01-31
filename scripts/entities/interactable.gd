class_name Interactable
extends Node2D

## Signal emitted when the hand grabs this object.
signal grabbed(hand: Hand)
## Signal emitted when the hand releases this object.
signal released(hand: Hand)
## Signal emitted when a grab attempt is rejected.
signal grab_rejected(hand: Hand)

## Base grip multiplier for this item.
@export var grip_multiplier: float = 1.0

## If false, the Hand won't even try to grab this.
func can_grab(hand: Hand) -> bool:
	if get_parent().has_method(&"_can_grab_check"):
		return get_parent()._can_grab_check(hand)
	return true

## Called by the Hand when it successfully starts a grab.
func on_grab(hand: Hand) -> void:
	grabbed.emit(hand)

## Called by the Hand when a grab is rejected.
func on_grab_rejected(hand: Hand) -> void:
	grab_rejected.emit(hand)

## Called by the Hand when it releases the object.
func on_release(hand: Hand) -> void:
	released.emit(hand)

## Called every physics frame while being held.
## Useful for items that have active behaviors while in hand.
func on_hold_process(hand: Hand, delta: float) -> void:
	if get_parent().has_method(&"_on_hold_process"):
		get_parent()._on_hold_process(hand, delta)
