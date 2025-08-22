#define _AMD64_

#pragma comment(lib, "NtosKrnl.lib")

// #include <ntddk.h>
#include <wdm.h>

// NTSTATUS KmdfHelloWorldEvtDeviceAdd(_In_ WDFDRIVER Driver, _Inout_ PWDFDEVICE_INIT DeviceInit) {
//     // We're not using the driver object,
//     // so we need to mark it as unreferenced
//     UNREFERENCED_PARAMETER(Driver);

//     NTSTATUS status;

//     // Allocate the device object
//     WDFDEVICE hDevice;    

//     // Print "Hello World"
//     KdPrintEx(( DPFLTR_IHVDRIVER_ID, DPFLTR_INFO_LEVEL, "KmdfHelloWorld: KmdfHelloWorldEvtDeviceAdd\n" ));

//     // Create the device object
//     status = WdfDeviceCreate(&DeviceInit, 
//                              WDF_NO_OBJECT_ATTRIBUTES,
//                              &hDevice
//                              );
//     return status;
// }

VOID DriverUnload(_In_ PDRIVER_OBJECT DriverObject) {
    // UNREFERENCED_PARAMETER(DriverObject);
    DbgPrint("[foxxeysDriver]: Unloaded\n");
}

NTSTATUS DriverEntry(_In_ PDRIVER_OBJECT DriverObject, _In_ PUNICODE_STRING RegistryPath) {
    // load
    // UNREFERENCED_PARAMETER(RegistryPath);
    (*DriverObject).DriverUnload = DriverUnload;
    DbgPrint("[foxxeysDriver]: Loaded.\n");

    // do stuff
    const char *string1 = "[foxxeysDriver]: Hello from Foxxey's Driver.\n";
    DbgPrint(string1);
    return STATUS_SUCCESS;
}