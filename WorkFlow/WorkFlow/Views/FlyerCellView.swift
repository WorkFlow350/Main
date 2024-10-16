//
//  FlyerCellView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/15/24.
//
//City
//Specialty
//Name
//Wage Type

import SwiftUI

struct FlyerCellView: View {
    let contractor: ContractorProfile
    @State private var isFullScreen: Bool = false // State to toggle full-screen view
    @StateObject private var contractorController = ContractorController()
    
    var body: some View {
        VStack {
          
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                            Text("Specialty:")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            
                            ForEach(contractor.skills, id: \.self) { skill in
                                Text(skill)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        //.padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    //.padding(.bottom, 5)
                    
                    Text(contractor.contractorName)
                        .font(.headline)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                        .padding(.top, 5) // Optional: set a small top padding for spacing
                        .padding(.bottom, 5) // Optional: set a small bottom padding for spacing
                    
                    Text("Service Area: \(contractor.city)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .fontWeight(.medium)

            }
        }
        .frame(maxWidth: .infinity)
        .padding(8) // Overall padding around the entire VStack if needed
        .background(Color.white) // Background color for visibility
        .cornerRadius(8) // Rounded corners
        .shadow(radius: 2) // Optional shadow for better UI
    }
}


// Preview provider for JobView
struct FlyerCellView_Previews: PreviewProvider {
    static var previews: some View {
        FlyerCellView(contractor: ContractorProfile(id: UUID(), contractorName: "Bob the Builder LLC", bio:"big buttface", skills: ["plumber","landscape","welding","tile"], rating: 5.0, jobsCompleted: 0, city: "Oxnard", email: "cool9990@gmail.com"))
    }
}


