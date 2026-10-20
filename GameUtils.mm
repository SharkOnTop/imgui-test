#import "GameUtils.h"
#include <mach-o/dyld.h>

// ═══════════════════════════════════════════
// OFFSETS — OB51 dump থেকে (latest patch-এ verify করো)
// ═══════════════════════════════════════════
#define OFF_CURRENT_MATCH         0x2ED8984
#define OFF_CURRENT_LOCAL_PLAYER  0x2ED9F38
#define OFF_GET_LOCAL_PLAYER      0x2ED9550
#define OFF_GET_MAX_HP            0x27A072C
#define OFF_GET_CUR_HP            0x27A05F0
#define OFF_WORLD_TO_SCREEN       0x72A9EEC
#define OFF_GET_TRANSFORM         0x72AC7B8
#define OFF_GET_POSITION          0x6F7063C
#define OFF_GET_HEAD_COLLIDER     0x27449A4
#define OFF_SET_AIM_ROTATION      0x274648C
#define OFF_IS_LOCAL_TEAMMATE     0x275ED84
#define OFF_FAKE_NAME             0x2741C98

// ── এগুলো Il2CppDumper দিয়ে বের করতে হবে ──
#define OFF_MATCH_ALL_PLAYERS     0x000000   // Match.AllPlayers
#define OFF_LIST_ITEMS            0x10       // List<T>.items
#define OFF_LIST_SIZE             0x18       // List<T>.size
#define OFF_LIST_ARRAY_START      0x20       // first element ptr
#define OFF_TEAM_ID               0x000000   // Player.teamId

uintptr_t g_baseAddress = 0;

uintptr_t GetBaseAddress() {
    if (g_baseAddress) return g_baseAddress;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (!name) continue;
        if (strstr(name, "UnityFramework") || strstr(name, "FreeFire")) {
            g_baseAddress = (uintptr_t)_dyld_get_image_header(i);
            return g_baseAddress;
        }
    }
    return 0;
}

uintptr_t GetCurrentMatch() {
    if (!GetBaseAddress()) return 0; // Crash Protection
    typedef uintptr_t (*Fn)(void);
    Fn fn = (Fn)(GetBaseAddress() + OFF_CURRENT_MATCH);
    return fn ? fn() : 0;
}

uintptr_t GetLocalPlayer() {
    if (!GetBaseAddress()) return 0; // Crash Protection
    typedef uintptr_t (*Fn)(void);
    Fn fn = (Fn)(GetBaseAddress() + OFF_CURRENT_LOCAL_PLAYER);
    return fn ? fn() : 0;
}

std::vector<uintptr_t> GetAllPlayers() {
    std::vector<uintptr_t> out;
    
    // Crash Protection: অফসেট 0 হলে কিছুই রিটার্ন করবে না
    if (OFF_MATCH_ALL_PLAYERS == 0x000000) return out; 

    uintptr_t match = GetCurrentMatch();
    if (!match) return out;

    uintptr_t list = ReadMem<uintptr_t>(match + OFF_MATCH_ALL_PLAYERS);
    if (!list) return out;

    int count = ReadMem<int>(list + OFF_LIST_SIZE);
    uintptr_t items = ReadMem<uintptr_t>(list + OFF_LIST_ITEMS);
    if (!items || count <= 0 || count > 200) return out;

    for (int i = 0; i < count; i++) {
        uintptr_t p = ReadMem<uintptr_t>(items + OFF_LIST_ARRAY_START + i * 8);
        if (p) out.push_back(p);
    }
    return out;
}

Vec3 GetPlayerPosition(uintptr_t player) {
    if (!player || !GetBaseAddress()) return {0,0,0};
    typedef uintptr_t (*GetTransform)(uintptr_t);
    GetTransform gt = (GetTransform)(GetBaseAddress() + OFF_GET_TRANSFORM);
    if (!gt) return {0,0,0};
    
    uintptr_t tr = gt(player);
    if (!tr) return {0,0,0};

    typedef Vec3 (*GetPos)(uintptr_t);
    GetPos gp = (GetPos)(GetBaseAddress() + OFF_GET_POSITION);
    if (!gp) return {0,0,0};
    
    return gp(tr);
}

Vec3 GetHeadPosition(uintptr_t player) {
    if (!player || !GetBaseAddress()) return {0,0,0};
    typedef uintptr_t (*GetHead)(uintptr_t);
    GetHead gh = (GetHead)(GetBaseAddress() + OFF_GET_HEAD_COLLIDER);
    if (!gh) return {0,0,0};
    
    uintptr_t col = gh(player);
    if (!col) return {0,0,0};
    return GetPlayerPosition(col);
}

Vec2 WorldToScreen(Vec3 world) {
    if (!GetBaseAddress()) return {-1, -1};
    typedef Vec3 (*Fn)(Vec3);
    Fn fn = (Fn)(GetBaseAddress() + OFF_WORLD_TO_SCREEN);
    if (!fn) return {-1, -1};
    
    Vec3 s = fn(world);
    return {s.x, s.y};
}

bool IsEnemy(uintptr_t local, uintptr_t other) {
    if (!local || !other) return false;
    
    // Crash Protection: টিম আইডি অফসেট 0 হলে সবারে এনিমি হিসেবে ধরে নিবে (যাতে ক্র্যাশ না হয়)
    if (OFF_TEAM_ID == 0x000000) return true; 
    
    int myTeam = ReadMem<int>(local + OFF_TEAM_ID);
    int otherTeam = ReadMem<int>(other + OFF_TEAM_ID);
    return myTeam != otherTeam;
}

bool IsAlive(uintptr_t player) {
    return GetCurHP(player) > 0;
}

int GetCurHP(uintptr_t player) {
    if (!player || !GetBaseAddress()) return 0;
    typedef int (*Fn)(uintptr_t);
    Fn fn = (Fn)(GetBaseAddress() + OFF_GET_CUR_HP);
    return fn ? fn(player) : 0;
}

int GetMaxHP(uintptr_t player) {
    if (!player || !GetBaseAddress()) return 100;
    typedef int (*Fn)(uintptr_t);
    Fn fn = (Fn)(GetBaseAddress() + OFF_GET_MAX_HP);
    return fn ? fn(player) : 100;
}

float Distance2D(Vec2 a, Vec2 b) {
    return sqrtf(powf(a.x - b.x, 2) + powf(a.y - b.y, 2));
}

uintptr_t SelectNearestTarget(Vec2 screenCenter, float fov) {
    uintptr_t local = GetLocalPlayer();
    if (!local) return 0;

    uintptr_t best = 0;
    float bestDist = 1e9f;

    for (uintptr_t e : GetAllPlayers()) {
        if (e == local) continue;
        if (!IsEnemy(local, e)) continue;
        if (!IsAlive(e)) continue;

        Vec3 headWorld = GetHeadPosition(e);
        Vec2 headScreen = WorldToScreen(headWorld);
        if (headScreen.x < 0) continue; // off-screen

        float d = Distance2D(screenCenter, headScreen);
        if (d < fov && d < bestDist) {
            bestDist = d;
            best = e;
        }
    }
    return best;
}

void SetAimRotation(uintptr_t localPlayer, Vec3 rotation) {
    if (!localPlayer || !GetBaseAddress()) return;
    typedef void (*Fn)(uintptr_t, Vec3);
    Fn fn = (Fn)(GetBaseAddress() + OFF_SET_AIM_ROTATION);
    if (fn) fn(localPlayer, rotation);
}
