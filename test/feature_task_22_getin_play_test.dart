import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/rewards/customer_play_store.dart';
import 'package:getin_coffee/core/rewards/customer_rewards_store.dart';

void main() {
  final play = CustomerPlayStore.instance;
  final rewards = CustomerRewardsStore.instance;

  setUp(() async {
    await play.resetToDemoDefaults();
    rewards.resetToDemoDefaults();
  });

  test('each Getin Play game can be used once per day', () async {
    final now = DateTime(2026, 9, 24, 12);

    expect(play.canPlay(PlayGameType.spinWin, now: now), isTrue);
    expect(play.canPlay(PlayGameType.stopTimer, now: now), isTrue);

    await play.recordPlay(
      game: PlayGameType.spinWin,
      resultTitle: 'Spin & Win',
      rewardText: '+10 Stars',
      playedAt: now,
    );

    expect(play.canPlay(PlayGameType.spinWin, now: now), isFalse);
    expect(play.canPlay(PlayGameType.stopTimer, now: now), isTrue);
    expect(
      play.canPlay(
        PlayGameType.spinWin,
        now: now.add(const Duration(days: 1)),
      ),
      isTrue,
    );
  });

  test('Getin Play bonus Stars are added to rewards history', () {
    final before = rewards.stars;

    rewards.addBonusStars(
      stars: 25,
      title: 'Stop the Timer',
      subtitle: 'Stopped at 7.05s',
    );

    expect(rewards.stars, before + 25);
    expect(rewards.history.first.title, 'Stop the Timer');
    expect(rewards.history.first.starsDelta, 25);
  });

  test('Spin & Win can grant a free drink without spending Stars', () {
    final beforeStars = rewards.stars;
    final beforeRewards = rewards.redeemedRewards.length;

    final prize = rewards.grantFreeDrinkReward(source: 'getin-play-test');

    expect(prize.definitionId, 'free-drink');
    expect(rewards.stars, beforeStars);
    expect(rewards.redeemedRewards.length, beforeRewards + 1);
  });
}
