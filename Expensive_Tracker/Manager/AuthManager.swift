import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AuthManager{

    static let shared = AuthManager()
    private init() {}

    var currentUser: User? { Auth.auth().currentUser }
    var isLoggedIn: Bool   { currentUser != nil }

    // MARK: - Email Sign Up
    func signUp(email: String, password: String, name: String,
                completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error { completion(.failure(error)); return }
            guard let user = result?.user else { return }
            let request = user.createProfileChangeRequest()
            request.displayName = name
            request.commitChanges { _ in completion(.success(user)) }
        }
    }

    // MARK: - Email Sign In
    func signIn(email: String, password: String,
                completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error { completion(.failure(error)); return }
            guard let user = result?.user else { return }
            completion(.success(user))
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle(presenting vc: UIViewController,
                          completion: @escaping (Result<User, Error>) -> Void) {
      
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else { return }

            let idToken     = user.idToken?.tokenString ?? ""
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let firebaseUser = authResult?.user else { return }
                completion(.success(firebaseUser))
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Reset Password
    func resetPassword(email: String,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error { completion(.failure(error)) }
            else { completion(.success(())) }
        }
    }
}
