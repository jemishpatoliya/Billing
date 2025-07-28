
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';

/// 🔸 EVENTS
sealed class RegisterEvent {}

final class SubmitRegisterEvent extends RegisterEvent {
  final UserModel user;
  SubmitRegisterEvent(this.user);
}

/// 🔹 STATES
sealed class RegisterState {}

final class RegisterInitial extends RegisterState {}

final class RegisterLoading extends RegisterState {}

final class RegisterSuccess extends RegisterState {}

final class RegisterFailure extends RegisterState {
  final String error;
  RegisterFailure(this.error);
}

/// 🔸 BLOC
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final UserRepository repository;

  RegisterBloc(this.repository) : super(RegisterInitial()) {
    on<SubmitRegisterEvent>(_onSubmitRegister);
  }

  Future<void> _onSubmitRegister(
      SubmitRegisterEvent event,
      Emitter<RegisterState> emit,
      ) async {
    emit(RegisterLoading());
    try {
      await repository.registerUser(event.user);
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterFailure(e.toString()));
      print(e.toString());
    }
  }
}
