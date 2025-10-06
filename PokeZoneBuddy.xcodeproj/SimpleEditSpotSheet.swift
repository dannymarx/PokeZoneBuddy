import SwiftUI
import SwiftData

@available(*, deprecated, message: "Use EditSpotSheet instead.")
struct SimpleEditSpotSheet: View {
    let spot: CitySpot
    let viewModel: CitiesViewModel

    var body: some View {
        EditSpotSheet(spot: spot, viewModel: viewModel)
    }
}
