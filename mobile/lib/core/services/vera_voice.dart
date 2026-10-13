import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Vera's voice: the Piper `en_GB-cori-high` model run fully on-device with
/// sherpa_onnx. The model (~60 MB) is downloaded from the sherpa-onnx release
/// on first use and cached. Everything heavy (download, model load, and audio
/// generation) runs inside a background isolate so the UI thread never blocks;
/// callers fall back to the device TTS voice when Piper isn't ready.
class VeraVoice {
  VeraVoice._();
  static final VeraVoice instance = VeraVoice._();

  final AudioPlayer _player = AudioPlayer();
  _PiperWorker? _worker;
  Future<_PiperWorker?>? _starting;
  Future<Directory>? _base;

  Future<Directory> _baseDir() =>
      _base ??= _resolveBase();

  Future<Directory> _resolveBase() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/verifai_piper');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<_PiperWorker?> _ensureWorker() =>
      _worker != null ? Future.value(_worker) : (_starting ??= _startWorker());

  Future<_PiperWorker?> _startWorker() async {
    try {
      _worker = await _PiperWorker.spawn((await _baseDir()).path);
    } catch (_) {
      _worker = null; // device TTS fallback
    } finally {
      _starting = null;
    }
    return _worker;
  }

  /// Starts the background worker (download + model load). Non-blocking.
  Future<void> warmUp() async {
    try {
      await _ensureWorker();
    } catch (_) {
      // warm-up failure just means the device TTS voice is used.
    }
  }

  /// Speaks [text] with the Piper voice. Returns false when the voice is not
  /// ready yet so the caller can fall back to device TTS.
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;
    final worker = await _ensureWorker();
    if (worker == null) return false;
    try {
      final wav = await worker.speak(text.trim());
      if (wav == null) return false;
      final file = File('${(await _baseDir()).path}/voice.wav');
      await file.writeAsBytes(wav);
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();
}

/// Long-lived Piper worker. The sherpa TTS object never leaves this isolate.
class _PiperWorker {
  _PiperWorker._();
  final _pending = <int, Completer<Uint8List?>>{};
  Completer<bool>? _ready;
  SendPort? _command;
  int _nextId = 0;

  static Future<_PiperWorker> spawn(String basePath) async {
    final incoming = ReceivePort();
    await Isolate.spawn(_piperEntry, (basePath, incoming.sendPort));
    final worker = _PiperWorker._();
    incoming.listen(worker._onMessage);
    return worker;
  }

  void _onMessage(Object? message) {
    if (message is SendPort) {
      _command = message;
      return;
    }
    final msg = message as List;
    final id = msg[0] as int;
    if (id == -1) {
      (_ready ??= Completer<bool>()).complete(msg[1] as bool);
      return;
    }
    _pending.remove(id)?.complete(msg[1] as Uint8List?);
  }

  Future<_PiperWorker> _whenConnected() async {
    while (_command == null) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return this;
  }

  Future<Uint8List?> speak(
    String text, {
    Duration readyTimeout = const Duration(seconds: 5),
  }) async {
    await _whenConnected();
    final ok = await (_ready ??= Completer<bool>())
        .future
        .timeout(readyTimeout, onTimeout: () => false);
    if (!ok) return null;
    final id = _nextId++;
    final pending = Completer<Uint8List?>();
    _pending[id] = pending;
    _command!.send(['speak', id, text]);
    return pending.future;
  }
}

const _piperModelUrl =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_GB-cori-high.tar.bz2';
const _piperFolder = 'vits-piper-en_GB-cori-high';
const _piperModelFile = 'en_GB-cori-high.onnx';

@pragma('vm:entry-point')
void _piperEntry((String, SendPort) args) async {
  final (basePath, reply) = args;
  final commands = ReceivePort();
  reply.send(commands.sendPort);

  final tts = await _loadTts(basePath);
  reply.send([-1, tts != null]);

  await for (final message in commands) {
    if (message is! List || message.isEmpty || message[0] != 'speak') continue;
    final id = message[1] as int;
    final text = message[2] as String;
    Uint8List? wav;
    try {
      final audio = tts?.generate(text: text.trim(), sid: 0, speed: 1.0);
      if (audio != null && audio.samples.isNotEmpty && audio.sampleRate > 0) {
        wav = _wav(audio.samples, audio.sampleRate);
      }
    } catch (_) {
      wav = null;
    }
    reply.send([id, wav]);
  }
}

Future<sherpa.OfflineTts?> _loadTts(String basePath) async {
  try {
    final dir = Directory('$basePath/$_piperFolder');
    if (!await _modelPresent(dir)) {
      await _downloadAndExtract(dir);
    }
    sherpa.initBindings();
    return sherpa.OfflineTts(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: '${dir.path}/$_piperModelFile',
            tokens: '${dir.path}/tokens.txt',
            dataDir: '${dir.path}/espeak-ng-data',
          ),
          numThreads: 2,
          provider: 'cpu',
        ),
      ),
    );
  } catch (_) {
    return null;
  }
}

Future<bool> _modelPresent(Directory dir) async {
  return await File('${dir.path}/$_piperModelFile').exists() &&
      await File('${dir.path}/tokens.txt').exists() &&
      await Directory('${dir.path}/espeak-ng-data').exists();
}

Future<void> _downloadAndExtract(Directory dir) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(_piperModelUrl));
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

    final extracted = Directory('${staging.path}/$_piperFolder');
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