import SwiftUI
import AVKit

struct SplashVideoView: View {
    var onFinished: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
            }

            // 跳过按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: onFinished) {
                        Text("跳过")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(20)
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            guard let url = Bundle.main.url(forResource: "splash", withExtension: "mp4") else { return }
            let p = AVPlayer(url: url)
            p.isMuted = false
            player = p
            p.play()

            // 视频播完自动跳转
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                onFinished()
            }
        }
        .onDisappear {
            player?.pause()
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }
}

// UIViewRepresentable 包装 AVPlayerLayer，支持全屏填充
private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setup(player: player)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

private class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?

    func setup(player: AVPlayer) {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill  // 填满屏幕，16:9 视频竖屏时自动裁剪
        self.layer.addSublayer(layer)
        self.playerLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
