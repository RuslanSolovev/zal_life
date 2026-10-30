// features/fitness/ui/widgets/timer_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerWidget extends StatefulWidget {
  final bool isDark;
  final int restSeconds;
  final VoidCallback? onTimerComplete;
  final VoidCallback? onSkip;

  const TimerWidget({
    super.key,
    this.isDark = false,
    this.restSeconds = 90,
    this.onTimerComplete,
    this.onSkip,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isComplete = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.restSeconds;
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.restSeconds),
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_progressController)
      ..addListener(() => setState(() {}));

    _startTimer();
  }

  void _startTimer() {
    _progressController.forward(from: 1.0 - (_secondsRemaining / widget.restSeconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);

        // Голосовые подсказки
        if (_secondsRemaining == 10) {
          HapticFeedback.mediumImpact();
        } else if (_secondsRemaining == 3) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _timer?.cancel();
        setState(() => _isComplete = true);
        HapticFeedback.heavyImpact();
        widget.onTimerComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка отдыха
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isComplete ? Icons.alarm_on_rounded : Icons.timer_rounded,
                key: ValueKey(_isComplete),
                size: 48,
                color: _isComplete ? const Color(0xFF4CAF50) : const Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 24),

            // Таймер
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _progressAnimation.value,
                    strokeWidth: 8,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isComplete ? const Color(0xFF4CAF50) : const Color(0xFFFF6B35),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isComplete ? 'ГОТОВО!' : timeString,
                      style: TextStyle(
                        fontSize: _isComplete ? 28 : 40,
                        fontWeight: FontWeight.w900,
                        color: _isComplete
                            ? const Color(0xFF4CAF50)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (!_isComplete)
                      Text(
                        'отдых',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Подсказки
            if (!_isComplete && _secondsRemaining <= 10)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _secondsRemaining <= 3 ? 'Приготовьтесь!' : 'Следующий подход скоро',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Пауза
                IconButton.filled(
                  onPressed: () {
                    setState(() => _isPaused = !_isPaused);
                  },
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 24),
                // +30 сек
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _secondsRemaining += 30;
                    });
                    _progressController.stop();
                    _progressController.forward(
                      from: 1.0 - (_secondsRemaining / widget.restSeconds),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('+30с'),
                ),
                const SizedBox(width: 24),
                // Пропустить
                TextButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    widget.onSkip?.call();
                  },
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Пропустить'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}