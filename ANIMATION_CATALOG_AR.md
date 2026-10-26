# فهرس حركات Motifect — Jammo فقط

تم فحص 40 ملف FBX من الحزمة في Godot 4.7.2 بوضع headless. الملفات أمكن تحميلها كمشاهد، وكل ملف احتوى على Skeleton3D من 77 عظمة وAnimationPlayer بمقطع Take1. هذا لا يثبت توافقها مع Jammo؛ نموذج Jammo غير موجود في مساحة العمل حتى الآن.

## ترتيب التجربة المقترح
1. `wrestling_body_slam.fbx` — إسقاط الجسم؛ حركة مصدر لشخصية واحدة.
2. `judo_hip_throw.fbx` — رمية الورك.
3. `wrestling_double_leg_takedown.fbx` — إسقاط بمسك الساقين.
4. `wrestling_single_leg_takedown.fbx` — إسقاط بمسك ساق واحدة.
5. `wrestling_guard_position.fbx` — وضعية أرضية.
6. `wrestling_stand_up_defense.fbx` — دفاع/نهوض.
7. `muay_thai_knee_clinch.fbx` — اشتباك قريب.
8. `muay_thai_combination.fbx` — مجموعة ضربات.

## بقية ملفات الحزمة
- Wrestling/Judo: `wrestling_body_slam.fbx`, `wrestling_double_leg_takedown.fbx`, `wrestling_guard_position.fbx`, `wrestling_single_leg_takedown.fbx`, `wrestling_stand_up_defense.fbx`, `judo_ankle_sweep.fbx`, `judo_hip_throw.fbx`.
- Muay Thai: `muay_thai_body_kick.fbx`, `muay_thai_combination.fbx`, `muay_thai_elbow_cut.fbx`, `muay_thai_guard_stance.fbx`, `muay_thai_knee_clinch.fbx`, `muay_thai_push_kick_defense.fbx`, `muay_thai_roundhouse.fbx`, `muay_thai_teep.fbx`.
- Taekwondo: `tkd_axe_kick.fbx`, `tkd_back_kick.fbx`, `tkd_front_kick_high.fbx`, `tkd_jump_front_kick.fbx`, `tkd_jump_spinning_kick.fbx`, `tkd_roundhouse_high.fbx`, `tkd_side_kick.fbx`, `tkd_spinning_heel_kick.fbx`.
- Weapons (lower priority): `spear_thrust_sequence.fbx`, `staff_block.fbx`, `staff_combo.fbx`, `staff_overhead_strike.fbx`, `staff_spin_guard.fbx`, `staff_sweep_legs.fbx`, `staff_thrust.fbx`, `sword_block_high.fbx`, `sword_combo_slash_thrust.fbx`, `sword_draw_stance.fbx`, `sword_overhead_strike.fbx`, `sword_parry_and_riposte.fbx`, `sword_sheathe.fbx`, `sword_slash_diagonal_down.fbx`, `sword_slash_horizontal.fbx`, `sword_spinning_slash.fbx`, `sword_thrust_forward.fbx`.

## التالي
أضف `Jammo_LowPoly.fbx` إلى `characters/Jammo/`, افحص عدد عظامه ووضعية الراحة، ثم أعد استهداف Body Slam واختبره بصريًا. هذه المرحلة تخص Jammo فقط؛ لا AJ ولا Orton. حركة Body Slam المصدرية لا تثبت وحدها وجود حركة رد فعل متزامنة للخصم.