#pragma comment(lib,"user32.lib") // the linker doesnt automatically include every static library. common ones like kernal32 or std libs seem to get linked in automatically. but for user32, i have to manually specify it either as a link option or as a pragma. i chose pragma.
#pragma comment(lib, "gdi32.lib")

#include <windows.h>
#include <stdio.h>

HINSTANCE DLLHandleInstance;

BOOL DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) { // reserved function. called when this DLL is loaded.
    DLLHandleInstance = hinstDLL;
    // printf("hinstDLL: %d, fdwReason: %u, lpvReserved: %p\n", (*hinstDLL).unused, fdwReason, lpvReserved); // DEBUG
    return TRUE;
}