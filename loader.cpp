#include <windows.h>
#include <urlmon.h>
#include <iostream>
#include <string>
#include <vector>
#include <tlhelp32.h>

#pragma comment(lib, "urlmon.lib")

// Function to download file to memory
std::vector<char> DownloadToMemory(const std::string& url) {
    IStream* stream;
    HRESULT hr = URLOpenBlockingStreamA(NULL, url.c_str(), &stream, 0, NULL);
    if (FAILED(hr)) {
        std::cout << "Failed to open URL" << std::endl;
        return {};
    }

    std::vector<char> data;
    char buffer[4096];
    ULONG bytesRead;
    while (SUCCEEDED(stream->Read(buffer, sizeof(buffer), &bytesRead)) && bytesRead > 0) {
        data.insert(data.end(), buffer, buffer + bytesRead);
    }
    stream->Release();
    return data;
}

// Function to get process ID by name
DWORD GetProcessIdByName(const std::string& processName) {
    PROCESSENTRY32 entry;
    entry.dwSize = sizeof(PROCESSENTRY32);
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
    if (Process32First(snapshot, &entry)) {
        do {
            if (processName == entry.szExeFile) {
                CloseHandle(snapshot);
                return entry.th32ProcessID;
            }
        } while (Process32Next(snapshot, &entry));
    }
    CloseHandle(snapshot);
    return 0;
}

// Function to inject DLL into process
bool InjectDLL(DWORD processId, const std::vector<char>& dllData) {
    // Create temp file
    char tempPath[MAX_PATH];
    if (!GetTempPathA(MAX_PATH, tempPath)) return false;
    std::string tempFile = std::string(tempPath) + "temp_asi.dll";

    // Write DLL data to temp file
    HANDLE hFile = CreateFileA(tempFile.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return false;
    DWORD written;
    if (!WriteFile(hFile, dllData.data(), dllData.size(), &written, NULL)) {
        CloseHandle(hFile);
        return false;
    }
    CloseHandle(hFile);

    // Allocate memory for the path in target process
    HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, processId);
    if (!hProcess) {
        DeleteFileA(tempFile.c_str());
        return false;
    }

    LPVOID pRemotePath = VirtualAllocEx(hProcess, NULL, tempFile.size() + 1, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!pRemotePath) {
        CloseHandle(hProcess);
        DeleteFileA(tempFile.c_str());
        return false;
    }

    // Write path to remote memory
    if (!WriteProcessMemory(hProcess, pRemotePath, tempFile.c_str(), tempFile.size() + 1, NULL)) {
        VirtualFreeEx(hProcess, pRemotePath, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        DeleteFileA(tempFile.c_str());
        return false;
    }

    // Get address of LoadLibraryA
    HMODULE hKernel32 = GetModuleHandleA("kernel32.dll");
    FARPROC pLoadLibrary = GetProcAddress(hKernel32, "LoadLibraryA");

    // Create remote thread to load the DLL
    HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)pLoadLibrary, pRemotePath, 0, NULL);
    if (!hThread) {
        VirtualFreeEx(hProcess, pRemotePath, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        DeleteFileA(tempFile.c_str());
        return false;
    }

    // Wait for thread to finish
    WaitForSingleObject(hThread, INFINITE);

    // Clean up
    CloseHandle(hThread);
    VirtualFreeEx(hProcess, pRemotePath, 0, MEM_RELEASE);
    CloseHandle(hProcess);

    // Delete temp file after loading
    DeleteFileA(tempFile.c_str());
    return true;
}

int main() {
    std::string url = "https://raw.githubusercontent.com/HentaikaZ/Evolved/main/FramerateVigilianteSA%20v2.asi";
    std::string processName = "gta_sa.exe";  // Adjust if different

    std::cout << "Downloading DLL..." << std::endl;
    std::vector<char> dllData = DownloadToMemory(url);
    if (dllData.empty()) {
        std::cout << "Failed to download DLL" << std::endl;
        return 1;
    }

    std::cout << "Finding process..." << std::endl;
    DWORD processId = GetProcessIdByName(processName);
    if (!processId) {
        std::cout << "Process not found" << std::endl;
        return 1;
    }

    std::cout << "Injecting DLL..." << std::endl;
    if (InjectDLL(processId, dllData)) {
        std::cout << "DLL injected successfully" << std::endl;
    } else {
        std::cout << "Failed to inject DLL" << std::endl;
        return 1;
    }

    return 0;
}
