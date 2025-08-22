#include <windows.h>

HINSTANCE DLLHandle;

BOOL DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) { // reserved function. called when this DLL is loaded.
    DLLHandle = hinstDLL;
    return TRUE;
}