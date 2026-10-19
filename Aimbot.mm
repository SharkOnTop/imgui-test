#import "GameUtils.h"
#include "imgui.h"

extern bool  g_enableAimbot;
extern bool  g_enableAimLock;
extern float g_aimFOV;
extern float g_aimSmooth;
extern int   g_aimBone;

static Vec3 AimPoint(uintptr_t e, int bone) {
    Vec3 h = GetHeadPosition(e);
    Vec3 b = GetPlayerPosition(e);
    if (bone == 0) return h;
    float ratio = (bone == 1) ? 0.2f : 0.5f;
    return { h.x, h.y - (h.y - b.y) * ratio, h.z };
}

void RunAimbot() {
    if (!g_enableAimbot && !g_enableAimLock) return;

    uintptr_t local = GetLocalPlayer();
    if (!local) return;

    ImVec2 ds = ImGui::GetIO().DisplaySize;
    Vec2 center = { ds.x/2, ds.y/2 };
    uintptr_t target = SelectNearestTarget(center, g_aimFOV);
    if (!target) return;

    Vec3 tp = AimPoint(target, g_aimBone);
    Vec3 lp = GetPlayerPosition(local);
    Vec3 d = { tp.x-lp.x, tp.y-lp.y, tp.z-lp.z };

    float yaw   = atan2f(d.x, d.z) * (180.0f/M_PI);
    float pitch = -atan2f(d.y, sqrtf(d.x*d.x+d.z*d.z)) * (180.0f/M_PI);

    Vec3 rot = { pitch, yaw, 0 };
    if (g_enableAimbot && g_aimSmooth > 1.0f) {
        Vec3 cur = ReadMem<Vec3>(local + 0x1C);
        rot.x = cur.x + (rot.x - cur.x) / g_aimSmooth;
        rot.y = cur.y + (rot.y - cur.y) / g_aimSmooth;
    }

    SetAimRotation(local, rot);
}
