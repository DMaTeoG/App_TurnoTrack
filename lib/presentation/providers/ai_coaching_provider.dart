import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gemini_ai_service.dart';
import '../../data/models/user_model.dart';

/// Provider for Gemini AI Service
final geminiAIServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

/// State for AI Coaching
class AICoachingState {
  final bool isLoading;
  final String? advice;
  final String? error;
  final DateTime? lastUpdated;

  const AICoachingState({
    this.isLoading = false,
    this.advice,
    this.error,
    this.lastUpdated,
  });

  AICoachingState copyWith({
    bool? isLoading,
    String? advice,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AICoachingState(
      isLoading: isLoading ?? this.isLoading,
      advice: advice ?? this.advice,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for AI Coaching using Riverpod 3.x
class AICoachingNotifier extends Notifier<AICoachingState> {
  late GeminiAIService _service;

  @override
  AICoachingState build() {
    _service = ref.read(geminiAIServiceProvider);
    return const AICoachingState();
  }

  /// Generate personalized coaching advice
  Future<void> generateAdvice({
    required UserModel user,
    required PerformanceMetrics metrics,
    String language = 'es',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final advice = await _service.generateCoachingAdvice(
        user: user,
        metrics: metrics,
        language: language,
      );

      state = state.copyWith(
        isLoading: false,
        advice: advice,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error generando consejo: ${e.toString()}',
      );
    }
  }

  /// Generate team summary for supervisors
  Future<String?> generateTeamSummary({
    required List<PerformanceMetrics> teamMetrics,
    String language = 'es',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final summary = await _service.generateTeamSummary(
        teamMetrics: teamMetrics,
        language: language,
      );

      state = state.copyWith(isLoading: false, lastUpdated: DateTime.now());

      return summary;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error generando resumen: ${e.toString()}',
      );
      return null;
    }
  }

  /// Predict attendance issues
  Future<String?> predictAttendanceIssues({
    required List<AttendanceModel> recentAttendance,
    String language = 'es',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prediction = await _service.predictAttendanceIssues(
        recentAttendance: recentAttendance,
        language: language,
      );

      state = state.copyWith(isLoading: false, lastUpdated: DateTime.now());

      return prediction;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error generando predicción: ${e.toString()}',
      );
      return null;
    }
  }

  /// Clear current advice
  void clearAdvice() {
    state = const AICoachingState();
  }
}

/// Provider for AI coaching state
final aiCoachingProvider =
    NotifierProvider<AICoachingNotifier, AICoachingState>(
      AICoachingNotifier.new,
    );
