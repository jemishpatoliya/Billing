import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';

/// 🔸 EVENTS
abstract class RegisterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitRegisterEvent extends RegisterEvent {
  final UserModel user;
  SubmitRegisterEvent(this.user);

  @override
  List<Object?> get props => [user];
}

/// 🔹 STATES
abstract class RegisterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {}

class RegisterFailure extends RegisterState {
  final String error;
  RegisterFailure(this.error);

  @override
  List<Object?> get props => [error];
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
    }
  }
}
