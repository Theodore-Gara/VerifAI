import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Vera's voice: the Piper `en_GB-cori-high` model run fully on-device with
/// sherpa_onnx. The model (~60 MB) is downloaded from the sherpa-onnx release
/// on first use and cached; if anything fails, callers fall back to the device
/// TTS voice.
class VeraVoice {
  VeraVoice._();
  static final VeraVoice instance = VeraVoice._();

  static const _modelUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_GB-cori-high.tar.bz2';
  static const _folder = 'vits-piper-en_GB-cori-high';
  static const _modelFile = 'en_GB-cori-high.onnx';

  sherpa.OfflineTts? _tts;
  bool _warming = false;
  final AudioPlayer _player = AudioPlayer();

  bool get ready => _tts != null;

  /// Prepares the voice in the background. Safe to call repeatedly.
  Future<void> warmUp() async {
    if (_tts != null || _warming) return;
    _warming = true;
    try {
      final dir = await _modelDir();
      if (!await _modelPresent(dir)) {
        await _downloadAndExtract(dir);
      }
      sherpa.initBindings();
      _tts = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: '${dir.path}/$_modelFile',
              tokens: '${dir.path}/tokens.txt',
              dataDir: '${dir.path}/espeak-ng-data',
            ),
            numThreads: 2,
            provider: 'cpu',
          ),
        ),
      );
    } catch (_) {
      _tts = null;
    } finally {
      _warming = false;
    }
  }

  /// Speaks [text] with the Piper voice. Returns false when the voice is not
  /// ready yet so the caller can fall back to device TTS.
  Future<bool> speak(String text) async {
    final tts = _tts;
    if (tts == null || text.trim().isEmpty) return false;
    try {
      final audio = tts.generate(text: text.trim(), sid: 0, speed: 1.0);
      if (audio.samples.isEmpty || audio.sampleRate <= 0) return false;
      final file = File('${(await _baseDir()).path}/voice.wav');
      await file.writeAsBytes(_wav(audio.samples, audio.sampleRate));
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  Future<Directory> _baseDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/verifai_piper');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _modelDir() async => Directory('${(await _baseDir()).path}/$_folder');

  Future<bool> _modelPresent(Directory dir) async {
    return await File('${dir.path}/$_modelFile').exists() &&
        await File('${dir.path}/tokens.txt').exists() &&
        await Directory('${dir.path}/espeak-ng-data').exists();
  }

  Future<void> _downloadAndExtract(Directory dir) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_modelUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('voice download failed (${response.statusCode})');
      }
      final compressed = BytesBuilder();
      await for (final chunk in response) {
        compressed.add(chunk);
      }
      final tar = BZip2Decoder().decodeBytes(compressed.takeBytes());
      final archive = TarDecoder().decodeBytes(tar, verify: false);

      final parent = dir.parent;
      final staging = Directory('${parent.path}/_voice_staging');
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);

      for (final file in archive) {
        final out = File('${staging.path}/${file.name}');
        if (file.isFile) {
          await out.parent.create(recursive: true);
          await out.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(out.path).create(recursive: true);
        }
      }

      final extracted = Directory('${staging.path}/$_folder');
      if (await extracted.exists()) {
        if (await dir.exists()) await dir.delete(recursive: true);
        await extracted.rename(dir.path);
      }
      if (await staging.exists()) await staging.delete(recursive: true);
    } finally {
      client.close(force: true);
    }
  }

  // Builds a 16-bit PCM mono WAV from the model's float samples.
  Uint8List _wav(Float32List samples, int sampleRate) {
    final n = samples.length;
    final dataSize = n * 2;
    final out = BytesBuilder();
    void str(String s) => out.add(ascii.encode(s));
    void u32(int v) => out.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    void u16(int v) => out.add([v & 0xff, (v >> 8) & 0xff]);
    final byteRate = sampleRate * 2;
    str('RIFF');
    u32(36 + dataSize);
    str('WAVE');
    str('fmt ');
    u32(16);
    u16(1); // PCM
    u16(1); // mono
    u32(sampleRate);
    u32(byteRate);
    u16(2); // block align
    u16(16); // bits
    str('data');
    u32(dataSize);
    final pcm = Int16List(n);
    for (var i = 0; i < n; i++) {
      pcm[i] = (samples[i] * 32767).round().clamp(-32768, 32767);
    }
    out.add(pcm.buffer.asUint8List());
    return out.toBytes();
  }
}
