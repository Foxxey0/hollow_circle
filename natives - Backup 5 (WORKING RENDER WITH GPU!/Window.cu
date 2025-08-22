#define EXPORT __declspec(dllexport)

#define THREAD_HANDLES_AMOUNT 2 // hard coded. its the amount of threads that will ever exist.

#include <windows.h>
#include <stdio.h>

#include "Init.h"
#include "MathHelper.h"
#include "CudaStuff.h"

// I made my own point struct for mousepos (inside screen, so cant be negative) because i realized i never need anything bigger than a short for screen dimension stuff like mouse position.
struct foxxey_MousePos {
    UINT16 x;
    UINT16 y;
};

HWND windowHandle;
HDC windowDeviceContextHandle; // its like a windowHandle, but for GDI. So its a graphical interface handle. this acts as a front buffer (but its actually a second buffer since this isnt the screen. theres a step after this thats a real front buffer). whatever is drawn here will be drawn to the window graphics which THEN get composed into the final display thing which includes other windows and stuff.
BITMAPINFOHEADER bitmapInfoHeader;
BITMAPINFO bitmapInfo; // contains the bitmapInfoHeader.
byte *bitmap; // has to be in BGR, and every row must be a multiple of 4 bytes long. just add some bytes of padding at the end of the row to do that.
// HDC memoryDeviceContextHandle; // a separate memory device context. this acts as the second buffer (but its actually the third buffer). we can draw to this one at any time.
// HBITMAP bitmapHandle; // is in context of the memoryDeviceContextHandle. this is the actual bitmap handle for our "second" buffer.

HANDLE threadHandlesArray[THREAD_HANDLES_AMOUNT];
HANDLE *threadHandles = threadHandlesArray;
// thread 0 is main thread (used to run startWindow() here)
// thread 1 is windowLogic (used to do logic like resizing or dragging window even if mouse isnt on window. which is why i cant do everything in windowProcedure())

DWORD windowLogic_id;
HANDLE windowLogic_handle;

// drag variables
boolean dragging = FALSE;
UINT16 draggingRelativeX = 0; // mouse position relative to window position (top left corner of window). mousePos -windowPos
UINT16 draggingRelativeY = 0;

// resize variables (theyre shorts because thats all i need. pixel dimensions on screen will always fit in shorts)
UINT16 resizeBorder = 20;
boolean resizing = FALSE;
boolean cursorOnResizeBorder = FALSE;
UINT8 resizingType = 0; // clockwise from top left. Ex. 0 - top left, 1 - top, 2 - top right, 3 - right. theres only 8 types. so this value is from 0 to 7.
INT16 resizingOriginalMousePosXRelativeToPos = 0; // its just the way the c window procedure parameters are. the mouse pos is relative to the window pos (top left).
INT16 resizingOriginalMousePosYRelativeToPos = 0;
INT16 resizingOriginalPosX = 0;
INT16 resizingOriginalPosY = 0;
UINT16 resizingOriginalWidth = 0;
UINT16 resizingOriginalHeight = 0;

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

void foxxey_Exit(INT8 exitCode) { // how can i close all threads before exiting?? i need a thread to exit!. Answer: I made an array of all thread handles that will exist, and i will close every single one thats not the current one, and then with this remaining thread, i do exit.
    HANDLE currentThread_handle = GetCurrentThread();
    for (UINT8 i = 0; i <= THREAD_HANDLES_AMOUNT -1; i++) {
        HANDLE threadhandle = threadHandles[i];
        if (threadhandle != NULL && threadhandle != currentThread_handle) {
            CloseHandle(threadhandle);
        }
    }

    free(bitmap);
    // DeleteObject(bitmapHandle); // we created this one
    // DeleteDC(memoryDeviceContextHandle); // we created this one
    ReleaseDC(windowHandle, windowDeviceContextHandle); // we got this one

    exit(exitCode);
}

struct foxxey_MousePos getMousePosFromlParameter(LPARAM lParameter) {
    UINT16 mouseX = (UINT16) lParameter; // lower short (rightmost). mousePos RELATIVE TO WINDOW.
    UINT16 mouseY = (UINT16) (lParameter >> (sizeof(UINT16) *8)); // next short (rightmost). reads lParameter with it shifted to the right to access the left, which are the higher bits. mousePos RELATIVE TO WINDOW. its *8 because im BITshifting, im not BYTEshifting. sizeof() returns amount of bytes.
    struct foxxey_MousePos mousePos = {mouseX, mouseY};
    return mousePos;
}

void setStartResizeVariables(struct foxxey_MousePos mousePos, RECT windowRect) { // variables to set when starting a resize.
    resizingOriginalMousePosXRelativeToPos = mousePos.x;
    resizingOriginalMousePosYRelativeToPos = mousePos.y;
    resizingOriginalPosX = windowRect.left;
    resizingOriginalPosY = windowRect.top;
    resizingOriginalWidth = windowRect.right -windowRect.left;
    resizingOriginalHeight = windowRect.bottom -windowRect.top;
    resizing = TRUE; // here last for protection. to make sure all other variable are set first.
}

// specifically for RGB bitmap
__host__ __device__ long rowBytesAmountToPaddedRowBytesAmount(long rowBytesAmount) {
    UINT8 paddingBytesAmount = 4 -(rowBytesAmount %4);
    if (paddingBytesAmount == 4) {
        paddingBytesAmount = 0;
    }
    return rowBytesAmount +paddingBytesAmount;
}

// windowHandle is the current window
LRESULT CALLBACK windowProcedure(HWND windowHandle, UINT message, WPARAM wParameter, LPARAM lParameter) {
    // printf("windowHandle: %d, message: %d, wParameter: %d, lParameter: %d\n", windowHandle, message, wParameter, lParameter); // DEBUG

    if (message == WM_MOUSEMOVE) {
        struct foxxey_MousePos mousePos = getMousePosFromlParameter(lParameter);

        RECT windowRect;
        if (!GetWindowRect(windowHandle, &windowRect)) {
            printf("EXITING: GetWindowRect() failed.\n");
            foxxey_Exit(-1);
        }

        if (!resizing) { // check if not resizing. if it is resizing, these variables should not change because the type of resize cant change during a resize.
            cursorOnResizeBorder = TRUE;

            if (mousePos.x <= resizeBorder -1) { // left
                if (mousePos.y <= resizeBorder -1) { // left +top
                    resizingType = 0;
                } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // left +bottom
                    resizingType = 6;
                } else { // only left
                    resizingType = 7;
                }
            } else if (mousePos.x >= (windowRect.right -windowRect.left) -(resizeBorder -1)) { // right
                if (mousePos.y <= resizeBorder -1) { // right +top
                    resizingType = 2;
                } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // right +bottom
                    resizingType = 4;
                } else { // only right
                    resizingType = 3;
                }
            } else if (mousePos.y <= resizeBorder -1) { // top
                resizingType = 1;
            } else if (mousePos.y >= (windowRect.bottom -windowRect.top) -(resizeBorder -1)) { // bottom
                resizingType = 5;
            } else {
                cursorOnResizeBorder = FALSE;
            }
        }
    } else if (message == WM_LBUTTONDOWN) { // check resizing first because its on top of the window where you could normally drag.
        if (!dragging) { // safe to resize.
            if (!resizing) { // not resizing yet but can. so START resizing.
                struct foxxey_MousePos mousePos = getMousePosFromlParameter(lParameter);

                RECT windowRect;
                if (!GetWindowRect(windowHandle, &windowRect)) {
                    printf("EXITING: GetWindowRect() failed.\n");
                    foxxey_Exit(-1);
                }
                if (cursorOnResizeBorder) {
                    setStartResizeVariables(mousePos, windowRect);
                }
            }
        }
        if (!resizing) { // safe to drag.
            if (!dragging) { // not dragging yet but can. so START dragging.
                struct foxxey_MousePos mousePos = getMousePosFromlParameter(lParameter);
                dragging = TRUE;
                draggingRelativeX = mousePos.x; // these are already relative to the window so i can set them directly.
                draggingRelativeY = mousePos.y;
                // printf("draggingRelativeX: %hd, draggingRelativeY: %hd\n", draggingRelativeX, draggingRelativeY); // DEBUG
            }
        }
    } else if (message == WM_SETCURSOR) { // cursor stuff. this is called whenever mouse moves over window. and thats fine. thats all i need.
        HCURSOR cursorHandle;
        if (cursorOnResizeBorder) {
            if (resizingType == 0 || resizingType == 4) {
                cursorHandle = LoadCursor(NULL, IDC_SIZENWSE);
            } else if (resizingType == 1 || resizingType == 5) {
                cursorHandle = LoadCursor(NULL, IDC_SIZENS);
            } else if (resizingType == 2 || resizingType == 6) {
                cursorHandle = LoadCursor(NULL, IDC_SIZENESW);
            } else if (resizingType == 3 || resizingType == 7) {
                cursorHandle = LoadCursor(NULL, IDC_SIZEWE);
            }
        } else {
            cursorHandle = LoadCursor(NULL, IDC_ARROW); // default
        }
        if (cursorHandle == NULL) {
            printf("EXITING: LoadCursor() failed.\n");
            foxxey_Exit(-1);
        }
        SetCursor(cursorHandle);
        return TRUE;
    }

    return DefWindowProc(windowHandle, message, wParameter, lParameter);
}

// function for a thread
DWORD WINAPI windowLogic_function(LPVOID lpThreadParameter) {
    SYSTEMTIME startTime; // time how long an iteration takes :)
    SYSTEMTIME endTime;
    WORD timeTaken;
    float FPS;
    while (1) { // do wnidow stuff

        GetLocalTime(&startTime);

        // test if escape is down to exit
        if (GetAsyncKeyState(VK_ESCAPE) == (SHORT) 0b1000000000000000) { // have to add (SHORT) to convert it to a system number which uses little endian. this way it will reverse the order of bytes of this hard-coded thing, which is the order the system reads in, so it will read correctly.
            printf("EXITING: Escape pressed.\n");
            foxxey_Exit(0);
        }
        
        // test if left mouse button is up to cancel dragging and resizing
        if (GetAsyncKeyState(VK_LBUTTON) == (SHORT) 0b0000000000000000) {
            resizing = FALSE;
            dragging = FALSE;
        }

        if (resizing) { // resizing, so change window size
            POINT mousePos;
            if (GetCursorPos(&mousePos) == 0) {
                printf("EXITING: GetCursorPos() failed.\n");
                foxxey_Exit(-1);
            }
            // i wish i didnt have to use "int" for these. screenwidth even for high-end computers is never over 65,000. and the type that goes up to 65,000 is a UINT16. so UINT16 is more than enough. but windows doesnt accept that, so i just have to pass in an int. stupid windows.
            int mousePosX_delta = mousePos.x -(resizingOriginalMousePosXRelativeToPos +resizingOriginalPosX);
            int mousePosY_delta = mousePos.y -(resizingOriginalMousePosYRelativeToPos +resizingOriginalPosY);

            if (resizingType == 7) { // W
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 3) { // E
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 1) { // N
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 5) { // S
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth, resizingOriginalHeight +mousePosY_delta, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 0) { // NW
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 2) { // NE
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight -mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 6) { // SW
                if (!SetWindowPos(windowHandle, NULL, resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY, resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight +mousePosY_delta, SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            } else if (resizingType == 4) { // SE
                if (!SetWindowPos(windowHandle, NULL, 0, 0, resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight +mousePosY_delta, SWP_NOMOVE | SWP_NOZORDER)) {
                    printf("EXITING: SetWindowPos() failed.\n");
                    foxxey_Exit(-1);
                }
            }

            // reset bitmap and bitmap info
            RECT windowRect;
            if (!GetWindowRect(windowHandle, &windowRect)) {
                printf("EXITING: GetWindowRect() failed.\n");
                foxxey_Exit(-1);
            }
            UINT16 windowWidth = windowRect.right -windowRect.left; // useful to make variable since i use these twice below
            UINT16 windowHeight = windowRect.bottom -windowRect.top; // useful to make variable since i use these twice below

            free(bitmap);
            bitmap = (byte *) malloc(rowBytesAmountToPaddedRowBytesAmount(windowWidth *3) *windowHeight);
            bitmapInfoHeader.biWidth = windowWidth;
            bitmapInfoHeader.biHeight = -windowHeight;
            bitmapInfo.bmiHeader = bitmapInfoHeader;
        } else if (dragging) { // dragging, so move window. "else if" because it should only be 1 at a time. protection.
            POINT mousePos;
            if (GetCursorPos(&mousePos) == 0) {
                printf("EXITING: GetCursorPos() failed.\n");
                foxxey_Exit(-1);
            }
            // printf("mouseX: %ld, mouseY: %ld\n", mousePos.x, mousePos.y); // DEBUG
            if (!SetWindowPos(windowHandle, NULL, mousePos.x -draggingRelativeX -1, mousePos.y -draggingRelativeY -1, 0, 0, SWP_NOSIZE | SWP_NOZORDER)) {
                printf("EXITING: SetWindowPos() failed.\n");
                foxxey_Exit(-1);
            }
        }
        
        // draw stuff
        // Rectangle(windowDeviceContext, 10, 30, 60, 80); // test
        RECT windowRect;
        if (!GetWindowRect(windowHandle, &windowRect)) {
            printf("EXITING: GetWindowRect() failed.\n");
            foxxey_Exit(-1);
        }
        // functional test!
        UINT16 windowWidth = windowRect.right -windowRect.left;
        UINT16 windowHeight = windowRect.bottom -windowRect.top;
        // long paddedRowBytesAmount = rowBytesAmountToPaddedRowBytesAmount(windowWidth *3);

        // for (int row = 0; row <= windowHeight -1; row++) { // test
        //     for (int col = 0; col <= windowWidth -1; col++) {
        //         if (row <= 10 -1) {
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +0)] = 0; // B
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +1)] = 255; // G
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +2)] = 255; // R
        //         } else {
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +0)] = 0; // B
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +1)] = 0; // G
        //             bitmap[(row *paddedRowBytesAmount) +(col *3 +2)] = 0; // R
        //         }
        //     }
        // }

        // hard-coded
        SYSTEMTIME time;
        GetLocalTime(&time);

        float circleMiddleX = (windowRect.right -windowRect.left) /2; // middle of circle
        float circleMiddleY = (windowRect.bottom -windowRect.top) /2; // middle of circle
        float borderWidth = 10;
        UINT32 totalAnimationTime = 9000; // in millis
        UINT32 totalColourAnimationTime = 5000; // in millis

        float radius;
        float progress = getProgress(totalAnimationTime);
        if (progress < .5f) { // 0 to .5
            radius = interpolate_circular_slowFastSlow(progress *2, 10, 500);
        } else { // .5 to 1
            radius = interpolate_circular_slowFastSlow((progress -.5) *2, 500, 10);
        }

        float colourProgress = getProgress(totalColourAnimationTime);
        struct colour_RGB circleColour = HSBToRGB(colourProgress, 1, 1);

        byte *d_bitmap = mallocDeviceBitmap(windowWidth, windowHeight); // malloc on device

        clearWindow(d_bitmap, windowWidth, windowHeight, {40, 43, 48});
        drawHollowCircleWithBorder(d_bitmap, windowWidth, windowHeight, circleMiddleX, circleMiddleY, radius, borderWidth, circleColour);
        drawHollowCircleWithBorder(d_bitmap, windowWidth, windowHeight, circleMiddleX +20, circleMiddleY +70, radius, borderWidth, circleColour);

        copyDeviceBitmapToHostBitmap(bitmap, windowWidth, windowHeight, d_bitmap); // copy to host
        freeDeviceBitmap(d_bitmap); // free on device
           

        // copy data from "second" buffer to "front" buffer
        // if (!BitBlt(windowDeviceContextHandle, 0, 0, 1, 1, memoryDeviceContextHandle, 0, 0, SRCCOPY)) {
        //     printf("EXITING: BitBlt() failed.\n");
        //     foxxey_Exit(-1);
        // }
        if (SetDIBitsToDevice(
            windowDeviceContextHandle, 
            0, 
            0, 
            windowRect.right -windowRect.left, 
            windowRect.bottom -windowRect.top, 
            0, 
            0, 
            0, 
            windowRect.bottom -windowRect.top, 
            bitmap, 
            &bitmapInfo, 
            DIB_RGB_COLORS
        ) == 0) {
            printf("EXITING: SetDIBitsToDevice() failed.\n");
            foxxey_Exit(-1);
        }

        GetLocalTime(&endTime);
        timeTaken = endTime.wMilliseconds -startTime.wMilliseconds;
        FPS = (timeTaken /((float) 1000));
        if (FPS == 0) { // protection against dividing by 0
            printf("MS/F: %u, FPS: INFINITE\n", timeTaken);
        } else {
            FPS = 1 /FPS; // finish the conversion from Milliseconds/Frame to Frames/Second. specifically this line converts it from Seconds/Frame to Frames/Second.
            printf("MS/F: %u, FPS: %f\n", timeTaken, FPS);
        }
    }
    return 0;
}

// entry point
extern "C" EXPORT void startWindow(void) {

    threadHandles[0] = GetCurrentThread(); // main thread's handle gets stored >:)

    
    LPCSTR className = "foxxey_TESTPROGRAM";

    WNDCLASSEX windowClass = {
        sizeof(WNDCLASSEX),
        0,
        windowProcedure, // callback function. handle messages sent to this window. behavior.
        0,
        0,
        DLLHandleInstance, // handle instance of place that has the window procedure (this place) (if its a dll, which this is, it has its own handle instance separate from the calling program. this DLL's handle instance is in DLLHandle)
        NULL, // icon
        NULL, // cursor
        NULL, // background brush
        NULL, // menu name?
        className,
        NULL
    };

    RegisterClassEx(&windowClass);

    if (GetClassInfoEx(DLLHandleInstance, className, &windowClass) != 0) {
        // printf("success: window class success.\n");
    } else {
        // Class not registered or an error occurred
        // You can call GetLastError() for more specific error information
        printf("ERROR: window class failed.\n");
        foxxey_Exit(-1);
    }

    windowHandle = CreateWindowEx(
        // WS_EX_COMPOSITED | WS_EX_LAYERED | WS_EX_NOREDIRECTIONBITMAP | WS_EX_TOPMOST | WS_EX_TRANSPARENT, // OO INTERESTING. LOOK INTO.
        0, // OO INTERESTING. LOOK INTO.
        className,
        NULL, // i dont want it to have a title bar at all, so i dont need a title name.
        WS_VISIBLE | WS_POPUP, // TODO
        200, // but it actually starts at x 201
        200, // but it actually starts at y 201
        200,
        200,
        NULL, // parent. this window will be a normal one, so theres no parent.
        NULL, // menu?
        DLLHandleInstance, // handle instance
        NULL
    );

    if (windowHandle == NULL) {
        printf("ERROR: window is null\n");
        foxxey_Exit(-1);
    }


    windowDeviceContextHandle = GetDC(windowHandle);
    if (windowDeviceContextHandle == NULL) {
        printf("EXITING: GetDC() failed.\n");
        foxxey_Exit(-1);
    }

    bitmap = (byte *) malloc(rowBytesAmountToPaddedRowBytesAmount(200 *3) *200); // this is doing bytes per row *height. i just think its the best way to do the padding since the padding must be tacked onto the end of every row.

    bitmapInfoHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmapInfoHeader.biWidth = 200;
    bitmapInfoHeader.biHeight = -200; // must be negative to flip it the right way. its just windows being stupid. real height cant be negative, but apparently setting this height to negative works.
    bitmapInfoHeader.biPlanes = 1;
    bitmapInfoHeader.biBitCount = 3 *8;
    bitmapInfoHeader.biCompression = BI_RGB;
    bitmapInfoHeader.biSizeImage = 0;
    bitmapInfoHeader.biXPelsPerMeter = 0; // meta data stuff. doesnt matter.
    bitmapInfoHeader.biYPelsPerMeter = 0; // meta data stuff. doesnt matter.
    bitmapInfoHeader.biClrUsed = 0; // no colour table. we want full colour range. a pallette for full-range would be 256^3 colours big. not worth it, clearly. we are better of not using indexes and just setting R G and B in a byte each. 3 bytes per pixel.
    bitmapInfoHeader.biClrImportant = 0;

    bitmapInfo.bmiHeader = bitmapInfoHeader; // NOTE: since this uses the value of the struct, not a reference, it must be reset every time bitmapInfoheader changes.
    // bitmapInfo.bmiColors = NULL;

    // memoryDeviceContextHandle = CreateCompatibleDC(windowDeviceContextHandle); // memory
    // if (memoryDeviceContextHandle == NULL) {
    //     printf("EXITING: CreateCompatibleDC() failed.\n");
    //     foxxey_Exit(-1);
    // }
    // bitmapHandle = CreateCompatibleBitmap(windowDeviceContextHandle, 200, 200); // why window device context handle? the docs say to use the HDC that was used to create the memory device context handle so that it uses the right colour scheme.
    // if (bitmapHandle == NULL) {
    //     printf("EXITING: CreateCompatibleBitmap() failed.\n");
    //     foxxey_Exit(-1);
    // }
    // SelectObject(memoryDeviceContextHandle, bitmapHandle);
    
    // SetWindowLong(windowHandle, GWL_STYLE, 0); // removes border?

    // thread to do window logic
    windowLogic_handle = CreateThread(NULL, 0, &windowLogic_function, NULL, 0, &windowLogic_id);
    threadHandles[1] = windowLogic_handle;
    if (windowLogic_handle == NULL) {
        printf("EXITING: windowLogic_handle creation failed.\n");
        foxxey_Exit(-1);
    }

    // window message listener. it HAS to be in the same thread that created the window. this cant in another thread.
    MSG msg;
    while (GetMessage(&msg, windowHandle, NULL, NULL) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return;
}