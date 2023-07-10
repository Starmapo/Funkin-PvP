package util;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
</target>
<files id="haxe" append="true">
    <compilerflag value="-I${haxelib:linc_sdl}/lib/sdl/include/" />

	<compilerflag value="-I${haxelib:linc_sdl}/lib/sdl/include/configs/default/"    unless="windows"/>
	<compilerflag value="-I${haxelib:linc_sdl}/lib/sdl/include/configs/windows/"    if="windows"/>
</files>
')
@:cppFileCode('
#define SDL_MAIN_HANDLED 1
#include <combaseapi.h>
#include <dwmapi.h>
#include <mmdeviceapi.h>
#include <SDL.h>
#include <SDL_video.h>

#define SAFE_RELEASE(punk)  \\
			  if ((punk) != NULL)  \\
				{ (punk)->Release(); (punk) = NULL; }

class AudioFixClient : public IMMNotificationClient {
	LONG _cRef;
	IMMDeviceEnumerator *_pEnumerator;
	
	public:
	AudioFixClient() :
		_cRef(1),
		_pEnumerator(NULL)
	{
		HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
							  NULL, CLSCTX_INPROC_SERVER,
							  __uuidof(IMMDeviceEnumerator),
							  (void**)&_pEnumerator);
		if (result == S_OK) {
			_pEnumerator->RegisterEndpointNotificationCallback(this);
		}
	}

	~AudioFixClient()
	{
		SAFE_RELEASE(_pEnumerator);
	}

	ULONG STDMETHODCALLTYPE AddRef()
	{
		return InterlockedIncrement(&_cRef);
	}

	ULONG STDMETHODCALLTYPE Release()
	{
		ULONG ulRef = InterlockedDecrement(&_cRef);
		if (0 == ulRef)
		{
			delete this;
		}
		return ulRef;
	}

	HRESULT STDMETHODCALLTYPE QueryInterface(
								REFIID riid, VOID **ppvInterface)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	};

	HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
								LPCWSTR pwstrDeviceId,
								DWORD dwNewState)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
								LPCWSTR pwstrDeviceId,
								const PROPERTYKEY key)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
		EDataFlow flow, ERole role,
		LPCWSTR pwstrDeviceId)
	{
		::Main_obj::audioDisconnected = true;
		return S_OK;
	};
};

AudioFixClient *curAudioFix;
')
#end
class WindowsAPI
{
	#if windows
	@:functionCode('
		return SDL_GL_GetSwapInterval();
	')
	#end
	public static function getVSync():Int
	{
		return 0;
	}

	#if windows
	@:functionCode('
	if (!curAudioFix) curAudioFix = new AudioFixClient();
	')
	#end
	public static function registerAudio():Void
	{
		Main.audioDisconnected = false;
	}

	#if windows
	@:functionCode('
        int darkMode = 1;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
            DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
        }
        UpdateWindow(window);
    ')
	#end
	public static function setWindowToDarkMode():Void {}

	#if windows
	@:functionCode('
		SDL_GL_SetSwapInterval(value);
	')
	#end
	public static function setVSync(value:Int):Void {}
}
