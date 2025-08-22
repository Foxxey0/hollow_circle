#define EXPORT __declspec(dllexport)
#define THREAD_HANDLES_AMOUNT 2 // hard coded. its the amount of threads that will ever exist.

#include <windows.h>
#include <stdio.h>

#include "Variables.h"

struct MousePos {
    short x;
    short y;
};

HWND windowHandle;

HANDLE threadHandlesArray[THREAD_HANDLES_AMOUNT];
HANDLE *threadHandles = threadHandlesArray;
// thread 0 is main thread (used to run startWindow() here)
// thread 1 is windowLogic (used to do logic like resizing or dragging window even if mouse isnt on window. which is why i cant do everything in windowProcedure())

DWORD windowLogic_id;
HANDLE windowLogic_handle;

// drag variables
boolean dragging = FALSE;
short draggingRelativeX = 0; // mouse position relative to window position (top left corner of window). mousePos -windowPos
short draggingRelativeY = 0;

// resize variables (theyre shorts because thats all i need. pixel dimensions on screen will always fit in shorts)
short resizeBorder = 20;
boolean resizing = FALSE;
unsigned char resizingType = 0; // clockwise from top left. Ex. 0 - top left, 1 - top, 2 - top right, 3 - right. theres only 8 types. so this value is from 0 to 7.
short resizingOriginalMousePosXRelativeToPos = 0; // its just the way the c window procedure parameters are. the mouse pos is relative to the window pos (top left).
short resizingOriginalMousePosYRelativeToPos = 0;
short resizingOriginalPosX = 0;
short resizingOriginalPosY = 0;
short resizingOriginalWidth = 0;
short resizingOriginalHeight = 0;

// helper method
// void printBits(byte *bytesPointer, UINT8 bytesAmount) { // READS IT AS IT IS ON THE SYSTEM. if its a known type like short or int or long or anything, then it wont print the way you expect. modern systems use little-endian, meaning the order of BYTES is reversed. the order of bits is the same though.
//     byte currentByte;
//     byte currentBit; // we still have to represent it as a byte since we cant go smaller than that.
//     for (int byteIndex = 0; byteIndex <= bytesAmount -1; byteIndex++) { // loops through bytes
//         currentByte = bytesPointer[byteIndex];
//         for (int bitIndex = 0; bitIndex <= 8 -1; bitIndex++) { // loops through bits
//             currentBit = currentByte & 0b10000000; // get truncated version of byte
//             if (currentBit == 0b10000000) {
//                 printf("1");
//             } else if (currentBit == 0b00000000) {
//                 printf("0");
//             } else {
//                 printf("wrong.");
//             }
//             currentByte = currentByte << 1; // prepares next one
//         }
//     }
//     printf("\n");
// }

void foxxeyExit(int exitCode) { // how can i close all threads before exiting?? i need a thread to exit!. Answer: I made an array of all thread handles that will exist, and i will close every single one thats not the current one, and then with this remaining thread, i do exit.
    HANDLE currentThread_handle = GetCurrentThread();
    for (int i = 0; i <= THREAD_HANDLES_AMOUNT -1; i++) {
        HANDLE threadhandle = threadHandles[i];
        if (threadhandle != NULL && threadhandle != currentThread_handle) {
            CloseHandle(threadhandle);
        }
    }
    exit(exitCode);
}

struct MousePos getMousePosFromlParameter(LPARAM lParameter) {
    short mouseX = (short) lParameter; // lower short (rightmost). mousePos RELATIVE TO WINDOW.
    short mouseY = (short) (lParameter >> (sizeof(short) *8)); // next short (rightmost). reads lParameter with it shifted to the right to access the left, which are the higher bits. mousePos RELATIVE TO WINDOW. its *8 because im BITshifting, im not BYTEshifting. sizeof() returns amount of bytes.
    struct MousePos mousePos = {mouseX, mouseY};
    return mousePos;
}

void setStartResizeVariables(struct MousePos mousePos, RECT windowRect) { // variables to set when starting a resize.
    resizingOriginalMousePosXRelativeToPos = mousePos.x;
    resizingOriginalMousePosYRelativeToPos = mousePos.y;
    resizingOriginalPosX = windowRect.left;
    resizingOriginalPosY = windowRect.top;
    resizingOriginalWidth = windowRect.right -windowRect.left;
    resizingOriginalHeight = windowRect.bottom -windowRect.top;
    resizing = TRUE; // here last for protection. to make sure all other variable are set first.
}

// windowHandle is the current window
LRESULT CALLBACK windowProcedure(HWND windowHandle, UINT message, WPARAM wParameter, LPARAM lParameter) {
    printf("windowHandle: %d, message: %d, wParameter: %d, lParameter: %d\n", windowHandle, message, wParameter, lParameter);

    if (message == WM_LBUTTONDOWN) { // check resizing first because its on top of the window where you could normally drag.
        if (!dragging) { // safe to resize.
            if (!resizing) { // not resizing yet but can. so START resizing.
                struct MousePos mousePos = getMousePosFromlParameter(lParameter);

                RECT windowRect;
                if (!GetWindowRect(windowHandle, &windowRect)) {
                    printf("EXITING: GetWindowRect() failed.\n");
                    foxxeyExit(-1);
                }

                if (mousePos.x <= resizeBorder -1) { // left
                    if (mousePos.y <= resizeBorder -1) { // left +top
                        resizingType = 0;
                        setStartResizeVariables(mousePos, windowRect);
                    } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // left +bottom
                        resizingType = 6;
                        setStartResizeVariables(mousePos, windowRect);
                    } else { // only left
                        resizingType = 7;
                        setStartResizeVariables(mousePos, windowRect);
                    }
                } else if (mousePos.x >= (windowRect.right -windowRect.left) -(resizeBorder -1)) { // right
                    if (mousePos.y <= resizeBorder -1) { // right +top
                        resizingType = 2;
                        setStartResizeVariables(mousePos, windowRect);
                    } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // right +bottom
                        resizingType = 4;
                        setStartResizeVariables(mousePos, windowRect);
                    } else { // only right
                        resizingType = 3;
                        setStartResizeVariables(mousePos, windowRect);
                    }
                } else if (mousePos.y <= resizeBorder -1) { // top
                    resizingType = 1;
                    setStartResizeVariables(mousePos, windowRect);
                } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // bottom
                    resizingType = 5;
                    setStartResizeVariables(mousePos, windowRect);
                }
            }
        }
        if (!resizing) { // safe to drag.
            if (!dragging) { // not dragging yet but can. so START dragging.
                struct MousePos mousePos = getMousePosFromlParameter(lParameter);
                dragging = TRUE;
                draggingRelativeX = mousePos.x; // these are already relative to the window so i can set them directly.
                draggingRelativeY = mousePos.y;
                // printf("draggingRelativeX: %hd, draggingRelativeY: %hd\n", draggingRelativeX, draggingRelativeY); // DEBUG
            }
        }
    }


    return DefWindowProc(windowHandle, message, wParameter, lParameter);
}

// function for a thread
DWORD WINAPI windowLogic_function(LPVOID lpThreadParameter) {
    while (1) { // do wnidow stuff

        // test if escape is down to exit
        if (GetAsyncKeyState(VK_ESCAPE) == (SHORT) 0b1000000000000000) { // have to add (SHORT) to convert it to a system number which uses little endian. this way it will reverse the order of bytes of this hard-coded thing, which is the order the system reads in, so it will read correctly.
            printf("EXITING: Escape pressed.\n");
            foxxeyExit(0);
        }
        
        // test if left mouse button is up to cancel dragging and resizing
        if (GetAsyncKeyState(VK_LBUTTON) == (SHORT) 0b0000000000000000) {
            resizing = FALSE;
            dragging = FALSE;
        }

        if (resizing) { // already resizing, so change window size
            printf("type: %d\n", resizingType);
            POINT mousePos;
            if (GetCursorPos(&mousePos) == 0) {
                printf("EXITING: GetCursorPos() failed.\n");
                foxxeyExit(-1);
            }
            int mousePosX_delta = mousePos.x -(resizingOriginalMousePosXRelativeToPos +resizingOriginalPosX);
            int mousePosY_delta = mousePos.y -(resizingOriginalMousePosYRelativeToPos +resizingOriginalPosY);

            if (resizingType == 7) { // W
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 3) { // E
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 1) { // N
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 5) { // S
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth, resizingOriginalHeight +mousePosY_delta, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 0) { // NW
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 2) { // NE
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 6) { // SW
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight +mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            } else if (resizingType == 4) { // SE
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight +mousePosY_delta, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxeyExit(-1);
                }
            }
        } else if (dragging) { // already dragging, so move window. "else if" because it should only be 1 at a time. protection.
            POINT mousePos;
            if (GetCursorPos(&mousePos) == 0) {
                printf("EXITING: GetCursorPos() failed.\n");
                foxxeyExit(-1);
            }
            // printf("mouseX: %ld, mouseY: %ld\n", mousePos.x, mousePos.y); // DEBUG
            if (!SetWindowPos(windowHandle, NULL, mousePos.x -draggingRelativeX -1, mousePos.y -draggingRelativeY -1, 0, 0, SWP_NOSIZE | SWP_NOZORDER)) {
                printf("EXITING: SetWindowPos() failed.\n");
                foxxeyExit(-1);
            }
        }
    }
    return 0;
}

EXPORT void startWindow(void) {

    threadHandles[0] = GetCurrentThread(); // main thread's handle gets stored >:)

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

    if (GetClassInfoEx(DLLHandle, className, &windowClass) != 0) {
        // printf("success: window class success.\n");
    } else {
        // Class not registered or an error occurred
        // You can call GetLastError() for more specific error information
        printf("ERROR: window class failed.\n");
        foxxeyExit(-1);
    }

    windowHandle = CreateWindowEx(
        // WS_EX_COMPOSITED | WS_EX_LAYERED | WS_EX_NOREDIRECTIONBITMAP | WS_EX_TOPMOST | WS_EX_TRANSPARENT, // OO INTERESTING. LOOK INTO.
        0, // OO INTERESTING. LOOK INTO.
        className,
        NULL, // i dont want it to have a title bar at all, so i dont need a title name.
        WS_VISIBLE | WS_POPUP | WS_BORDER, // TODO
        200,
        200,
        200,
        200,
        NULL, // parent. this window will be a normal one, so theres no parent.
        NULL, // menu?
        DLLHandle, // handle instance
        NULL
    );

    if (windowHandle == NULL) {
        printf("ERROR: window is null\n");
        foxxeyExit(-1);
    } else {
        printf("window handle: %d\n", windowHandle);
    }

    // SetWindowLong(windowHandle, GWL_STYLE, 0); // removes border?

    // thread to do window logic
    windowLogic_handle = CreateThread(NULL, 0, &windowLogic_function, NULL, 0, &windowLogic_id);
    threadHandles[1] = windowLogic_handle;
    if (windowLogic_handle == NULL) {
        printf("EXITING: windowLogic_handle creation failed.\n");
        foxxeyExit(-1);
    }

    // window message listener. it HAS to be in the same thread that created the window. this cant in another thread.
    MSG msg;
    while (GetMessage(&msg, windowHandle, NULL, NULL) > 0) {
        printf("thing.\n");
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return;
}