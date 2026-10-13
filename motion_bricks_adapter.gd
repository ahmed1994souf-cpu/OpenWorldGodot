class_name MotionBricksAdapter
extends Node
## Runtime bridge for the real MotionBricks C ABI through GDExtension.
## The game remains fully playable with the existing Mixamo clips when the
## native Android library or model bundle is not installed.

@export var enabled := true
@export var model_path := "res://motion_bricks/generated/g1-f32"
@export var style_paths := {
    "Idle": "res://motion_bricks/generated/styles/idle.mbstyle",
    "Walk": "res://motion_bricks/generated/styles/walk.mbstyle",
    "Run": "res://motion_bricks/generated/styles/walk.mbstyle"
}
@export var cpu_threads := 2
@export var update_interval := 0.12

var native: Object
var available := false
var configured := false
var _timer := 0.0
var _last_move := Vector3.ZERO
var _last_facing := Vector3.FORWARD
var _skeleton: Skeleton3D
var _bone := {}
var _frame := 0

const G1_NAMES := [
    "left_hip_pitch_joint","left_hip_roll_joint","left_hip_yaw_joint","left_knee_joint","left_ankle_pitch_joint","left_ankle_roll_joint",
    "right_hip_pitch_joint","right_hip_roll_joint","right_hip_yaw_joint","right_knee_joint","right_ankle_pitch_joint","right_ankle_roll_joint",
    "waist_yaw_joint","waist_roll_joint","waist_pitch_joint",
    "left_shoulder_pitch_joint","left_shoulder_roll_joint","left_shoulder_yaw_joint","left_elbow_joint","left_wrist_roll_joint","left_wrist_pitch_joint","left_wrist_yaw_joint",
    "right_shoulder_pitch_joint","right_shoulder_roll_joint","right_shoulder_yaw_joint","right_elbow_joint","right_wrist_roll_joint","right_wrist_pitch_joint","right_wrist_yaw_joint"
]

func _ready() -> void:
    _skeleton = get_parent().find_child("Skeleton3D", true, false) as Skeleton3D
    if _skeleton:
        for i in _skeleton.get_bone_count():
            _bone[_skeleton.get_bone_name(i).to_lower()] = i
    if enabled and ClassDB.class_exists("MotionBricksNative"):
        native = ClassDB.instantiate("MotionBricksNative")
        if native:
            configured = bool(native.configure(ProjectSettings.globalize_path(model_path), ProjectSettings.globalize_path(str(style_paths.get("Idle", ""))), cpu_threads))
            available = configured
    if available:
        print("[MotionBricks] native runtime loaded; G1 -> player retarget active")
    else:
        print("[MotionBricks] native runtime/model not available; using existing animations")

func request_motion(move: Vector3, facing: Vector3, style: String = "Walk") -> bool:
    if not available or native == null:
        return false
    var path: String = str(style_paths.get(style, ""))
    # The upstream API expects a concrete style asset path. If the requested
    # style is absent, keep the previous native style rather than interrupting.
    if path.is_empty():
        path = str(style_paths.get("Walk", ""))
    _last_move = move
    _last_facing = facing
    return bool(native.plan(move, facing, ProjectSettings.globalize_path(path)))

func _physics_process(delta: float) -> void:
    if not available or native == null or _skeleton == null:
        return
    _timer -= delta
    if _timer > 0.0:
        return
    _timer = update_interval
    var pose: Dictionary = native.sample(_frame)
    if pose.is_empty():
        return
    _apply_g1_pose(pose)
    _frame += 1
    if _frame >= int(pose.get("frames", 1)):
        native.advance(_frame)
        _frame = 0

func _q(a: PackedFloat32Array, i: int) -> Quaternion:
    return Quaternion(a[i], a[i + 1], a[i + 2], a[i + 3]).normalized()

func _set_rot(name: String, q: Quaternion) -> void:
    var idx: int = int(_bone.get(name.to_lower(), -1))
    if idx >= 0:
        _skeleton.set_bone_pose_rotation(idx, q)

func _apply_g1_pose(pose: Dictionary) -> void:
    var r: PackedFloat32Array = pose.get("rotations", PackedFloat32Array())
    if r.size() < 29 * 4:
        return
    # G1 has three hinge joints at each hip/shoulder/waist. Mixamo uses one
    # bone for the corresponding segment, so compose the native rotations.
    var lhip := _q(r, 0) * _q(r, 4) * _q(r, 8)
    var lknee := _q(r, 12)
    var lfoot := _q(r, 16) * _q(r, 20)
    var rhip := _q(r, 24) * _q(r, 28) * _q(r, 32)
    var rknee := _q(r, 36)
    var rfoot := _q(r, 40) * _q(r, 44)
    var waist := _q(r, 48) * _q(r, 52) * _q(r, 56)
    var lshoulder := _q(r, 60) * _q(r, 64) * _q(r, 68)
    var lelbow := _q(r, 72)
    var lwrist := _q(r, 76) * _q(r, 80) * _q(r, 84)
    var rshoulder := _q(r, 88) * _q(r, 92) * _q(r, 96)
    var relbow := _q(r, 100)
    var rwrist := _q(r, 104) * _q(r, 108) * _q(r, 112)

    _set_rot("UpperLeg_L", lhip)
    _set_rot("LowerLeg_L", lknee)
    _set_rot("Foot_L", lfoot)
    _set_rot("UpperLeg_R", rhip)
    _set_rot("LowerLeg_R", rknee)
    _set_rot("Foot_R", rfoot)
    _set_rot("Spine", waist)
    _set_rot("Shoulder_L", lshoulder)
    _set_rot("LowerArm_L", lelbow)
    _set_rot("Hand_L", lwrist)
    _set_rot("Shoulder_R", rshoulder)
    _set_rot("LowerArm_R", relbow)
    _set_rot("Hand_R", rwrist)

func reset_motion() -> void:
    if native and native.has_method("reset"):
        native.reset()
