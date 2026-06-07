import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_tracker/app_theme.dart';

enum BreathingPhase {
  inhale,   // Вдох
  exhale,   // Выдох
  hold,     // Задержка
}

class BreathingExercise extends StatefulWidget {
  final Function(int duration, int breathsCount) onComplete;
  final Function(BreathingPhase phase, int secondsLeft) onPhaseChange;

  const BreathingExercise({
    super.key,
    required this.onComplete,
    required this.onPhaseChange,
  });

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  BreathingPhase _currentPhase = BreathingPhase.inhale;
  int _secondsLeft = 4;
  int _breathsCount = 0;
  Timer? _timer;
  
  int _inhaleDuration = 4;   // секунды на вдох
  int _exhaleDuration = 4;   // секунды на выдох
  int _holdDuration = 0;      // секунды задержки
  
  bool _isActive = false;
  
  // Разные режимы дыхания
  final Map<String, Map<String, int>> _modes = {
    'Расслабление': {'inhale': 4, 'hold': 0, 'exhale': 6},
    'Энергия': {'inhale': 6, 'hold': 2, 'exhale': 4},
    'Квадратное': {'inhale': 4, 'hold': 4, 'exhale': 4},
    'Глубокое': {'inhale': 8, 'hold': 2, 'exhale': 8},
  };
  
  String _currentMode = 'Расслабление';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _setMode(_currentMode);
  }
  
  void _setMode(String mode) {
    final modeData = _modes[mode]!;
    _inhaleDuration = modeData['inhale']!;
    _holdDuration = modeData['hold']!;
    _exhaleDuration = modeData['exhale']!;
    
    setState(() {
      _currentMode = mode;
      _secondsLeft = _inhaleDuration;
      _currentPhase = BreathingPhase.inhale;
    });
  }
  
  void _startBreathing() {
    if (_isActive) {
      _stopBreathing();
      return;
    }
    
    setState(() {
      _isActive = true;
      _breathsCount = 0;
    });
    
    _startPhase();
  }
  
  void _stopBreathing() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
  }
  
  void _startPhase() {
    _timer?.cancel();
    
    // Обновляем анимацию в зависимости от фазы
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        _animationController.duration = Duration(seconds: _inhaleDuration);
        _animationController.forward(from: 0);
        _secondsLeft = _inhaleDuration;
        break;
      case BreathingPhase.hold:
        _animationController.stop();
        _secondsLeft = _holdDuration;
        break;
      case BreathingPhase.exhale:
        _animationController.duration = Duration(seconds: _exhaleDuration);
        _animationController.reverse(from: 1);
        _secondsLeft = _exhaleDuration;
        break;
    }
    
    widget.onPhaseChange(_currentPhase, _secondsLeft);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          widget.onPhaseChange(_currentPhase, _secondsLeft);
        } else {
          _nextPhase();
        }
      });
    });
  }
  
  void _nextPhase() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        if (_holdDuration > 0) {
          _currentPhase = BreathingPhase.hold;
        } else {
          _currentPhase = BreathingPhase.exhale;
        }
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.exhale;
        break;
      case BreathingPhase.exhale:
        _currentPhase = BreathingPhase.inhale;
        _breathsCount++;
        widget.onComplete(_getTotalDuration(), _breathsCount);
        break;
    }
    
    _startPhase();
  }
  
  int _getTotalDuration() {
    return (_inhaleDuration + _exhaleDuration + _holdDuration) * _breathsCount;
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  String _getPhaseText() {
    switch (_currentPhase) {
      case BreathingPhase.inhale: return 'ВДОХ';
      case BreathingPhase.hold: return 'ЗАДЕРЖКА';
      case BreathingPhase.exhale: return 'ВЫДОХ';
    }
  }
  
  Color _getPhaseColor() {
    switch (_currentPhase) {
      case BreathingPhase.inhale: return Colors.green;
      case BreathingPhase.hold: return Colors.orange;
      case BreathingPhase.exhale: return Colors.blue;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Выбор режима
          if (!_isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentMode,
                  items: _modes.keys.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            mode == 'Расслабление' ? Icons.spa :
                            mode == 'Энергия' ? Icons.flash_on :
                            mode == 'Квадратное' ? Icons.crop_square :
                            Icons.air,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(mode),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !_isActive) {
                      _setMode(value);
                    }
                  },
                ),
              ),
            ),
          
          const SizedBox(height: 40),
          
          // Анимированный круг
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Container(
                  width: 200 + (100 * _scaleAnimation.value),
                  height: 200 + (100 * _scaleAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getPhaseColor().withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: _getPhaseColor().withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.all(20 - (20 * _scaleAnimation.value)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getPhaseColor().withOpacity(0.2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getPhaseText(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getPhaseColor(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_secondsLeft сек',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_breathsCount > 0 && _isActive) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Циклов: $_breathsCount',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Spacer(),
          
          // Кнопки управления
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isActive)
                ElevatedButton.icon(
                  onPressed: _stopBreathing,
                  icon: const Icon(Icons.stop),
                  label: const Text('Закончить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _startBreathing,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Начать'),
                  style: ElevatedButton.styleFrom(
                    
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Инструкция
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInstruction('Вдох', Colors.green, _inhaleDuration),
                    if (_holdDuration > 0)
                      _buildInstruction('Задержка', Colors.orange, _holdDuration),
                    _buildInstruction('Выдох', Colors.blue, _exhaleDuration),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Следуйте за анимацией круга',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstruction(String text, Color color, int seconds) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            text == 'Вдох' ? Icons.arrow_upward :
            text == 'Выдох' ? Icons.arrow_downward :
            Icons.pause,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('$seconds сек', style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}