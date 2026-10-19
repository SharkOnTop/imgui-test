#import "GameUtils.h"
#include "imgui.h"

extern bool g_enableESP;
extern float g_espRange;

void DrawESP() {
    if (!g_enableESP) return;
    uintptr_t local = GetLocalPlayer();
    if (!local) return;

    Vec3 localPos = GetPlayerPosition(local);
    ImDrawList* d = ImGui::GetBackgroundDrawList();

    for (uintptr_t e : GetAllPlayers()) {
        if (e == local || !IsEnemy(local, e) || !IsAlive(e)) continue;

        Vec3 ePos = GetPlayerPosition(e);
        float dist = sqrtf(powf(ePos.x-localPos.x,2) +
                           powf(ePos.y-localPos.y,2) +
                           powf(ePos.z-localPos.z,2));
        if (dist > g_espRange) continue;

        Vec3 hw = GetHeadPosition(e);
        Vec2 hs = WorldToScreen(hw);
        Vec2 fs = WorldToScreen(ePos);
        if (hs.x < 0 || fs.x < 0) continue;

        float h = fs.y - hs.y;
        float w = h * 0.6f;
        float x = hs.x - w / 2;

        d->AddRect(ImVec2(x, hs.y), ImVec2(x+w, hs.y+h),
                   IM_COL32(0,200,255,255), 0.0f, 0, 2.0f);

        int cur = GetCurHP(e);
        int mx  = GetMaxHP(e);
        float r = mx > 0 ? (float)cur/mx : 0;

        d->AddRectFilled(ImVec2(x-8, hs.y), ImVec2(x-4, hs.y+h),
                         IM_COL32(0,0,0,180));
        d->AddRectFilled(ImVec2(x-8, hs.y+h*(1-r)), ImVec2(x-4, hs.y+h),
                         IM_COL32(0,255,100,255));

        char buf[32];
        snprintf(buf, sizeof(buf), "%.0fm", dist);
        d->AddText(ImVec2(x, hs.y-14), IM_COL32(255,255,255,255), buf);
        d->AddText(ImVec2(x, hs.y+h+4), IM_COL32(255,100,100,255), "ENEMY");
    }
}
