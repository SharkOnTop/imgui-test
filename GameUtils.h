#ifndef GAMEUTILS_H
#define GAMEUTILS_H

#include <cstdint>
#include <vector>
#include <cmath>
#include <mach/mach.h>

struct Vec2 { float x, y; };
struct Vec3 { float x, y, z; };

// Memory
uintptr_t GetBaseAddress();

template<typename T>
T ReadMem(uintptr_t addr) {
    T val = {};
    if (!addr) return val;
    vm_read_overwrite(mach_task_self(), addr, sizeof(T), (vm_address_t)&val, nullptr);
    return val;
}

template<typename T>
void WriteMem(uintptr_t addr, T val) {
    if (!addr) return;
    vm_write(mach_task_self(), addr, (vm_address_t)&val, sizeof(T));
}

// Game objects
uintptr_t GetLocalPlayer();
uintptr_t GetCurrentMatch();
std::vector<uintptr_t> GetAllPlayers();

// Player data
Vec3 GetPlayerPosition(uintptr_t player);
Vec3 GetHeadPosition(uintptr_t player);
Vec2 WorldToScreen(Vec3 world);
bool IsEnemy(uintptr_t local, uintptr_t other);
bool IsAlive(uintptr_t player);
int  GetCurHP(uintptr_t player);
int  GetMaxHP(uintptr_t player);

// Targeting
float Distance2D(Vec2 a, Vec2 b);
uintptr_t SelectNearestTarget(Vec2 screenCenter, float fov);
void SetAimRotation(uintptr_t localPlayer, Vec3 rotation);

#endif
