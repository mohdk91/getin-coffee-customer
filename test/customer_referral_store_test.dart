import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/referrals/customer_referral_store.dart';

void main() {
  group('CustomerReferralStore', () {
    final store = CustomerReferralStore.instance;

    test('exposes a referral code and matching referral link', () {
      expect(store.referralCode, 'GETIN-MOHAMMED');
      expect(store.referralLink, contains(store.referralCode));
      expect(store.shareMessage, contains(store.referralLink));
    });

    test('calculates demo referral stats from activity', () {
      expect(store.invitedCount, store.history.length);
      expect(store.completedCount, 2);
      expect(store.totalEarned, 100);
    });

    test('history includes multiple referral lifecycle states', () {
      final statuses = store.history.map((item) => item.status).toSet();
      expect(statuses, contains(CustomerReferralStatus.invited));
      expect(statuses, contains(CustomerReferralStatus.registered));
      expect(statuses, contains(CustomerReferralStatus.rewardAvailable));
    });
  });
}
