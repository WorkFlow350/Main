//
//  fullScreenImageView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/14/24.
//

import SwiftUI

struct fullScreenImageView: View {
    let imageUrl: String?
    @Binding var isFullScreen: Bool

    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea() // Black background
            
            if let imageURL = imageUrl, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit() // Keep aspect ratio for full-screen image
                        .ignoresSafeArea() // Cover the entire screen
                        .onTapGesture {
                            withAnimation {
                                isFullScreen = false // Dismiss full-screen on tap
                            }
                        }
                } placeholder: {
                    ProgressView() // Placeholder while loading
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            // Back Button
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            isFullScreen = false // Dismiss the full-screen view
                        }
                    }) {
                        Image(systemName: "chevron.left") // Use a back arrow icon
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}


