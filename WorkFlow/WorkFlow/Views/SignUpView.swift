//
//  SignUpView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/22/24.
//

import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""
    @State private var profileName: String = ""
    @State private var profileBio: String = ""
    @State private var password: String = ""
    @State private var passwordConfirmation: String = ""
    @State private var city: String = ""
    
    @State private var selectedCategory: JobCategory = .landscaping
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var isHomeowner: Bool = true
    @State private var isCategoryPickerPresented: Bool = false
    /*
     email, name, city, password, confirm password, category, image, isImagePickerPresented, isCategoryPickerPresented
     */
    @EnvironmentObject var jobController: JobController
    @EnvironmentObject var contractorController: ContractorController
    var body: some View {
        ZStack {
            /*
             // Add gradient background from light to dark blue
             LinearGradient(
             gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
             startPoint: .top,
             endPoint: .bottom
             )
             .edgesIgnoringSafeArea(.all) // Ensure background covers entire screen
             */
            ScrollView { // Wrap everything in a ScrollView
                VStack(spacing: 20) {
                    // Toggle between Homeowner and Contractor view
                    Picker("Account Type", selection: $isHomeowner) {
                        Text("Homeowner").tag(true)
                        Text("Contractor").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding() // Styling: Padding for the toggle
                    
                    // Section for entering job or flyer details
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Custom styling for the text fields
                        if(isHomeowner){
                            InputCellView(text:$email,
                                          title: "Email Address",
                                          placeholder: "name@example")
                            .autocapitalization(.none)
                            
                            InputCellView(text:$profileName,
                                          title: "Full Name",
                                          placeholder: "John Smith")
                            .autocapitalization(.none)
                            
                            InputCellView(text:$city,
                                          title: "City",
                                          placeholder: "Camarillo")
                            .autocapitalization(.none)
                            InputCellView(text:$password,
                                          title: "Password",
                                          placeholder: "Enter your password", isSecureField:true)
                            .autocapitalization(.none)
                            
                            InputCellView(text:$passwordConfirmation,
                                          title: "Confirm Password",
                                          placeholder: "Enter your password", isSecureField:true)
                            .autocapitalization(.none)
                        }
                        else{
                            InputCellView(text:$email,
                                          title: "Email Address",
                                          placeholder: "name@example")
                            .autocapitalization(.none)
                            
                            InputCellView(text:$profileName,
                                          title: "Company Name",
                                          placeholder: "WorkFlow")
                            .autocapitalization(.none)
                            
                            InputCellView(text:$profileBio,
                                          title: "Company Bio",
                                          placeholder: "Describe skills")
                            .autocapitalization(.none)
                            
                            InputCellView(text:$city,
                                          title: "City",
                                          placeholder: "Camarillo")
                            .autocapitalization(.none)
                            
                            
                            InputCellView(text:$password,
                                          title: "Password",
                                          placeholder: "Enter your password", isSecureField:true)
                            .autocapitalization(.none)
                            
                            InputCellView(text:$passwordConfirmation,
                                          title: "Confirm Password",
                                          placeholder: "Enter your password", isSecureField:true)
                            .autocapitalization(.none)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top,12)
        
        Button{
            print("Log User in")
        } label: {
            HStack{
                Text("SIGN UP")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            
            .foregroundColor(.white)
            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
        }
        .background(Color(.systemBlue))
        .cornerRadius(10)
        .padding(.top, 24)
        
    }
    
    
    struct SignUpView_Previews: PreviewProvider {
        static var previews: some View {
            SignUpView()
        }
    }
}
