import 'package:flutter_bloc/flutter_bloc.dart';

enum DashboardTab { home, profile, settings }

class DashboardNavCubit extends Cubit<DashboardTab> {
  DashboardNavCubit() : super(DashboardTab.home);

  void changeTab(DashboardTab tab) => emit(tab);
}
