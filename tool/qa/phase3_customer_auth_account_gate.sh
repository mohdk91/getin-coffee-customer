#!/bin/bash
set -u

CUSTOMER="${1:-/Users/mohammed/StudioProjects/getin_coffee}"
LARAVEL="${2:-/Users/mohammed/Getin-V2}"

fail() {
  echo "FAILED: $1"
  exit 1
}

echo "================================================"
echo " PHASE 3 CUSTOMER AUTH / ACCOUNT RELEASE GATE"
echo "================================================"

customer_tests="
test/customer_auth_repository_test.dart
test/customer_otp_repository_test.dart
test/customer_profile_repository_test.dart
test/customer_address_api_repository_test.dart
test/customer_preferences_api_repository_test.dart
test/customer_sessions_api_repository_test.dart
test/customer_account_restore_test.dart
test/customer_settings_store_test.dart
"

echo
echo "=== VERIFY CUSTOMER PHASE 3 TEST FILES ==="
for f in $customer_tests; do
  [ -f "$CUSTOMER/$f" ] || fail "Missing Customer test: $f"
  echo "OK: $f"
done

echo
echo "=== CUSTOMER FLUTTER ANALYZE ==="
(cd "$CUSTOMER" && flutter analyze) || fail "Customer flutter analyze"

echo
echo "=== CUSTOMER PHASE 3 FOCUSED TESTS ==="
focused_log="/tmp/getin-phase3-customer-focused.log"
if (cd "$CUSTOMER" && flutter test $customer_tests >"$focused_log" 2>&1); then
  tail -8 "$focused_log"
else
  cat "$focused_log"
  fail "Customer Phase 3 focused tests"
fi

echo
echo "=== CUSTOMER FULL TEST SUITE ==="
full_log="/tmp/getin-phase3-customer-full.log"
if (cd "$CUSTOMER" && flutter test >"$full_log" 2>&1); then
  tail -8 "$full_log"
else
  cat "$full_log"
  fail "Customer full Flutter suite"
fi

echo
echo "=== CUSTOMER ANDROID DEBUG APK ==="
if [ -x "$CUSTOMER/android/gradlew" ]; then
  (cd "$CUSTOMER/android" && ./gradlew --stop >/dev/null 2>&1) || true
fi

apk_log="/tmp/getin-phase3-customer-apk.log"
if (cd "$CUSTOMER" && flutter build apk --debug >"$apk_log" 2>&1); then
  tail -15 "$apk_log"
else
  cat "$apk_log"
  fail "Customer Android debug APK"
fi

echo
echo "=== LARAVEL CUSTOMER AUTH / ACCOUNT FOCUSED TESTS ==="
laravel_tests="
tests/Feature/Api/V1/Customer/CustomerLoginApiTest.php
tests/Feature/Api/V1/Customer/CustomerRegistrationApiTest.php
tests/Feature/Api/V1/Customer/CustomerOtpApiTest.php
tests/Feature/Api/V1/Customer/CustomerProfileApiTest.php
tests/Feature/Api/V1/Customer/CustomerAddressesApiTest.php
tests/Feature/Api/V1/Customer/CustomerPreferencesApiTest.php
tests/Feature/Api/V1/Customer/CustomerSessionsDevicesApiTest.php
tests/Feature/Release/AuthenticationFinalQaTest.php
"

for f in $laravel_tests; do
  [ -f "$LARAVEL/$f" ] || fail "Missing Laravel test: $f"
done

laravel_focused="/tmp/getin-phase3-laravel-focused.log"
if (cd "$LARAVEL" && php artisan test $laravel_tests >"$laravel_focused" 2>&1); then
  grep -E "Tests:|Duration:" "$laravel_focused" | tail -2 || tail -8 "$laravel_focused"
else
  cat "$laravel_focused"
  fail "Laravel focused customer auth/account tests"
fi

echo
echo "=== FULL LARAVEL REGRESSION — QUIET ==="
laravel_full="/tmp/getin-phase3-laravel-full.log"
if (cd "$LARAVEL" && php artisan test >"$laravel_full" 2>&1); then
  grep -E "Tests:|Duration:" "$laravel_full" | tail -2 || tail -8 "$laravel_full"
else
  cat "$laravel_full"
  fail "Laravel full regression"
fi

echo
echo "=== FINAL DIFF CHECK ==="
git -C "$CUSTOMER" diff --check || fail "Customer diff check"
git -C "$LARAVEL" diff --check || fail "Laravel diff check"

echo
echo "PHASE 3 CUSTOMER AUTH / ACCOUNT RELEASE GATE: PASS"
