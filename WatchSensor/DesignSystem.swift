//
//  DesignSystem.swift
//  WatchSensor
//
//  モダンなブランドデザインのための共通スタイル定義。
//  配色・角丸・影・タイポグラフィを一元管理し、ダークモードにも対応する。
//

import SwiftUI

// MARK: - Brand Colors

/// アプリ全体のブランドカラー。センサー計測アプリらしい信頼感のある
/// ディープブルー / ティール系を基調にし、ライト・ダーク両対応にする。
enum Brand {
    /// メインのアクセント（ボタン・強調）。
    static let accent = Color("BrandAccent")
    /// サブのアクセント（グラフの2色目など）。
    static let accentSecondary = Color("BrandAccentSecondary")

    /// 画面全体の背景。
    static let background = Color("BrandBackground")
    /// カードやリスト行の背景（背景より一段持ち上げる）。
    static let surface = Color("BrandSurface")

    /// 主要テキスト。
    static let textPrimary = Color.primary
    /// 補助テキスト。
    static let textSecondary = Color.secondary

    /// センサー3軸（X/Y/Z）を色分けするためのパレット。
    static let axisColors: [Color] = [
        Color("BrandAccent"),
        Color("BrandAccentSecondary"),
        Color(red: 0.98, green: 0.55, blue: 0.32) // warm orange
    ]

    /// グラデーション背景（ヘッダーやヒーロー用）。
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.95), accentSecondary.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Layout Tokens

/// 余白・角丸などのレイアウト定数。
/// （SwiftUI の `Layout` プロトコルと名前が衝突しないよう `Metrics` とする）
enum Metrics {
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10
    static let spacing: CGFloat = 16
    static let spacingSmall: CGFloat = 8
    static let cardPadding: CGFloat = 16
}

// MARK: - Reusable Card Style

/// カード風のコンテナ装飾。リスト行や各種セクションで共通利用する。
struct CardModifier: ViewModifier {
    var padding: CGFloat = Metrics.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .fill(Brand.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    /// カード装飾を付与する。
    func brandCard(padding: CGFloat = Metrics.cardPadding) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Primary Button Style

/// ブランドカラーのグラデーションを使った主要アクション用ボタンスタイル。
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cornerRadiusSmall, style: .continuous)
                    .fill(Brand.heroGradient)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .shadow(color: Brand.accent.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Custom Dialog

/// 画像・タイトル・メッセージ・OK ボタンを持つカスタムダイアログ。
/// 標準 `.alert` は画像を埋め込めないため、こちらでブランド調のカードを浮かせる。
struct BrandDialog: View {
    let imageName: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let confirmTitle: LocalizedStringKey
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: Metrics.spacing) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 140)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusSmall, style: .continuous))
            }

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onConfirm) {
                Text(confirmTitle)
            }
            .buttonStyle(BrandButtonStyle())
        }
        .padding(Metrics.spacing + 4)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(Brand.surface)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 40)
    }
}

/// 背景を暗くしてダイアログを中央に浮かせる表示 modifier。
private struct BrandDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let imageName: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let confirmTitle: LocalizedStringKey
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    BrandDialog(
                        imageName: imageName,
                        title: title,
                        message: message,
                        confirmTitle: confirmTitle
                    ) {
                        isPresented = false
                        onConfirm()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// 画像付きのカスタムダイアログを表示する。
    func brandDialog(
        isPresented: Binding<Bool>,
        imageName: String? = nil,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        confirmTitle: LocalizedStringKey = "OK",
        onConfirm: @escaping () -> Void = {}
    ) -> some View {
        modifier(BrandDialogModifier(
            isPresented: isPresented,
            imageName: imageName,
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm
        ))
    }
}
