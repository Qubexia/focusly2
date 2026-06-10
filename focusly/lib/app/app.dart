import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/deep_link_service.dart';
import '../core/services/premium_refresh_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event_state.dart';
import '../features/subscription/presentation/cubit/subscription_cubit.dart';
import 'router.dart';

class ZakerlyApp extends StatefulWidget {
  const ZakerlyApp({super.key});

  @override
  State<ZakerlyApp> createState() => _ZakerlyAppState();
}

class _ZakerlyAppState extends State<ZakerlyApp> with WidgetsBindingObserver {
  AuthBloc? _authBloc;
  SubscriptionCubit? _subscriptionCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.initialize(appRouter);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPremiumStatus();
    }
  }

  void _refreshPremiumStatus() {
    final authBloc = _authBloc;
    if (authBloc == null) return;
    if (authBloc.state is! AuthAuthenticated) return;
    PremiumRefreshService.instance.refreshOnce(authBloc);
    _subscriptionCubit?.load();
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      context.read<SubscriptionCubit>().load();
      PremiumRefreshService.instance.refreshOnce(context.read<AuthBloc>());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = AuthBloc();
            _authBloc = bloc;
            return bloc;
          },
        ),
        BlocProvider(create: (_) {
          final cubit = SubscriptionCubit();
          _subscriptionCubit = cubit;
          return cubit;
        }),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                current is AuthAuthenticated &&
                (previous is! AuthAuthenticated ||
                    previous.user.id != current.user.id),
            listener: _onAuthStateChanged,
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: premiumStatusChanged,
            listener: (context, state) {
              context.read<SubscriptionCubit>().load();
            },
          ),
        ],
        child: MaterialApp.router(
        title: 'Zakerly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        ),
      ),
    );
  }
}
