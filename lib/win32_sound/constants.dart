// waveform audio error return values
const _WAVERR_BASE = 32;
const WAVERR_BADFORMAT = _WAVERR_BASE + 0; // unsupported wave format
const WAVERR_STILLPLAYING = _WAVERR_BASE + 1; // still something playing
const WAVERR_UNPREPARED = _WAVERR_BASE + 2; // header not prepared
const WAVERR_SYNC = _WAVERR_BASE + 3; // device is synchronous
const WAVERR_LASTERROR = _WAVERR_BASE + 3; // last error in range

// device ID for wave device mapper
const WAVE_MAPPER = -1;

// flags for dwFlags field of WAVEHDR
const WHDR_DONE = 0x00000001; // done bit
const WHDR_PREPARED = 0x00000002; // set if this header has been prepared
const WHDR_BEGINLOOP = 0x00000004; // loop start block
const WHDR_ENDLOOP = 0x00000008; // loop end block
const WHDR_INQUEUE = 0x00000010; // reserved for driver

// flags for dwSupport field of WAVEOUTCAPS
const WAVECAPS_PITCH = 0x0001; // supports pitch control
const WAVECAPS_PLAYBACKRATE = 0x0002; // supports playback rate control
const WAVECAPS_VOLUME = 0x0004; // supports volume control
const WAVECAPS_LRVOLUME = 0x0008; // separate left-right volume control
const WAVECAPS_SYNC = 0x0010;
const WAVECAPS_SAMPLEACCURATE = 0x0020;

// defines for dwFormat field of WAVEINCAPS and WAVEOUTCAPS
const WAVE_INVALIDFORMAT = 0x00000000; // invalid format
const WAVE_FORMAT_1M08   = 0x00000001; // 11.025 kHz, Mono,   8-bit
const WAVE_FORMAT_1S08   = 0x00000002; // 11.025 kHz, Stereo, 8-bit
const WAVE_FORMAT_1M16   = 0x00000004; // 11.025 kHz, Mono,   16-bit
const WAVE_FORMAT_1S16   = 0x00000008; // 11.025 kHz, Stereo, 16-bit
const WAVE_FORMAT_2M08   = 0x00000010; // 22.05  kHz, Mono,   8-bit
const WAVE_FORMAT_2S08   = 0x00000020; // 22.05  kHz, Stereo, 8-bit
const WAVE_FORMAT_2M16   = 0x00000040; // 22.05  kHz, Mono,   16-bit
const WAVE_FORMAT_2S16   = 0x00000080; // 22.05  kHz, Stereo, 16-bit
const WAVE_FORMAT_4M08   = 0x00000100; // 44.1   kHz, Mono,   8-bit
const WAVE_FORMAT_4S08   = 0x00000200; // 44.1   kHz, Stereo, 8-bit
const WAVE_FORMAT_4M16   = 0x00000400; // 44.1   kHz, Mono,   16-bit
const WAVE_FORMAT_4S16   = 0x00000800; // 44.1   kHz, Stereo, 16-bit
const WAVE_FORMAT_44M08  = 0x00000100; // 44.1   kHz, Mono,   8-bit
const WAVE_FORMAT_44S08  = 0x00000200; // 44.1   kHz, Stereo, 8-bit
const WAVE_FORMAT_44M16  = 0x00000400; // 44.1   kHz, Mono,   16-bit
const WAVE_FORMAT_44S16  = 0x00000800; // 44.1   kHz, Stereo, 16-bit
const WAVE_FORMAT_48M08  = 0x00001000; // 48     kHz, Mono,   8-bit
const WAVE_FORMAT_48S08  = 0x00002000; // 48     kHz, Stereo, 8-bit
const WAVE_FORMAT_48M16  = 0x00004000; // 48     kHz, Mono,   16-bit
const WAVE_FORMAT_48S16  = 0x00008000; // 48     kHz, Stereo, 16-bit
const WAVE_FORMAT_96M08  = 0x00010000; // 96     kHz, Mono,   8-bit
const WAVE_FORMAT_96S08  = 0x00020000; // 96     kHz, Stereo, 8-bit
const WAVE_FORMAT_96M16  = 0x00040000; // 96     kHz, Mono,   16-bit
const WAVE_FORMAT_96S16  = 0x00080000; // 96     kHz, Stereo, 16-bit

//flags for wFormatTag field of WAVEFORMAT
const WAVE_FORMAT_UNKNOWN = 0x0000;
//const WAVE_FORMAT_PCM = 0x0001;
const WAVE_FORMAT_ADPCM = 0x0002;
//const WAVE_FORMAT_IEEE_FLOAT = 0x0003;
const WAVE_FORMAT_ALAW = 0x0006;
const WAVE_FORMAT_MULAW = 0x0007;
const WAVE_FORMAT_DTS = 0x0008;
const WAVE_FORMAT_MPEG = 0x0050;
const WAVE_FORMAT_MPEGLAYER3 = 0x0055;
const WAVE_FORMAT_MPEG_ADTS_AAC = 0x1600;
const WAVE_FORMAT_MPEG_RAW_AAC = 0x1601;
const WAVE_FORMAT_DTS2 = 0x200;
const WAVE_FORMAT_OGG_VORBIS_MODE_1 = 0x674F;
const WAVE_FORMAT_OGG_VORBIS_MODE_2 = 0x6750;
const WAVE_FORMAT_OGG_VORBIS_MODE_3 = 0x6751;
const WAVE_FORMAT_OGG_VORBIS_MODE_1_PLUS = 0x676F;
const WAVE_FORMAT_OGG_VORBIS_MODE_2_PLUS = 0x6770;
const WAVE_FORMAT_OGG_VORBIS_MODE_3_PLUS = 0x6771;
const WAVE_FORMAT_MPEG4_AAC = 0xA106;
const WAVE_FORMAT_FLAC = 0xF1AC;
