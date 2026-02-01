import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallScreen extends StatefulWidget {
  final String appId;
  final String token;
  final String channelName;

  const VoiceCallScreen({
    Key? key,
    required this.appId,
    required this.token,
    required this.channelName,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _isJoined = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Get microphone permission
    await [Permission.microphone].request();

    // Create Agora RTC Engine
    _engine = createAgoraRtcEngine();

    // Initialize
    await _engine.initialize(
      RtcEngineContext(
        appId: widget.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _log("Local user ${connection.localUid} joined");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _log("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              _log("Remote user $remoteUid left");
              setState(() {
                _remoteUid = null;
              });
            },
        onError: (ErrorCodeType err, String msg) {
          _log("Error: $err - $msg");
        },
      ),
    );

    // Join channel
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  void _log(String info) {
    debugPrint(info);
    setState(() {
      _logs.add(info);
    });
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Ensure resources are released if the widget is disposed unexpectedly
    // However, if we navigated back normally, _leaveChannel should have been called.
    // We'll add a check or try/catch.
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Voice Call')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _remoteUid != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 100, color: Colors.blue),
                        const SizedBox(height: 20),
                        Text(
                          "Connected to remote user: $_remoteUid",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          _isJoined
                              ? "Waiting for others..."
                              : "Joining channel...",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            height: 150,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(_logs[index], style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: _leaveChannel,
              icon: const Icon(Icons.call_end),
              label: const Text("End Call"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
