import 'dart:ffi';

final _winmm = DynamicLibrary.open('winmm.dll');

/// The waveOutBreakLoop function breaks a loop on the given waveform-audio
/// output device and allows playback to continue with the next block in
/// the driver list.
///
/// ```c
/// MMRESULT WINAPI waveOutBreakLoop(
///   _In_ HWAVEOUT hwo
/// );
/// ```
/// {@category winmm}
int waveOutBreakLoop(int hwo) => _waveOutBreakLoop(hwo);

final _waveOutBreakLoop =
    _winmm.lookupFunction<Int32 Function(Int64 hwo), int Function(int hwo)>('waveOutBreakLoop');
