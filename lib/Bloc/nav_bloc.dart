import 'package:flutter_bloc/flutter_bloc.dart';

class NavCubit extends Cubit<String> {
  NavCubit() : super('transport');

  void changePage(String page) => emit(page);
}
