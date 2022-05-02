import 'dart:ffi';

@Packed(1)
class MPEGLAYER3WAVEFORMAT extends Struct {
  @Uint16()
  int wFormatTag;

  @Uint16()
  int nChannels;

  @Uint32()
  int nSamplesPerSec;

  @Uint32()
  int nAvgBytesPerSec;

  @Uint16()
  int nBlockAlign;

  @Uint16()
  int wBitsPerSample;

  @Uint16()
  int cbSize;

  @Uint16()
  int wID;

  @Uint32()
  int fdwFlags;

  @Uint16()
  int nBlockSize;

  @Uint16()
  int nFramesPerBlock;

  @Uint16()
  int nCodecDelay;
}
