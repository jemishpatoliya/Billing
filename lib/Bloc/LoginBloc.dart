import 'package:flutter_bloc/flutter_bloc.dart';
import '../Database/UserRepository.dart';
import '../Library/UserSession.dart';
import '../Model/UserModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EVENTS
sealed class LoginEvent {}

final class SubmitLoginEvent extends LoginEvent {
  final String email;
  final String password;

  SubmitLoginEvent(this.email, this.password);
}

/// STATES
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserModel user;
  LoginSuccess(this.user);
}

final class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

/// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    on<SubmitLoginEvent>(_onLoginSubmit);
  }

  Future<void> _onLoginSubmit(
      SubmitLoginEvent event,
      Emitter<LoginState> emit,
      ) async {
    emit(LoginLoading());
    try {
      final user = await repository.loginUser(event.email, event.password);
      if (user != null) {
        // Set user session with permissions here
        UserSession.setLoggedInUser(user);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInEmail', user.email ?? ''); // Save email

        emit(LoginSuccess(user));
      } else {
        emit(LoginFailure('Invalid email or password'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
      print(e.toString());
    }
  }
}
