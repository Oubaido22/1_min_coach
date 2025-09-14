import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonDetectionWarning extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onDismiss;

  const PersonDetectionWarning({
    Key? key,
    required this.isVisible,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<PersonDetectionWarning> createState() => _PersonDetectionWarningState();
}

class _PersonDetectionWarningState extends State<PersonDetectionWarning>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  Timer? _alarmTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAlarm = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(PersonDetectionWarning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAlarm();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopAlarm();
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _startAlarm() {
    if (_isPlayingAlarm) return;
    
    _isPlayingAlarm = true;
    _pulseController.repeat(reverse: true);
    _shakeController.repeat(reverse: true);
    
    // Play alarm sound every 2 seconds
    _alarmTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _playAlarmSound();
    });
    
    // Play initial alarm
    _playAlarmSound();
  }

  void _stopAlarm() {
    _isPlayingAlarm = false;
    _pulseController.stop();
    _shakeController.stop();
    _alarmTimer?.cancel();
    _audioPlayer.stop();
  }

  void _playAlarmSound() {
    // Use system sound for alarm
    HapticFeedback.heavyImpact();
    
    // You can also play a custom alarm sound file if you have one
    // _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

  @override
  void dispose() {
    _stopAlarm();
    _pulseController.dispose();
    _shakeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (DateTime.now().millisecond % 2 == 0 ? 1 : -1), 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Warning Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_off,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Warning Title
                      Text(
                        'PERSON NOT DETECTED',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Warning Message
                      Text(
                        'Please return to the camera view to continue your workout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Dismiss Button
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'I\'M BACK',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
