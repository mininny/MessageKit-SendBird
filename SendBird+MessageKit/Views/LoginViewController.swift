//
//  LoginViewController.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/21.
//  Copyright © 2020 Mininny. All rights reserved.
//

import UIKit
import SendBirdSDK

class LoginViewController: UIViewController {
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBAction func didPressSignInButton(_ sender: Any) {
        guard let userId = self.userIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), userId != "" else {
            return
        }
        self.updateButtonUI()
        self.signIn(userId: userId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userIdTextField.delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController {
            destination.modalPresentationStyle = .fullScreen
        }
    }
    
    func signIn(userId: String) {
        // MARK: SendBirdCall.authenticate()
        SBDMain.connect(withUserId: userId) { (user, error) in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.resetButtonUI()
                }
            }
            
            guard user != nil, error == nil else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.performSegue(withIdentifier: "SignedIn", sender: nil)
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func resetButtonUI() {
        self.signInButton.backgroundColor = UIColor(red: 123 / 255, green: 83 / 255, blue: 239 / 255, alpha: 1.0)
        self.signInButton.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 0.88), for: .normal)
        self.signInButton.setTitle("Sign In", for: .normal)
        self.signInButton.isEnabled = true
    }
    
    func updateButtonUI() {
        self.signInButton.backgroundColor = UIColor(red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1.0)
        self.signInButton.setTitleColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.12), for: .normal)
        self.signInButton.setTitle("Signing In...", for: .normal)
        self.signInButton.isEnabled = false
    }
}

