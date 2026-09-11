import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO Startup Routing & Auth Decision Engine Tests', () {
    test('Scenario 1: Fresh install routes to Language Selection', () {
      const session = UserSession(
        hasSelectedLanguage: false,
        hasSelectedRole: false,
        isArtisanAuthenticated: false,
        isCustomerAuthenticated: false,
      );

      expect(session.startupRoute, '/language-selection');
    });

    test('Scenario 2: Language selected but role not chosen routes to Role Selection', () {
      const session = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: false,
        isArtisanAuthenticated: false,
        isCustomerAuthenticated: false,
      );

      expect(session.startupRoute, '/welcome');
    });

    test('Scenario 3: Artisan role selected but not logged in routes to Artisan Login', () {
      const session = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: false,
        isCustomerAuthenticated: false,
      );

      expect(session.startupRoute, '/login');
    });

    test('Scenario 4: Customer role selected but not logged in routes to Customer Login', () {
      const session = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isArtisanAuthenticated: false,
        isCustomerAuthenticated: false,
      );

      expect(session.startupRoute, '/customer/login');
    });

    test('Scenario 5: Authenticated Artisan boots straight to Artisan Home', () {
      const session = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: true,
      );

      expect(session.startupRoute, '/home');
      expect(session.isAuthenticated, isTrue);
    });

    test('Scenario 6: Authenticated Customer boots straight to Customer Home', () {
      const session = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: true,
        hasCustomerProfile: true,
      );

      expect(session.startupRoute, '/customer/home');
      expect(session.isAuthenticated, isTrue);
    });

    test('Scenario 7: SessionNotifier loginAsArtisan sets authentication & persists state', () async {
      final notifier = SessionNotifier(const UserSession());
      notifier.loginAsArtisan(
        mobileNumber: '+91 98765 43210',
        name: 'Meenakshi Ammal',
        craftType: 'Toda Embroidery',
        region: 'Nilgiris, Tamil Nadu',
      );

      expect(notifier.state.isArtisanAuthenticated, isTrue);
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.activeRole, UserRole.artisan);
      expect(notifier.state.artisanName, 'Meenakshi Ammal');
      expect(notifier.state.startupRoute, '/home');
    });

    test('Scenario 8: SessionNotifier loginAsCustomer sets authentication & persists state', () async {
      final notifier = SessionNotifier(const UserSession());
      notifier.loginAsCustomer(
        mobileNumber: '+91 91234 56789',
        name: 'Rahul Varma',
      );

      expect(notifier.state.isCustomerAuthenticated, isTrue);
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.activeRole, UserRole.customer);
      expect(notifier.state.customerName, 'Rahul Varma');
      expect(notifier.state.startupRoute, '/customer/home');
    });

    test('Scenario 9: Role switching preserves dual sessions when both are authenticated', () {
      final notifier = SessionNotifier(const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        isCustomerAuthenticated: true,
      ));

      // Switch to customer
      final switchResult = notifier.switchRole(UserRole.customer);
      expect(switchResult, RoleSwitchResult.switched);
      expect(notifier.state.activeRole, UserRole.customer);
      expect(notifier.state.isCustomerAuthenticated, isTrue);
      expect(notifier.state.isArtisanAuthenticated, isTrue);

      // Switch back to artisan
      final switchBackResult = notifier.switchRole(UserRole.artisan);
      expect(switchBackResult, RoleSwitchResult.switched);
      expect(notifier.state.activeRole, UserRole.artisan);
      expect(notifier.state.isArtisanAuthenticated, isTrue);
      expect(notifier.state.isCustomerAuthenticated, isTrue);
    });

    test('Scenario 10: Role switching asks for auth if target role has never logged in', () {
      final notifier = SessionNotifier(const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: true,
        isArtisanAuthenticated: false,
      ));

      // Attempt switch to unauthenticated Artisan
      final switchResult = notifier.switchRole(UserRole.artisan);
      expect(switchResult, RoleSwitchResult.needsArtisanAuth);
      expect(notifier.state.isCustomerAuthenticated, isTrue);
    });

    test('Scenario 11: Artisan logout only clears Artisan session and preserves Customer session', () async {
      final notifier = SessionNotifier(const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        isCustomerAuthenticated: true,
      ));

      await notifier.logoutArtisan();

      expect(notifier.state.isArtisanAuthenticated, isFalse);
      expect(notifier.state.isCustomerAuthenticated, isTrue);
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.startupRoute, '/login');
    });

    test('Scenario 12: Customer logout only clears Customer session and preserves Artisan session', () async {
      final notifier = SessionNotifier(const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isArtisanAuthenticated: true,
        isCustomerAuthenticated: true,
      ));

      await notifier.logoutCustomer();

      expect(notifier.state.isCustomerAuthenticated, isFalse);
      expect(notifier.state.isArtisanAuthenticated, isTrue);
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.startupRoute, '/customer/login');
    });

    test('Scenario 13: Uncompleted Artisan profile routes to onboarding until completed', () {
      var session = const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: false,
      );

      expect(session.startupRoute, '/onboarding');

      session = session.copyWith(hasArtisanProfile: true);
      expect(session.startupRoute, '/home');
    });
  });
}
