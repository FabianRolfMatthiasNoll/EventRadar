import 'package:event_radar/views/profile/profile_settings_screen.dart';
import 'package:event_radar/views/profile/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/viewmodels/profile_settings_viewmodel.dart';
import '../../widgets/main_scaffold.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
        title: 'Profil',
        currentIndex: 3,
        // body: ProfileSettingsScreen(),
        body: RegisterScreen(),
    );
  }
}
