#define EXPORT __declspec(dllexport)

// #define sqrtOf2 1.4142135623730950488016887242097f
#define halfOfsqrtOf2 0.7071067690849304f

#include <windows.h>
#include <stdio.h>
#include <d3d11.h>
#include <dxgi.h>
#include <cuda_d3d11_interop.h>

extern "C" {
    #include "Init.h"
    #include "MathHelper.h"
}
#include "CudaStuff.h"

// I made my own point struct for mousepos (inside screen, so cant be negative) because i realized i never need anything bigger than a short for screen dimension stuff like mouse position.
struct foxxey_MousePos {
    UINT16 x;
    UINT16 y;
};

struct resizeSafely_threadFunction_parameters {
    INT16 posX;
    INT16 posY;
    UINT16 width;
    UINT16 height;
};

struct threadInfo {
    HANDLE handle;
    DWORD id;
};

HWND windowHandle;
// HDC windowDeviceContextHandle; // its like a windowHandle, but for GDI. So its a graphical interface handle. this acts as a front buffer (but its actually a second buffer since this isnt the screen. theres a step after this thats a real front buffer). whatever is drawn here will be drawn to the window graphics which THEN get composed into the final display thing which includes other windows and stuff.
// BITMAPINFOHEADER bitmapInfoHeader;
// BITMAPINFO bitmapInfo; // contains the bitmapInfoHeader.
// byte *bitmap; // has to be in BGR, and every row must be a multiple of 4 bytes long. just add some bytes of padding at the end of the row to do that.
// HDC memoryDeviceContextHandle; // a separate memory device context. this acts as the second buffer (but its actually the third buffer). we can draw to this one at any time.
// HBITMAP bitmapHandle; // is in context of the memoryDeviceContextHandle. this is the actual bitmap handle for our "second" buffer.

struct threadInfo *threads;
UINT16 threadsArraySize = 4;
UINT16 threadsNextEmptyIndex = 0; // im using this method cuz its smart. every time i add a new thread, i just do it in this index. if the index becomes bigger than the array size, THEN i check for dead threads and take their spots, and if THOSE are full, then increase array size.

// DWORD windowLogic_id;
// HANDLE windowLogic_handle;

// DWORD resizeBitmap_id;
// HANDLE resizeBitmap_handle;

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

// fullscreen stuff (custom fullscreen stuff)
BOOL canToggleFullscreen = TRUE;
INT16 fullscreenOriginalPosX = 0;
INT16 fullscreenOriginalPosY = 0;
UINT16 fullscreenOriginalWidth = 200; // just some default values, just in case.
UINT16 fullscreenOriginalHeight = 200;

// for resizeSafely() to work. wait until bitmap is NOT being drawn to, before doing ANYTHING including resizing cuz that would break the bitmap drawing midway through. // - But even then, ALSO wait for setPosition to not be happening
// by the way, the reason resizingSafely exists is so that i can resize the window from another thread. This is needed for the fullscreen thing because its triggered in the windowprocedure method, which runs in a different thread. But the manual resizing doesnt. the manual resizing happens in the same thread as the bitmap drawing, so that doesnt need a safety, its checked first.
BOOL resizingSafely = FALSE;
BOOL drawingToBitmap = FALSE;

// framebuffer stuff
ID3D11Device* devicePointer;
ID3D11DeviceContext* deviceContextPointer;
IDXGISwapChain* swapChainPointer;
ID3D11Texture2D* backBufferPointer;

cudaGraphicsResource *cudaResource;
cudaArray_t cudaArray;

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

// prints the status of each thread (if not null, its alive, i think.)
void threads_print() {
    printf("size: %u, nextempty: %u, ", threadsArraySize, threadsNextEmptyIndex);
    for (int index = 0; index <= threadsArraySize -1; index++ ) {
        if (threads[index].id == NULL) {
            printf("NULL, ");
        } else {
            DWORD threadStatus = WaitForSingleObject(threads[index].handle, 0);
            // if (threadStatus == WAIT_OBJECT_0) { // thread is dead
            //     threadHandles[index] = threadHandle;
            //     return;
            // }
            printf("status%lu, ", threadStatus);
        }
    }
    printf("\n");
}

void foxxey_Exit(INT8 exitCode) { // how can i close all threads before exiting?? i need a thread to exit!. Answer: I made an array of all thread handles that will exist, and i will close every single one thats not the current one, and then with this remaining thread, i do exit.
    DWORD currentThreadId = GetCurrentThreadId();

    for (int index = 1; index <= threadsArraySize -1; index++) { // index 0 is ALWAYS the MAIN THREAD. do NOT terminate that.
        struct threadInfo threadInfo = threads[index];
        printf("thread Id: %lu, current Thread Id: %lu\n", threadInfo.id, currentThreadId); // DEBUG
        if (threadInfo.id != NULL && threadInfo.id != currentThreadId) {
            printf("TERMINATE THREAD\n"); // DEBUG
            TerminateThread(threadInfo.handle, 0);
            CloseHandle(threadInfo.handle);
        }
    }

    // printf("END1\n"); // DEBUG

    // printf("END2\n"); // DEBUG
    // DeleteObject(bitmapHandle); // we created this one
    // DeleteDC(memoryDeviceContextHandle); // we created this one
    // ReleaseDC(windowHandle, windowDeviceContextHandle); // we got this one
    // TODO

    // printf("END3\n"); // DEBUG
    threads_print();

    free(threads); // i malloced

    exit(exitCode);
}

// takes next empty spot. if there isnt one, then look through array for a dead thread to use IT'S spot. if cant find any, then double size of array (i heard of this method online) and then add it.
void threads_add(struct threadInfo threadInfo) { // TEST IF IT WORKS
    if (threadsNextEmptyIndex > threadsArraySize -1) { // no more empty indexes. so now search for dead threads so we can take their place with this new thread. if not, then increase array size.
        for (int index = 0; index <= threadsArraySize -1; index++) { // check for dead thread
            DWORD threadStatus = WaitForSingleObject(threads[index].handle, 0);
            if (threadStatus == WAIT_OBJECT_0) { // thread is dead
                threads[index] = threadInfo;
                return;
            }
        }
        // a dead thread wasnt found. all spots are taken by live threads. so lets double the array size!
        UINT16 threadsArraySize_temp = threadsArraySize << 2; // doubles array size variable by 2. i just wanna use bitwise operator cuz its cool! also to make it faster JUST IN CASE it doesnt do it for me if i do *= 2;
        struct threadInfo *threads_temp = (struct threadInfo *) malloc(threadsArraySize_temp *sizeof(struct threadInfo)); // make temporary array of the new size
        for (int index = 0; index <= threadsArraySize -1; index++) { // copy everything from original array to new array.
            threads_temp[index] = threads[index];
        }
        free(threads); // free original array. we dont need it anymore. we have all the thread handles copied to the new array by now.
        threads = threads_temp; // set the array pointer to the temp (new) one.
        threadsArraySize = threadsArraySize_temp; // set the array size variable to the temp (new) one.
        // set all thread ids to NULL just in case.
        for (int index = 0; index <= threadsArraySize -1; index++) {
            threads[index].id = NULL;
        }
    } // else { // an empty index exists! use it immediately. now we dont have to iterate through the array!}

    threads[threadsNextEmptyIndex] = threadInfo;
    threadsNextEmptyIndex++;
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

void resizeBitmap() {
    RECT windowRect;
    if (!GetWindowRect(windowHandle, &windowRect)) {
        printf("EXITING: GetWindowRect() failed.\n");
        foxxey_Exit(-1);
    }
    UINT16 windowWidth = windowRect.right -windowRect.left; // useful to make variable since i use these twice below
    UINT16 windowHeight = windowRect.bottom -windowRect.top; // useful to make variable since i use these twice below

    // free(bitmap);
    // bitmap = (byte *) malloc(rowBytesAmountToPaddedRowBytesAmount(windowWidth *3) *windowHeight);
    // bitmapInfoHeader.biWidth = windowWidth;
    // bitmapInfoHeader.biHeight = -windowHeight;
    // bitmapInfo.bmiHeader = bitmapInfoHeader;
    // TODO
}

// thread function
DWORD WINAPI resizeSafely_threadFunction(LPVOID lpThreadParameter) {

    struct resizeSafely_threadFunction_parameters parameters = *((struct resizeSafely_threadFunction_parameters *) lpThreadParameter); // deference the struct pointer
    // printf("P3width: %ld, P3Height: %ld\n", parameters.width, parameters.height); // DEBUG
    // wait for this function's turn.
    while (1) {
        if (!drawingToBitmap) { // dont resizeSafely while its drawing to bitmap
            resizingSafely = TRUE;
            break;
        }
    }

    if (!SetWindowPos(windowHandle, NULL, parameters.posX, parameters.posY, parameters.width, parameters.height, SWP_NOZORDER)) {
        printf("EXITING: SetWindowPos() failed.\n");
        foxxey_Exit(-1);
    }

    resizeBitmap();

    resizingSafely = FALSE;

    return 0;
}

// resize, then reset bitmap and bitmap info. if resizing in another thread, we dont want it to resize at the same time bitmap is being drawn to. so we have to check the debounce variable and wait for it to be time to resize. but i dont wanna wait in the current thread, so we gotta do it in a new thread. thats what this does.
void resizeSafely(INT16 posX, INT16 posY, UINT16 width, UINT16 height) {
    // thread to resize safely and quickly so we dont have to wait in the current thread. we can do the waiting in this new thread!
    struct resizeSafely_threadFunction_parameters *arguments = (struct resizeSafely_threadFunction_parameters *) malloc(sizeof(struct resizeSafely_threadFunction_parameters)); // must malloc because im gonna pass this to a new thread which a different scope. if i use normal definition, then it will just dissapear as soon as this function ends, and the new thread would have nothing to work with. so you GOTTA malloc it so its on the heap and can be retrieved by ANY scope.
    (*arguments) = {posX, posY, width, height};
    HANDLE resizeSafely_threadHandle;
    DWORD resizeSafely_threadId;
    resizeSafely_threadHandle = CreateThread(NULL, 0, &resizeSafely_threadFunction, arguments, 0, &resizeSafely_threadId);
    struct threadInfo resizeSafely_threadInfo = {resizeSafely_threadHandle, resizeSafely_threadId};
    threads_add(resizeSafely_threadInfo);
    if (resizeSafely_threadInfo.id == NULL) {
        printf("EXITING: resizeSafely_threadInfo.id creation failed.\n");
        foxxey_Exit(-1);
    }
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
    } else if (message == WM_KEYDOWN) {
        // test if F is down to toggle fullscreen
        if (wParameter == 'F') {
            if (canToggleFullscreen) {
                canToggleFullscreen = FALSE;

                RECT windowRect;
                if (!GetWindowRect(windowHandle, &windowRect)) {
                    printf("EXITING: GetWindowRect() failed.\n");
                    foxxey_Exit(-1);
                }

                // printf("Aleft: %ld, Aright: %ld\n", windowRect.left, windowRect.right); // DEBUG

                UINT16 windowWidth = windowRect.right -windowRect.left;
                UINT16 windowHeight = windowRect.bottom -windowRect.top;
                int screenWidth = GetSystemMetrics(SM_CXSCREEN);
                int screenHeight = GetSystemMetrics(SM_CYSCREEN);

                // check if already in fullscreen. if so, then revert to what it was before the toggle fullscreen on.
                if (windowWidth == screenWidth && windowHeight == screenHeight) {
                    printf("turning fullscreen OFF\n"); // DEBUG
                    resizeSafely(fullscreenOriginalPosX, fullscreenOriginalPosY, fullscreenOriginalWidth, fullscreenOriginalHeight);
                    // if (!SetWindowPos(windowHandle, NULL, fullscreenOriginalPosX, fullscreenOriginalPosY, fullscreenOriginalWidth, fullscreenOriginalHeight, SWP_NOZORDER)) {
                    //     printf("EXITING: SetWindowPos() failed.\n");
                    //     foxxey_Exit(-1);
                    // }
                } else { // MAKE it fullscreen and save the original dimension values
                    printf("turning fullscreen ON\n"); // DEBUG
                    fullscreenOriginalPosX = windowRect.left;
                    fullscreenOriginalPosY = windowRect.top;
                    fullscreenOriginalWidth = windowWidth;
                    fullscreenOriginalHeight = windowHeight;
                    resizeSafely(0, 0, screenWidth, screenHeight);
                    // if (!SetWindowPos(windowHandle, NULL, 0, 0, screenWidth, screenHeight, SWP_NOZORDER)) {
                    //     printf("EXITING: SetWindowPos() failed.\n");
                    //     foxxey_Exit(-1);
                    // }
                }
            }
        }
    } else if (message == WM_KEYUP) {
        // test if F is UP to reset canToggleFullscreen debounce
        if (wParameter == 'F') {
            canToggleFullscreen = TRUE;
        }
    }

    return DefWindowProc(windowHandle, message, wParameter, lParameter);
}

// function for a thread
DWORD WINAPI windowLogic_threadFunction(LPVOID lpThreadParameter) {
    SYSTEMTIME startTime; // time how long an iteration takes :)
    SYSTEMTIME currentTime;
    UINT32 timeTaken;
    // float FPS;
    GetLocalTime(&startTime);

    UINT16 counter_cycles = 0;
    while (1) { // do wnidow stuff

        GetLocalTime(&currentTime);
        timeTaken = ((currentTime.wMinute *60 *1000) +(currentTime.wSecond *1000) +(currentTime.wMilliseconds)) -((startTime.wMinute *60 *1000) +(startTime.wSecond *1000) +(startTime.wMilliseconds)); // i dont think i need more than an hour of duration for now, so ill only go up to minutes :)
        // printf("%d\n", timeTaken); // DEBUG
        if (timeTaken >= 1000) { // if 1 second has passed, see how many frames happened in that second
            printf("FPS: %hu\n", counter_cycles);
            counter_cycles = 0; // reset counter
            GetLocalTime(&startTime); // reset timer
        }

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
            resizeBitmap();
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
        // wait for this function's turn
        while (1) {
            if (!resizingSafely) { // dont draw while its resizingSafely
                drawingToBitmap = TRUE;
                break;
            }
        }

        // Rectangle(windowDeviceContext, 10, 30, 60, 80); // test
        RECT windowRect;
        if (!GetWindowRect(windowHandle, &windowRect)) {
            printf("EXITING: GetWindowRect() failed.\n");
            foxxey_Exit(-1);
        }
        
        // printf("left: %ld, right: %ld\n", windowRect.left, windowRect.right); // DEBUG

        // functional test!
        UINT16 windowWidth = windowRect.right -windowRect.left;
        UINT16 windowHeight = windowRect.bottom -windowRect.top;

        UINT32 windowWidthReciprocal = ((UINT64) 1 << 32) /windowWidth; // gpu tricks! its shifted 32 bits to the left so we can avoid float division. we can just multiply using shifted reciprocal, then shift to the right 32 to get rid of the values that WOULD be less than 1.

        UINT32 pixelsAmount = windowWidth *windowHeight;
        UINT32 paddedRowBytesAmount = rowBytesAmountToPaddedRowBytesAmount(windowWidth *3); // the reason im doing this separate from bytesAmount is cuz the kernals need this value. and of course, i only need to calculate it once, so i might as well calculate it on the cpu.
        UINT32 bytesAmount = paddedRowBytesAmount *windowHeight;
        dim3 gridDim_ = {((pixelsAmount -1) /256) +1, 1, 1};
        dim3 blockDim_ = {32, 4, 2}; // 256 total

        // circle stuff
        float circleMiddleX = windowWidth *.5f; // middle of circle
        float circleMiddleY = windowHeight *.5f; // middle of circle
        float borderWidth = 10;
        UINT32 totalAnimationTime = 9000; // in millis
        UINT32 totalColourAnimationTime = 5000; // in millis

        float radius;
        float progress = getProgress(totalAnimationTime);
        if (progress < .5f) { // 0 to .5
            radius = interpolate_circular_slowFastSlow(progress *2, 10, 500);
        } else { // .5 to 1
            radius = interpolate_circular_slowFastSlow((progress -.5f) *2, 500, 10);
        }

        float innerRadius = radius -borderWidth;

        float radiusSquared = radius *radius;
        float innerRadiusSquared = innerRadius *innerRadius;

        // float innerAABBHalfLength = radius *sqrtOf2 *.5f;
        float innerAABBHalfLength = innerRadius *halfOfsqrtOf2;

        // colour animation
        float colourProgress = getProgress(totalColourAnimationTime);
        struct colour_RGB circleColour = HSBToRGB(colourProgress, 1, 1);

        struct colour_RGB backgroundColour = {40, 43, 48};

        // byte *d_bitmap; // pointer of bitmap on device memory. gpu's version of bitmap.

        cudaGraphicsMapResources(1, &cudaResource, 0);
        cudaGraphicsSubResourceGetMappedArray(&cudaArray, cudaResource, 0, 0);

        cudaResourceDesc resDesc = {};
        resDesc.resType = cudaResourceTypeArray;
        resDesc.res.array.array = cudaArray;

        cudaSurfaceObject_t surface;
        cudaCreateSurfaceObject(&surface, &resDesc);

        clearWindow_kernel<<<gridDim_, blockDim_>>>(surface, windowWidth, windowWidthReciprocal, windowHeight, pixelsAmount, paddedRowBytesAmount, backgroundColour); // 1 thread per pixel
        drawHollowCircleWithBorder_kernel<<<gridDim_, blockDim_>>>(surface, windowWidth, windowWidthReciprocal, windowHeight, pixelsAmount, paddedRowBytesAmount, circleMiddleX, circleMiddleY, radiusSquared, innerRadiusSquared, radius, innerAABBHalfLength, circleColour); // 1 thread per pixel
    
        cudaDestroySurfaceObject(surface);
        cudaGraphicsUnmapResources(1, &cudaResource, 0);

        (*swapChainPointer).Present(0, 0); // why should i need these if i only have 1 buffer??

        drawingToBitmap = FALSE;

        // GetLocalTime(&endTime);
        // timeTaken = endTime.wMilliseconds -startTime.wMilliseconds;
        // FPS = (timeTaken /((float) 1000));
        // if (FPS == 0) { // protection against dividing by 0
        //     printf("MS/F: %u, FPS: INFINITE\n", timeTaken);
        // } else {
        //     FPS = 1 /FPS; // finish the conversion from Milliseconds/Frame to Frames/Second. specifically this line converts it from Seconds/Frame to Frames/Second.
        //     printf("MS/F: %u, FPS: %f\n", timeTaken, FPS);
        // }
        counter_cycles++;
    }
    return 0;
}

// entry point
extern "C" EXPORT void startWindow(void) {

    // init array using malloc
    threads = (struct threadInfo *) malloc(threadsArraySize *sizeof(struct threadInfo));
    // set all thread ids to NULL just in case.
    for (int index = 0; index <= threadsArraySize -1; index++) {
        threads[index].id = NULL;
    }

    HANDLE currentThreadHandle;
    if (!DuplicateHandle(
        GetCurrentProcess(),     // source process
        GetCurrentThread(),           // pseudo-handle
        GetCurrentProcess(),     // target process
        &currentThreadHandle,             // out: real handle
        0,                       // access (ignored because DUPLICATE_SAME_ACCESS)
        FALSE,                   // not inheritable
        DUPLICATE_SAME_ACCESS
    )) {
        printf("CANT EXIT, ERROR: DuplicateHandle() failed.\n");
        exit(-1);
        // foxxey_Exit(-1);
    }
    struct threadInfo currentThreadInfo = {currentThreadHandle, GetCurrentThreadId()};
    threads_add(currentThreadInfo); // main thread's handle gets stored >:)

    printf("Main Thread Id: %lu\n", currentThreadInfo.id); // DEBUG


    // setup swapchain stuff
    DXGI_MODE_DESC bufferDescription = {
        200,
        200,
        {0, 0}, // will tell DXGI to automatically get screen's refresh rate.
        DXGI_FORMAT_R8G8B8A8_UNORM, // store as normal colour values that im used to, but will automatically transform to 0-1, for the screen to display them.
        DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED,
        DXGI_MODE_SCALING_UNSPECIFIED
    };

    DXGI_SAMPLE_DESC sampleDescription = {
        1,
        NULL
    };

    DXGI_SWAP_CHAIN_DESC swapChainDescription = {
        bufferDescription,
        sampleDescription,
        DXGI_USAGE_RENDER_TARGET_OUTPUT,
        1, // 1 buffer.
        windowHandle,
        TRUE,
        DXGI_SWAP_EFFECT_FLIP_DISCARD, // IMPORTANT. this flips (switches pointers), AND doesnt put in effort to save the backbuffer contents. its THE fastest.
        0 | DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING
    };

    D3D11CreateDeviceAndSwapChain(
        NULL,
        D3D_DRIVER_TYPE_HARDWARE,
        NULL,
        0,
        NULL,
        0,
        D3D11_SDK_VERSION,
        &swapChainDescription,
        &swapChainPointer,
        &devicePointer,
        NULL,
        &deviceContextPointer
    );

    (*swapChainPointer).GetBuffer(0, __uuidof(ID3D11Texture2D), (void **) &backBufferPointer); // gets the pointer to the back buffer so i can draw to it.

    cudaGraphicsD3D11RegisterResource(&cudaResource, backBufferPointer, cudaGraphicsRegisterFlagsNone);

    // window stuff
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
        WS_VISIBLE | WS_POPUP,
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


    // windowDeviceContextHandle = GetDC(windowHandle);
    // if (windowDeviceContextHandle == NULL) {
    //     printf("EXITING: GetDC() failed.\n");
    //     foxxey_Exit(-1);
    // }
    // TODO maybe

    // bitmap = (byte *) malloc(rowBytesAmountToPaddedRowBytesAmount(200 *3) *200); // this is doing bytes per row *height. i just think its the best way to do the padding since the padding must be tacked onto the end of every row.

    // bitmapInfoHeader.biSize = sizeof(BITMAPINFOHEADER);
    // bitmapInfoHeader.biWidth = 200;
    // bitmapInfoHeader.biHeight = -200; // must be negative to flip it the right way. its just windows being stupid. real height cant be negative, but apparently setting this height to negative works.
    // bitmapInfoHeader.biPlanes = 1;
    // bitmapInfoHeader.biBitCount = 3 *8;
    // bitmapInfoHeader.biCompression = BI_RGB;
    // bitmapInfoHeader.biSizeImage = 0;
    // bitmapInfoHeader.biXPelsPerMeter = 0; // meta data stuff. doesnt matter.
    // bitmapInfoHeader.biYPelsPerMeter = 0; // meta data stuff. doesnt matter.
    // bitmapInfoHeader.biClrUsed = 0; // no colour table. we want full colour range. a pallette for full-range would be 256^3 colours big. not worth it, clearly. we are better of not using indexes and just setting R G and B in a byte each. 3 bytes per pixel.
    // bitmapInfoHeader.biClrImportant = 0;

    // bitmapInfo.bmiHeader = bitmapInfoHeader; // NOTE: since this uses the value of the struct, not a reference, it must be reset every time bitmapInfoheader changes.
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
    HANDLE windowLogic_threadHandle;
    DWORD windowLogic_threadId;
    windowLogic_threadHandle = CreateThread(NULL, 0, &windowLogic_threadFunction, NULL, 0, &windowLogic_threadId);
    struct threadInfo windowLogic_threadInfo = {windowLogic_threadHandle, windowLogic_threadId};
    printf("windowLogic Thread Id: %lu\n", windowLogic_threadId); // DEBUG
    threads_add(windowLogic_threadInfo);
    if (windowLogic_threadInfo.id == NULL) {
        printf("EXITING: windowLogic_threadInfo.id creation failed.\n");
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
