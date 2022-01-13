import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/documents.dart';
import 'package:partner_app/screens/home.dart';
import 'package:partner_app/screens/insertEmail.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseDatabase/methods.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

extension AppFirebaseAuth on FirebaseAuth {
  Future<void> verificationCompletedCallback({
    @required BuildContext context,
    @required PhoneAuthCredential credential,
    @required FirebaseDatabase firebaseDatabase,
    @required FirebaseAuth firebaseAuth,
    @required Function onExceptionCallback,
  }) async {
    try {
      // important: if the user doesn't have an account, one will be created
      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // however, we only consider the user to be registered as a pilot, if they
      // have an entry in partners database. It may also be the case that the user
      // already has an account throught the client app (e.g., firebase.isRegistered
      // is true and they have a displayName). In those cases, we use some of
      // their already provided information (phone number, email and password).
      FirebaseModel firebase = Provider.of<FirebaseModel>(
        context,
        listen: false,
      );

      // try download partner data
      PartnerModel partner = Provider.of<PartnerModel>(
        context,
        listen: false,
      );
      TripModel trip = Provider.of<TripModel>(
        context,
        listen: false,
      );

      try {
        // download partner data
        await partner.downloadData(firebase);
        // if partner has active trip request, download it as well
        if (partner.partnerStatus == PartnerStatus.busy) {
          await trip.downloadData(firebase, notify: false);
        }
      } catch (e) {
        throw FirebaseAuthException(code: "internal-error");
      }

      // if user already has a partner account
      if (partner.id != null && firebase.isRegistered) {
        // log sign in event
        try {
          await firebase.analytics.logLogin();
        } catch (_) {}

        // if accountStatus is 'approved', push Home screen
        if (partner.accountStatus == AccountStatus.approved) {
          GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(
            context,
            listen: false,
          );
          TimerModel timer = Provider.of<TimerModel>(
            context,
            listen: false,
          );

          ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
            context,
            listen: false,
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            Home.routeName,
            (_) => false,
            arguments: HomeArguments(
              firebase: firebase,
              partner: partner,
              googleMaps: googleMaps,
              timer: timer,
              trip: trip,
              connectivity: connectivity,
            ),
          );
        } else {
          // otherwise, push documents screen
          Navigator.pushReplacementNamed(
            context,
            Documents.routeName,
            arguments: DocumentsArguments(firebase: firebase, partner: partner),
          );
        }
      } else if (firebase.isRegistered) {
        // if user already has a client account, skip insertEmail and push
        // inserName screen. After all, they are to keep their login credentials
        // but have the chance of inserting their actual name and other info.
        Navigator.pushNamed(
          context,
          InsertName.routeName,
          arguments: InsertNameArguments(
            userCredential: userCredential,
            userEmail: firebase.auth.currentUser.email,
          ),
        );
      } else {
        // if user has no partner or client account, push insertEmail
        Navigator.pushNamed(
          context,
          InsertEmail.routeName,
          arguments: InsertEmailArguments(userCredential: userCredential),
        );
      }
    } catch (e) {
      onExceptionCallback(e);
    }
  }

  String verificationFailedCallback(FirebaseAuthException e) {
    String warningMessage;
    if (e.code == "invalid-phone-number") {
      warningMessage = "Número de telefone inválido. Por favor, tente outro.";
    } else if (e.code == "too-many-requests") {
      warningMessage =
          "Ops, número de tentativas excedidas. Tente novamente em alguns minutos.";
    } else if (e.code == "network-request-failed") {
      warningMessage =
          "Você está offline. Conecte-se à internet e tente novamente.";
    } else {
      warningMessage = "Ops, algo deu errado. Tente novamente mais tarde.";
    }
    return warningMessage;
  }

  Future<CreateEmailResponse> createEmail(String email) async {
    try {
      // try to sign in with provided email
      await this.signInWithEmailAndPassword(
        email: email,
        password: Uuid().v4(),
      );
      // in the unlikely case sign in succeeds, sign back out
      this.signOut();
      // return false because there is already an account with the email;
      return CreateEmailResponse(
        successful: false,
        message: "O email já está sendo usado. Tente outro.",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        // user not found means there is no account with the email
        return CreateEmailResponse(successful: true);
      }
      if (e.code == "wrong-password") {
        // wrong password means the email is already registered
        return CreateEmailResponse(
          successful: false,
          message: "O email já está sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return CreateEmailResponse(
          successful: false,
          message: "Email inválido. Tente outro.",
        );
      }
      return CreateEmailResponse(
        successful: false,
        message: "O email não pode ser usado. Tente outro.",
      );
    }
  }

  Future<void> createPartner(
    FirebaseModel firebase,
    UserCredential credential, {
    String email,
    String password,
    @required String displayName,
    @required String cpf,
    @required Gender gender,
  }) async {
    try {
      //update other userCredential information
      if (email != null) {
        await credential.user.updateEmail(email);
      }
      if (password != null) {
        await credential.user.updatePassword(password);
      }
      await credential.user.updateDisplayName(displayName);

      // create partner entry in database with some of the fields set
      final partner = this.currentUser;
      try {
        await firebase.database.createPartner(PartnerInterface.fromJson({
          "uid": partner.uid,
          "name": partner.displayName.split(" ").first,
          "last_name": partner.displayName
              .substring(partner.displayName.indexOf(" ") + 1),
          "cpf": cpf,
          "gender": gender.toString().substring(7),
          "phone_number": partner.phoneNumber,
          "account_status": "pending_documents",
        }));
      } catch (e) {
        throw FirebaseAuthException(code: "database-failure");
      }

      // send email verification if necessary
      if (!firebase.auth.currentUser.emailVerified) {
        await credential.user.sendEmailVerification();
      }

      // log sign up event
      try {
        await firebase.analytics.logSignUp(signUpMethod: "phone_number");
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential> _reauthenticateWithEmailAndPassword(String password) {
    // reauthenticate user to avoid 'requires-recent-login' error
    EmailAuthCredential credential = EmailAuthProvider.credential(
      email: this.currentUser.email,
      password: password,
    );
    return this.currentUser.reauthenticateWithCredential(credential);
  }

  Future<CheckPasswordResponse> checkPassword(String password) async {
    try {
      // check if user entered correct old password and avoid 'requires-recent-login' error
      await _reauthenticateWithEmailAndPassword(password);
      return CheckPasswordResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "wrong-password":
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message: "Senha incorreta. Tente novamente.",
          );
        case "too-many-requests":
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message:
                "Muitas tentativas sucessivas. Tente novamente mais tarde.",
          );
        default:
          // user-mismatch, user-not-found, invalid-credential, invalid-email
          // should never happen
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message: "Algo deu errado. Tente novamente mais tarde.",
          );
      }
    }
  }

  Future<UpdatePasswordResponse> reauthenticateAndUpdatePassword({
    @required String oldPassword,
    @required String newPassword,
  }) async {
    // check if user entered correct old password and avoid 'requires-recent-login' error
    CheckPasswordResponse cpr = await checkPassword(oldPassword);
    if (cpr != null && !cpr.successful) {
      return UpdatePasswordResponse(
        successful: cpr.successful,
        code: cpr.code,
        message: cpr.message,
      );
    }

    try {
      // update password
      await this.currentUser.updatePassword(newPassword);
      return UpdatePasswordResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "weak-password": // should never happen
          return UpdatePasswordResponse(
            successful: false,
            code: e.code,
            message: "Nova senha muito fraca. Tente novamente.",
          );
        default: // should never happen
          // requires-recent-login
          return UpdatePasswordResponse(
            successful: false,
            code: e.code,
            message:
                "Falha ao atualizar senha. Saia da conta, entre novamente e tente outra vez.",
          );
      }
    }
  }

  Future<UpdateEmailResponse> reauthenticateAndUpdateEmail({
    @required String email,
    @required String password,
  }) async {
    try {
      // reauthenticate user to avoid 'requires-recent-login' error
      await _reauthenticateWithEmailAndPassword(password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Senha incorreta. Tente novamente.",
        );
      } else {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Algo deu errado. Tente novamente mais tarde.",
        );
      }
    }

    try {
      // try to update email
      await this.currentUser.updateEmail(email);
      return UpdateEmailResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "O email já está sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Email inválido. Tente outro.",
        );
      }
      // e.code == "requires-recent-login" should never happen
      return UpdateEmailResponse(
        successful: false,
        code: e.code,
        message:
            "Falha ao alterar email. Saia e entre novamente na sua conta e tente novamente.",
      );
    }
  }

  // Future<DeleteAccountResponse> deleteAccount({
  //   @required FirebaseModel firebase,
  //   @required String password,
  //   @required Map<DeleteReason, bool> reasons,
  // }) async {
  //   UserCredential userCredential;
  //   try {
  //     // check if user entered correct old password and avoid 'requires-recent-login' error
  //     userCredential = await _reauthenticateWithEmailAndPassword(password);
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == "wrong-password") {
  //       return DeleteAccountResponse(
  //         successful: false,
  //         code: e.code,
  //         message: "Senha incorreta. Tente novamente.",
  //       );
  //     } else {
  //       return DeleteAccountResponse(
  //         successful: false,
  //         code: e.code,
  //         message: "Algo deu errado. Tente novamente mais tarde.",
  //       );
  //     }
  //   }

  //   try {
  //     // delete user from firebase authentication
  //     await userCredential.user.delete();
  //     return DeleteAccountResponse(successful: true);
  //   } on FirebaseAuthException catch (_) {
  //     return DeleteAccountResponse(
  //       successful: false,
  //       message: "Algo deu errado. Tente novamente mais tarde.",
  //     );
  //   }
  // }
}

class CreateEmailResponse {
  final bool successful;
  final String message;
  final String code;

  CreateEmailResponse({
    @required this.successful,
    this.code,
    this.message,
  });
}

class UpdateEmailResponse extends CreateEmailResponse {
  UpdateEmailResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class UpdatePasswordResponse extends CreateEmailResponse {
  UpdatePasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class CheckPasswordResponse extends CreateEmailResponse {
  CheckPasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class DeleteAccountResponse extends CreateEmailResponse {
  DeleteAccountResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}
