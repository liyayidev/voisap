import 'package:flutter/material.dart';
import 'package:agora_project/services/api_service.dart';
import 'package:agora_project/voice_call_screen.dart'; // Import for direct navigation if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final _usernameController = TextEditingController();
  final _targetNumberController = TextEditingController();

  String? _userId;
  String? _phoneNumber;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final uid = await _apiService.getUserId();
    final phone = await _apiService.getPhoneNumber();
    if (uid != null) {
      setState(() {
        _userId = uid;
        _phoneNumber = phone;
      });
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final data = await _apiService.login(_usernameController.text);
    setState(() => _isLoading = false);

    if (data != null) {
      setState(() {
        _userId = data['user_id'];
        _phoneNumber = data['phone_number'];
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    setState(() {
      _userId = null;
      _phoneNumber = null;
    });
  }

  Future<void> _triggerCall() async {
    if (_targetNumberController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a number to dial')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.triggerCall(_targetNumberController.text);
    setState(() => _isLoading = false);

    if (result != null) {
      // If result contains a token, we might need to join immediately (e.g. for Agent call)
      // or wait for notification (User call).
      // Current server logic: Returns token for BOTH cases (Agent & P2P).
      // So the CALLER can join immediately.

      final channelName = result['channel_name'];
      final token = result['token'];

      // Navigate to Call Screen immediately as Caller
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              appId: "CHANGE_ME_OR_FETCH_FROM_SERVER",
              token: token,
              channelName: channelName,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to connect call')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Phone System'),
        actions: [
          if (_userId != null)
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _userId == null
            ? _buildLoginForm()
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _login,
            child: const Text('Login & Get Number'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Logged in as: $_userId',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  "My Phone Number",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(height: 5),
                Text(
                  _phoneNumber ?? "Loading...",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          TextField(
            controller: _targetNumberController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, letterSpacing: 2),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Dial Number',
              hintText: 'e.g. 100 or 1234',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _triggerCall,
              icon: const Icon(Icons.call),
              label: const Text('CALL', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Dial 100 for Voice AI Agent",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
