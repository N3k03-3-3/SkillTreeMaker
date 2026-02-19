class_name NodeAnimationState
extends RefCounted

## 単一ノードのアニメーション状態を保持する
##
## _process() で毎フレーム更新され、_draw() で参照される。
## アンロックアニメーション、ホバースケール、CAN_UNLOCK パルスを管理する。


# --- Constants ---

## アンロックアニメーション時間（秒）
const UNLOCK_DURATION: float = 0.4

## アンロック時の最大スケール倍率
const UNLOCK_SCALE_PEAK: float = 1.3

## ホバー時の目標スケール倍率
const HOVER_SCALE_TARGET: float = 1.08

## ホバーのスケール補間速度（lerp weight per second）
const HOVER_LERP_SPEED: float = 10.0

## CAN_UNLOCK パルス周期（秒）
const PULSE_PERIOD: float = 1.5

## CAN_UNLOCK パルス最小 alpha
const PULSE_ALPHA_MIN: float = 0.4

## CAN_UNLOCK パルス最大 alpha
const PULSE_ALPHA_MAX: float = 1.0

## エッジ色遷移時間（秒）
const EDGE_TRANSITION_DURATION: float = 0.3

## スケール収束判定閾値
const SCALE_EPSILON: float = 0.001


# --- Public Variables ---

## アンロックアニメーション進行度（-1.0 = 非アクティブ, 0.0〜1.0 = 進行中）
var unlock_progress: float = -1.0

## 現在のスケール倍率（1.0 = 通常）
var current_scale: float = 1.0

## ホバー中か
var is_hovered: bool = false

## CAN_UNLOCK パルス用の経過時間
var pulse_time: float = 0.0


# --- Public Functions ---

## アンロックアニメーションを開始する
func start_unlock() -> void:
	unlock_progress = 0.0


## 毎フレーム更新する
##
## @param delta: フレーム間隔（秒）(float)
## @param is_can_unlock: CAN_UNLOCK 状態か (bool)
## @return: 再描画が必要なら true
func update(delta: float, is_can_unlock: bool) -> bool:
	var needs_redraw: bool = false

	# アンロックアニメーション
	needs_redraw = _update_unlock(delta) or needs_redraw

	# ホバースケール（アンロックアニメ中はスキップ）
	needs_redraw = _update_hover_scale(delta) or needs_redraw

	# CAN_UNLOCK パルス
	needs_redraw = _update_pulse(delta, is_can_unlock) or needs_redraw

	return needs_redraw


## パルス進行度から枠の alpha 値を取得する
##
## @return: PULSE_ALPHA_MIN〜PULSE_ALPHA_MAX のパルス alpha
func get_pulse_alpha() -> float:
	var t: float = pulse_time / PULSE_PERIOD
	var sin_val: float = sin(t * TAU)
	return lerpf(PULSE_ALPHA_MIN, PULSE_ALPHA_MAX, (sin_val + 1.0) * 0.5)


## アニメーションが進行中かどうかを判定する
##
## @param is_can_unlock: CAN_UNLOCK 状態か (bool)
## @return: アニメーション中なら true
func is_animating(is_can_unlock: bool) -> bool:
	# CAN_UNLOCK パルスは常時アニメーション
	if is_can_unlock:
		return true

	# アンロックアニメーション進行中
	if unlock_progress >= 0.0 and unlock_progress < 1.0:
		return true

	# ホバースケールが通常に戻っていない
	if absf(current_scale - 1.0) > SCALE_EPSILON and not is_hovered:
		return true

	# ホバー中でスケールが目標に達していない
	if is_hovered and absf(current_scale - HOVER_SCALE_TARGET) > SCALE_EPSILON:
		return true

	return false


# --- Private Functions ---

## アンロックアニメーションを更新する
##
## @param delta: フレーム間隔（秒）(float)
## @return: 再描画が必要なら true
func _update_unlock(delta: float) -> bool:
	if unlock_progress < 0.0 or unlock_progress >= 1.0:
		return false

	unlock_progress = minf(unlock_progress + delta / UNLOCK_DURATION, 1.0)

	# バウンス風: 前半で膨張、後半で収縮
	if unlock_progress < 0.5:
		current_scale = lerpf(1.0, UNLOCK_SCALE_PEAK, unlock_progress * 2.0)
	else:
		current_scale = lerpf(UNLOCK_SCALE_PEAK, 1.0, (unlock_progress - 0.5) * 2.0)

	if unlock_progress >= 1.0:
		current_scale = 1.0

	return true


## ホバースケールを更新する
##
## @param delta: フレーム間隔（秒）(float)
## @return: 再描画が必要なら true
func _update_hover_scale(delta: float) -> bool:
	# アンロックアニメーション中はスキップ
	if unlock_progress >= 0.0 and unlock_progress < 1.0:
		return false

	var target_scale: float = HOVER_SCALE_TARGET if is_hovered else 1.0
	if is_equal_approx(current_scale, target_scale):
		return false

	current_scale = lerpf(current_scale, target_scale, minf(delta * HOVER_LERP_SPEED, 1.0))
	if absf(current_scale - target_scale) < SCALE_EPSILON:
		current_scale = target_scale

	return true


## CAN_UNLOCK パルスを更新する
##
## @param delta: フレーム間隔（秒）(float)
## @param is_can_unlock: CAN_UNLOCK 状態か (bool)
## @return: 再描画が必要なら true
func _update_pulse(delta: float, is_can_unlock: bool) -> bool:
	if is_can_unlock:
		pulse_time += delta
		if pulse_time > PULSE_PERIOD:
			pulse_time -= PULSE_PERIOD
		return true

	if pulse_time > 0.0:
		pulse_time = 0.0
		return true

	return false
