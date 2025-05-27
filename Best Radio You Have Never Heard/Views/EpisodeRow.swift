import SwiftUI

struct EpisodeRow: View {
    let item: RSSItem
    @Binding var selectedItemId: UUID?
    
    var body: some View {
        HStack(spacing: 12) {
            // Row image with improved styling
            Image("RowImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 100)
                .cornerRadius(8)
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Progress indicator
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(.orange)
                    .cornerRadius(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            NavigationLink(destination: DetailView(item: item)
                .onAppear { selectedItemId = item.id }
                .onDisappear { selectedItemId = nil }
            ) {
                EmptyView()
            }
            .opacity(0)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
} 