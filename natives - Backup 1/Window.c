#define EXPORT __declspec(dllexport)

#include <windows.h>
#include <stdio.h>

#include "Variables.h"

HWND windowHandle;

// windowHandle is the current window
LRESULT CALLBACK windowProcedure(HWND windowHandle, UINT message, WPARAM wParameter, LPARAM lParameter) {
    printf("windowHandle: %d, message: %d, wParameter: %d, lParameter: %d", windowHandle, message, wParameter, lParameter);
    return DefWindowProc(windowHandle, message, wParameter, lParameter);
}

EXPORT void startWindow(void) {

    LPCSTR className = "FOXXEY_TESTPROGRAM";

    WNDCLASSEX windowClass = {
        sizeof(WNDCLASSEX),
        0,
        windowProcedure, // callback function. handle messages sent to this window. behavior.
        0,
        0,
        DLLHandle, // handle instance of place that has the window procedure (this place) (if its a dll, which this is, it has its own handle instance separate from the calling program. this DLL's handle instance is in DLLHandle)
        NULL, // icon
        NULL, // cursor
        NULL, // background brush
        NULL, // menu name?
        className,
        NULL
    };

    RegisterClassEx(&windowClass);

    windowHandle = CreateWindowEx(
        WS_EX_COMPOSITED | WS_EX_LAYERED | WS_EX_NOREDIRECTIONBITMAP | WS_EX_TOPMOST | WS_EX_TRANSPARENT, // OO INTERESTING. LOOK INTO.
        className,
        NULL, // i dont want it to have a title bar at all, so i dont need a title name.
        WS_MAXIMIZE | WS_SIZEBOX | WS_VISIBLE,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        NULL, // parent. this window will be a normal one, so theres no parent.
        NULL, // menu?
        DLLHandle, // handle instance
        NULL
    );

    if (windowHandle == NULL) {
        return;
    }

    return;
}