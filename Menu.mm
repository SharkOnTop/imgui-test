#import "GameUtils.h"
#include "imgui.h"

bool g_enableESP = false;
bool g_enableAimbot = false;
bool g_enableAimLock = false;
float g_espRange = 500.0f;
float g_aimFOV = 30.0f;
float g_aimSmooth = 5.0f;
int g_aimBone = 0;
bool g_showMenu = true;

void DrawMenu() {
    if (!g_showMenu) return;

    ImGui::SetNextWindowSize(ImVec2(380, 450), ImGuiCond_FirstUseEver);
    ImGui::Begin("SHARK TOOL", &g_showMenu);

    if (ImGui::CollapsingHeader("ESP", ImGuiTreeNodeFlags_DefaultOpen)) {
        ImGui::Checkbox("Enable ESP", &g_enableESP);
        if (g_enableESP)
            ImGui::SliderFloat("Range", &g_espRange, 50, 1000, "%.0fm");
    }

    if (ImGui::CollapsingHeader("Aimbot", ImGuiTreeNodeFlags_DefaultOpen)) {
        ImGui::Checkbox("Enable Aimbot", &g_enableAimbot);
        ImGui::Checkbox("Enable Aimlock", &g_enableAimLock);
        ImGui::SliderFloat("FOV", &g_aimFOV, 5, 90, "%.0f");
        ImGui::SliderFloat("Smooth", &g_aimSmooth, 1, 20, "%.1f");

        ImGui::Text("Aim Bone:");
        ImGui::RadioButton("Head", &g_aimBone, 0); ImGui::SameLine();
        ImGui::RadioButton("Neck", &g_aimBone, 1); ImGui::SameLine();
        ImGui::RadioButton("Chest", &g_aimBone, 2);
    }

    ImGui::Separator();
    if (ImGui::Button("Hide Menu")) g_showMenu = false;

    ImGui::End();
}
