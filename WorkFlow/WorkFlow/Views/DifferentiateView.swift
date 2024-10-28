//
//  PLACEHOLDER.swift
//  WorkFlow
//
//  Created by Steve Coyotl on 10/22/24.
//

import SwiftUI

struct DifferentiateView: View {
    @EnvironmentObject var AuthController: AuthController
    var body: some View {
        if AuthController.appUser?.role == .homeowner {
            // displays homeowner view
           HoMainView()
        } else if AuthController.appUser?.role == .contractor {
            // displays contractor view
            CoMainView()
        } else {
            Text("theres no user type")
            Text("\(String(describing: AuthController.appUser?.id))")
        }
    }
}

/*#Preview {
    DifferentiateView()
}
*/
