//
//  SessionListView.swift
//  WatchSensor
//
//  保存済みセンサー計測セッションの一覧画面（SwiftUI）。
//

import SwiftUI

struct SessionListView: View {
    @StateObject private var viewModel = SessionListViewModel()
    /// 同意フロー（UMP → ATT → 広告初期化）を一度だけ起動するためのフラグ。
    @State private var didStartConsentFlow = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.background.ignoresSafeArea()

                Group {
                    if viewModel.sessions.isEmpty {
                        EmptyStateView()
                    } else {
                        sessionList
                    }
                }
            }
            .navigationTitle("Watch Sensor")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Brand.background, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if !AdsConfig.isHidden {
                    AdBannerView()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Brand.background)
                }
            }
        }
        .tint(Brand.accent)
        .onAppear {
            guard !didStartConsentFlow else { return }
            didStartConsentFlow = true
            // UI が表示されてから同意フロー→広告初期化を開始する（scene が必要なため）。
            ConsentManager.shared.gatherConsentAndStartAds()
        }
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: Metrics.spacing) {
                ForEach(viewModel.sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionRowView(session: session)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.spacing)
            .padding(.top, Metrics.spacing)
            .padding(.bottom, Metrics.spacing)
        }
        .refreshable {
            viewModel.reload()
        }
    }
}

/// リスト1行分のカード。計測名・日時・アイコンを表示する。
struct SessionRowView: View {
    let session: SessionRecord

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: Metrics.spacing) {
            ZStack {
                RoundedRectangle(cornerRadius: Metrics.cornerRadiusSmall, style: .continuous)
                    .fill(Brand.heroGradient)
                    .frame(width: 48, height: 48)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.directoryName)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                if session.createdAt.timeIntervalSince1970 > 0 {
                    Text(Self.dateFormatter.string(from: session.createdAt))
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Brand.textSecondary.opacity(0.6))
        }
        .brandCard()
    }
}

/// 保存データが無いときの空状態。
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: Metrics.spacing) {
            ZStack {
                Circle()
                    .fill(Brand.accent.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "applewatch.watchface")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Brand.accent)
            }
            Text("No Measurements Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
            Text("Start a recording on your Apple Watch and save it to see your data here.")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    SessionListView()
}
