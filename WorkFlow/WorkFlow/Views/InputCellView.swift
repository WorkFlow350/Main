//  InputCellView.swift - A reusable input component for text fields, supporting both regular and secure inputs.
import SwiftUI

struct InputCellView: View {
    @Binding var text: String  // Binding to hold the user input text.
    let title: String  // Title label for the input field.
    let placeholder: String  // Placeholder text for the input field.
    var isSecureField = false  // Flag to determine if the field should be secure.

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display the title above the input field.
            Text(title)
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.footnote)

            // Conditionally render a secure or regular text field.
            if isSecureField {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))  // Set font size for secure input.
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))  // Set font size for regular input.
            }

            Divider()  // Divider line below the input field for separation.
        }
    }
}

// Preview for InputCellView.
#Preview {
    InputCellView(text: .constant(""), title: "email address", placeholder: "name@gmail.com")
}
