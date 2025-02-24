import 'dart:ffi';

@Packed(1)
final class MPEGLAYER3WAVEFORMAT extends Struct {
  @Uint16()
  external int wFormatTag;

  @Uint16()
  external int nChannels;

  @Uint32()
  external int nSamplesPerSec;

  @Uint32()
  external int nAvgBytesPerSec;

  @Uint16()
  external int nBlockAlign;

  @Uint16()
  external int wBitsPerSample;

  @Uint16()
  external int cbSize;

  @Uint16()
  external int wID;

  @Uint32()
  external int fdwFlags;

  @Uint16()
  external int nBlockSize;

  @Uint16()
  external int nFramesPerBlock;

  @Uint16()
  external int nCodecDelay;
}
