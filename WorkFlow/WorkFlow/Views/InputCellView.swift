//
//  InputCellView.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/22/24.
//

import SwiftUI

struct InputCellView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Text(title)
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.footnote)
            if isSecureField{
                SecureField(placeholder, text: $text)
                    .font(.system(size:14))
            }
            else{
                TextField(placeholder, text: $text)
                    .font(.system(size:14))
            }
            Divider()
        }
    }
}

#Preview {
    InputCellView(text: .constant(""), title:"email address", placeholder: "name@gmail.com")
}
