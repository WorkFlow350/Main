import SwiftUI

struct InputCellView: View {
    // MARK: - Properties
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false
    var isRequired = false
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Title
            HStack{
                Text(title)
                    .foregroundColor(Color(.darkGray))
                    .fontWeight(.semibold)
                    .font(.footnote)
                if isRequired{
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .font(.footnote)
                }
            }

            // MARK: - Input Field
            if isSecureField {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
            }

            // MARK: - Divider
            Divider()
        }
    }
}

#Preview {
    InputCellView(text: .constant(""), title: "email address", placeholder: "name@gmail.com")
}
