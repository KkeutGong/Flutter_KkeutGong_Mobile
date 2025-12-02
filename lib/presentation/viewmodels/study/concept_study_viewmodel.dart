import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/concept_study_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/study_card.dart';

class ConceptStudyViewModel extends ChangeNotifier {
  final ConceptStudyRepository _repository;
  final StudyProgressRepository _progressRepository = StudyProgressRepository();
  final String subjectName;

  ConceptStudyViewModel({
    required this.subjectName,
    ConceptStudyRepository? repository,
  }) : _repository = repository ?? ConceptStudyRepository();

  List<StudyCard> _allCards = [];
  List<StudyCard> _currentRoundCards = [];
  List<StudyCard> get cards => _currentRoundCards;

  final Set<String> _knownCardIds = {};

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _round = 1;
  int get round => _round;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  String? _error;
  String? get error => _error;

  int get totalCards => _currentRoundCards.length;
  int get totalAllCards => _allCards.length;
  int get knownCardsCount => _knownCardIds.length;

  bool isKnown(String id) => _knownCardIds.contains(id);

  double get progress {
    if (_allCards.isEmpty) return 0;
    return _knownCardIds.length / _allCards.length;
  }
  String get progressText => '${_knownCardIds.length}/$totalAllCards';

    StudyCard? get currentCard => _currentRoundCards.isNotEmpty && _currentIndex < _currentRoundCards.length 
      ? _currentRoundCards[_currentIndex] 
      : null;

    bool get hasNext => _currentIndex < _currentRoundCards.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  Future<void> loadCards({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allCards = await _repository.getStudyCards(subjectName, forceRefresh: forceRefresh);
      final persistedKnown = await _progressRepository.getConceptKnownIds(subjectName);
      final validKnown = persistedKnown.intersection(_allCards.map((e) => e.id).toSet());
      _knownCardIds
        ..clear()
        ..addAll(validKnown);
      final unknown = _allCards.where((c) => !_knownCardIds.contains(c.id)).toList();
      _currentRoundCards = List.from(unknown);
      _isCompleted = unknown.isEmpty;
      _round = 1;
      _currentIndex = 0;
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isInitialized = false;
    _knownCardIds.clear();
    await loadCards(forceRefresh: true);
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _currentRoundCards.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleFavorite() {
    if (_currentRoundCards.isEmpty) return;

    final card = _currentRoundCards[_currentIndex];
    card.isFavorite = !card.isFavorite;
    _repository.updateCardFavorite(card.id, card.isFavorite);
    notifyListeners();
  }

  void markAsKnown() {
    if (_currentRoundCards.isEmpty || _currentIndex >= _currentRoundCards.length) return;

    final card = _currentRoundCards[_currentIndex];
    if (!_knownCardIds.contains(card.id)) {
      _knownCardIds.add(card.id);
      _repository.updateCardKnown(card.id, true);
      notifyListeners();
      saveProgress();
    }
  }

  void unmarkAsKnown() {
    if (_currentRoundCards.isEmpty || _currentIndex >= _currentRoundCards.length) return;
    final card = _currentRoundCards[_currentIndex];
    if (_knownCardIds.remove(card.id)) {
      _repository.updateCardKnown(card.id, false);
      // Known 해제된 카드는 다음 라운드에서 다시 등장 (현재 라운드에는 유지)
      notifyListeners();
      saveProgress();
    }
  }

  void goToNext() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    } else {
      _finishCurrentRound();
    }
  }

  void _finishCurrentRound() {
    final unknownCards = _currentRoundCards.where((c) => !_knownCardIds.contains(c.id)).toList();

    if (unknownCards.isEmpty) {
      _isCompleted = true;
      notifyListeners();
      saveProgress();
      return;
    }

    _round++;
    _currentRoundCards = List.from(unknownCards);
    _currentRoundCards.shuffle(Random());
    _currentIndex = 0;
    notifyListeners();
    saveProgress();
  }

  void goToPrevious() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void forceNextRound() => _finishCurrentRound();

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  Future<void> saveProgress() async {
    await _progressRepository.saveConceptProgress(
      subjectName: subjectName,
      knownCount: _knownCardIds.length,
      total: _allCards.length,
    );
    await _progressRepository.saveConceptKnownIds(
      subjectName: subjectName,
      knownIds: _knownCardIds.toList(),
    );
  }
}
