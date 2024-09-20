import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart'; // Import Home Screen
import 'analytics.dart'; // Import Analytics Screen
import 'notifications.dart'; // Import Notifications Screen
import 'profile.dart'; // Import Profile Screen
import 'signin.dart'; // Import Sign In Screen
import 'register.dart'; // Import Register Screen
import 'splashScreen.dart'; // Import Splash Screen
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Your generated Firebase options file
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'auth_service.dart';
import 'emailverification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized.');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}
class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final AuthService _authService = AuthService();

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/signin': (context) => SignInScreen(),
        '/home': (context) => MainScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/register': (context) => RegisterScreen(),
        '/emailVerification': (context) => EmailVerificationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home' && !isLoggedIn) {
          return MaterialPageRoute(builder: (context) => SignInScreen());
        }
        return null;
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static List<Widget> _pages = <Widget>[
    HomeScreen(userName: '',),
    AnalyticsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AuthService().listenAuthStateChanges(); // Listen to auth state changes
    _handleDynamicLinks();
  }

  void _handleDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink
        .listen((PendingDynamicLinkData? dynamicLink) {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        // Handle the deep link, e.g., email verification
        if (deepLink.queryParameters.containsKey('email')) {
          String email = deepLink.queryParameters['email']!;
          String emailLink = deepLink.toString();

          AuthService().signInWithEmailLink(email, emailLink).then((user) {
            if (user != null) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }).catchError((error) {
            print('Error signing in with email link: $error');
          });
        }
      }
    }).onError((error) {
      print('Error handling dynamic link: $error');
    });

    // Handle initial dynamic link if the app was opened using it
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = initialLink?.link;

    if (deepLink != null && deepLink.queryParameters.containsKey('email')) {
      String email = deepLink.queryParameters['email']!;
      String emailLink = deepLink.toString();

      AuthService().signInWithEmailLink(email, emailLink).then((user) {
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }).catchError((error) {
        print('Error signing in with email link: $error');
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
