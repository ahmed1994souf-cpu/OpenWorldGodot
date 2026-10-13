# MotionBricks runtime assets

Place the official MotionBricks model bundle here, preserving its bundle directory structure, then point the player adapter at it.

Important: the upstream model outputs the Unitree G1 skeleton (34-joint representation). This project therefore keeps the native layer isolated and uses the existing player animations as a safe fallback until the retarget map is validated on-device.
