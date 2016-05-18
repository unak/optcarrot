require "fiddle/import"

module Optcarrot
  # A minimal binding for SDL2
  module SDL2
    extend Fiddle::Importer
    dlload "SDL2"
    typealias "int16", "short"
    typealias "int32", "int"
    typealias "pointer", "void *"
    typealias "string", "void *"
    typealias "uint8", "unsigned char"
    typealias "uint16", "unsigned short"
    typealias "uint32", "unsigned int"

    def self.layout(*params)
      klass = struct(params.enum_for(:each_slice, 2).map{|name, type| "#{type} #{name}"})
      def klass.ptr
        :pointer
      end
      klass
    end

    def self.attach_function(name, func, params, ret, blocking: false)
      extern "#{ret.to_s} #{func}(#{params.map(&:to_s).join(', ')})"
      define_singleton_method(name) do |*args|
        method(func).(*args)
      end
    end

    # struct SDL_Version
    Version =
      layout(
        :major, :uint8,
        :minor, :uint8,
        :patch, :uint8,
      )

    INIT_TIMER    = 0x00000001
    INIT_AUDIO    = 0x00000010
    INIT_VIDEO    = 0x00000020
    INIT_JOYSTICK = 0x00000200

    # Video

    WINDOWPOS_UNDEFINED       = 0x1fff0000
    WINDOW_FULLSCREEN         = 0x00000001
    WINDOW_OPENGL             = 0x00000002
    WINDOW_SHOWN              = 0x00000004
    WINDOW_HIDDEN             = 0x00000008
    WINDOW_BORDERLESS         = 0x00000010
    WINDOW_RESIZABLE          = 0x00000020
    WINDOW_MINIMIZED          = 0x00000040
    WINDOW_MAXIMIZED          = 0x00000080
    WINDOW_INPUT_GRABBED      = 0x00000100
    WINDOW_INPUT_FOCUS        = 0x00000200
    WINDOW_MOUSE_FOCUS        = 0x00000400
    WINDOW_FULLSCREEN_DESKTOP = (WINDOW_FULLSCREEN | 0x00001000)

    pixels = [0x04030201].pack('l')
    PACKEDORDER =
      case pixels.unpack("C*")
      when [1, 2, 3, 4] then 3 # PACKEDORDER_ARGB
      when [4, 3, 2, 1] then 8 # PACKEDORDER_BGRA
      else
        raise "unknown endian"
      end

    PIXELFORMAT_8888 =
      (1 << 28) |
      (6 << 24) | # PIXELTYPE_PACKED32
      (PACKEDORDER << 20) |
      (6 << 16) | # PACKEDLAYOUT_8888
      (32 << 8) | # bits
      (4 << 0)    # bytes

    TEXTUREACCESS_STREAMING = 1

    # Input

    # struct SDL_KeyboardEvent
    KeyboardEvent =
      layout(
        :type, :uint32,
        :timestamp, :uint32,
        :windowID, :uint32,
        :state, :uint8,
        :repeat, :uint8,
        :padding2, :uint8,
        :padding3, :uint8,
        :scancode, :int,
        :sym, :int,
      )

    # struct SDL_JoyAxisEvent
    JoyAxisEvent =
      layout(
        :type, :uint32,
        :timestamp, :uint32,
        :which, :uint32,
        :axis, :uint8,
        :padding1, :uint8,
        :padding2, :uint8,
        :padding3, :uint8,
        :value, :int16,
        :padding4, :uint16,
      )

    # struct SDL_JoyButtonEvent
    JoyButtonEvent =
      layout(
        :type, :uint32,
        :timestamp, :uint32,
        :which, :uint32,
        :button, :uint8,
        :state, :uint8,
        :padding1, :uint8,
        :padding2, :uint8,
      )

    # struct SDL_JoyDeviceEvent
    JoyDeviceEvent =
      layout(
        :type, :uint32,
        :timestamp, :uint32,
        :which, :int32,
      )

    # Audio

    AUDIO_S8     = 0x8008
    AUDIO_S16LSB = 0x8010
    AUDIO_S16MSB = 0x9010

    pixels = [0x0201].pack('s')
    AUDIO_S16SYS =
      case pixels.unpack("C*")
      when [1, 2] then AUDIO_S16LSB
      when [2, 1] then AUDIO_S16MSB
      else
        raise "unknown endian"
      end

    # struct SDL_AudioSpec
    AudioSpec =
      layout(
        :freq, :int,
        :format, :uint16,
        :channels, :uint8,
        :silence, :uint8,
        :samples, :uint16,
        :padding, :uint16,
        :size, :uint32,
        :callback, :pointer,
        :userdata, :pointer,
      )

    # rubocop:disable Style/MethodName
    def self.AudioCallback(blk)
      bind("void callback(void *, void *, int)", &blk)
    end
    # rubocop:enable Style/MethodName

    # attach_functions

    functions = {
      InitSubSystem: [[:uint32], :int],
      QuitSubSystem: [[:uint32], :void, blocking: true],
      Delay: [[:int], :void, blocking: true],
      GetError: [[], :string],
      GetTicks: [[], :uint32],

      CreateWindow: [[:string, :int, :int, :int, :int, :uint32], :pointer],
      DestroyWindow: [[:pointer], :void],
      CreateRenderer: [[:pointer, :int, :uint32], :pointer],
      DestroyRenderer: [[:pointer], :void],
      CreateRGBSurfaceFrom: [[:pointer, :int, :int, :int, :int, :uint32, :uint32, :uint32, :uint32], :pointer],
      FreeSurface: [[:pointer], :void],
      GetWindowFlags: [[:pointer], :uint32],
      SetWindowFullscreen: [[:pointer, :uint32], :int],
      SetWindowSize: [[:pointer, :int, :int], :void],
      SetWindowTitle: [[:pointer, :string], :void],
      SetWindowIcon: [[:pointer, :pointer], :void],
      SetHint: [[:string, :string], :int],
      RenderSetLogicalSize: [[:pointer, :int, :int], :int],
      CreateTexture: [[:pointer, :uint32, :int, :int, :int], :pointer],
      DestroyTexture: [[:pointer], :void],
      PollEvent: [[:pointer], :int],
      UpdateTexture: [[:pointer, :pointer, :pointer, :int], :int],
      RenderClear: [[:pointer], :int],
      RenderCopy: [[:pointer, :pointer, :pointer, :pointer], :int],
      RenderPresent: [[:pointer], :int],

      OpenAudioDevice: [[:string, :int, AudioSpec.ptr, AudioSpec.ptr, :int], :uint32, blocking: true],
      PauseAudioDevice: [[:uint32, :int], :void, blocking: true],
      CloseAudioDevice: [[:uint32], :void, blocking: true],

      NumJoysticks: [[], :int],
      JoystickOpen: [[:int], :pointer],
      JoystickClose: [[:pointer], :void],
      JoystickNameForIndex: [[:int], :string],
      JoystickNumAxes: [[:pointer], :int],
      JoystickNumButtons: [[:pointer], :int],
      JoystickInstanceID: [[:pointer], :uint32],

      QueueAudio: [[:uint32, :pointer, :int], :int],
      GetQueuedAudioSize: [[:uint32], :uint32],
      ClearQueuedAudio: [[:uint32], :void],
    }

    # check SDL version

    attach_function(:GetVersion, :SDL_GetVersion, [:pointer], :void)
    version = Version.malloc
    GetVersion(version)
    version = [version.major, version.minor, version.patch]
    if (version <=> [2, 0, 4]) < 0
      functions.delete(:QueueAudio)
      functions.delete(:GetQueuedAudioSize)
      functions.delete(:ClearQueuedAudio)
    end

    functions.each do |name, params|
      attach_function(name, :"SDL_#{ name }", *params)
    end
  end
end
