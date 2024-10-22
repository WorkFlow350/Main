//
//  SignInView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/22/24.
//

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack{
            VStack{
                Image("Applcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)
                
                //form fields use inputCellView
                VStack(spacing: 24){
                    InputCellView(text:$email,
                                  title: "Email Address",
                                  placeholder: "name@example")
                    .autocapitalization(.none)
                    InputCellView(text:$password,
                                  title: "Password",
                                  placeholder: "Enter your password", isSecureField:true)
                    .autocapitalization(.none)
                }
                .padding(.horizontal)
                .padding(.top,12)

                //sign in button
                Button{
                    print("Log User in")
                } label: {
                    HStack{
                        Text("SIGN IN")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                }
                .background(Color(.systemBlue))
                .cornerRadius(10)
                .padding(.top, 24)
                
                Spacer()
                
                //sign up button
                // Sign Up & Continue as Guest Buttons
                VStack(spacing: 16) {
                    // Sign Up Button
                    NavigationLink(destination: SignUpView()) {
                        Text("Don't have an account? Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    // Continue as Guest Button
                    NavigationLink(destination: MainTabView()) {
                        Text("Continue as Guest")
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 32)
            }            }
        }
    }


#Preview {
    SignInView()
}
