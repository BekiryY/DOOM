import serial
import keyboard
import threading
import time
import ctypes
import ctypes.wintypes

PORT = 'COM6'
BAUD = 1000000

KEY_MAP = {
    'w':          0,
    's':          1,
    'a':          2,
    'd':          3,
    'left':       2,
    'right':      3,
    'up':         0,
    'down':       1,
    'ctrl':       4,
    'space':      5,
    'shift':      6,
    'alt':        9,
    ',':          10,
    '.':          11,
    '1':          12,
    '2':          13,
    '3':          14,
    '4':          15,
    '5':          16,
    '6':          17,
    '7':          18,
    'esc':        7,
    'enter':      8,
    'tab':        19,
    'f1':         20,
    'f2':         21,
    'f3':         22,
    'f5':         23,
    'f6':         24,
    'f7':         25,
    'f8':         26,
    'f9':         27,
    'f10':        28,
    'f11':        29,
    'pause':      30,
    '-':          31,
    '=':          32,
}

auto_map = {}
auto_counter = [33]

def get_idx(name):
    if name in KEY_MAP:
        return KEY_MAP[name]
    if name not in auto_map:
        if auto_counter[0] <= 254:
            auto_map[name] = auto_counter[0]
            auto_counter[0] += 1
            print(f"[MAP] auto-assigned '{name}' → idx {auto_map[name]}", flush=True)
        else:
            return 0xFF
    return auto_map[name]

# ── WinAPI type fixes for x64 ──────────────────────────────────────────────────

LRESULT  = ctypes.c_longlong
LPARAM   = ctypes.c_longlong
WPARAM   = ctypes.c_ulonglong

WNDPROCTYPE = ctypes.WINFUNCTYPE(LRESULT,
                                  ctypes.wintypes.HWND,
                                  ctypes.wintypes.UINT,
                                  WPARAM,
                                  LPARAM)

_DefWindowProc          = ctypes.windll.user32.DefWindowProcW
_DefWindowProc.restype  = LRESULT
_DefWindowProc.argtypes = [ctypes.wintypes.HWND, ctypes.wintypes.UINT, WPARAM, LPARAM]

_GetRawInputData          = ctypes.windll.user32.GetRawInputData
_GetRawInputData.restype  = ctypes.wintypes.UINT
_GetRawInputData.argtypes = [LPARAM,                   # hRawInput (HRAWINPUT)
                              ctypes.wintypes.UINT,    # uiCommand
                              ctypes.c_void_p,         # pData
                              ctypes.POINTER(ctypes.wintypes.UINT),  # pcbSize
                              ctypes.wintypes.UINT]    # cbSizeHeader

# ── Structs ────────────────────────────────────────────────────────────────────

RIM_TYPEKEYBOARD = 1
RIDEV_INPUTSINK  = 0x00000100
WM_INPUT         = 0x00FF
HWND_MESSAGE     = ctypes.wintypes.HWND(-3)
RID_INPUT        = 0x10000003

class RAWINPUTDEVICELIST(ctypes.Structure):
    _fields_ = [("hDevice", ctypes.wintypes.HANDLE),
                ("dwType",  ctypes.wintypes.DWORD)]

class RAWINPUTHEADER(ctypes.Structure):
    _fields_ = [("dwType",  ctypes.wintypes.DWORD),
                ("dwSize",  ctypes.wintypes.DWORD),
                ("hDevice", ctypes.wintypes.HANDLE),
                ("wParam",  WPARAM)]

class RAWKEYBOARD(ctypes.Structure):
    _fields_ = [("MakeCode",         ctypes.wintypes.USHORT),
                ("Flags",            ctypes.wintypes.USHORT),
                ("Reserved",         ctypes.wintypes.USHORT),
                ("VKey",             ctypes.wintypes.USHORT),
                ("Message",          ctypes.wintypes.UINT),
                ("ExtraInformation", ctypes.wintypes.ULONG)]

class RAWINPUT_KEYBOARD(ctypes.Structure):
    _fields_ = [("header",   RAWINPUTHEADER),
                ("keyboard", RAWKEYBOARD)]

class WNDCLASSEX(ctypes.Structure):
    _fields_ = [("cbSize",        ctypes.wintypes.UINT),
                ("style",         ctypes.wintypes.UINT),
                ("lpfnWndProc",   WNDPROCTYPE),
                ("cbClsExtra",    ctypes.c_int),
                ("cbWndExtra",    ctypes.c_int),
                ("hInstance",     ctypes.wintypes.HANDLE),
                ("hIcon",         ctypes.wintypes.HANDLE),
                ("hCursor",       ctypes.wintypes.HANDLE),
                ("hbrBackground", ctypes.wintypes.HANDLE),
                ("lpszMenuName",  ctypes.wintypes.LPCWSTR),
                ("lpszClassName", ctypes.wintypes.LPCWSTR),
                ("hIconSm",       ctypes.wintypes.HANDLE)]

class RAWINPUTDEVICE(ctypes.Structure):
    _fields_ = [("usUsagePage", ctypes.wintypes.USHORT),
                ("usUsage",     ctypes.wintypes.USHORT),
                ("dwFlags",     ctypes.wintypes.DWORD),
                ("hwndTarget",  ctypes.wintypes.HWND)]

# ── Device listing ─────────────────────────────────────────────────────────────

def list_keyboards():
    count = ctypes.wintypes.UINT(0)
    ctypes.windll.user32.GetRawInputDeviceList(
        None, ctypes.byref(count), ctypes.sizeof(RAWINPUTDEVICELIST))
    if count.value == 0:
        return []
    devices = (RAWINPUTDEVICELIST * count.value)()
    ctypes.windll.user32.GetRawInputDeviceList(
        devices, ctypes.byref(count), ctypes.sizeof(RAWINPUTDEVICELIST))
    keyboards = []
    for d in devices:
        if d.dwType != RIM_TYPEKEYBOARD:
            continue
        size = ctypes.wintypes.UINT(0)
        ctypes.windll.user32.GetRawInputDeviceInfoW(
            d.hDevice, 0x20000007, None, ctypes.byref(size))
        buf = ctypes.create_unicode_buffer(size.value)
        ctypes.windll.user32.GetRawInputDeviceInfoW(
            d.hDevice, 0x20000007, buf, ctypes.byref(size))
        keyboards.append((d.hDevice, buf.value))
    return keyboards

# ── Select keyboard ────────────────────────────────────────────────────────────

keyboards = list_keyboards()
print("Available keyboards:")
for i, (handle, name) in enumerate(keyboards):
    print(f"  [{i}] {name}")
print()

selected_handle = None
if len(keyboards) == 0:
    print("No keyboards found, capturing from all.")
elif len(keyboards) == 1:
    print(f"Only one keyboard found, using it.")
    selected_handle = keyboards[0][0]
else:
    while True:
        try:
            choice = int(input(f"Select keyboard [0-{len(keyboards)-1}] (or -1 for all): "))
            if choice == -1:
                print("Capturing from all keyboards.")
                break
            if 0 <= choice < len(keyboards):
                selected_handle = keyboards[choice][0]
                print(f"Selected: {keyboards[choice][1]}")
                break
        except ValueError:
            pass
        print("Invalid choice, try again.")

print()

# ── Serial ─────────────────────────────────────────────────────────────────────

try:
    ser = serial.Serial(PORT, baudrate=BAUD, timeout=0)
    print(f"Connected to {PORT} @ {BAUD} baud", flush=True)
except Exception as e:
    print(f"[SERIAL ERROR] {e}", flush=True)
    input("Press enter to exit.")
    exit(1)

held = set()
last_device = [None]

# ── RX thread ──────────────────────────────────────────────────────────────────

def rx_thread():
    while True:
        try:
            waiting = ser.in_waiting
            if waiting > 0:
                data = ser.read(waiting)
                cleaned = bytes(b for b in data if b != 0x00)
                text = cleaned.decode('ascii', errors='replace')
                print(text, end='', flush=True)
            else:
                time.sleep(0.001)
        except Exception as e:
            print(f"\n[RX ERROR] {e}", flush=True)
            break

# ── Raw input window ───────────────────────────────────────────────────────────

def raw_input_thread():
    try:
        def wnd_proc(hwnd, msg, wparam, lparam):
            if msg == WM_INPUT:
                size = ctypes.wintypes.UINT(0)
                _GetRawInputData(lparam, RID_INPUT, None,
                                 ctypes.byref(size), ctypes.sizeof(RAWINPUTHEADER))
                buf = ctypes.create_string_buffer(size.value)
                _GetRawInputData(lparam, RID_INPUT, buf,
                                 ctypes.byref(size), ctypes.sizeof(RAWINPUTHEADER))
                ri = ctypes.cast(buf, ctypes.POINTER(RAWINPUT_KEYBOARD)).contents
                if ri.header.dwType == RIM_TYPEKEYBOARD:
                    last_device[0] = ri.header.hDevice
            return _DefWindowProc(hwnd, msg, wparam, lparam)

        proc = WNDPROCTYPE(wnd_proc)
        hinstance = ctypes.windll.kernel32.GetModuleHandleW(None)

        wc = WNDCLASSEX()
        wc.cbSize        = ctypes.sizeof(WNDCLASSEX)
        wc.lpfnWndProc   = proc
        wc.hInstance     = hinstance
        wc.lpszClassName = "RawInputCapture"

        result = ctypes.windll.user32.RegisterClassExW(ctypes.byref(wc))
        if result == 0:
            err = ctypes.windll.kernel32.GetLastError()
            if err != 1410:
                print(f"[RAW INPUT] RegisterClassExW failed: error {err}", flush=True)
                return

        hwnd = ctypes.windll.user32.CreateWindowExW(
            0, "RawInputCapture", "RawInput", 0,
            0, 0, 0, 0, HWND_MESSAGE, None, hinstance, None)

        if not hwnd:
            err = ctypes.windll.kernel32.GetLastError()
            print(f"[RAW INPUT] CreateWindowExW failed: error {err}", flush=True)
            return

        rid = RAWINPUTDEVICE()
        rid.usUsagePage = 0x01
        rid.usUsage     = 0x06
        rid.dwFlags     = RIDEV_INPUTSINK
        rid.hwndTarget  = hwnd

        ok = ctypes.windll.user32.RegisterRawInputDevices(
            ctypes.byref(rid), 1, ctypes.sizeof(RAWINPUTDEVICE))
        if not ok:
            err = ctypes.windll.kernel32.GetLastError()
            print(f"[RAW INPUT] RegisterRawInputDevices failed: error {err}", flush=True)
            return

        print("[RAW INPUT] listening...", flush=True)

        msg = ctypes.wintypes.MSG()
        while ctypes.windll.user32.GetMessageW(ctypes.byref(msg), None, 0, 0) != 0:
            ctypes.windll.user32.TranslateMessage(ctypes.byref(msg))
            ctypes.windll.user32.DispatchMessageW(ctypes.byref(msg))

    except Exception as e:
        print(f"[RAW INPUT ERROR] {e}", flush=True)

# ── Start ──────────────────────────────────────────────────────────────────────

print("Press Ctrl+C to quit\n", flush=True)

threading.Thread(target=rx_thread,        daemon=True).start()
threading.Thread(target=raw_input_thread, daemon=True).start()

time.sleep(0.3)


def on_key(e):
    if selected_handle is not None and last_device[0] != selected_handle:
        return

    name = e.name.lower()
    idx  = get_idx(name)

    if e.event_type == 'down' and name not in held:
        held.add(name)
        ser.write(bytes([0x01, idx]))
        print(f"[TX] press   → '{name}' (idx {idx})", flush=True)

    elif e.event_type == 'up' and name in held:
        held.discard(name)
        ser.write(bytes([0x00, idx]))
        print(f"[TX] release → '{name}' (idx {idx})", flush=True)

keyboard.hook(on_key)

try:
    while True:
        time.sleep(0.01)
except KeyboardInterrupt:
    pass
finally:
    keyboard.unhook_all()
    ser.close()
    print("\nAuto-mapped keys this session:")
    for k, v in auto_map.items():
        print(f"  '{k}' → {v}")
    print("Disconnected.")