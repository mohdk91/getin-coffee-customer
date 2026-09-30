import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/rewards/customer_play_store.dart';
import '../../core/rewards/customer_rewards_store.dart';
import '../../core/theme/app_colors.dart';

class GetinPlayScreen extends StatelessWidget {
  const GetinPlayScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        CustomerPlayStore.instance,
        CustomerRewardsStore.instance,
      ]),
      builder: (context, _) {
        final play = CustomerPlayStore.instance;
        final rewards = CustomerRewardsStore.instance;
        final available = PlayGameType.values.where(play.canPlay).length;

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            surfaceTintColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Getin Play',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _PlayHero(
                  stars: rewards.stars,
                  availableGames: available,
                ),
                const SizedBox(height: 18),
                const Text(
                  'PLAY & WIN',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _GameCard(
                  icon: Icons.casino_outlined,
                  title: 'Spin & Win',
                  description:
                      'Spin once today for bonus Stars or a Free Drink.',
                  badge: play.canPlay(PlayGameType.spinWin)
                      ? '1 TRY TODAY'
                      : 'PLAYED TODAY',
                  available: play.canPlay(PlayGameType.spinWin),
                  onTap: () => _open(context, const SpinWinScreen()),
                ),
                const SizedBox(height: 12),
                _GameCard(
                  icon: Icons.timer_outlined,
                  title: 'Stop the Timer',
                  description:
                      'Stop as close as you can to exactly 7.00 seconds.',
                  badge: play.canPlay(PlayGameType.stopTimer)
                      ? '1 TRY TODAY'
                      : 'PLAYED TODAY',
                  available: play.canPlay(PlayGameType.stopTimer),
                  onTap: () => _open(context, const StopTimerScreen()),
                ),
                if (play.history.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'RECENT WINS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...play.history.take(5).map(
                        (entry) => _HistoryTile(entry: entry),
                      ),
                ],
                const SizedBox(height: 14),
                const _PlayRulesCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayHero extends StatelessWidget {
  final int stars;
  final int availableGames;

  const _PlayHero({
    required this.stars,
    required this.availableGames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.beige,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '★ $stars Stars',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Play. Win. Enjoy Getin.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            availableGames == 0
                ? 'You used today’s game tries. Come back tomorrow.'
                : '$availableGames game ${availableGames == 1 ? 'try' : 'tries'} available today.',
            style: const TextStyle(
              color: Color(0xFFD7E1DD),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final bool available;
  final VoidCallback onTap;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: available ? AppColors.green : AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: available ? AppColors.beige : AppColors.muted,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: available
                                ? const Color(0xFFE8F0EC)
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color:
                                  available ? AppColors.green : AppColors.muted,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PlayHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSpin = entry.game == PlayGameType.spinWin;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isSpin ? Icons.casino_outlined : Icons.timer_outlined,
            color: AppColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.resultTitle,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.rewardText,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.playedAt.day}/${entry.playedAt.month}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayRulesCard extends StatelessWidget {
  const _PlayRulesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.green, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Demo rules: one attempt per game per day. Prizes are Getin rewards only and cannot be withdrawn as cash. Production eligibility, reset times and prize inventory will be controlled by the backend.',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 9.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpinWinScreen extends StatefulWidget {
  const SpinWinScreen({super.key});

  @override
  State<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinPrize {
  final String label;
  final int stars;
  final bool freeDrink;

  const _SpinPrize({
    required this.label,
    this.stars = 0,
    this.freeDrink = false,
  });
}

class _SpinWinScreenState extends State<SpinWinScreen>
    with SingleTickerProviderStateMixin {
  static const List<_SpinPrize> _prizes = <_SpinPrize>[
    _SpinPrize(label: '+5 Stars', stars: 5),
    _SpinPrize(label: '+10 Stars', stars: 10),
    _SpinPrize(label: '+15 Stars', stars: 15),
    _SpinPrize(label: 'Free Drink', freeDrink: true),
    _SpinPrize(label: '+20 Stars', stars: 20),
    _SpinPrize(label: '+25 Stars', stars: 25),
  ];

  late final AnimationController _controller;
  Animation<double>? _rotationAnimation;
  double _rotation = 0;
  bool _spinning = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addListener(() {
        final animation = _rotationAnimation;
        if (animation != null && mounted) {
          setState(() => _rotation = animation.value);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final play = CustomerPlayStore.instance;
    if (_spinning || !play.canPlay(PlayGameType.spinWin)) return;

    final selected = math.Random().nextInt(_prizes.length);
    final segment = (2 * math.pi) / _prizes.length;
    final target = (2 * math.pi * 6) - ((selected + 0.5) * segment);

    setState(() {
      _spinning = true;
      _result = null;
    });

    _rotationAnimation = Tween<double>(
      begin: _rotation,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    await _controller.forward(from: 0);
    if (!mounted) return;

    final prize = _prizes[selected];
    if (!play.usesApi) {
      if (prize.freeDrink) {
        CustomerRewardsStore.instance.grantFreeDrinkReward(
          source: 'getin-play-spin',
        );
      } else {
        CustomerRewardsStore.instance.addBonusStars(
          stars: prize.stars,
          title: 'Spin & Win',
          subtitle: 'Getin Play prize',
        );
      }
    }

    await play.recordPlay(
      game: PlayGameType.spinWin,
      resultTitle: 'Spin & Win',
      rewardText: prize.label,
    );

    if (!mounted) return;
    setState(() {
      _spinning = false;
      _result = prize.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = CustomerPlayStore.instance.canPlay(PlayGameType.spinWin);
    final previous = CustomerPlayStore.instance.latestFor(PlayGameType.spinWin);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        foregroundColor: AppColors.green,
        elevation: 0,
        title: const Text(
          'Spin & Win',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            CustomerPlayStore.instance,
            CustomerRewardsStore.instance,
          ]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              const Text(
                'One spin. One guaranteed Getin prize.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Transform.rotate(
                        angle: _rotation,
                        child: const CustomPaint(
                          size: Size.square(290),
                          painter: _PrizeWheelPainter(_prizes),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.greenDark,
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_result != null)
                _ResultBanner(
                  title: 'You won $_result!',
                  subtitle: 'Your prize is already in your Getin account.',
                )
              else if (!canPlay && previous != null)
                _ResultBanner(
                  title: 'Today’s spin: ${previous.rewardText}',
                  subtitle: 'Your next Spin & Win try resets tomorrow.',
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: canPlay && !_spinning ? _spin : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _spinning
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          canPlay ? 'SPIN NOW' : 'COME BACK TOMORROW',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Prizes in this local demo are applied immediately after the wheel stops.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrizeWheelPainter extends CustomPainter {
  final List<_SpinPrize> prizes;

  const _PrizeWheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (2 * math.pi) / prizes.length;
    const colors = <Color>[
      AppColors.green,
      AppColors.beige,
      AppColors.gold,
      AppColors.greenDark,
      Color(0xFFE8E0CC),
      Color(0xFF35564C),
    ];

    for (var index = 0; index < prizes.length; index++) {
      final start = -math.pi / 2 + (index * sweep);
      final paint = Paint()..color = colors[index % colors.length];
      canvas.drawArc(rect, start, sweep, true, paint);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(start + (sweep / 2));
      canvas.translate(radius * 0.62, 0);
      canvas.rotate(math.pi / 2);

      final darkText = index == 1 || index == 2 || index == 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[index].label,
          style: TextStyle(
            color: darkText ? AppColors.greenDark : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 78);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius * 0.17,
      Paint()..color = AppColors.cream,
    );
    canvas.drawCircle(
      center,
      radius * 0.11,
      Paint()..color = AppColors.green,
    );
  }

  @override
  bool shouldRepaint(covariant _PrizeWheelPainter oldDelegate) => false;
}

class StopTimerScreen extends StatefulWidget {
  const StopTimerScreen({super.key});

  @override
  State<StopTimerScreen> createState() => _StopTimerScreenState();
}

class _StopTimerScreenState extends State<StopTimerScreen> {
  static const double _targetSeconds = 7.0;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  double _elapsed = 0;
  bool _running = false;
  bool _saving = false;
  String? _resultTitle;
  String? _rewardText;

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _start() {
    if (_running ||
        _saving ||
        !CustomerPlayStore.instance.canPlay(PlayGameType.stopTimer)) {
      return;
    }

    _stopwatch
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 20), (_) {
      final elapsed = _stopwatch.elapsedMicroseconds / 1000000;
      if (!mounted) return;
      if (elapsed >= 10) {
        _finish();
        return;
      }
      setState(() => _elapsed = elapsed);
    });
    setState(() {
      _elapsed = 0;
      _running = true;
      _resultTitle = null;
      _rewardText = null;
    });
  }

  Future<void> _finish() async {
    if (!_running || _saving) return;

    _ticker?.cancel();
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMicroseconds / 1000000;
    final difference = (elapsed - _targetSeconds).abs();
    final stars = _starsForDifference(difference);

    setState(() {
      _elapsed = elapsed;
      _running = false;
      _saving = true;
    });

    if (!CustomerPlayStore.instance.usesApi) {
      CustomerRewardsStore.instance.addBonusStars(
        stars: stars,
        title: 'Stop the Timer',
        subtitle: 'Stopped at ${elapsed.toStringAsFixed(2)}s',
      );
    }

    final title = difference <= 0.05
        ? 'Almost perfect!'
        : difference <= 0.30
            ? 'Great timing!'
            : difference <= 0.60
                ? 'Nice stop!'
                : 'Good try!';
    final reward = '+$stars Stars';

    await CustomerPlayStore.instance.recordPlay(
      game: PlayGameType.stopTimer,
      resultTitle: '$title ${elapsed.toStringAsFixed(2)}s',
      rewardText: reward,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _resultTitle = '$title ${elapsed.toStringAsFixed(2)}s';
      _rewardText = reward;
    });
  }

  int _starsForDifference(double difference) {
    if (difference <= 0.05) return 50;
    if (difference <= 0.15) return 25;
    if (difference <= 0.30) return 15;
    if (difference <= 0.60) return 10;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        CustomerPlayStore.instance,
        CustomerRewardsStore.instance,
      ]),
      builder: (context, _) {
        final canPlay = CustomerPlayStore.instance.canPlay(
          PlayGameType.stopTimer,
        );
        final previous = CustomerPlayStore.instance.latestFor(
          PlayGameType.stopTimer,
        );

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            surfaceTintColor: AppColors.cream,
            foregroundColor: AppColors.green,
            elevation: 0,
            title: const Text(
              'Stop the Timer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                const Text(
                  'TARGET',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '7.00 seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: AppColors.greenDark,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      _elapsed.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 58,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (_resultTitle != null && _rewardText != null)
                  _ResultBanner(
                    title: _resultTitle!,
                    subtitle: 'You earned $_rewardText.',
                  )
                else if (!canPlay && previous != null)
                  _ResultBanner(
                    title: previous.resultTitle,
                    subtitle:
                        '${previous.rewardText} · Your next try resets tomorrow.',
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: !canPlay || _saving
                        ? null
                        : _running
                            ? _finish
                            : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _running ? AppColors.gold : AppColors.green,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            !canPlay
                                ? 'COME BACK TOMORROW'
                                : _running
                                    ? 'STOP'
                                    : 'START',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const _TimerRewards(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerRewards extends StatelessWidget {
  const _TimerRewards();

  @override
  Widget build(BuildContext context) {
    const rows = <(String, String)>[
      ('Within 0.05 sec', '+50 Stars'),
      ('Within 0.15 sec', '+25 Stars'),
      ('Within 0.30 sec', '+15 Stars'),
      ('Within 0.60 sec', '+10 Stars'),
      ('Participation', '+5 Stars'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REWARD LEVELS',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ResultBanner({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
