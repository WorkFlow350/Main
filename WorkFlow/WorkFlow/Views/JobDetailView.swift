//
//  JobDetailView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/14/24.
//

import SwiftUI

struct JobDetailView: View {
    let job: Job // Pass in the job data from the selected cell

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text(job.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Location: \(job.city)")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Category: \(job.category.rawValue)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("Description:")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(job.description)
                    .font(.body)
                    .padding(.top, 5)

                Spacer()
            }
            .padding()
            .navigationTitle("Job Details") // This will appear in the navigation bar
        }
}
/*
 #Preview {
 JobDetailView()
 }
 */
