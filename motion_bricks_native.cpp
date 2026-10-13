#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <motionbricks/motionbricks.h>

using namespace godot;

class MotionBricksNative : public Object {
    GDCLASS(MotionBricksNative, Object)

    mb_runtime_options *options = nullptr;
    mb_model *model = nullptr;
    mb_style *style = nullptr;
    mb_agent *agent = nullptr;
    mb_command *command = nullptr;
    mb_motion *pending_motion = nullptr;
    bool configured = false;
    uint64_t seed = 1;
    String active_style;
    int current_frame = 0;
    int frame_count = 0;

    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("configure", "model_path", "style_path", "threads"), &MotionBricksNative::configure);
        ClassDB::bind_method(D_METHOD("reset"), &MotionBricksNative::reset);
        ClassDB::bind_method(D_METHOD("plan", "move", "facing", "style"), &MotionBricksNative::plan);
        ClassDB::bind_method(D_METHOD("sample", "frame_index"), &MotionBricksNative::sample);
        ClassDB::bind_method(D_METHOD("is_configured"), &MotionBricksNative::is_configured);
        ClassDB::bind_method(D_METHOD("joint_count"), &MotionBricksNative::joint_count);
    }

    void cleanup() {
        if (pending_motion) { mb_motion_free(pending_motion); pending_motion = nullptr; }
        if (agent) { mb_agent_free(agent); agent = nullptr; }
        if (style) { mb_style_free(style); style = nullptr; }
        if (command) { mb_command_free(command); command = nullptr; }
        if (model) { mb_model_free(model); model = nullptr; }
        if (options) { mb_runtime_options_free(options); options = nullptr; }
        configured = false;
    }

    bool ok(mb_status s, const char *where) {
        if (s == MB_OK) return true;
        UtilityFunctions::printerr(String("MotionBricks: ") + where + ": " + String(mb_status_string(s)));
        return false;
    }

public:
    ~MotionBricksNative() { cleanup(); }

    bool configure(String model_path, String style_path, int threads) {
        cleanup();
        char err[1024] = {};
        if (!ok(mb_runtime_options_create(&options, err, sizeof(err)), "runtime_options_create")) return false;
        if (!ok(mb_runtime_options_set_device(options, MB_DEVICE_CPU, err, sizeof(err)), "set_device")) return false;
        if (!ok(mb_runtime_options_set_threads(options, (uint32_t)MAX(1, threads), err, sizeof(err)), "set_threads")) return false;
        if (!ok(mb_model_load(model_path.utf8().get_data(), options, &model, err, sizeof(err)), "model_load")) return false;
        if (!ok(mb_command_create(&command, err, sizeof(err)), "command_create")) return false;
        if (!ok(mb_style_load(model, style_path.utf8().get_data(), &style, err, sizeof(err)), "style_load")) return false;
        if (!ok(mb_agent_create(model, &agent, err, sizeof(err)), "agent_create")) return false;
        if (!ok(mb_agent_reset(agent, style, err, sizeof(err)), "agent_reset")) return false;
        mb_command_set_seed(command, seed, err, sizeof(err));
        current_frame = 0;
        frame_count = 0;
        active_style = style_path;
        configured = true;
        return true;
    }

    bool is_configured() const { return configured; }
    int joint_count() const {
        if (!model) return 0;
        char err[256] = {};
        uint32_t n = 0;
        if (mb_model_get_joint_count(model, &n, err, sizeof(err)) != MB_OK) return 0;
        return (int)n;
    }

    void reset() {
        if (!configured) return;
        char err[256] = {};
        mb_agent_reset(agent, style, err, sizeof(err));
    }

    bool plan(Vector3 move, Vector3 facing, String style_name) {
        if (!configured) return false;
        char err[1024] = {};
        if (style_name != active_style) {
            mb_style *new_style = nullptr;
            if (mb_style_load(model, style_name.utf8().get_data(), &new_style, err, sizeof(err)) == MB_OK) {
                mb_style_free(style);
                style = new_style;
                active_style = style_name;
                mb_agent_reset(agent, style, err, sizeof(err));
            }
        }
        if (!ok(mb_command_set_movement_direction(command, move.x, move.y, move.z, err, sizeof(err)), "movement")) return false;
        if (!ok(mb_command_set_facing_direction(command, facing.x, facing.y, facing.z, err, sizeof(err)), "facing")) return false;
        mb_command_set_seed(command, seed++, err, sizeof(err));
        if (pending_motion) { mb_motion_free(pending_motion); pending_motion = nullptr; }
        if (!ok(mb_agent_plan(agent, command, &pending_motion, err, sizeof(err)), "plan")) return false;
        current_frame = 0;
        uint64_t frames = 0;
        if (pending_motion) mb_motion_get_frame_count(pending_motion, &frames, err, sizeof(err));
        frame_count = (int)frames;
        return pending_motion != nullptr;
    }

    Dictionary sample(int frame_index) {
        Dictionary out;
        if (!configured || !pending_motion) return out;
        char err[1024] = {};
        uint64_t frames = 0, joints = 0, count = 0;
        const float *roots = nullptr, *rots = nullptr;
        mb_motion_get_frame_count(pending_motion, &frames, err, sizeof(err));
        mb_motion_get_joint_count(pending_motion, &joints, err, sizeof(err));
        mb_motion_get_root_translations(pending_motion, &roots, &count, err, sizeof(err));
        mb_motion_get_local_rotations_xyzw(pending_motion, &rots, &count, err, sizeof(err));
        if (frames == 0 || joints == 0 || !rots) return out;
        int f = CLAMP(frame_index, 0, (int)frames - 1);
        Vector3 root(roots ? roots[f*3+0] : 0.0f, roots ? roots[f*3+1] : 0.0f, roots ? roots[f*3+2] : 0.0f);
        PackedFloat32Array rotations;
        rotations.resize((int)joints * 4);
        for (uint64_t j = 0; j < joints * 4; ++j) rotations[(int)j] = rots[f*joints*4+j];
        out["root"] = root;
        out["rotations"] = rotations;
        out["frames"] = (int)frames;
        out["joints"] = (int)joints;
        out["frame"] = f;
        return out;
    }

    void advance(int frames) {
        if (!configured || !agent || frames <= 0) return;
        char err[256] = {};
        if (mb_agent_advance(agent, (uint32_t)frames, err, sizeof(err)) != MB_OK) return;
        current_frame += frames;
        if (pending_motion && current_frame >= frame_count) {
            mb_motion_free(pending_motion);
            pending_motion = nullptr;
            frame_count = 0;
            current_frame = 0;
        }
    }
};

void initialize_motion_bricks(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) ClassDB::register_class<MotionBricksNative>();
}
void uninitialize_motion_bricks(ModuleInitializationLevel level) {}

extern "C" {
GDExtensionBool GDE_EXPORT motion_bricks_godot_library_init(
    GDExtensionInterfaceGetProcAddress get_proc_address,
    GDExtensionClassLibraryPtr library,
    GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init_obj(get_proc_address, library, initialization);
    init_obj.register_initializer(initialize_motion_bricks);
    init_obj.register_terminator(uninitialize_motion_bricks);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
